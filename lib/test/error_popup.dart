// lib/services/error_popup.dart
import 'package:flutter/material.dart';
// لا نحتاج إلى confetti هنا، ولكن يمكنك إضافته إذا أردت تأثيرًا مختلفًا

Future<void> showErrorPopup(BuildContext context, VoidCallback onClosed) async {
  // لا يوجد confettiController هنا إلا إذا أردت تأثيرًا خاصًا بالخطأ

  await showGeneralDialog(
    context: context,
    barrierDismissible: false, // المستخدم يجب أن يضغط على الزر للإغلاق
    barrierLabel: 'Error Popup',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      // لا يوجد تأثير confetti هنا، فقط محتوى النافذة

      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: SizedBox( // يمكنك تعديل الارتفاع حسب الحاجة
            height: 230, // قللنا الارتفاع قليلاً لعدم وجود confetti
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '😟', // إيموجي حزين
                  style: TextStyle(fontSize: 50),
                ),
                const SizedBox(height: 16),
                const Text(
                  'إجابة خاطئة!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent), // لون مختلف للخطأ
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'لا بأس، حاول التركيز في السؤال القادم.',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700, // يمكنك اختيار لون مناسب
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(180, 50),
                  ),
                  onPressed: () {
                    // لا يوجد confetti لإيقافه
                    if (Navigator.canPop(dialogContext)) {
                       Navigator.of(dialogContext).pop(); // أغلق النافذة الحالية فقط
                    }
                    // دالة onClosed سيتم استدعاؤها بواسطة .whenComplete
                  },
                  child: const Text('التالي',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  ).whenComplete(() {
    // هذا الكود يُنفذ بعد إغلاق النافذة (pop)
    // لا يوجد confettiController لتنظيفه هنا
    onClosed(); // استدعاء الدالة onClosed التي تم تمريرها
  });
}