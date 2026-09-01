import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../data/questionnaires.dart';
import '../state/meetings.dart';
import '../state/recording.dart';
import 'meeting_detail_page.dart';
import 'theme.dart';

class RecordingPage extends ConsumerStatefulWidget {
  const RecordingPage({super.key, required this.questionnaireId});

  final String questionnaireId;

  @override
  ConsumerState<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends ConsumerState<RecordingPage> {
  final _title = TextEditingController();
  final _participants = TextEditingController();
  final _notes = TextEditingController();
  final _answerControllers = <String, TextEditingController>{};
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _participants.dispose();
    _notes.dispose();
    for (final c in _answerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionnaire = questionnaireById(widget.questionnaireId);
    final controller =
        ref.read(recordingProvider(widget.questionnaireId).notifier);
    final state = ref.watch(recordingProvider(widget.questionnaireId));

    return PopScope(
      canPop: !state.isRecording,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard(controller);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(questionnaire.name)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _RecorderCard(
              seconds: state.seconds,
              isRecording: state.isRecording,
              isPaused: state.isPaused,
              answered: state.answeredCount,
              total: state.answers.length,
              error: state.error,
              onStart: controller.start,
              onPause: controller.togglePause,
              onStop: _saving ? null : _finish,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titulo de la reunion'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _participants,
              decoration: const InputDecoration(
                labelText: 'Participantes',
                helperText: 'Separados por coma',
              ),
            ),
            const SizedBox(height: 24),
            Text('Cuestionario',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Respondé mientras avanza la grabación. Queda marcado el minuto en que anotaste cada respuesta.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final question in questionnaire.questions)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: _answerControllers.putIfAbsent(
                      question.id, () => TextEditingController()),
                  maxLines: question.multiline ? null : 1,
                  minLines: question.multiline ? 2 : 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: question.text,
                    helperText: question.hint.isEmpty ? null : question.hint,
                    suffixIcon: _stampFor(state, question.id),
                  ),
                  onChanged: (value) => controller.answer(question.id, value),
                ),
              ),
            TextField(
              controller: _notes,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas libres',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _stampFor(RecordingState state, String questionId) {
    for (final a in state.answers) {
      if (a.questionId == questionId && a.atSecond != null) {
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Align(
            alignment: Alignment.centerRight,
            widthFactor: 1,
            child: Text(formatDuration(a.atSecond!),
                style: Theme.of(context).textTheme.labelSmall),
          ),
        );
      }
    }
    return null;
  }

  Future<void> _confirmDiscard(RecordingController controller) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar grabacion'),
        content: const Text('Se esta grabando. Si salis ahora se pierde el audio.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Seguir grabando')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Descartar')),
        ],
      ),
    );

    if (discard == true && mounted) {
      await controller.discard();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _finish() async {
    final controller =
        ref.read(recordingProvider(widget.questionnaireId).notifier);

    setState(() => _saving = true);
    final meeting = await controller.stop(
      title: _title.text,
      participants: _participants.text
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList(),
      notes: _notes.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (meeting == null) return;

    await ref.read(meetingsProvider.notifier).add(meeting);
    if (AppConfig.isConfigured) {
      // Sin await: el detalle muestra el avance del pipeline.
      unawaited(ref.read(meetingsProvider.notifier).process(meeting.id));
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MeetingDetailPage(meetingId: meeting.id),
      ),
    );
  }
}

class _RecorderCard extends StatelessWidget {
  const _RecorderCard({
    required this.seconds,
    required this.isRecording,
    required this.isPaused,
    required this.answered,
    required this.total,
    required this.error,
    required this.onStart,
    required this.onPause,
    required this.onStop,
  });

  final int seconds;
  final bool isRecording;
  final bool isPaused;
  final int answered;
  final int total;
  final String? error;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRecording)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isPaused ? scheme.outline : scheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  formatDuration(seconds),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$answered de $total preguntas respondidas',
                style: Theme.of(context).textTheme.bodySmall),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 20),
            if (!isRecording && seconds == 0)
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('Empezar a grabar'),
              )
            else if (isRecording)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPause,
                    icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(isPaused ? 'Reanudar' : 'Pausar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop),
                    label: const Text('Terminar'),
                  ),
                ],
              )
            else
              const Text('Grabacion finalizada'),
          ],
        ),
      ),
    );
  }
}
