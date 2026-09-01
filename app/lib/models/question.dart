class Question {
  const Question({
    required this.id,
    required this.text,
    this.hint = '',
    this.multiline = true,
  });

  final String id;
  final String text;
  final String hint;
  final bool multiline;
}

class Questionnaire {
  const Questionnaire({
    required this.id,
    required this.name,
    required this.questions,
  });

  final String id;
  final String name;
  final List<Question> questions;
}
