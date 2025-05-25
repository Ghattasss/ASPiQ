/*import 'package:flutter/material.dart';
import 'package:myfinalpro/widget/page_route_names.dart';
import 'package:myfinalpro/widget/routes_generator.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASPIQ',
      debugShowCheckedModeBanner: false,
      initialRoute: PageRouteName.initial,
      onGenerateRoute: RoutesGenerator.onGenerateRoute,
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // <-- *** 1. استيراد Provider ***

// ! تأكد من صحة هذه المسارات
import 'package:myfinalpro/core/serveses/shared_preferance_servace.dart';
import 'package:myfinalpro/services/bloc_observer.dart';
import 'package:myfinalpro/widget/page_route_names.dart';
import 'package:myfinalpro/widget/routes_generator.dart';
import 'package:myfinalpro/services/Api_services.dart'; // <-- *** 2. استيراد ApiService ***

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SharedPreferenceServices.init();
    print("SharedPreferences Initialized Successfully in main.");
  } catch (e, s) {
    print("!!!!!!!! ERROR initializing SharedPreferences in main: $e !!!!!!!!");
    print("Stacktrace: $s");
  }

  try {
    Bloc.observer = MyBlocObserver();
    print("BlocObserver Initialized.");
  } catch (e) {
    print("Error initializing BlocObserver: $e");
  }

  // --- الخطوة 4: تشغيل التطبيق ---
  // لا تغيير هنا، الـ Provider سيكون داخل MyApp
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- *** 3. تغليف MaterialApp بـ Provider *** ---
    return Provider<ApiService>(
      // إنشاء نسخة واحدة من ApiService عند بداية التطبيق
      create: (_) => ApiService(),
      child: MaterialApp(
        title: 'ASPIQ',
        debugShowCheckedModeBanner: false,
        // --- دعم اللغة العربية ---
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // supportedLocales: const [
        //   Locale('ar', ''), // العربية
        // ],
        locale: const Locale('ar', ''), // تحديد العربية كلغة افتراضية
        theme: ThemeData(
          primaryColor: const Color(0xff2C73D9),
          fontFamily: 'Cairo', // استخدام الخط Cairo
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2C73D9)),
          useMaterial3: true,
        ),
        initialRoute: PageRouteName.initial,
        onGenerateRoute: RoutesGenerator.onGenerateRoute,
      ),
    );
    // --- *** نهاية التغليف *** ---
  }
}