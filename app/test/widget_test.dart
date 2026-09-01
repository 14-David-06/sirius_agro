import 'package:flutter_test/flutter_test.dart';
import 'package:sirius_reuniones/data/questionnaires.dart';
import 'package:sirius_reuniones/models/answer.dart';
import 'package:sirius_reuniones/models/meeting.dart';
import 'package:sirius_reuniones/models/report.dart';

void main() {
  test('cada cuestionario tiene id unico y preguntas', () {
    final ids = questionnaires.map((q) => q.id).toSet();
    expect(ids.length, questionnaires.length);
    for (final q in questionnaires) {
      expect(q.questions, isNotEmpty);
      expect(q.questions.map((x) => x.id).toSet().length, q.questions.length);
    }
  });

  test('questionnaireById cae en la primera plantilla si no existe', () {
    expect(questionnaireById('no-existe').id, questionnaires.first.id);
  });

  test('Meeting sobrevive el viaje por JSON', () {
    final original = Meeting(
      id: 'abc',
      title: 'Comite semanal',
      startedAt: DateTime(2026, 9, 1, 10, 30),
      questionnaireId: 'default',
      answers: const [
        Answer(
          questionId: 'objetivo',
          question: 'Objetivo de la reunion',
          text: 'Revisar avance',
          atSecond: 42,
        ),
      ],
      durationSeconds: 1830,
      participants: const ['Ana', 'Beto'],
      transcript: 'texto',
      report: const Report(
        resumenEjecutivo: 'resumen',
        acuerdos: ['acuerdo uno'],
        pendientes: [ActionItem(tarea: 'enviar acta', responsable: 'Ana')],
      ),
      status: MeetingStatus.conInforme,
    );

    final restored = Meeting.fromJson(original.toJson());

    expect(restored.title, original.title);
    expect(restored.startedAt, original.startedAt);
    expect(restored.durationSeconds, 1830);
    expect(restored.participants, ['Ana', 'Beto']);
    expect(restored.answers.single.atSecond, 42);
    expect(restored.report!.pendientes.single.responsable, 'Ana');
    expect(restored.status, MeetingStatus.conInforme);
  });
}
