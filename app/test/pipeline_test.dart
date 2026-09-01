import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirius_reuniones/core/api_client.dart';
import 'package:sirius_reuniones/data/meeting_store.dart';
import 'package:sirius_reuniones/models/answer.dart';
import 'package:sirius_reuniones/models/meeting.dart';
import 'package:sirius_reuniones/models/report.dart';
import 'package:sirius_reuniones/state/meetings.dart';

const _report = Report(
  resumenEjecutivo: 'Se reviso el lote 4.',
  acuerdos: ['Revisar la proxima semana'],
);

/// Backend simulado: cuenta llamadas y puede fallar en el paso que se le pida.
class FakeApi extends ApiClient {
  FakeApi({this.failAt});

  /// 'transcribe', 'report' o 'publish'. Solo falla la primera vez.
  String? failAt;

  int transcribeCalls = 0;
  int reportCalls = 0;
  int publishCalls = 0;

  void _maybeFail(String step) {
    if (failAt == step) {
      failAt = null;
      throw ApiException('$step no disponible');
    }
  }

  @override
  Future<TranscriptionResult> transcribe({
    required Uint8List audio,
    required String filename,
    String language = 'es',
  }) async {
    transcribeCalls++;
    _maybeFail('transcribe');
    return const TranscriptionResult(
      text: 'Ana propuso revisar el lote 4.',
      durationSeconds: 1830,
    );
  }

  @override
  Future<Report> buildReport({
    required Map<String, dynamic> meta,
    required String transcript,
    required List<Answer> answers,
  }) async {
    reportCalls++;
    _maybeFail('report');
    return _report;
  }

  @override
  Future<PublishResult> publish({
    required Map<String, dynamic> meta,
    required String transcript,
    required List<Answer> answers,
    required Report report,
  }) async {
    publishCalls++;
    _maybeFail('publish');
    return const PublishResult(
      recordId: 'recABC',
      url: 'https://airtable.com/appTEST/recABC',
    );
  }
}

void main() {
  late Directory tempDir;
  late String audioPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('reuniones_test');
    audioPath = '${tempDir.path}/reunion.m4a';
    await File(audioPath).writeAsBytes(List.filled(1024, 0));
  });

  tearDown(() => tempDir.delete(recursive: true));

  Meeting buildMeeting() => Meeting(
        id: 'abc',
        title: 'Comite semanal',
        startedAt: DateTime(2026, 9, 1, 10),
        questionnaireId: 'default',
        answers: const [
          Answer(
            questionId: 'objetivo',
            question: 'Objetivo de la reunion',
            text: 'Revisar el lote 4',
            atSecond: 42,
          ),
        ],
        durationSeconds: 1800,
        audioPath: audioPath,
      );

  test('el pipeline recorre transcripcion, informe y publicacion', () async {
    final api = FakeApi();
    final notifier = MeetingsNotifier(MeetingStore(), api);

    await notifier.add(buildMeeting());
    await notifier.process('abc');

    final meeting = notifier.state.single;
    expect(meeting.status, MeetingStatus.publicada);
    expect(meeting.transcript, contains('lote 4'));
    expect(meeting.report!.acuerdos, isNotEmpty);
    expect(meeting.airtableUrl, contains('recABC'));
    // Whisper devolvio 1830 s, que pisa la duracion medida por el cronometro.
    expect(meeting.durationSeconds, 1830);
  });

  test('un fallo deja la reunion en error con el mensaje visible', () async {
    final api = FakeApi(failAt: 'report');
    final notifier = MeetingsNotifier(MeetingStore(), api);

    await notifier.add(buildMeeting());
    await notifier.process('abc');

    final meeting = notifier.state.single;
    expect(meeting.status, MeetingStatus.error);
    expect(meeting.errorMessage, contains('report no disponible'));
    expect(meeting.transcript, isNotEmpty, reason: 'la transcripcion se conserva');
    expect(meeting.airtableUrl, isNull);
  });

  test('reintentar retoma sin repetir los pasos ya hechos', () async {
    final api = FakeApi(failAt: 'publish');
    final notifier = MeetingsNotifier(MeetingStore(), api);

    await notifier.add(buildMeeting());
    await notifier.process('abc');
    expect(notifier.state.single.status, MeetingStatus.error);

    await notifier.process('abc');

    expect(notifier.state.single.status, MeetingStatus.publicada);
    expect(api.transcribeCalls, 1, reason: 'no se vuelve a subir el audio');
    expect(api.reportCalls, 1, reason: 'no se vuelve a pagar el informe');
    expect(api.publishCalls, 2);
  });

  test('sin audio no intenta transcribir', () async {
    final api = FakeApi();
    final notifier = MeetingsNotifier(MeetingStore(), api);

    await notifier.add(buildMeeting().copyWith(audioPath: ''));
    await notifier.process('abc');

    expect(notifier.state.single.status, MeetingStatus.error);
    expect(api.transcribeCalls, 0);
  });

  test('las reuniones sobreviven al reinicio de la app', () async {
    final api = FakeApi();
    final notifier = MeetingsNotifier(MeetingStore(), api);
    await notifier.add(buildMeeting());
    await notifier.process('abc');

    // Un arranque nuevo lee del almacenamiento local.
    final reloaded = MeetingsNotifier(MeetingStore(), api);
    await reloaded.load();

    expect(reloaded.state.single.airtableUrl, contains('recABC'));
    expect(reloaded.state.single.status, MeetingStatus.publicada);
  });
}
