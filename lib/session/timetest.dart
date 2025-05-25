import 'package:flutter/material.dart';
// تأكد من المسار الصحيح لـ QuizManagerScreen
import 'package:myfinalpro/test/quiz_manager_screen.dart'; // أو المسار الصحيح لديك

class StartTest extends StatelessWidget {
  final List<int> previousSessionDetailIds;

  const StartTest({
    super.key,
    required this.previousSessionDetailIds,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff2C73D9),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'حان وقت الاختبار',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Color(0xff2C73D9)),
                  ),
                  const SizedBox(height: 15),
                  Image.asset(
                    'assets/images/clock.gif', // تأكد أن الملف موجود في هذا المسار
                    width: 180,
                    height: 140,
                    errorBuilder: (context, error, stackTrace) {
                      print("Error loading GIF: assets/images/clock.gif - $error");
                      return Container(
                        width: 180,
                        height: 140,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.timer_off_outlined, color: Colors.grey, size: 50)),
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => QuizManagerScreen(
                                  completedSessionDetailIds: previousSessionDetailIds,
                                ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2C73D9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        child: const Text('ابدأ الاختبار'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward,
                  size: 35, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
               tooltip: 'رجوع',
            ),
          ),
        ],
      ),
    );
  }
}