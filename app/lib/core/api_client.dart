import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/answer.dart';
import '../models/report.dart';
import 'config.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class TranscriptionResult {
  const TranscriptionResult({required this.text, this.durationSeconds});
  final String text;
  final double? durationSeconds;
}

class PublishResult {
  const PublishResult({required this.recordId, required this.url});
  final String recordId;
  final String url;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _headers => {
        'X-API-Key': AppConfig.apiKey,
        'Content-Type': 'application/json',
      };

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Never _fail(http.Response response) {
    String detail = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        detail = decoded['detail'].toString();
      }
    } catch (_) {
      // El backend no siempre responde JSON (proxies, 502 de infraestructura).
    }
    throw ApiException('HTTP ${response.statusCode}: $detail');
  }

  Future<TranscriptionResult> transcribe({
    required Uint8List audio,
    required String filename,
    String language = 'es',
  }) async {
    final request = http.MultipartRequest('POST', _uri('/v1/transcriptions'))
      ..headers['X-API-Key'] = AppConfig.apiKey
      ..fields['language'] = language
      ..files.add(http.MultipartFile.fromBytes('file', audio, filename: filename));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode >= 400) _fail(response);

    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return TranscriptionResult(
      text: json['text'] as String,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
    );
  }

  Future<Report> buildReport({
    required Map<String, dynamic> meta,
    required String transcript,
    required List<Answer> answers,
  }) async {
    final response = await _client.post(
      _uri('/v1/reports'),
      headers: _headers,
      body: jsonEncode({
        'meta': meta,
        'transcript': transcript,
        'answers': answers.map((a) => a.toJson()).toList(),
      }),
    );
    if (response.statusCode >= 400) _fail(response);

    return Report.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<PublishResult> publish({
    required Map<String, dynamic> meta,
    required String transcript,
    required List<Answer> answers,
    required Report report,
  }) async {
    final response = await _client.post(
      _uri('/v1/meetings'),
      headers: _headers,
      body: jsonEncode({
        'meta': meta,
        'transcript': transcript,
        'answers': answers.map((a) => a.toJson()).toList(),
        'report': report.toJson(),
      }),
    );
    if (response.statusCode >= 400) _fail(response);

    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return PublishResult(
      recordId: json['record_id'] as String,
      url: json['url'] as String,
    );
  }
}
