// lib/session/models/session_model.dart
import 'dart:math'; // لـ min
import 'package:flutter/foundation.dart'; // لـ debugPrint

// --- كلاس Session ---
class Session {
  final int? sessionId;
  final String? title;
  final String? description; // يستخدم في IntroScreen (الإرشادات)
  final String? goal; // يستخدم في IntroScreen (الأهداف)
  final int? groupId;
  final int typeId; // يستخدم لتحديد الألوان مثلاً، أو نوع الجلسة (تدريبية، رسالة، الخ)
  final int? detailsCount; // عدد التمارين الكلي المتوقع
  final List<SessionDetail> details; // قائمة التمارين الأساسية (1-4 عادة)
  final SessionDetail? newDetail; // الكائن الإضافي المستخدم في التمرين قبل الأخير
  final Map<String, dynamic>? attributes; // حقل لتخزين أي بيانات إضافية مثل رسائل الاختبار

  int get id => sessionId ?? 0; // Getter لسهولة الوصول إلى ID

  Session({
    this.sessionId,
    this.title,
    this.description,
    this.goal,
    this.groupId,
    required this.typeId,
    this.detailsCount,
    required this.details,
    this.newDetail,
    this.attributes,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    List<SessionDetail> detailsList = [];
    SessionDetail? newDetailParsed;

    // --- تحليل قائمة details الأساسية ---
    dynamic detailsData = json['details'];
    if (detailsData != null) {
      // التعامل مع حالة أن detailsData قد يكون Map يحتوي على $values أو List مباشرة
      dynamic valuesList = (detailsData is Map<String, dynamic> && detailsData.containsKey('\$values'))
          ? detailsData['\$values']
          : null;
      List? sourceList = (valuesList != null && valuesList is List)
          ? valuesList
          : (detailsData is List ? detailsData : null);

      if (sourceList != null) {
        detailsList = sourceList
            .where((v) => v is Map<String, dynamic>) // تأكد أن العنصر هو Map
            .map((v) {
              try {
                return SessionDetail.fromJson(v as Map<String, dynamic>);
              } catch (e) {
                debugPrint("Error parsing SessionDetail from details list: $e\nData: $v");
                return null; // أرجع null إذا فشل التحليل لهذا العنصر
              }
            })
            .whereType<SessionDetail>() // أزل أي عناصر null نتجت عن فشل التحليل
            .toList();
      } else {
        debugPrint("Warning: 'details' key is not a parsable list or '\$values' not found in Session JSON. Data: $detailsData");
      }
    } else {
      debugPrint("Warning: 'details' key not found in Session JSON. Assuming empty list.");
    }

    // --- تحليل newDetail بشكل منفصل ---
    dynamic newDetailData = json['newDetail'];
    if (newDetailData != null && newDetailData is Map<String, dynamic>) {
      // تحقق إذا كان newDetail يحتوي على $values أيضًا، أو أنه كائن مباشر
      dynamic newDetailActualData = (newDetailData.containsKey('\$values') && newDetailData['\$values'] is List && (newDetailData['\$values'] as List).isNotEmpty)
          ? (newDetailData['\$values'] as List).first // افترض أن $values لـ newDetail يحتوي على عنصر واحد
          : newDetailData;

      if (newDetailActualData is Map<String, dynamic>) {
        try {
          newDetailParsed = SessionDetail.fromJson(newDetailActualData);
        } catch (e) {
          debugPrint("Error parsing newDetail: $e\nData: $newDetailActualData");
        }
      } else {
          debugPrint("Info: newDetail object (or its \$values content) not found or invalid in Session JSON. Data: $newDetailData");
      }
    } else {
      debugPrint("Info: 'newDetail' key not found or is not a Map in Session JSON.");
    }

    final expectedCount = json['detailsCount'] as int?;
    if (expectedCount != null && detailsList.length != expectedCount && detailsList.isNotEmpty) { // لا تطبع التحذير إذا كانت detailsList فارغة بسبب رسالة
      debugPrint("Warning: detailsCount ($expectedCount) does not match actual details list length (${detailsList.length}). This might be okay if it's a message response.");
    }

    // --- *** بداية التعديل: قراءة الرسائل الخاصة بالاختبارات ودمجها في attributes *** ---
    Map<String, dynamic> parsedAttributes = {};

    // 1. قراءة من حقل 'message' (لاحظ أن صورك أظهرت 'message' وليس 'Message')
    if (json['message'] != null && json['message'] is String) {
      String messageContent = json['message'] as String;
      if (messageContent.toLowerCase().contains("اختبار الشهر")) {
        parsedAttributes['monthly_test_message'] = messageContent;
        // محاولة استخراج sessionId إذا كان موجودًا مع الرسالة
        if (json['sessionId'] != null && json['sessionId'] is int) {
          parsedAttributes['monthly_test_session_id'] = json['sessionId'];
        }
      } else if (messageContent.toLowerCase().contains("اختبار ال 3 شهور")) {
        parsedAttributes['three_month_test_message'] = messageContent;
        // لا يوجد sessionId واضح لرسالة اختبار الـ 3 شهور في الأمثلة التي أرسلتها،
        // لذا لن نضيفه هنا بشكل افتراضي.
      }
      debugPrint("[Session.fromJson] Parsed attributes from 'message' field: $parsedAttributes");
    }

    // 2. (اختياري) قراءة من حقل 'attributes' إذا كان الـ API يرسله أيضًا
    if (json['attributes'] is Map<String, dynamic>) {
      // دمج مع ما تم تحليله من 'message' مع إعطاء الأولوية لما هو موجود بالفعل
      (json['attributes'] as Map<String, dynamic>).forEach((key, value) {
        parsedAttributes.putIfAbsent(key, () => value);
      });
      debugPrint("[Session.fromJson] Merged with direct 'attributes' field. Current attributes: $parsedAttributes");
    }
    // --- *** نهاية التعديل *** ---

    // تحديد typeId: إذا كانت رسالة اختبار، استخدم typeId خاص، وإلا استخدم القيمة من JSON أو قيمة افتراضية
    int determinedTypeId = json['typeId'] as int? ?? 1; // قيمة افتراضية 1 للجلسات العادية
    if (parsedAttributes.containsKey('monthly_test_message') || parsedAttributes.containsKey('three_month_test_message')) {
      determinedTypeId = 99; // مثال: typeId 99 لرسائل النظام/الاختبارات
    }


    return Session(
      sessionId: json['sessionId'] as int?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      goal: json['goal'] as String?,
      groupId: json['groupId'] as int?,
      typeId: determinedTypeId, // استخدام الـ typeId المحدد
      detailsCount: expectedCount,
      details: detailsList, // ستكون فارغة إذا كانت الاستجابة مجرد رسالة اختبار
      newDetail: newDetailParsed, // سيكون null إذا كانت الاستجابة مجرد رسالة اختبار
      attributes: parsedAttributes.isNotEmpty ? parsedAttributes : null,
    );
  }
}

// --- كلاس SessionDetail (يبقى كما هو من الكود الذي قدمته) ---
class SessionDetail {
  final int id;
  final int? originalDetailId;
  final String? datatypeOfContent;
  final String? text;
  final String? image;
  final String? video;
  final String? story;
  final String? sound;
  final String? part;
  final String? more;
  final int? itemGroupId; // تأكد من أن هذا هو المفتاح الصحيح في JSON (قد يكون 'groupId')
  final String? itemGroupName; // تأكد من أن هذا هو المفتاح الصحيح في JSON (قد يكون 'groupName')
  final String? desc;

