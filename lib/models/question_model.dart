// File: lib/models/question_model.dart
class Question {
  final int id;
  final String emotion;
  final String dimension;
  final String text;
  final String? explanation; // Optional explanation for the question

  Question({
    required this.id,
    required this.emotion,
    required this.dimension,
    required this.text,
    this.explanation,
  });
}