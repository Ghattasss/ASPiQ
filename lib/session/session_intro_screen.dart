// lib/screens/session_intro_screen.dart
import 'package:flutter/material.dart';
import 'models/session_model.dart'; // تأكد من المسار الصحيح
import 'session_details_screen.dart'; // شاشة عرض التمارين

class SessionIntroScreen extends StatelessWidget {
  final Session session;
  final String jwtToken;

  const SessionIntroScreen({
    super.key,
    required this.session,
    required this.jwtToken,
  });

  // دالة مساعدة لتحويل الأرقام
  String _convertToArabicNumbers(String number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      number = number.replaceAll(english[i], arabic[i]);
    }
    return number;
  }

  // دالة مساعدة لتحليل وعرض نقاط الأهداف
  List<Widget> _parseAndDisplayTextPoints(String text, Color textColor) {
    final points = text
        .split(RegExp(r'\s*-\s*|\s*\n\s*'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    List<Widget> widgets = [];
    for (int i = 0; i < points.length; i++) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${_convertToArabicNumbers((i + 1).toString())}- ",
                style: TextStyle(
                    color: textColor.withAlpha(230),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(
                points[i].trim(),
                style: TextStyle(fontSize: 16, color: textColor, height: 1.4),
              ),
            ),
          ],
        ),
      ));
    }
    if (widgets.isEmpty) {
      widgets.add(Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(text,
              style: TextStyle(fontSize: 16, color: textColor, height: 1.4))));
    }
    return widgets;
  }

  // دالة مساعدة لعرض نقاط الإرشادات الثابتة
  Widget _buildStaticInstructionPoint(
      String number, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${_convertToArabicNumbers(number)}- ",
              style: TextStyle(
                  color: textColor.withAlpha(230),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text.trim(),
              style: TextStyle(fontSize: 16, color: textColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        Colors.blue.shade50; // Default background color
    final Color primaryColor = const Color(0xff2C73D9); // Default primary color
    const Color cardBackgroundColor = Colors.white;
    const Color textColor = Colors.black87;
    const String instruction1 =
        "ضرورة الجلوس فى المستوى البصرى للطفل وذلك لجذب إنتباهه";
    const String instruction2 =
        "تنظيم بيئة التدريب، تجنب المشتتات وأن تكون بيئة التدريب بعيدة عن الضوضاء.";
    const String instruction3 =
        "إستخدام إسلوب التواصل الفعال والذى يتضمن إستخدام لغة سهلة مبسطة مدعومة بالإشارات والتواصل غير اللفظى ولغة العيون وتعابير الوجه واليد.";

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            session.title ?? 'مقدمة الجلسة',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: primaryColor),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 100.0),
          children: [
            Center(
                child: Text(session.title ?? 'الجلسة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor))),
            const SizedBox(height: 30),
            Row(
              children: [
                Text("زمن الجلسة:",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor)),
                const SizedBox(width: 8),
                Text(_convertToArabicNumbers("45") + " دقيقة",
                    style: const TextStyle(fontSize: 18, color: textColor)),
              ],
            ),
            const Divider(height: 30, thickness: 0.5),
            if (session.goal != null && session.goal!.isNotEmpty) ...[
              Text(
                "أهداف الجلسة:",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0.5,
                color: cardBackgroundColor,
                margin: const EdgeInsets.only(bottom: 25),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _parseAndDisplayTextPoints(
                            session.goal!, textColor))),
              ),
            ],
            Text(
              "إرشادات الجلسة:",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0.5,
              color: cardBackgroundColor,
              margin: const EdgeInsets.only(bottom: 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStaticInstructionPoint(
                          "١", instruction1, textColor),
                      _buildStaticInstructionPoint(
                          "٢", instruction2, textColor),
                      _buildStaticInstructionPoint(
                          "٣", instruction3, textColor),
                    ]),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // *** استخدام session.details للتحقق ***
                if (session.details.isNotEmpty) {
                  print(
                      "Session Details (Exercises) Length: ${session.details.length}");
                  print("Navigating from Intro to Details screen.");
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionDetailsScreen(
                        initialSession: session,
                        jwtToken: jwtToken,
                      ),
                    ),
                  ); // تمرير Session الكامل
                } else {
                  print("Error: No exercises found in the session.");
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لا توجد تمارين متاحة.')));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0)),
              ),
              child: const Text('ابدأ التمارين'),
            ),
          ),
        ),
      ),
    );
  }
}
