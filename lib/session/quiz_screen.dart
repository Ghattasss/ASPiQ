/*import 'package:flutter/material.dart';
import '../services/Api_services.dart';  // لاستدعاء updateSessionDone
import 'package:myfinalpro/screens/home_screen.dart';

class QuizScreen extends StatefulWidget {
  final int sessionId;
  final String jwtToken;
  // يمكنك إضافة قائمة الأسئلة هنا إذا تم تمريرها
  // final List<dynamic> quizQuestions;

  const QuizScreen({
    super.key,
    required this.sessionId,
    required this.jwtToken,
    // required this.quizQuestions
  });

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  bool _isLoading = false; // للتحميل عند إرسال الإجابات أو تحديث الجلسة
  // قائمة لتخزين إجابات المستخدم (إذا أردت إرسالها)
  // List<Map<String, dynamic>> _userAnswers = [];
  // قائمة أسئلة الكويز (يجب جلبها أو استقبالها)
  List<dynamic> _quizQuestions = []; // مثال: [{"question": "...", "options": ["...", "..."], "correct": 0}, ...]

  @override
  void initState() {
    super.initState();
    // --- جلب أسئلة الكويز ---
    // إما من widget.quizQuestions إذا تم تمريرها
    // أو عن طريق استدعاء API Service هنا
    // _fetchQuizQuestions();
     _loadMockQuestions(); // استخدام أسئلة وهمية مؤقتاً
  }

  // --- دالة مؤقتة لأسئلة وهمية ---
  void _loadMockQuestions(){
     setState(() {
       _quizQuestions = [
          {"id": 101, "question": "في الموقف السابق، كان الطفل يشعر بـ:", "options": ["السعادة", "الحزن"], "correct": 0},
          {"id": 102, "question": "ماذا يجب أن يفعل ليشكر أخته؟", "options": ["يشكرها بهدوء", "يركض ويصرخ"], "correct": 0},
          // أضف المزيد من الأسئلة الوهمية
       ];
        _isLoading = false; // إيقاف التحميل بعد جلب الأسئلة
     });
  }

  // --- معالجة اختيار إجابة ---
  void _handleAnswerSelected(int questionId, int selectedOptionIndex) {
     print("Quiz Q:$questionId, User selected option: $selectedOptionIndex");
     // يمكنك إضافة منطق للتحقق من الإجابة الصحيحة وعرض تغذية راجعة
     // أو فقط تخزين الإجابة والانتقال للسؤال التالي

     if (_currentQuestionIndex < _quizQuestions.length - 1) {
        setState(() { _currentQuestionIndex++; }); // انتقل للسؤال التالي
     } else {
        // اكتمل الكويز
        _completeQuiz();
     }
  }

  // --- إنهاء الكويز وتحديث حالة الجلسة ---
  Future<void> _completeQuiz() async {
    if (!mounted) return;
    setState(() { _isLoading = true; }); // بدء التحميل

    print("Completing quiz for session ID: ${widget.sessionId}");
    bool success = await ApiService.updateSessionDone(widget.sessionId, widget.jwtToken);

    if (!mounted) return;

    if (success) {
      print("Session status updated successfully.");
       // عرض شاشة "أحسنت" ثم الانتقال للهوم
       Navigator.pushAndRemoveUntil(
         context,
         MaterialPageRoute(builder: (context) => const QuizCompletionScreen()), // شاشة افتراضية
         (route) => false
       );
    } else {
      print("Error updating session status.");
       setState(() { _isLoading = false; }); // إيقاف التحميل
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("حدث خطأ أثناء إنهاء الجلسة."), backgroundColor: Colors.red,)
      );
       // يمكنك توفير زر لإعادة المحاولة أو الانتقال للهوم مباشرة
    }
  }


  @override
  Widget build(BuildContext context) {
    // التحقق من وجود أسئلة قبل بناء الواجهة
    final bool hasQuestions = _quizQuestions.isNotEmpty;
    final currentQuestion = hasQuestions ? _quizQuestions[_currentQuestionIndex] : null;
    final List<dynamic> options = hasQuestions ? (currentQuestion?['options'] ?? []) : [];


    return Scaffold(
      appBar: AppBar(
        title: const Text("اختبار الجلسة"),
         automaticallyImplyLeading: false, // منع الرجوع أثناء الكويز
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasQuestions
              ? const Center(child: Text("لا توجد أسئلة متاحة لهذا الاختبار."))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- عرض رقم السؤال ---
                      Text(
                         "السؤال ${_currentQuestionIndex + 1} من ${_quizQuestions.length}",
                         style: Theme.of(context).textTheme.titleMedium,
                         textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      // --- نص السؤال ---
                      Text(
                         currentQuestion?['question'] ?? '...',
                         style: Theme.of(context).textTheme.headlineSmall,
                         textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // --- عرض الخيارات ---
                      Expanded( // لجعل الأزرار تأخذ المساحة المتبقية
                        child: ListView.separated(
                           itemCount: options.length,
                           separatorBuilder: (_, __) => const SizedBox(height: 15),
                           itemBuilder: (context, index) {
                              return ElevatedButton(
                                 onPressed: () => _handleAnswerSelected(currentQuestion?['id'] ?? -1, index),
                                 child: Text(options[index]?.toString() ?? 'خيار $index'),
                                 style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    textStyle: const TextStyle(fontSize: 18)
                                 ),
                              );
                           }
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// --- شاشة افتراضية بسيطة لنهاية الكويز ---
class QuizCompletionScreen extends StatelessWidget {
  const QuizCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الانتقال للهوم بعد ثانيتين
    Future.delayed(const Duration(seconds: 2), () {
       if (Navigator.canPop(context)) { // تحقق بسيط
           Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => HomeScreen()), (route) => false);
       }
    });

    return Scaffold(
       backgroundColor: Colors.teal[50],
       body: Center(
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: const [
                Icon(Icons.check_circle, color: Colors.teal, size: 100),
                SizedBox(height: 20),
                Text("أحسنت!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal)),
                 SizedBox(height: 10),
                Text("لقد أنهيت الجلسة بنجاح.", style: TextStyle(fontSize: 18, color: Colors.black54)),
             ],
          )
       ),
    );
  }
}*/