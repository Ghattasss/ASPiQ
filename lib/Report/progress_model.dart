// lib/Report/progress_model.dart (أو مسارك الصحيح)
import 'package:flutter/foundation.dart'; // لـ debugPrint إذا احتجت

class ProgressResponse {
  final int progress; // سيبقى النوع int هنا إذا كنتِ تريدين التقدم كعدد صحيح

  ProgressResponse({required this.progress});

  factory ProgressResponse.fromJson(Map<String, dynamic> json) {
    // الخطوة 1: اقرأ القيمة كـ num? (تقبل int?, double?, أو null)
    // هذا أكثر أمانًا إذا كان الـ API قد يرجع أحيانًا رقمًا صحيحًا وأحيانًا رقمًا عشريًا.
    num? progressValueFromJson = json['progress'] as num?;

    // الخطوة 2: قم بتحويلها إلى int.
    // إذا كانت progressValueFromJson هي double، فإن toInt() ستأخذ الجزء الصحيح (مثلاً 75.8 تصبح 75).
    // إذا كانت int، ستبقى int.
    // إذا كانت null، ستستخدم القيمة الافتراضية 0.
    int finalProgress = progressValueFromJson?.toInt() ?? 0;

    // بديل للخطوة 2: إذا كنت تريد التقريب لأقرب عدد صحيح بدلاً من أخذ الجزء الصحيح فقط
    // (مثلاً 75.8 تصبح 76، و 75.3 تصبح 75)
    // int finalProgress = progressValueFromJson?.round() ?? 0;

    debugPrint("[ProgressResponse.fromJson] Raw progress value: ${json['progress']}, Parsed as num: $progressValueFromJson, Final int: $finalProgress");

    return ProgressResponse(
      progress: finalProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'progress': progress,
    };
  }
}