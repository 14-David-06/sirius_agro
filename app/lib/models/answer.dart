class Answer {
  const Answer({
    required this.questionId,
    required this.question,
    this.text = '',
    this.atSecond,
  });

  final String questionId;
  final String question;
  final String text;

  /// Segundo de la grabacion en que quedo anotada, para volver al audio.
  final int? atSecond;

  bool get isAnswered => text.trim().isNotEmpty;

  Answer copyWith({String? text, int? atSecond}) => Answer(
        questionId: questionId,
        question: question,
        text: text ?? this.text,
        atSecond: atSecond ?? this.atSecond,
      );

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'question': question,
        'answer': text,
        'at_second': atSecond,
      };

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
        questionId: json['question_id'] as String,
        question: json['question'] as String,
        text: (json['answer'] as String?) ?? '',
        atSecond: json['at_second'] as int?,
      );
}
