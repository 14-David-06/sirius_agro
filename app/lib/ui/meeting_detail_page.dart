import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/config.dart';
import '../models/meeting.dart';
import '../models/report.dart';
import '../state/meetings.dart';
import 'theme.dart';

class MeetingDetailPage extends ConsumerWidget {
  const MeetingDetailPage({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meeting = ref.watch(meetingProvider(meetingId));
    if (meeting == null) {
      return const Scaffold(body: Center(child: Text('Reunion no encontrada')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(meeting.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _PipelineCard(meeting: meeting),
          const SizedBox(height: 16),
          _MetaCard(meeting: meeting),
          if (meeting.report != null) ...[
            const SizedBox(height: 16),
            _ReportCard(report: meeting.report!),
          ],
          if (meeting.answers.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AnswersCard(meeting: meeting),
          ],
          if (meeting.transcript.isNotEmpty) ...[
            const SizedBox(height: 16),
            _TranscriptCard(transcript: meeting.transcript),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar reunion'),
        content: const Text(
            'Se borra el audio y los datos locales. Lo que ya esta en Airtable no se toca.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(meetingsProvider.notifier).remove(meetingId);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _PipelineCard extends ConsumerWidget {
  const _PipelineCard({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _step(context, 'Audio grabado', done: true),
            _step(context, 'Transcripcion',
                done: meeting.transcript.isNotEmpty,
                busy: meeting.status == MeetingStatus.transcribiendo),
            _step(context, 'Informe',
                done: meeting.report != null,
                busy: meeting.status == MeetingStatus.generandoInforme),
            _step(context, 'Publicado en Airtable',
                done: meeting.airtableUrl != null,
                busy: meeting.status == MeetingStatus.publicando),
            if (meeting.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(meeting.errorMessage!,
                    style: TextStyle(color: scheme.onErrorContainer)),
              ),
            ],
            if (meeting.airtableUrl != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(meeting.airtableUrl!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copiar enlace',
                    onPressed: () => Clipboard.setData(
                        ClipboardData(text: meeting.airtableUrl!)),
                  ),
                ],
              ),
            ],
            if (meeting.status != MeetingStatus.publicada &&
                !meeting.status.isBusy) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: AppConfig.isConfigured
                    ? () =>
                        ref.read(meetingsProvider.notifier).process(meeting.id)
                    : null,
                icon: const Icon(Icons.cloud_upload),
                label: Text(meeting.errorMessage != null
                    ? 'Reintentar'
                    : 'Procesar y publicar'),
              ),
              if (!AppConfig.isConfigured)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Falta configurar API_BASE_URL y API_KEY.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _step(
    BuildContext context,
    String label, {
    required bool done,
    bool busy = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: busy
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: done ? scheme.primary : scheme.outline,
                  ),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: done ? null : scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(context, Icons.event,
                DateFormat.yMMMMEEEEd('es').add_Hm().format(meeting.startedAt)),
            _row(context, Icons.timer_outlined,
                formatDuration(meeting.durationSeconds)),
            if (meeting.participants.isNotEmpty)
              _row(context, Icons.group_outlined,
                  meeting.participants.join(', ')),
            if (meeting.notes.isNotEmpty)
              _row(context, Icons.sticky_note_2_outlined, meeting.notes),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informe', style: text.titleMedium),
            const SizedBox(height: 12),
            SelectableText(report.resumenEjecutivo),
            if (report.temas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Temas', style: text.titleSmall),
              for (final t in report.temas)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.titulo,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      SelectableText(t.detalle),
                    ],
                  ),
                ),
            ],
            if (report.acuerdos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Acuerdos', style: text.titleSmall),
              for (final a in report.acuerdos) _bullet(a),
            ],
            if (report.pendientes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Pendientes', style: text.titleSmall),
              for (final p in report.pendientes)
                _bullet([
                  p.tarea,
                  if (p.responsable.isNotEmpty) p.responsable,
                  if (p.fechaLimite.isNotEmpty) p.fechaLimite,
                ].join('  -  ')),
            ],
            if (report.riesgos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Riesgos', style: text.titleSmall),
              for (final r in report.riesgos) _bullet(r),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('-  '),
            Expanded(child: SelectableText(text)),
          ],
        ),
      );
}

class _AnswersCard extends StatelessWidget {
  const _AnswersCard({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuestionario', style: Theme.of(context).textTheme.titleMedium),
            for (final a in meeting.answers)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(a.question,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        if (a.atSecond != null)
                          Text(formatDuration(a.atSecond!),
                              style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                    SelectableText(a.text.isEmpty ? 'Sin responder' : a.text),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.transcript});

  final String transcript;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text('Transcripcion'),
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [SelectableText(transcript)],
      ),
    );
  }
}
