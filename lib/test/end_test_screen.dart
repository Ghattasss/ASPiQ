import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:myfinalpro/screens/home_screen.dart'; // تأكد من المسار الصحيح
import 'package:shared_preferences/shared_preferences.dart';

class EndTestScreen extends StatefulWidget {
  final bool testPassed;

  const EndTestScreen({super.key, this.testPassed = true});

  @override
  _EndTestScreenState createState() => _EndTestScreenState();
}

class _EndTestScreenState extends State<EndTestScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.testPassed) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _startCooldownAndNavigateHome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cooldownStartTimeMillis = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('lastSessionStartTime', cooldownStartTimeMillis);
      debugPrint(
          "EndTestScreen: Cooldown timer started. Ref time saved: $cooldownStartTimeMillis");

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Error saving cooldown start time: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ في بدء مؤقت الانتظار.')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String message = widget.testPassed
        ? '🎉 رائع! لقد أنهيت الاختبار بنجاح 🎉'
        : 'انتهى الاختبار. لا تقلق، سنركز أكثر على هذه النقاط في الجلسات القادمة لمساعدتك على التمكن منها بشكل أفضل';

    IconData iconData = widget.testPassed
        ? Icons.celebration_rounded 
        : Icons.sentiment_very_dissatisfied_rounded;
    Color iconColor =
        widget.testPassed ? const Color(0xff2C73D9) : Colors.orange.shade700;

    return Scaffold(
      backgroundColor: const Color(0xff2C73D9),
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.testPassed)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xff2C73D9),
                  Colors.white,
                  Colors.purple,
                  Colors.yellow,
                  Colors.green,
                  Colors.redAccent
                ],
                gravity: 0.1,
                emissionFrequency: 0.04,
                numberOfParticles: 15,
              ),
            ),
          AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, size: 60, color: iconColor),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color:
                          const Color(0xff2C73D9)), // اللون الأزرق للنص دائمًا
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _startCooldownAndNavigateHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2C73D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: const Text('العودة للرئيسية',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
