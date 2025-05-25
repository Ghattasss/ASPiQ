import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

/// مساعد لتخزين واسترجاع محادثات الدردشة محليًا
class ChatStorageHelper {
  static const String _chatHistoryKey = 'chat_history';

  /// تحويل رسالة الدردشة إلى JSON
  static Map<String, dynamic> _messageToJson(ChatMessage message) {
    return {
      'text': message.text,
      'isUserMessage': message.isUserMessage,
      'isError': message.isError,
      // لا نقوم بتخزين questionData لأنه قد يكون معقدًا للتخزين المحلي
      // يمكن إضافته لاحقًا إذا كان ضروريًا
    };
  }

  /// تحويل JSON إلى رسالة دردشة
  static ChatMessage _messageFromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUserMessage: json['isUserMessage'] as bool,
      isError: json['isError'] as bool? ?? false,
    );
  }

  /// حفظ قائمة الرسائل في التخزين المحلي
  static Future<bool> saveMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // تحويل قائمة الرسائل إلى JSON
      final List<Map<String, dynamic>> jsonList =
      messages.map((message) => _messageToJson(message)).toList();

      // تحويل قائمة JSON إلى سلسلة نصية
      final String jsonString = jsonEncode(jsonList);

      // حفظ السلسلة النصية في التخزين المحلي
      return await prefs.setString(_chatHistoryKey, jsonString);
    } catch (e) {
      print('خطأ في حفظ المحادثة: $e');
      return false;
    }
  }

  /// استرجاع قائمة الرسائل من التخزين المحلي
  static Future<List<ChatMessage>?> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // التحقق من وجود بيانات محفوظة
      if (!prefs.containsKey(_chatHistoryKey)) {
        return null;
      }

      // استرجاع السلسلة النصية من التخزين المحلي
      final String? jsonString = prefs.getString(_chatHistoryKey);
      if (jsonString == null) {
        return null;
      }

      // تحويل السلسلة النصية إلى قائمة JSON
      final List<dynamic> jsonList = jsonDecode(jsonString);

      // تحويل قائمة JSON إلى قائمة رسائل
      return jsonList
          .map((json) => _messageFromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('خطأ في استرجاع المحادثة: $e');
      return null;
    }
  }

  /// حذف جميع الرسائل المحفوظة
  static Future<bool> clearMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_chatHistoryKey);
    } catch (e) {
      print('خطأ في حذف المحادثة: $e');
      return false;
    }
  }
}