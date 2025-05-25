// lib/models/submission_result.dart

class SubmissionResult {
  final int questionId;
  final String questionText;
  final String rawAnswer; // <-- حقل جديد: إجابة الأم الأصلية
  final String classifiedAnswer; // <-- تغيير الاسم ليكون أوضح: الإجابة المصنفة
  final bool success;

  SubmissionResult({
    required this.questionId,
    required this.questionText,
    required this.rawAnswer, // <-- إضافة required
    required this.classifiedAnswer, // <-- استخدام الاسم الجديد
    required this.success,
  });
}