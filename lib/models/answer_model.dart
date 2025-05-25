// File: lib/models/answer_model.dart
class AnswerModel {
  final int sessionId; // This will be the question.id
  final String answer;   // The classified answer ("نعم", "لا", "بمساعدة")

  AnswerModel({required this.sessionId, required this.answer});

  // Method to convert AnswerModel instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'SessionId': sessionId,
      'Answer': answer, // Ensure this key matches your backend's expectation
    };
  }
}