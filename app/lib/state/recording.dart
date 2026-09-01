import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../data/questionnaires.dart';
import '../models/answer.dart';
import '../models/meeting.dart';

class RecordingState {
  const RecordingState({
    required this.answers,
    this.isRecording = false,
    this.isPaused = false,
    this.seconds = 0,
    this.error,
  });

  final List<Answer> answers;
  final bool isRecording;
  final bool isPaused;
  final int seconds;
  final String? error;

  int get answeredCount => answers.where((a) => a.isAnswered).length;

  RecordingState copyWith({
    List<Answer>? answers,
    bool? isRecording,
    bool? isPaused,
    int? seconds,
    String? error,
    bool clearError = false,
  }) =>
      RecordingState(
        answers: answers ?? this.answers,
        isRecording: isRecording ?? this.isRecording,
        isPaused: isPaused ?? this.isPaused,
        seconds: seconds ?? this.seconds,
        error: clearError ? null : (error ?? this.error),
      );
}

final recordingProvider =
    StateNotifierProvider.family<RecordingController, RecordingState, String>(
  (ref, questionnaireId) => RecordingController(questionnaireId),
);

class RecordingController extends StateNotifier<RecordingState> {
  RecordingController(this.questionnaireId)
      : super(RecordingState(
          answers: [
            for (final q in questionnaireById(questionnaireId).questions)
              Answer(questionId: q.id, question: q.text),
          ],
        ));

  final String questionnaireId;
  final _recorder = AudioRecorder();
  Timer? _ticker;
  String? _path;

  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      state = state.copyWith(error: 'Sin permiso de microfono.');
      return;
    }

    // AAC mono a 32 kbps: ~14 MB por hora, debajo del limite de 25 MB de Whisper.
    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 32000,
      sampleRate: 22050,
      numChannels: 1,
    );

    var path = '';
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      path = '${dir.path}/reunion-${const Uuid().v4()}.m4a';
    }

    await _recorder.start(config, path: path);
    _path = path;
    state = state.copyWith(isRecording: true, isPaused: false, clearError: true);
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isPaused) {
        state = state.copyWith(seconds: state.seconds + 1);
      }
    });
  }

  Future<void> togglePause() async {
    if (state.isPaused) {
      await _recorder.resume();
      state = state.copyWith(isPaused: false);
    } else {
      await _recorder.pause();
      state = state.copyWith(isPaused: true);
    }
  }

  /// Guarda la respuesta y deja marcado el segundo en que se anoto.
  void answer(String questionId, String text) {
    state = state.copyWith(
      answers: [
        for (final a in state.answers)
          if (a.questionId == questionId)
            a.copyWith(
              text: text,
              atSecond: a.atSecond ?? (state.isRecording ? state.seconds : null),
            )
          else
            a,
      ],
    );
  }

  /// Detiene la grabacion y devuelve la reunion lista para guardar.
  Future<Meeting?> stop({
    required String title,
    required List<String> participants,
    required String notes,
  }) async {
    _ticker?.cancel();
    final resultPath = await _recorder.stop() ?? _path;
    final seconds = state.seconds;
    state = state.copyWith(isRecording: false, isPaused: false);

    if (resultPath == null || resultPath.isEmpty) {
      state = state.copyWith(error: 'No se pudo guardar el audio.');
      return null;
    }

    return Meeting(
      id: const Uuid().v4(),
      title: title.trim().isEmpty ? 'Reunion sin titulo' : title.trim(),
      startedAt: DateTime.now().subtract(Duration(seconds: seconds)),
      questionnaireId: questionnaireId,
      answers: state.answers,
      durationSeconds: seconds,
      participants: participants,
      notes: notes,
      audioPath: resultPath,
    );
  }

  Future<void> discard() async {
    _ticker?.cancel();
    if (await _recorder.isRecording()) await _recorder.cancel();
    state = state.copyWith(isRecording: false, isPaused: false, seconds: 0);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
