import 'package:flutter/material.dart';
// لا نحتاج dart:async هنا

// --- استيراد الشاشات والملفات الضرورية ---
// تأكد من صحة هذه المسارات في مشروعكimport 'package:myfinalpro/emotion/emotion_screen.dart'; 
import 'package:myfinalpro/session/timetest.dart'; // StartTest
import 'package:myfinalpro/widget/page_route_names.dart';
import 'package:myfinalpro/widget/report.dart';        // ReportView
import 'package:myfinalpro/login/login_view.dart';      // LoginView
import 'package:myfinalpro/registration/registration.dart'; // RegistrationView
import 'package:myfinalpro/screens/skills.dart';       // SkillsScreen
import 'package:myfinalpro/screens/splash_screen.dart';  // SplashScreen
// تأكد من أن هذا هو المسار الصحيح لملف شاشة البريك وأن الكلاس بداخله اسمه BreakScreen
import 'package:myfinalpro/session/break.dart';      // <-- تعديل المسار والاسم إذا لزم الأمر
import 'package:myfinalpro/session/session_details_screen.dart'; // <-- شاشة تفاصيل الجلسة
import 'package:myfinalpro/widget/about_app.dart';      // About_App
import 'package:myfinalpro/screens/assessment_screen.dart'; // AssessmentScreen
import 'package:myfinalpro/widget/editaccount.dart';   // EditAccountScreen
import 'package:myfinalpro/session/models/session_model.dart'; // <-- *** استيراد المودل ضروري هنا ***
import 'package:myfinalpro/emotion/sequential_session_screen.dart';
import 'package:myfinalpro/models/smart_assistant_screen.dart';

class RoutesGenerator {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    debugPrint("Generating route for: ${settings.name} with arguments: ${settings.arguments}"); // استخدام debugPrint

    final args = settings.arguments;

    switch (settings.name) {
      case PageRouteName.initial:
        return MaterialPageRoute( builder: (_) => SplashScreen(), settings: settings );
      case PageRouteName.login:
        return MaterialPageRoute( builder: (_) => const LoginView(), settings: settings );
      case PageRouteName.registration:
        return MaterialPageRoute( builder: (_) => const RegistrationView(), settings: settings );
      case PageRouteName.skills:
        return MaterialPageRoute( builder: (_) => SkillsScreen(), settings: settings ); // قد تحتاج لـ const
      case PageRouteName.emotions: // <-- تأكد أن هذا الاسم موجود في PageRouteName
        return MaterialPageRoute( builder: (_) => const TrainingSessionsScreen(), settings: settings );
      case PageRouteName.editProfile:
        return MaterialPageRoute( builder: (_) => const EditAccountScreen(), settings: settings );
      case PageRouteName.aboutApp:
        return MaterialPageRoute( builder: (_) => const About_App(), settings: settings );
      case PageRouteName.reports:
        return MaterialPageRoute( builder: (_) => const ReportView(), settings: settings );
      case PageRouteName.smartAssistant:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case PageRouteName.starttest: // <-- تأكد أن هذا الاسم موجود في PageRouteName
         if (args is List<int>) { // التحقق من أن الـ arguments هي قائمة من الأرقام
          return MaterialPageRoute(
            builder: (_) => StartTest(previousSessionDetailIds: args), // تمرير الـ args
            settings: settings,
          );
        } else {
          // إذا لم يتم تمرير الـ arguments أو كان نوعها خاطئًا
          debugPrint("RouteGenerator Error: Arguments for StartTest (at ${PageRouteName.starttest}) are not List<int>. Received: $args");
          return _errorRoute(settings, "بيانات بدء الاختبار غير متوفرة أو غير صالحة.");
        }
      // --- إضافة مسارات الكويز ---
      /*case PageRouteName.quizManager: // <<--- تأكد من إضافة هذا الثابت في PageRouteName
        return MaterialPageRoute( builder: (_) => const QuizManagerScreen(), settings: settings );
      case PageRouteName.quizEnd:     // <<--- تأكد من إضافة هذا الثابت في PageRouteName
        return MaterialPageRoute( builder: (_) => EndTestScreen(), settings: settings ); // قد لا تحتاج لـ const إذا كانت stateful
      // --- نهاية إضافة مسارات الكويز ---*/

      case PageRouteName.chatPot:
        final String? tokenArgument = settings.arguments as String?;
        if (tokenArgument != null && tokenArgument.isNotEmpty) {
          return MaterialPageRoute( builder: (_) => AssessmentScreen(jwtToken: tokenArgument), settings: settings );
        } else {
          debugPrint("RouteGenerator Error: Missing jwtToken for AssessmentScreen.");
          return _errorRoute(settings, "Token not provided for assessment");
        }

      case PageRouteName.session:
        final args = settings.arguments;
        if (args is Map<String, dynamic> && args.containsKey('initialSession') && args.containsKey('jwtToken')) {
          final dynamic sessionArg = args['initialSession'];
          final String jwtToken = args['jwtToken'] as String? ?? '';

          Session? sessionModel;
          if (sessionArg is Map<String, dynamic>) {
             try { sessionModel = Session.fromJson(sessionArg); }
             catch (e) { debugPrint("RouteGenerator Error: Failed to parse sessionData Map into Session object: $e"); return _errorRoute(settings, "Invalid session data format"); }
          } else if (sessionArg is Session) { sessionModel = sessionArg; }

          if (sessionModel != null && jwtToken.isNotEmpty) {
             return MaterialPageRoute( builder: (_) => SessionDetailsScreen( initialSession: sessionModel!, jwtToken: jwtToken ), settings: settings );
          } else { debugPrint("RouteGenerator Error: Failed to obtain valid Session object or token."); return _errorRoute(settings, "Invalid session data or token"); }
        } else { debugPrint("RouteGenerator Error: Missing or invalid arguments map for SessionDetailsScreen."); return _errorRoute(settings, "Session arguments missing or invalid"); }

      case PageRouteName.breaak: // <-- تأكد أن هذا الاسم موجود في PageRouteName
        final Duration? breakDurationArg = settings.arguments as Duration?;
        if (breakDurationArg != null) {
          return MaterialPageRoute( builder: (_) => BreakScreen(duration: breakDurationArg), settings: settings );
        } else {
          debugPrint("RouteGenerator Error: Missing breakDuration for BreakScreen.");
          return _errorRoute(settings, "Break duration missing");
        }

      default:
        debugPrint("Route Error: Route ${settings.name} not found. Navigating to Splash.");
        return MaterialPageRoute( builder: (_) => SplashScreen(), settings: settings );
    }
  }

  static Route<dynamic> _errorRoute(RouteSettings settings, String error) {
    debugPrint("Route Error: $error for route ${settings.name}"); // استخدام debugPrint
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('خطأ في التوجيه')),
        body: Center(child: Text('حدث خطأ أثناء الانتقال.\n($error)')),
      ),
      settings: settings,
    );
  }
}