  SessionDetail({
    required this.id,
    this.originalDetailId,
    this.datatypeOfContent,
    this.text,
    this.image,
    this.video,
    this.story,
    this.sound,
    this.part,
    this.more,
    this.itemGroupId,
    this.itemGroupName,
    this.desc,
  });

  factory SessionDetail.fromJson(Map<String, dynamic> json) {
    int parsedId;
    final idValue = json['id'] ?? json['detail_ID']; // الأولوية لـ id
    if (idValue != null && idValue is int) {
      parsedId = idValue;
    } else if (idValue != null && idValue is String) {
      parsedId = int.tryParse(idValue) ?? 0;
    } else {
      debugPrint("Warning (SessionDetail): Missing or invalid 'id' or 'detail_ID'. Using 0. Data: $json");
      parsedId = 0;
    }

    int? parsedOriginalDetailId;
    final detailIdSourceValue = json['detail_ID']; // هذا هو ID التمرين الأصلي
    if (detailIdSourceValue != null && detailIdSourceValue is int) {
      parsedOriginalDetailId = detailIdSourceValue;
    } else if (detailIdSourceValue != null && detailIdSourceValue is String) {
      parsedOriginalDetailId = int.tryParse(detailIdSourceValue);
    }

    final textValue = json['text_'] ?? json['text'];
    final imageValue = json['image_'] ?? json['image'];
    String? imagePath = imageValue as String?;
    if (imagePath != null) {
      imagePath = imagePath.replaceAll('\\', '/').trim();
    }

    return SessionDetail(
      id: parsedId, // استخدام الـ ID المستخرج (من 'id' أو 'detail_ID')
      originalDetailId: parsedOriginalDetailId, // تخزين 'detail_ID' الأصلي هنا
      datatypeOfContent: json['datatypeOfContent'] as String?,
      text: textValue as String?,
      image: imagePath,
      video: json['video'] as String?,
      story: json['story'] as String?,
      sound: json['sound'] as String?,
      part: json['part'] as String?,
      more: json['more'] as String?,
      itemGroupId: json['groupId'] as int?, // تأكد أن المفتاح 'groupId' صحيح
      itemGroupName: json['groupName'] as String?, // تأكد أن المفتاح 'groupName' صحيح
      desc: json['desc'] as String?,
    );
  }

  bool get hasImage => image != null && image!.isNotEmpty;
  bool get hasText => text != null && text!.isNotEmpty;
  bool get hasDesc => desc != null && desc!.isNotEmpty;
  bool get hasVideo => video != null && video!.isNotEmpty;
}