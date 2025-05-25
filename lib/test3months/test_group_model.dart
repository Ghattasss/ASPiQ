// lib/test3months/test_group_model.dart
import 'package:flutter/foundation.dart';

// TestGroupResponse class remains unchanged for this specific fix,
// unless the error originates from its direct fields.

class TestGroupResponse {
  final int groupId;
  final String groupName;
  final List<TestGroupSession> sessions;
  final String? messageFromApi;

  TestGroupResponse({
    required this.groupId,
    required this.groupName,
    required this.sessions,
    this.messageFromApi,
  });

  factory TestGroupResponse.fromJson(Map<String, dynamic> json) {
    var sessionsList = <TestGroupSession>[];
    if (json['sessions']?['\$values'] is List) {
      sessionsList = List<TestGroupSession>.from(
          (json['sessions']['\$values'] as List).map((x) {
            if (x is Map<String, dynamic>) {
              try {
                return TestGroupSession.fromJson(x);
              } catch (e) {
                debugPrint("Error parsing TestGroupSession: $e \nData: $x");
                return null;
              }
            }
            return null;
          }).where((s) => s != null).cast<TestGroupSession>()
      );
    } else {
      debugPrint("TestGroupResponse Warning: sessions['\$values'] missing or invalid in JSON.");
    }

    String? apiMessage;
    if (json['Message'] is String) {
      apiMessage = json['Message'] as String?;
    } else if (json['message'] is String) {
      apiMessage = json['message'] as String?;
    }
    
    // Robust parsing for groupId
    int parsedGroupId = 0;
    final groupIdVal = json['groupId'];
    if (groupIdVal is int) {
      parsedGroupId = groupIdVal;
    } else if (groupIdVal is String) {
      parsedGroupId = int.tryParse(groupIdVal) ?? 0;
    }


    return TestGroupResponse(
      groupId: parsedGroupId,
      groupName: json['groupName'] as String? ?? 'مجموعة غير محددة',
      sessions: sessionsList,
      messageFromApi: apiMessage,
    );
  }
}

class TestGroupSession {
  final int sessionId;
  final String title;
  final int detailsCount;
  final List<TestQuestionDetail> details;
  final TestQuestionDetail newDetail;

  TestGroupSession({
    required this.sessionId,
    required this.title,
    required this.detailsCount,
    required this.details,
    required this.newDetail,
  });

  factory TestGroupSession.fromJson(Map<String, dynamic> json) {
    var detailsList = <TestQuestionDetail>[];
    if (json['details']?['\$values'] is List) {
      detailsList = List<TestQuestionDetail>.from(
          (json['details']['\$values'] as List).map((x) {
            if (x is Map<String, dynamic>) {
              try {
                return TestQuestionDetail.fromJson(x);
              } catch (e) {
                debugPrint("Error parsing TestQuestionDetail from details list: $e \nData: $x");
                return null;
              }
            }
            return null;
          }).where((d) => d != null).cast<TestQuestionDetail>()
      );
    } else {
      debugPrint("TestGroupSession Warning: details['\$values'] missing or invalid for session '${json['title']}'.");
    }

    TestQuestionDetail parsedNewDetail;
    if (json['newDetail'] is Map<String, dynamic>) {
      try {
        parsedNewDetail = TestQuestionDetail.fromJson(json['newDetail']);
      } catch (e) {
        debugPrint("Error parsing newDetail for session '${json['title']}': $e \nData: ${json['newDetail']}");
        parsedNewDetail = TestQuestionDetail.empty();
      }
    } else {
      debugPrint("TestGroupSession Warning: newDetail missing or invalid for session '${json['title']}', using empty.");
      parsedNewDetail = TestQuestionDetail.empty();
    }

    // --- MODIFICATION FOR ROBUST sessionId PARSING ---
    int parsedSessionId = 0; // Default value if null, missing, or unparsable
    final sessionIdVal = json['sessionId'];
    if (sessionIdVal is int) {
      parsedSessionId = sessionIdVal;
    } else if (sessionIdVal is String) {
      parsedSessionId = int.tryParse(sessionIdVal) ?? 0;
      if (int.tryParse(sessionIdVal) == null && sessionIdVal.isNotEmpty) { // Log if parsing failed for non-empty string
          debugPrint("TestGroupSession Warning: sessionId string '$sessionIdVal' could not be parsed to int for session '${json['title']}', using 0.");
      }
    } else if (sessionIdVal is double) { // Handle if API sends it as double e.g. 5.0
        parsedSessionId = sessionIdVal.toInt();
        debugPrint("TestGroupSession Warning: sessionId was double ($sessionIdVal), converted to int for session '${json['title']}'.");
    } else if (sessionIdVal != null) { // If it's some other non-null, non-int, non-String, non-double type
        debugPrint("TestGroupSession Warning: sessionId was of unexpected type (${sessionIdVal.runtimeType}: $sessionIdVal) for session '${json['title']}', using 0.");
    }
    // If sessionIdVal was null, parsedSessionId remains 0 due to its initialization.

    // --- MODIFICATION FOR ROBUST detailsCount PARSING ---
    int parsedDetailsCount = 0; // Default value
    final detailsCountVal = json['detailsCount'];
    if (detailsCountVal is int) {
      parsedDetailsCount = detailsCountVal;
    } else if (detailsCountVal is String) {
      parsedDetailsCount = int.tryParse(detailsCountVal) ?? 0;
       if (int.tryParse(detailsCountVal) == null && detailsCountVal.isNotEmpty) {
          debugPrint("TestGroupSession Warning: detailsCount string '$detailsCountVal' could not be parsed to int for session '${json['title']}', using 0.");
      }
    } else if (detailsCountVal is double) {
        parsedDetailsCount = detailsCountVal.toInt();
        debugPrint("TestGroupSession Warning: detailsCount was double ($detailsCountVal), converted to int for session '${json['title']}'.");
    } else if (detailsCountVal != null) {
        debugPrint("TestGroupSession Warning: detailsCount was of unexpected type (${detailsCountVal.runtimeType}: $detailsCountVal) for session '${json['title']}', using 0.");
    }

    return TestGroupSession(
      sessionId: parsedSessionId, // Use the robustly parsed value
      title: json['title'] as String? ?? 'قسم غير مسمى',
      detailsCount: parsedDetailsCount, // Use the robustly parsed value
      details: detailsList,
      newDetail: parsedNewDetail,
    );
  }
}

