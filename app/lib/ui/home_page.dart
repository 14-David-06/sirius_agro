import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/config.dart';
import '../data/questionnaires.dart';
import '../models/meeting.dart';
import '../state/meetings.dart';
import 'meeting_detail_page.dart';
import 'recording_page.dart';
import 'theme.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetings = ref.watch(meetingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reuniones'),
        actions: [
          if (!AppConfig.isConfigured)
            IconButton(
              icon: const Icon(Icons.warning_amber),
              tooltip: 'Backend sin configurar',
              onPressed: () => _showConfigHelp(context),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startMeeting(context),
        icon: const Icon(Icons.mic),
        label: const Text('Nueva reunion'),
      ),
      body: meetings.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: meetings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _MeetingTile(meeting: meetings[i]),
            ),
    );
  }

  Future<void> _startMeeting(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Cuestionario a usar',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            for (final q in questionnaires)
              ListTile(
                leading: const Icon(Icons.checklist),
                title: Text(q.name),
                subtitle: Text('${q.questions.length} preguntas'),
                onTap: () => Navigator.pop(context, q.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecordingPage(questionnaireId: selected)),
    );
  }

  void _showConfigHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backend sin configurar'),
        content: const Text(
          'Falta API_BASE_URL o API_KEY. Corre la app con:\n\n'
          'flutter run --dart-define=API_BASE_URL=https://tu-backend '
          '--dart-define=API_KEY=tu-clave\n\n'
          'Podes grabar igual, pero no se puede transcribir ni publicar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Todavia no hay reuniones',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Grabá una reunión y respondé el cuestionario mientras avanza. '
              'Al terminar se transcribe, se genera el informe y se publica en Airtable.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingTile extends ConsumerWidget {
  const _MeetingTile({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(meeting.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${DateFormat("d MMM y · HH:mm", "es").format(meeting.startedAt)}'
            '  ·  ${formatDuration(meeting.durationSeconds)}',
          ),
        ),
        trailing: _StatusChip(status: meeting.status),
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Icon(Icons.mic, color: scheme.onSecondaryContainer),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MeetingDetailPage(meetingId: meeting.id),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MeetingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      MeetingStatus.publicada => (scheme.primaryContainer, scheme.onPrimaryContainer),
      MeetingStatus.error => (scheme.errorContainer, scheme.onErrorContainer),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.isBusy) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            ),
            const SizedBox(width: 6),
          ],
          Text(status.label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: fg)),
        ],
      ),
    );
  }
}
