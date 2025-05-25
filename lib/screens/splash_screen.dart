import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- إضافة مهمة

// --- استيراد الشاشات اللازمة ---
import 'onboarding_screen.dart';
import '../screens/home_screen.dart'; // <-- إضافة مهمة

class SplashScreen extends StatefulWidget {
  // استخدام const إذا لم يكن هناك متغيرات تتغير
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool animateText = false;
  bool animateLogo = false;

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate(); // استدعاء الدالة الجديدة
  }

  // --- دالة جديدة للتهيئة والتحقق والتنقل ---
  Future<void> _initializeAndNavigate() async {
    // تأخير بسيط قبل بدء الحركات لجعلها أكثر سلاسة
    // لا يزال بإمكانك بدء الحركات مبكرًا إذا أردت
    await Future.delayed(const Duration(milliseconds: 500));
    // التحقق إذا كانت الواجهة لا تزال موجودة قبل تحديث الحالة
    if (mounted) {
      setState(() {
        animateText = true;
        animateLogo = true;
      });
    }

    // --- 1. التحقق من حالة تسجيل الدخول ---
    final Future<bool> checkLoginFuture = _checkLoginStatus();

    // --- 2. تحديد الحد الأدنى لمدة عرض الشاشة ---
    const minimumSplashDuration = Duration(seconds: 4);
    final Future<void> delayFuture = Future.delayed(minimumSplashDuration);

    // --- 3. انتظار اكتمال كل من التحقق والحد الأدنى للوقت ---
    // Future.wait ينتظر اكتمال كل الـ Futures في القائمة
    final results = await Future.wait([checkLoginFuture, delayFuture]);

    // --- 4. الحصول على نتيجة التحقق وتحديد الوجهة ---
    final bool isLoggedIn = results[0] as bool; // النتيجة الأولى هي نتيجة checkLoginFuture

    Widget targetScreen;
    if (isLoggedIn) {
      print("Splash: User is logged in. Navigating to HomeScreen.");
      targetScreen = const HomeScreen(); // <-- الوجهة إذا كان مسجل دخوله
    } else {
      print("Splash: User is NOT logged in. Navigating to OnboardingScreen.");
      targetScreen = OnboardingScreen(); // <-- الوجهة إذا لم يكن مسجل دخوله
    }

    // --- 5. التنقل إلى الوجهة المحددة مع استبدال الـ Splash Screen ---
    // التحقق مرة أخرى إذا كانت الواجهة لا تزال موجودة قبل التنقل
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    }
  }

  // --- دالة للتحقق من وجود التوكن ---
  Future<bool> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // نفس المفتاح المستخدم في LoginView لحفظ التوكن
      final String? token = prefs.getString('auth_token');
      // يعتبر المستخدم مسجل دخوله إذا كان التوكن موجودًا وغير فارغ
      return token != null && token.isNotEmpty;
    } catch (e) {
      // في حالة حدوث خطأ أثناء قراءة SharedPreferences، اعتبره غير مسجل الدخول
      print("Error checking login status in Splash: $e");
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    //final screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white, // خلفية بيضاء للشاشة
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // تأثير التلاشي (Fade-in) على اللوجو
              AnimatedOpacity(
                opacity: animateLogo ? 1 : 0,
                // يظهر تدريجياً عند تفعيل animateLogo
                duration: const Duration(milliseconds: 1200),
                child: Image.asset(
                  'assets/images/logo.png',
                  // الصورة المستخدمة كشعار للتطبيق
                  width: screenWidth * 0.5,
                  fit: BoxFit.contain,
                   errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 80), // بديل في حالة الخطأ
                ),
              ),

              // النص المتحرك الذي يكون على شكل جزئين "ASP" و "iQ"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // تحريك الجزء الأول من النص "ASP" من اليسار
                  AnimatedSlide(
                    offset: animateText ? Offset.zero : const Offset(-1, 0), // استخدام Offset.zero أفضل
                    // يتحرك من اليسار
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    child: const Text(
                      "ASP",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(
                            0xFF2C73D9), // لون أزرق متناسق مع تصميم التطبيق
                      ),
                    ),
                  ),

                  // تحريك الجزء الثاني من النص "iQ" من اليمين
                  AnimatedSlide(
                    offset: animateText ? Offset.zero : const Offset(1, 0), // استخدام Offset.zero أفضل
                    // يتحرك من اليمين
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    child: const Text(
                      "iQ",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C73D9),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}