class TestQuestionDetail {
  final int detailId;
  final String? imagePath;
  final String? video;
  final String? textContent;
  final String dataTypeOfContent;
  final String? sound;
  final String? questions;
  final String rightAnswer;
  final String? answers;
  final int? groupId; // This is from newDetail in TestGroupSession, related to the detail's origin if it's a distractor
  final String? groupName; // Same as above

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasText => textContent != null && textContent!.isNotEmpty;
  bool get hasVideo => video != null && video!.isNotEmpty;

  String? get localAssetPath {
    if (hasImage && imagePath != null) {
      final corrected = imagePath!.replaceAll(r'\', '/').trim();
      String relativePath = corrected;
      if (relativePath.startsWith('assets/')) {
        relativePath = relativePath.substring('assets/'.length);
      }
      if (relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }
      return 'assets/$relativePath';
    }
    return null;
  }

  List<String> get answerOptions {
    if (answers != null && answers!.isNotEmpty) {
      return answers!.split('-').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  TestQuestionDetail({
    required this.detailId,
    this.imagePath,
    this.video,
    this.textContent,
    required this.dataTypeOfContent,
    this.sound,
    this.questions,
    required this.rightAnswer,
    this.answers,
    this.groupId,
    this.groupName,
  });

  factory TestQuestionDetail.fromJson(Map<String, dynamic> json) {
    int pDetailId = 0;
    final detailIdVal = json['detail_ID'];

    if (detailIdVal is int) {
      pDetailId = detailIdVal;
    } else if (detailIdVal is String) {
      pDetailId = int.tryParse(detailIdVal) ?? 0;
    } else if (json.containsKey('id') && json['id'] is int) {
      pDetailId = json['id'];
    } else if (detailIdVal is double) {
        pDetailId = detailIdVal.toInt();
    }


    String? img = json['image_'] ?? json['image'];
    if (img != null) {
      img = img.replaceAll(r'\', '/').trim();
    }
    String? txt = json['text_'] ?? json['text'];

    return TestQuestionDetail(
      detailId: pDetailId,
      imagePath: img,
      video: json['video'] as String?,
      textContent: txt,
      dataTypeOfContent: json['dataTypeOfContent'] as String? ?? (img != null && img.isNotEmpty ? 'Img' : (txt != null && txt.isNotEmpty ? 'Text' : 'Unknown')),
      sound: json['sound'] as String?,
      questions: json['questions'] as String?,
      rightAnswer: json['right_Answer'] as String? ?? '',
      answers: json['answers'] as String?,
      groupId: json['groupId'] as int?, // Assuming groupId in detail JSON might be null
      groupName: json['groupName'] as String?,
    );
  }

  factory TestQuestionDetail.empty() {
    return TestQuestionDetail(
      detailId: 0,
      dataTypeOfContent: 'Unknown',
      rightAnswer: '',
    );
  }
}