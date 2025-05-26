// lib/emotion/session_list_model_v2.dart
// Or any other appropriate path, e.g., lib/features/sessions_v2/models/session_list_model_v2.dart

import 'dart:convert';
import 'package:flutter/foundation.dart'; // لاستخدام debugPrint

// --- دالة التحليل الرئيسية ---
List<SessionV2> sessionsV2FromJson(String str) {
  try {
    final jsonData = jsonDecode(str);
    if (jsonData is Map && jsonData.containsKey('\$values') && jsonData['\$values'] is List) {
      final List rawList = jsonData['\$values'];
      final List validItems = rawList.where((item) => item != null && item is Map<String, dynamic>).toList();
      return List<SessionV2>.from(validItems.map((x) => SessionV2.fromJson(x as Map<String, dynamic>)));
    } else {
      debugPrint("[sessionsV2FromJson] Error: Unexpected JSON structure. Expected Map with '\$values' key containing a List.");
      debugPrint("[sessionsV2FromJson] Received JSON string sample: ${str.substring(0, (str.length > 500 ? 500 : str.length))}...");
      return [];
    }
  } catch (e) {
    debugPrint("[sessionsV2FromJson] Error decoding JSON into sessions list: $e");
    debugPrint("[sessionsV2FromJson] Received JSON string sample: ${str.substring(0, (str.length > 500 ? 500 : str.length))}...");
    return [];
  }
}

// --- كلاس الجلسة الرئيسية ---
class SessionV2 {
  final String? refId;
  final String? id; // Assuming 'id' field is not present in V2 root session objects based on sample
  final int? sessionId;
  final String title;
  final String description;
  final String goal;
  final int? groupId;
  final int? typeId;
  final bool isOpen;
  final int? doneCount;
  final SessionDetailsV2 details;

  SessionV2({
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

  factory SessionV2.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      throw FormatException("Cannot parse empty session JSON map");
    }
    return SessionV2(
      refId: json['\$id']?.toString(),
      // id: json['id']?.toString(), // V2 Sample doesn't show 'id' at this level, only '$id'
      sessionId: json['session_ID_'], // Key from V2 sample
      title: json['title'] ?? 'جلسة غير معنونة',
      description: json['description'] ?? '',
      goal: json['goal'] ?? '',
      groupId: json['group_id'], // Key from V2 sample
      typeId: json['type_Id_'],   // Key from V2 sample
      isOpen: json['isOpen'] ?? false,
      doneCount: json['doneCount'],
      details: SessionDetailsV2.fromJson(json['details'] ?? {'\$values': []}),
    );
  }
}

// --- كلاس تفاصيل الجلسة ---
class SessionDetailsV2 {
  final String? refId;
  final List<DetailItemV2> values;

  SessionDetailsV2({
    this.refId,
    required this.values,
  });

  factory SessionDetailsV2.fromJson(Map<String, dynamic> json) {
    var valuesList = <DetailItemV2>[];
    if (json['\$values'] != null && json['\$values'] is List) {
      final List rawList = json['\$values'];
      final List validItems = rawList.where((item) => item != null && item is Map<String, dynamic>).toList();
      valuesList = List<DetailItemV2>.from(
        validItems.map((x) => DetailItemV2.fromJson(x as Map<String, dynamic>))
      );
    }
    return SessionDetailsV2(
      refId: json['\$id']?.toString(),
      values: valuesList,
    );
  }
}

// --- كلاس عنصر التفاصيل (المحتوى الفعلي مثل الصورة) ---
class DetailItemV2 {
  final String? refId;
  // final int? id; // V2 Sample doesn't show 'id' at this level, only '$id'
  final String dataTypeOfContent;
  final String? imagePath; // We'll map 'image_' to this
  final String? video;
  final String? story;
  final String? sound;
  final String? text;      // We'll map 'text_' to this
  final String? part;
  final String? more;
  final String? description; // We'll map 'desc' to this

  DetailItemV2({
    this.refId,
    // this.id,
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

  factory DetailItemV2.fromJson(Map<String, dynamic> json) {
     if (json.isEmpty) {
      throw FormatException("Cannot parse empty detail item JSON map");
    }
    return DetailItemV2(
      refId: json['\$id']?.toString(),
      // id: json['id'], // V2 Sample doesn't show 'id'
      dataTypeOfContent: json['dataTypeOfContent'] ?? 'Unknown',
      imagePath: json['image_'], // Mapped from 'image_'
      video: json['video'],
      story: json['story'],
      sound: json['sound'],
      text: json['text_'],     // Mapped from 'text_'
      part: json['part'],
      more: json['more'],
      description: json['desc'], // Mapped from 'desc'
    );
  }

  // --- Getter لحساب مسار الصورة المحلي الصحيح ---
  String? get fullAssetPath {
    if (imagePath == null || imagePath!.trim().isEmpty) {
      return null;
    }
    try {
      // Normalize backslashes to forward slashes
      final cleanPath = imagePath!.replaceAll(r'\', '/');
      // Remove leading slash if present, as 'assets/' will provide it
      final finalPath = cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath;
      // Ensure no double slashes if 'assets/' and finalPath might create one
      final assetPath = 'assets/$finalPath'.replaceAll('//', '/');
      // debugPrint("[DetailItemV2.fullAssetPath] Original: '$imagePath', Processed: '$assetPath'");
      return assetPath;
    } catch (e) {
      debugPrint("[DetailItemV2.fullAssetPath] Error processing image path '$imagePath': $e");
      return null;
    }
  }
}