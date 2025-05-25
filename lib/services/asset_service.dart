// lib/services/asset_service.dart
import 'dart:convert'; // لـ jsonDecode
import 'dart:math';   // لـ Random
import 'package:flutter/services.dart' show rootBundle; // للوصول لـ AssetManifest

/// يقوم بتحميل قائمة الملفات من مجلد محدد داخل الـ assets ويختار مساراً عشوائياً منها.
///
/// [folderPath] هو المسار للمجلد داخل assets (يجب أن ينتهي بـ '/').
/// مثال: 'assets/objects/' أو 'assets/images/distractors/'
///
/// يرجع [Future<String?>]:
/// - مسار الـ asset الكامل (يبدأ بـ assets/) عند النجاح.
/// - null إذا كان المجلد فارغاً أو حدث خطأ.
Future<String?> getRandomAssetPathFromFolder(String folderPath) async {
  // التأكد من صحة المسار
  if (!folderPath.endsWith('/')) {
    print("Error (getRandomAssetPathFromFolder): folderPath must end with '/', received: $folderPath");
    return null;
  }

  // المسار الكامل المتوقع للملفات في Manifest (يجب أن يبدأ بـ assets/ وينتهي بـ /)
  final String fullPrefix = folderPath.startsWith('assets/') ? folderPath : 'assets/$folderPath';

  // التأكد مرة أخرى من أن المسار الكامل ينتهي بـ /
  final String normalizedFullPrefix = fullPrefix.endsWith('/') ? fullPrefix : '$fullPrefix/';

  print("Attempting to get random asset from normalized folder prefix: $normalizedFullPrefix"); // Debugging

  try {
    // تحميل وقراءة ملف البيان
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    // فلترة المسارات لتشمل فقط الملفات *المباشرة* داخل المجلد المحدد
    final List<String> directAssetPaths = manifestMap.keys
        .where((String key) {
      // 1. يجب أن يبدأ بالمسار الكامل للمجلد
      bool startsWithPrefix = key.startsWith(normalizedFullPrefix);
      // 2. يجب ألا يحتوي على شرطة مائلة أخرى بعد البادئة (لضمان أنه ملف مباشر وليس في مجلد فرعي)
      //    نقوم بإزالة البادئة ونبحث عن '/' في الباقي
      bool isDirectFile = startsWithPrefix && !key.substring(normalizedFullPrefix.length).contains('/');
      // 3. تأكد أنه ليس المجلد نفسه (إذا كان المسار يتضمن اسم ملف بالخطأ)
      bool isNotDirectory = !key.endsWith('/'); // طريقة أبسط للتحقق أنه ملف

      return startsWithPrefix && isDirectFile && isNotDirectory;
    })
        .toList();

    print("Found ${directAssetPaths.length} direct assets matching prefix '$normalizedFullPrefix': $directAssetPaths"); // Debugging

    if (directAssetPaths.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(directAssetPaths.length);
      final selectedPath = directAssetPaths[randomIndex];
      // المسار في Manifest هو المسار الكامل الذي يمكن استخدامه مباشرة في Image.asset()
      print("Randomly selected asset: $selectedPath"); // Debugging
      return selectedPath;
    } else {
      print("Warning: No direct assets found matching the path prefix: $normalizedFullPrefix. Check folder path, contents, and AssetManifest.json");
      // قد يكون المجلد فارغًا، أو أن المسار خاطئ، أو أن الملفات في مجلدات فرعية فقط
      return null; // لم يتم العثور على ملفات مباشرة
    }
  } catch (e, stacktrace) { // طباعة الخطأ وتتبع المكدس للمزيد من التفاصيل
    print("Error loading or parsing AssetManifest.json or finding assets: $e");
    print("Stacktrace: $stacktrace"); // Debugging
    // الأسباب المحتملة:
    // - ملف AssetManifest.json غير موجود أو تالف (هل تم عمل build؟)
    // - خطأ في قراءة الملفات
    return null;
  }
}

// --- مثال لكيفية استدعاء الدالة (يمكن وضعه داخل أي دالة async) ---
/*
Future<void> testRandomImage() async {
  // تأكد أن هذا المجلد موجود بالفعل في مشروعك ومُعلن في pubspec.yaml
  const String myObjectsFolder = 'assets/objects/';

  print("Testing getRandomAssetPathFromFolder...");
  // استدعاء الدالة
  String? randomPath = await getRandomAssetPathFromFolder(myObjectsFolder);

  if (randomPath != null) {
    print("Test successful! Random path: $randomPath");
    // يمكنك الآن استخدام randomPath في Image.asset(randomPath)
    // مثال:
    // showDialog(context: context, builder: (_) => AlertDialog(content: Image.asset(randomPath)));
  } else {
    print("Test failed: Could not get random path from $myObjectsFolder");
    // تحقق من:
    // 1. وجود المجلد assets/objects/ في المشروع.
    // 2. وجود صور مباشرة داخل هذا المجلد (وليس فقط مجلدات فرعية).
    // 3. إعلان المجلد 'assets/objects/' في pubspec.yaml.
    // 4. عدم وجود أخطاء في طباعة الـ console أثناء تشغيل الدالة.
    // 5. سلامة ملف AssetManifest.json (قد تحتاج لـ flutter clean).
  }
}
*/