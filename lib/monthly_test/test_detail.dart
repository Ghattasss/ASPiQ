// lib/models/test_detail.dart
// --- *** لا حاجة لـ ApiService هنا الآن *** ---
// import 'package:myfinalpro/services/Api_services.dart';

// دالة مساعدة لتحليل قائمة الـ answers (تبقى كما هي)
// List<String> parseAnswers(String? answersString) {
//   if (answersString == null || answersString.trim().isEmpty) {
//     return [];
//   }
//   return answersString
//       .split('-')
//       .map((e) => e.trim())
//       .where((e) => e.isNotEmpty)
//       .toList();
// }
//
// class TestDetail {
//   final int? id;
//   final int? detailId;
//   final String? rawImageUrl; // المسار الأصلي من الباك (مثل: img\فهم\...)
//   final String? videoUrl;
//   final String? dataTypeOfContent;
//   final String? soundUrl;
//   final String? question;
//   final String? rightAnswer; // الإجابة الصحيحة النصية
//   final String? answersString;
//   final List<String> answerOptions;
//   final String? textContent;
//   final int? groupId;
//   final String? groupName;
//
//   TestDetail({
//     this.id,
//     this.detailId,
//     this.rawImageUrl,
//     this.videoUrl,
//     this.dataTypeOfContent,
//     this.soundUrl,
//     this.question,
//     this.rightAnswer,
//     this.answersString,
//     required this.answerOptions,
//     this.textContent,
//     this.groupId,
//     this.groupName,
//   });
//
//   factory TestDetail.fromJson(Map<String, dynamic> json) {
//     final String? rawAnswers = json['answers'] as String?;
//     return TestDetail(
//       id: json['id'] as int?,
//       detailId: json['detail_ID'] as int?,
//       rawImageUrl: json['image_'] as String?,
//       videoUrl: json['video'] as String?,
//       dataTypeOfContent: json['dataTypeOfContent'] as String?,
//       soundUrl: json['sound'] as String?,
//       question: json['questions'] as String?,
//       rightAnswer: json['right_Answer'] as String?,
//       answersString: rawAnswers,
//       answerOptions: parseAnswers(rawAnswers),
//       textContent: json['text_'] as String?,
//       groupId: json['groupId'] as int?,
//       groupName: json['groupName'] as String?,
//     );
//   }
//
//   // --- *** تعديل Getter لبناء مسار Asset المحلي *** ---
//   String? get localAssetPath {
//     if (rawImageUrl == null || rawImageUrl!.trim().isEmpty) {
//       print("Warning (TestDetail): rawImageUrl is null or empty for detailId: $detailId");
//       return null;
//     }
//     // 1. إصلاح الشرطة المائلة
//     String correctedRelativePath = rawImageUrl!.replaceAll(r'\', '/');
//
//     // 2. التأكد من عدم وجود "assets/" في البداية (إذا كانت مضافة بالخطأ)
//     if (correctedRelativePath.startsWith('assets/')) {
//       correctedRelativePath = correctedRelativePath.substring('assets/'.length);
//     }
//     // 3. التأكد من عدم وجود "/" في البداية للمسار النسبي
//     if (correctedRelativePath.startsWith('/')) {
//       correctedRelativePath = correctedRelativePath.substring(1);
//     }
//
//
//     // 4. بناء مسار الـ Asset الكامل بإضافة "assets/"
//     String finalAssetPath = 'assets/$correctedRelativePath';
//
//     print("Info (TestDetail): Constructed LOCAL ASSET path for detailId $detailId: $finalAssetPath from raw '$rawImageUrl'");
//     return finalAssetPath;
//   }
//   // --- *** نهاية تعديل Getter *** ---
//
//   // --- الإجابة الصحيحة للصورة هي مسار الـ Asset المحلي ---
//   String? get rightAnswerImagePathOrUrl => localAssetPath;
// // --- نهاية التعديل ---
// }

