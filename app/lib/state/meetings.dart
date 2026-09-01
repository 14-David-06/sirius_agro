import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/audio_loader.dart';
import '../data/meeting_store.dart';
import '../models/meeting.dart';

final apiClientProvider = Provider((ref) => ApiClient());
final meetingStoreProvider = Provider((ref) => MeetingStore());

final meetingsProvider =
    StateNotifierProvider<MeetingsNotifier, List<Meeting>>((ref) {
  return MeetingsNotifier(
    ref.watch(meetingStoreProvider),
    ref.watch(apiClientProvider),
  )..load();
});

/// Una reunion concreta, para que las pantallas de detalle se refresquen solas.
final meetingProvider = Provider.family<Meeting?, String>((ref, id) {
  final meetings = ref.watch(meetingsProvider);
  for (final m in meetings) {
    if (m.id == id) return m;
  }
  return null;
});

class MeetingsNotifier extends StateNotifier<List<Meeting>> {
  MeetingsNotifier(this._store, this._api) : super(const []);

  final MeetingStore _store;
  final ApiClient _api;

  Future<void> load() async {
    state = await _store.load();
  }

  Future<void> add(Meeting meeting) async {
    state = [meeting, ...state];
    await _store.save(state);
  }

  Future<void> remove(String id) async {
    final meeting = _find(id);
    if (meeting?.audioPath != null) {
      await deleteAudio(meeting!.audioPath!);
    }
    state = state.where((m) => m.id != id).toList();
    await _store.save(state);
  }

  Meeting? _find(String id) {
    for (final m in state) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<Meeting?> _update(String id, Meeting Function(Meeting) change) async {
    final current = _find(id);
    if (current == null) return null;

    final updated = change(current);
    state = [for (final m in state) m.id == id ? updated : m];
    await _store.save(state);
    return updated;
  }

  Future<void> updateAnswersAndNotes(
    String id, {
    String? title,
    String? notes,
    List<String>? participants,
  }) =>
      _update(
        id,
        (m) => m.copyWith(title: title, notes: notes, participants: participants),
      );

  /// Transcribe -> informe -> Airtable. Cada paso se salta si ya esta hecho,
  /// asi que reintentar despues de un error retoma donde quedo.
  Future<void> process(String id) async {
    var meeting = _find(id);
    if (meeting == null) return;

    try {
      if (meeting.transcript.trim().isEmpty) {
        if (meeting.audioPath == null) {
          throw ApiException('La reunion no tiene audio para transcribir.');
        }
        meeting = await _update(
          id,
          (m) => m.copyWith(status: MeetingStatus.transcribiendo, clearError: true),
        );

        final bytes = await readAudio(meeting!.audioPath!);
        final result = await _api.transcribe(
          audio: bytes,
          filename: 'reunion-$id.m4a',
        );
        meeting = await _update(
          id,
          (m) => m.copyWith(
            transcript: result.text,
            status: MeetingStatus.transcrita,
            durationSeconds: result.durationSeconds?.round(),
          ),
        );
      }

      if (meeting!.report == null) {
        meeting = await _update(
          id,
          (m) => m.copyWith(status: MeetingStatus.generandoInforme),
        );
        final report = await _api.buildReport(
          meta: meeting!.metaJson,
          transcript: meeting.transcript,
          answers: meeting.answers,
        );
        meeting = await _update(
          id,
          (m) => m.copyWith(report: report, status: MeetingStatus.conInforme),
        );
      }

      if (meeting!.airtableUrl == null) {
        meeting = await _update(
          id,
          (m) => m.copyWith(status: MeetingStatus.publicando),
        );
        final published = await _api.publish(
          meta: meeting!.metaJson,
          transcript: meeting.transcript,
          answers: meeting.answers,
          report: meeting.report!,
        );
        await _update(
          id,
          (m) => m.copyWith(
            airtableUrl: published.url,
            status: MeetingStatus.publicada,
          ),
        );
      }
    } catch (e) {
      await _update(
        id,
        (m) => m.copyWith(status: MeetingStatus.error, errorMessage: e.toString()),
      );
    }
  }
}
