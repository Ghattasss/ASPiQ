// lib/services/sucess_popup.dart
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

// --- تعديل: الدالة تعيد Future<void> وتقبل onClosed ---
Future<void> showSuccessPopup(BuildContext context, VoidCallback onClosed) async {
// --- نهاية التعديل ---

  final ConfettiController confettiController =
      ConfettiController(duration: const Duration(seconds: 1));

  // --- تعديل: استخدام await لانتظار إغلاق النافذة ---
  await showGeneralDialog(
  // --- نهاية التعديل ---
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Success Popup',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
           if (context.mounted) confettiController.play();
       });


      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Stack(
            alignment: Alignment.center,
            children: [
              // ✅ تأثير القصاصات الورقية
              ConfettiWidget(
                confettiController: confettiController,
                blastDirection: -pi / 2,
                // ✅ سقوط الورق من الأعلى
                shouldLoop: true,
                // ✅ استمرار التأثير حتى يضغط المستخدم
                colors: [
                  Colors.red,
                  Colors.green,
                  Color(0xff2C73D9),
                  Colors.yellow,
                  Colors.purple
                ],
                // ✅ ألوان متعددة
                gravity: 0.3,
                numberOfParticles: 20,
                emissionFrequency: 0.05,

                // ✅ جعل الورق مربعات
                createParticlePath: (size) {
                  return Path()..addRect(Rect.fromLTWH(0, 0, 10, 10));
                },
              ),

              // ✅ محتوى النافذة
              SizedBox(
                height: 250,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎉 أحسنت، أنت رائع!',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2C73D9)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff2C73D9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(180, 50),
                      ),
                      onPressed: () {
    confettiController.stop(); // إيقاف التأثير عند الضغط

    // --- التعديل: فقط أغلق البوب أب ---
    // تحقق أولاً إذا كان يمكن إغلاق النافذة (احتياطي)
    if (Navigator.canPop(context)) {
       Navigator.of(context).pop(); // أغلق النافذة الحالية فقط
    }
    // --- نهاية التعديل ---

    // لا يوجد انتقال هنا بعد الآن.
    // دالة onClosed التي تم تمريرها لـ showSuccessPopup
    // سيتم استدعاؤها تلقائيًا بواسطة .whenComplete بعد إغلاق النافذة.
 },
                      child: const Text('التالي',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
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
  );
}
