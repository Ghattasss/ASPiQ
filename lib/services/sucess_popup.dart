// lib/services/sucess_popup.dart
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

// التعريف لا يزال يقبل 3 وسائط
void showSuccessPopup(
    BuildContext context,
    ConfettiController confettiController,
    VoidCallback onNext
    ) {

  // --- *** التعديل هنا: استخدام try-catch بدلاً من isDisposed *** ---
  try {
    // محاولة تشغيل التأثير
    confettiController.play();
    print("Playing confetti from showSuccessPopup");
  } catch (e) {
    // إذا حدث خطأ (غالباً لأنه تم التخلص منه)، اطبع تحذيرًا وتجاهله
    print("Warning: Could not play confetti (controller might be disposed): $e");
  }
  // --- *** نهاية التعديل *** ---


  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Success Popup',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: EdgeInsets.zero,
          content: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirection: pi / 2,
                  shouldLoop: false,
                  colors: const [ Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow ],
                  gravity: 0.1,
                  numberOfParticles: 25,
                  emissionFrequency: 0.05,
                  createParticlePath: (size) {
                    final path = Path();
                    path.addRect(Rect.fromLTWH(-5, -5, 10, 10));
                    return path;
                  },
                  particleDrag: 0.05,
                  maxBlastForce: 8,
                  minBlastForce: 4,
                ),
              ),
              SizedBox(
                height: 260,
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
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff2C73D9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(180, 50),
                        elevation: 5,
                      ),
                      onPressed: () {
                        print("Popup 'Next' button pressed.");
                        Navigator.of(context).pop();
                        onNext();
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
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  ).whenComplete(() {
    print("Success Popup closed (whenComplete).");
    // --- تأكيد إضافي: محاولة إيقاف الكونترولر هنا قد تكون آمنة ---
    // هذا سيوقف الانفجار إذا كان لا يزال يعمل عند إغلاق البوب أب بسرعة
    try {
      if (confettiController.state == ConfettiControllerState.playing) {
        confettiController.stop();
        print("Stopped confetti on popup close.");
      }
    } catch (e) {
      // تجاهل الخطأ إذا كان قد تم التخلص منه بالفعل
      print("Couldn't stop confetti on popup close (already disposed?).");
    }
  });
}