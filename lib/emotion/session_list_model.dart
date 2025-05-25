// lib/models/session_model.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; // لاستخدام debugPrint

// --- دالة التحليل الرئيسية ---
List<Session> sessionsFromJson(String str) {
  try {
    final jsonData = jsonDecode(str);
    if (jsonData is Map && jsonData.containsKey('\$values') && jsonData['\$values'] is List) {
      final List rawList = jsonData['\$values'];
      final List validItems = rawList.where((item) => item != null && item is Map<String, dynamic>).toList();
      return List<Session>.from(validItems.map((x) => Session.fromJson(x as Map<String, dynamic>)));
    } else {
      debugPrint("[sessionsFromJson] Error: Unexpected JSON structure. Expected Map with '\$values' key containing a List.");
      return [];
    }
  } catch (e) {
    debugPrint("[sessionsFromJson] Error decoding JSON into sessions list: $e");
    debugPrint("[sessionsFromJson] Received JSON string sample: ${str.substring(0, (str.length > 500 ? 500 : str.length))}...");
    return [];
  }
}

// --- كلاس الجلسة الرئيسية ---
class Session {
  final String? refId;
  final String? id;
  final int? sessionId;
  final String title;
  final String description;
  final String goal;
  final int? groupId;
  final int? typeId;
  final bool isOpen;
  final int? doneCount;
  final SessionDetails details;

  Session({
    this.refId,
    this.id,
    this.sessionId,
    required this.title,
    required this.description,
    required this.goal,
    this.groupId,
    this.typeId,
    required this.isOpen,
    this.doneCount,
    required this.details,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) { // التحقق من Map فارغ أيضاً
      throw FormatException("Cannot parse empty session JSON map");
    }
    return Session(
      refId: json['\$id']?.toString(),
      id: json['id']?.toString(),
      sessionId: json['session_ID_'] ?? json['sessionId'],
      title: json['title'] ?? 'جلسة غير معنونة',
      description: json['description'] ?? '',
      goal: json['goal'] ?? '',
      groupId: json['group_id'] ?? json['groupId'],
      typeId: json['type_Id_'] ?? json['typeId'],
      isOpen: json['isOpen'] ?? false,
      doneCount: json['doneCount'],
      details: SessionDetails.fromJson(json['details'] ?? {'\$values': []}),
    );
  }
}

// --- كلاس تفاصيل الجلسة ---
class SessionDetails {
  final String? refId;
  final List<DetailItem> values;

  SessionDetails({
    this.refId,
    required this.values,
  });

  factory SessionDetails.fromJson(Map<String, dynamic> json) {
    var valuesList = <DetailItem>[];
    if (json['\$values'] != null && json['\$values'] is List) {
      final List rawList = json['\$values'];
      final List validItems = rawList.where((item) => item != null && item is Map<String, dynamic>).toList();
      valuesList = List<DetailItem>.from(
        validItems.map((x) => DetailItem.fromJson(x as Map<String, dynamic>))
      );
    }
    return SessionDetails(
      refId: json['\$id']?.toString(),
      values: valuesList,
    );
  }
}

// --- كلاس عنصر التفاصيل (المحتوى الفعلي مثل الصورة) ---
class DetailItem {
  final String? refId;
  final int? id;
  final String dataTypeOfContent;
  final String? imagePath;
  final String? video;
  final String? story;
  final String? sound;
  final String? text;
  final String? part;
  final String? more;
  final String? description;

  DetailItem({
    this.refId,
    this.id,
    required this.dataTypeOfContent,
    this.imagePath,
    this.video,
    this.story,
    this.sound,
    this.text,
    this.part,
    this.more,
    this.description,
  });

  factory DetailItem.fromJson(Map<String, dynamic> json) {
     if (json.isEmpty) {
      throw FormatException("Cannot parse empty detail item JSON map");
    }
    return DetailItem(
      refId: json['\$id']?.toString(),
      id: json['id'],
      dataTypeOfContent: json['dataTypeOfContent'] ?? 'Unknown',
      imagePath: json['image_'],
      video: json['video'],
      story: json['story'],
      sound: json['sound'],
      text: json['text_'],
      part: json['part'],
      more: json['more'],
      description: json['desc'],
    );
  }

  // --- Getter لحساب مسار الصورة المحلي الصحيح ---
  String? get fullAssetPath {
    if (imagePath == null || imagePath!.trim().isEmpty) { // التحقق من trim() أيضاً
      return null;
    }
    try {
      final cleanPath = imagePath!.replaceAll(r'\', '/');
      final finalPath = cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath;
      // التأكد من عدم وجود // في المسار النهائي
      final assetPath = 'assets/$finalPath'.replaceAll('//', '/');
      return assetPath;
    } catch (e) {
      debugPrint("[DetailItem.fullAssetPath] Error processing image path '$imagePath': $e");
      return null;
    }
  }
}