///////////////
// List<String> parseAnswers(String? answersString) {
//   if (answersString == null || answersString.trim().isEmpty) {
//     return [];
//   }
//   return answersString
//       .split('-')
//       .map((e) => e.trim())
//       .where((e) => e.isNotEmpty)
//       .toList();
// }
//
// class TestDetail {
//   final int? id;
//   final int? detailId;
//   final String? rawImageUrl; // المسار الأصلي من الباك (مثل: img\فهم\...)
//   final String? videoUrl;
//   final String? dataTypeOfContent; // <-- مهم: لتحديد نوع المحتوى
//   final String? soundUrl;
//   final String? question;
//   final String? rightAnswer; // الإجابة الصحيحة النصية
//   final String? answersString;
//   final List<String> answerOptions;
//   final String? textContent; // <-- مهم: المحتوى النصي للمواقف
//   final int? groupId;
//   final String? groupName;
//
//   TestDetail({
//     this.id,
//     this.detailId,
//     this.rawImageUrl,
//     this.videoUrl,
//     this.dataTypeOfContent,
//     this.soundUrl,
//     this.question,
//     this.rightAnswer,
//     this.answersString,
//     required this.answerOptions,
//     this.textContent,
//     this.groupId,
//     this.groupName,
//   });
//
//   factory TestDetail.fromJson(Map<String, dynamic> json) {
//     final String? rawAnswers = json['answers'] as String?;
//     return TestDetail(
//       id: json['id'] as int?,
//       detailId: json['detail_ID'] as int?,
//       rawImageUrl: json['image_'] as String?,
//       videoUrl: json['video'] as String?,
//       dataTypeOfContent: json['dataTypeOfContent'] as String?, // <-- قراءة النوع
//       soundUrl: json['sound'] as String?,
//       question: json['questions'] as String?,
//       rightAnswer: json['right_Answer'] as String?,
//       answersString: rawAnswers,
//       answerOptions: parseAnswers(rawAnswers),
//       textContent: json['text_'] as String?, // <-- قراءة النص
//       groupId: json['groupId'] as int?,
//       groupName: json['groupName'] as String?,
//     );
//   }
//
//   // Getter لبناء مسار Asset المحلي (يبقى كما هو)
//   String? get localAssetPath {
//     if (rawImageUrl == null || rawImageUrl!.trim().isEmpty) {
//       // لا تطبع تحذير هنا إذا كان النوع نصيًا
//       // print("Warning (TestDetail): rawImageUrl is null or empty for detailId: $detailId");
//       return null;
//     }
//     String correctedRelativePath = rawImageUrl!.replaceAll(r'\', '/');
//     if (correctedRelativePath.startsWith('assets/')) {
//       correctedRelativePath = correctedRelativePath.substring('assets/'.length);
//     }
//     if (correctedRelativePath.startsWith('/')) {
//       correctedRelativePath = correctedRelativePath.substring(1);
//     }
//     String finalAssetPath = 'assets/$correctedRelativePath';
//     // print("Info (TestDetail): Constructed LOCAL ASSET path for detailId $detailId: $finalAssetPath from raw '$rawImageUrl'");
//     return finalAssetPath;
//   }
//
//   // الإجابة الصحيحة للصورة هي مسار الـ Asset المحلي (يبقى كما هو)
//   String? get rightAnswerImagePathOrUrl => localAssetPath;
// }

// lib/models/test_detail.dart
// --- NO CHANGES NEEDED HERE ---

// دالة مساعدة لتحليل قائمة الـ answers (تبقى كما هي)
List<String> parseAnswers(String? answersString) {
  if (answersString == null || answersString.trim().isEmpty) {
    return [];
  }
  return answersString
      .split('-')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

class TestDetail {
  final int? id;
  final int? detailId;
  final String? rawImageUrl; // المسار الأصلي من الباك (مثل: img\فهم\...)
  final String? videoUrl;
  final String? dataTypeOfContent;
  final String? soundUrl;
  final String? question;
  final String? rightAnswer; // الإجابة الصحيحة النصية
  final String? answersString;
  final List<String> answerOptions;
  final String? textContent;
  final int? groupId;
  final String? groupName;

  TestDetail({
    this.id,
    this.detailId,
    this.rawImageUrl,
    this.videoUrl,
    this.dataTypeOfContent,
    this.soundUrl,
    this.question,
    this.rightAnswer,
    this.answersString,
    required this.answerOptions,
    this.textContent,
    this.groupId,
    this.groupName,
  });

  factory TestDetail.fromJson(Map<String, dynamic> json) {
    final String? rawAnswers = json['answers'] as String?;
    return TestDetail(
      id: json['id'] as int?,
      detailId: json['detail_ID'] as int?,
      rawImageUrl: json['image_'] as String?,
      videoUrl: json['video'] as String?,
      dataTypeOfContent: json['dataTypeOfContent'] as String?,
      soundUrl: json['sound'] as String?,
      question: json['questions'] as String?,
      rightAnswer: json['right_Answer'] as String?,
      answersString: rawAnswers,
      answerOptions: parseAnswers(rawAnswers),
      textContent: json['text_'] as String?,
      groupId: json['groupId'] as int?,
      groupName: json['groupName'] as String?,
    );
  }

  // --- Getter لبناء مسار Asset المحلي (الكود صحيح ولا يحتاج تعديل) ---
  String? get localAssetPath {
    if (rawImageUrl == null || rawImageUrl!.trim().isEmpty) {
      print("Warning (TestDetail): rawImageUrl is null or empty for detailId: $detailId");
      return null;
    }
    // 1. إصلاح الشرطة المائلة
    String correctedRelativePath = rawImageUrl!.replaceAll(r'\', '/');

    // 2. التأكد من عدم وجود "assets/" في البداية (إذا كانت مضافة بالخطأ)
    if (correctedRelativePath.startsWith('assets/')) {
      correctedRelativePath = correctedRelativePath.substring('assets/'.length);
    }
    // 3. التأكد من عدم وجود "/" في البداية للمسار النسبي
    if (correctedRelativePath.startsWith('/')) {
      correctedRelativePath = correctedRelativePath.substring(1);
    }


    // 4. بناء مسار الـ Asset الكامل بإضافة "assets/"
    String finalAssetPath = 'assets/$correctedRelativePath';

    print("Info (TestDetail): Constructed LOCAL ASSET path for detailId $detailId: $finalAssetPath from raw '$rawImageUrl'");
    return finalAssetPath;
  }

  // --- نهاية Getter ---

  // --- الإجابة الصحيحة للصورة هي مسار الـ Asset المحلي (يعتمد على localAssetPath) ---
  String? get rightAnswerImagePathOrUrl => localAssetPath;
// --- نهاية التعديل ---
}