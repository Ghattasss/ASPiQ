// lib/screens/animated_break_screen.dart (اسم مقترح للملف)
// lib/screens/break_screen.dart
import 'dart:async'; // لاستخدام Timer
import 'package:flutter/material.dart';
import 'dart:math';

class BreakScreen extends StatefulWidget {
  final Duration duration; // استقبال المدة

  const BreakScreen({Key? key, required this.duration}) : super(key: key);

  @override
  _BreakScreenState createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen> with TickerProviderStateMixin { // استخدم TickerProviderStateMixin
  late AnimationController _waveController;
  late AnimationController _timerController; // للتحكم في مؤقت العد التنازلي
  double waveOffset = 0.0;
  Timer? _popTimer; // مؤقت للإغلاق التلقائي

  // حساب الوقت المتبقي
  Duration get _remainingTime {
     if (!_timerController.isAnimating && !_timerController.isCompleted) {
         return widget.duration; // الوقت الأولي
     }
     // حساب الوقت المتبقي بناءً على تقدم الأنيميشن
     return widget.duration * (1.0 - _timerController.value);
  }

  @override
  void initState() {
    super.initState();

    // --- Wave Animation Controller ---
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // مدة دورة الموجة
    )..addListener(() {
        if (mounted) { // تحقق قبل setState
          setState(() {
            // حركة أبطأ للموجة
            waveOffset += 0.02; // تقليل قيمة الزيادة
          });
        }
      })..repeat();

    // --- Timer Animation Controller ---
    _timerController = AnimationController(
        vsync: this,
        duration: widget.duration // مدة الأنيميشن هي مدة البريك
    )..addListener(() {
       // إعادة بناء الواجهة لعرض الوقت المتبقي
       if(mounted) setState(() {});
    })..forward(); // ابدأ الأنيميشن فوراً


    // --- Timer to Pop Screen ---
    _popTimer = Timer(widget.duration, () {
      print("BreakScreen: Timer finished, popping.");
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _timerController.dispose(); // التخلص من كنترولر المؤقت
    _popTimer?.cancel(); // ألغِ مؤقت الإغلاق
    super.dispose();
  }

  // --- تنسيق الوقت المتبقي ---
   String formatBreakDuration(Duration duration) {
     duration = duration.isNegative ? Duration.zero : duration;
     String twoDigits(int n) => n.toString().padLeft(2, '0');
     // عرض الدقائق والثواني فقط للبريك
     final minutes = twoDigits(duration.inMinutes.remainder(60));
     final seconds = twoDigits(duration.inSeconds.remainder(60));
     return '$minutes:$seconds';
   }
   // --- التحويل للأرقام العربية ---
    String _convertToArabicNumbers(String number) {
       const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
       const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
       String result = number;
       for (int i = 0; i < english.length; i++) { result = result.replaceAll(english[i], arabic[i]); }
       return result;
    }


  @override
  Widget build(BuildContext context) {
    // اللون الأساسي للبريك
    const breakColor = Color(0xff2C73D9);

    return PopScope( // لمنع الإغلاق بالسحب للخلف (اختياري)
      canPop: false, // لا تسمح بالإغلاق اليدوي
      child: Scaffold(
        body: Stack(
          children: [
            // خلفية بيضاء
            Container(color: Colors.white),
            // --- رسم الموجة ---
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              // أرسل waveOffset وتقدم المؤقت للتحكم في ارتفاع الموجة
              painter: WavePainter(waveOffset, _timerController.value, breakColor),
            ),
            // --- محتوى الشاشة (العنوان والمؤقت) ---
            Positioned.fill( // اجعل العمود يملأ الشاشة
              child: Column(
                 mainAxisAlignment: MainAxisAlignment.center, // توسيط المحتوى رأسياً
                 children: [
                   // --- عنوان البريك ---
                   const Text(
                     "وقت الاستراحة", // تغيير العنوان
                     textAlign: TextAlign.center,
                     style: TextStyle( fontSize: 32, fontWeight: FontWeight.bold, color: breakColor, ),
                   ),
                   const SizedBox(height: 40), // مسافة أكبر
                   // --- عرض المؤقت ---
                   Text(
                     _convertToArabicNumbers(formatBreakDuration(_remainingTime)),
                     textAlign: TextAlign.center,
                     style: const TextStyle( fontSize: 60, fontWeight: FontWeight.bold, color: breakColor, fontFamily: 'monospace'), // خط أكبر للمؤقت
                     textDirection: TextDirection.ltr, // الأرقام دائماً LTR
                   ),
                    const SizedBox(height: 10),
                    Text( "ثانية : دقيقة", style: TextStyle(color: breakColor.withOpacity(0.8), fontSize: 16), ),
                    const SizedBox(height: 60), // مسافة إضافية
                 ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- كلاس رسم الموجة (مع تعديل بسيط لاستخدام تقدم المؤقت) ---
class WavePainter extends CustomPainter {
  final double waveOffset;
  final double timerProgress; // قيمة بين 0.0 (البداية) و 1.0 (النهاية)
  final Color waveColor;

  WavePainter(this.waveOffset, this.timerProgress, this.waveColor);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = waveColor.withOpacity(0.6); // تقليل الشفافية قليلاً

    Path path = Path();
    // ابدأ من أسفل اليسار
    path.moveTo(0, size.height);

    // حساب الارتفاع الأساسي للموجة (تقل مع الوقت)
    // تبدأ من حوالي 80% من الارتفاع وتنتهي عند 0
    double baseHeight = size.height * (0.8 * (1.0 - timerProgress));

    // رسم الموجة
    for (double x = 0; x <= size.width; x++) {
      // معادلة الموجة (يمكن تعديل التردد والسعة)
      // sin(frequency * x + offset) * amplitude + base_height
      double y = baseHeight + (sin((x * 0.015) + waveOffset) * 30); // تقليل السعة والتردد قليلاً
      // تأكد أن y لا تتجاوز ارتفاع الشاشة
      y = y.clamp(0.0, size.height);
      path.lineTo(x, y);
    }

    // أغلق المسار بالوصول لأسفل اليمين ثم العودة لأسفل اليسار
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

     // --- رسم موجة ثانية بتأخير وشفافية مختلفة (اختياري) ---
     Paint paint2 = Paint()..color = waveColor.withOpacity(0.3);
     Path path2 = Path();
     path2.moveTo(0, size.height);
     double baseHeight2 = size.height * (0.83 * (1.0 - timerProgress)); // تبدأ أعلى قليلاً
     for (double x = 0; x <= size.width; x++) {
       double y = baseHeight2 + (sin((x * 0.012) + waveOffset * 0.8) * 35); // تردد وسعة مختلفان قليلاً
       y = y.clamp(0.0, size.height);
       path2.lineTo(x, y);
     }
     path2.lineTo(size.width, size.height);
     path2.close();
     canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true; // أعد الرسم دائماً للأنيميشن
}