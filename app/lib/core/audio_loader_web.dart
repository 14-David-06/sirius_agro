import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// En web `record` devuelve un blob URL; se lee con un GET al propio blob.
Future<Uint8List> readAudio(String url) async {
  final response = await http.get(Uri.parse(url));
  return response.bodyBytes;
}

Future<void> deleteAudio(String url) async {}
