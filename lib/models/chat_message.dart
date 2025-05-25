// lib/models/chat_message.dart
import 'package:myfinalpro/models/question_model.dart'; // تأكد من مسار Question
class ChatMessage {
  final String text;
  final bool isUserMessage; // <-- تم تعريف المعامل هنا
  final Question? questionData;
  final bool isError;// اختياري لتخزين بيانات السؤال المرتبط برسالة البوت

  // Constructor يتطلب isUserMessage
  ChatMessage({
    required this.text,
    required this.isUserMessage, // <-- تم إضافته هنا
    this.questionData,
    this.isError = false,
  });
}