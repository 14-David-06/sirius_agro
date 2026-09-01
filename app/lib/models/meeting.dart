import 'answer.dart';
import 'report.dart';

/// Donde quedo la reunion en el pipeline grabar -> transcribir -> informe -> Airtable.
enum MeetingStatus {
  grabada,
  transcribiendo,
  transcrita,
  generandoInforme,
  conInforme,
  publicando,
  publicada,
  error,
}

extension MeetingStatusLabel on MeetingStatus {
  String get label => switch (this) {
        MeetingStatus.grabada => 'Grabada',
        MeetingStatus.transcribiendo => 'Transcribiendo...',
        MeetingStatus.transcrita => 'Transcrita',
        MeetingStatus.generandoInforme => 'Generando informe...',
        MeetingStatus.conInforme => 'Informe listo',
        MeetingStatus.publicando => 'Publicando...',
        MeetingStatus.publicada => 'En Airtable',
        MeetingStatus.error => 'Error',
      };

  bool get isBusy => this == MeetingStatus.transcribiendo ||
      this == MeetingStatus.generandoInforme ||
      this == MeetingStatus.publicando;
}

class Meeting {
  Meeting({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.questionnaireId,
    required this.answers,
    this.durationSeconds = 0,
    this.participants = const [],
    this.notes = '',
    this.audioPath,
    this.transcript = '',
    this.report,
    this.airtableUrl,
    this.status = MeetingStatus.grabada,
    this.errorMessage,
  });

  final String id;
  final String title;
  final DateTime startedAt;
  final String questionnaireId;
  final List<Answer> answers;
  final int durationSeconds;
  final List<String> participants;
  final String notes;

  /// Ruta local del archivo (o blob URL en web). Null si ya se subio y se borro.
  final String? audioPath;
  final String transcript;
  final Report? report;
  final String? airtableUrl;
  final MeetingStatus status;
  final String? errorMessage;

  Meeting copyWith({
    String? title,
    List<Answer>? answers,
    int? durationSeconds,
    List<String>? participants,
    String? notes,
    String? audioPath,
    String? transcript,
    Report? report,
    String? airtableUrl,
    MeetingStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) =>
      Meeting(
        id: id,
        title: title ?? this.title,
        startedAt: startedAt,
        questionnaireId: questionnaireId,
        answers: answers ?? this.answers,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        participants: participants ?? this.participants,
        notes: notes ?? this.notes,
        audioPath: audioPath ?? this.audioPath,
        transcript: transcript ?? this.transcript,
        report: report ?? this.report,
        airtableUrl: airtableUrl ?? this.airtableUrl,
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'started_at': startedAt.toIso8601String(),
        'questionnaire_id': questionnaireId,
        'answers': answers.map((a) => a.toJson()).toList(),
        'duration_seconds': durationSeconds,
        'participants': participants,
        'notes': notes,
        'audio_path': audioPath,
        'transcript': transcript,
        'report': report?.toJson(),
        'airtable_url': airtableUrl,
        'status': status.name,
        'error_message': errorMessage,
      };

  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
        id: j['id'] as String,
        title: j['title'] as String,
        startedAt: DateTime.parse(j['started_at'] as String),
        questionnaireId: j['questionnaire_id'] as String,
        answers: ((j['answers'] as List?) ?? [])
            .map((e) => Answer.fromJson(e as Map<String, dynamic>))
            .toList(),
        durationSeconds: (j['duration_seconds'] as int?) ?? 0,
        participants: ((j['participants'] as List?) ?? []).cast<String>(),
        notes: (j['notes'] as String?) ?? '',
        audioPath: j['audio_path'] as String?,
        transcript: (j['transcript'] as String?) ?? '',
        report: j['report'] == null
            ? null
            : Report.fromJson(j['report'] as Map<String, dynamic>),
        airtableUrl: j['airtable_url'] as String?,
        status: MeetingStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => MeetingStatus.grabada,
        ),
        errorMessage: j['error_message'] as String?,
      );

  /// Payload comun que espera el backend para informe y publicacion.
  Map<String, dynamic> get metaJson => {
        'title': title,
        'started_at': startedAt.toIso8601String(),
        'duration_seconds': durationSeconds,
        'participants': participants,
        'questionnaire_id': questionnaireId,
        'notes': notes,
      };
}
