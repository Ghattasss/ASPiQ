import 'package:flutter/material.dart';
// --- استيراد شاشة تدفق التمارين ---
import '../monthly_test/exercise_flow_screen.dart';

class Timetest extends StatelessWidget {
  const Timetest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff2C73D9),
      body: Stack( // استخدام Stack لوضع زر الرجوع فوق المحتوى
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85, // عرض نسبي
              constraints: BoxConstraints(maxWidth: 340), // حد أقصى للعرض
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0), // تعديل الحشو
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [ // إضافة ظل
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // ليأخذ أقل ارتفاع ممكن
                children: [
                  const Text(
                    'حان وقت الاختبار',
                    style: TextStyle(
                        fontSize: 26, // تكبير الخط
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2C73D9)),
                  ),
                  const SizedBox(height: 15), // تقليل المسافة

                  // عرض صورة GIF (تأكد من وجودها في assets/images/)
                  Image.asset(
                    'assets/images/clock.gif', // تأكد من المسار الصحيح
                    width: 180, // تقليل العرض قليلاً
                    height: 140, // تقليل الارتفاع قليلاً
                    errorBuilder: (ctx, err, st) => Icon(Icons.timer_outlined, size: 100, color: Colors.grey[400]), // في حالة عدم تحميل الصورة
                  ),

                  const SizedBox(height: 25), // زيادة المسافة
                  SizedBox(
                    width: double.infinity, // ليأخذ عرض الحاوية
                    child: ElevatedButton(
                      // ! --- التعديل هنا للانتقال إلى ExerciseFlowScreen ---
                      onPressed: () {
                        // استخدام pushReplacement أفضل حتى لا يعود المستخدم لهذه الشاشة
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => ExerciseFlowScreen()), // الانتقال لشاشة التمارين
                        );
                      },
                      // ! --- نهاية التعديل ---
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff2C73D9),
                        foregroundColor: Colors.white, // لون النص
                        padding: EdgeInsets.symmetric(vertical: 15), // زيادة الحشو الرأسي
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'ابدأ الاختبار',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // سهم الرجوع (محاذاة لليسار في الواجهة العربية)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // تحت شريط الحالة
            left: 16, // لليسار في RTL
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, // أيقونة مناسبة للخلف
                  size: 28, color: Colors.white),
              tooltip: 'رجوع', // تلميح للزر
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // يرجع إلى الشاشة السابقة (HomeScreen)
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}