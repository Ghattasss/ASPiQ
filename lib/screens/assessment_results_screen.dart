// lib/screens/assessment_results_screen.dart
import 'package:flutter/material.dart';
// --- استيراد الملفات الضرورية ---
import '../models/submission_result.dart'; // <-- استيراد النموذج المنفصل
import 'home_screen.dart';             // <-- استيراد الشاشة الرئيسية

class AssessmentResultsScreen extends StatelessWidget {
  final List<SubmissionResult> results; // استقبال قائمة النتائج

  // تعديل الـ constructor لاستخدام super parameters وإضافة const
  const AssessmentResultsScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    // حساب الإحصائيات مع التحقق من null (إذا لزم الأمر، لكن Results لا يجب أن تكون null)
    final successfulSubmissions = results.where((r) => r.success == true).length;
    final totalQuestionsAttempted = results.length;
    final failedCount = totalQuestionsAttempted - successfulSubmissions;
    final answeredNoOrHelp = results.where((r) => r.classifiedAnswer == 'لا' || r.classifiedAnswer == 'بمساعدة').length; // استخدام classifiedAnswer

    return Scaffold(
      appBar: AppBar(
        title: const Text("ملخص نتائج التقييم"),
        centerTitle: true,
        automaticallyImplyLeading: false, // منع زر الرجوع
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- بطاقة الملخص العلوي ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "اكتمل التقييم!",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green[800]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // استخدام const للويدجتس الثابتة
                        _buildStatItem("الأسئلة", totalQuestionsAttempted.toString(), Icons.list_alt_rounded),
                        _buildStatItem("تحتاج متابعة", answeredNoOrHelp.toString(), Icons.flag_outlined, color: Colors.orange.shade800),
                        _buildStatItem("أُرسلت بنجاح", successfulSubmissions.toString(), Icons.cloud_done_outlined, color: Colors.green.shade700),
                      ],
                    ),
                     if (failedCount > 0) ...[
                       const SizedBox(height: 10),
                       Text(
                         "فشل إرسال $failedCount ${failedCount == 1 ? 'إجابة' : 'إجابات'}. يرجى التحقق من اتصالك.", // رسالة أوضح
                         style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                         textAlign: TextAlign.center,
                       ),
                     ]
                     else if (totalQuestionsAttempted > 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Text(
                             "(تم إرسال جميع الإجابات بنجاح)",
                              style: TextStyle(color: Colors.green, fontSize: 13),
                              textAlign: TextAlign.center,
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- عنوان قائمة التفاصيل ---
            const Text(
              "تفاصيل الإجابات:", // عنوان أبسط
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 10),

            // --- قائمة التفاصيل ---
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text("لم يتم تسجيل أي إجابات.", style: TextStyle(color: Colors.grey)))
                  : Container(
                     decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300)
                     ),
                     child: ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (context, index) => const Divider(height: 0.5, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final result = results[index];
                          final Color statusColor = result.success ? Colors.green.shade600 : Colors.red.shade600;
                          final IconData statusIcon = result.success ? Icons.check_circle_outline : Icons.error_outline; // تغيير الأيقونات
                          final Color answerColor = result.classifiedAnswer == 'نعم' ? Colors.teal.shade700 : (result.classifiedAnswer == 'لا' ? Colors.deepOrange.shade800 : Colors.blueGrey.shade700);

                          return Padding(
                             padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 // --- السؤال ---
                                 Row(
                                   children: [
                                     CircleAvatar(radius: 12, backgroundColor: Colors.grey.shade200, child: Text('${result.questionId}', style: const TextStyle(fontSize: 10, color: Colors.black54))),
                                     const SizedBox(width: 10),
                                     Expanded(child: Text("سؤال: ${result.questionText}", style: const TextStyle(fontSize: 13.5, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis,)),
                                   ],
                                 ),
                                 const SizedBox(height: 8),
                                 // --- إجابة الأم ---
                                  Text(
                                     "  إجابتك: \"${result.rawAnswer}\"", // <-- عرض الإجابة الأصلية
                                     style: const TextStyle(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
                                  ),
                                 const SizedBox(height: 6),
                                 // --- نتيجة المودل وحالة الإرسال ---
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Row( // نتيجة المودل
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         Text("  التصنيف: ", style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                                         Text(
                                           result.classifiedAnswer, // <-- عرض الإجابة المصنفة
                                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: answerColor),
                                         ),
                                       ],
                                     ),
                                      Row( // حالة الإرسال
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                           Text(result.success ? "أُرسلت" : "فشل الإرسال", style: TextStyle(fontSize: 12, color: statusColor)),
                                           const SizedBox(width: 4),
                                           Icon(statusIcon, color: statusColor, size: 16),
                                        ],
                                      )
                                   ],
                                 ),
                               ],
                             ),
                          );
                        },
                     ),
                  ),
            ),
            const SizedBox(height: 20),

            // --- زر العودة للرئيسية ---
            ElevatedButton.icon(
              icon: const Icon(Icons.home_outlined),
              label: const Text("العودة إلى الشاشة الرئيسية"),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()), // تأكد من استيراد HomeScreen
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Theme.of(context).primaryColor
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ويدجت مساعد لعرض الإحصائيات ---
  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 30, color: color ?? Colors.blueGrey[700]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}