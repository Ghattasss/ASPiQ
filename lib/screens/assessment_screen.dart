// lib/screens/assessment_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

// --- استيراد الملفات الضرورية ---
import '../models/question_model.dart';
import 'assessment_data.dart'; // تأكد من وجود المتغير assessmentQuestions هنا
import '../services/Api_services.dart'; // تأكد من وجود الكلاس والدوال
import 'home_screen.dart';
import '../models/answer_model.dart'; // <-- *** تعديل: استيراد AnswerModel ***

// --- نموذج لتمثيل رسالة في الشات ---
class ChattMessage {
  final String text;
  final bool isUserMessage;
  final Question? questionData;

  ChattMessage(
      {required this.text, required this.isUserMessage, this.questionData});
}

// --- الشاشة الرئيسية للتقييم ---
class AssessmentScreen extends StatefulWidget {
  final String jwtToken;
  const AssessmentScreen({super.key, required this.jwtToken});

  @override
  _AssessmentScreenState createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _currentIndex = 0;
  bool _isLoading = false; // حالة تحميل عامة
  String? _uiMessage;     // لعرض رسائل للمستخدم (أخطاء، معلومات)
  bool _skipActive = false;
  String? _emotionToSkip;
  bool _isSessionProcessingComplete = false; // يُصبح true بعد معالجة كل الأسئلة وقبل الإرسال النهائي

  final List<ChattMessage> _chatMessages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

  // --- *** تعديل: قائمة لتخزين الإجابات قبل الإرسال المجمع *** ---
  final List<AnswerModel> _answersToSubmit = [];

  @override
  void initState() {
    super.initState();
    if (assessmentQuestions.isNotEmpty) {
      _startChatFlow();
    } else {
      _showUiMessage("خطأ: لم يتم تحميل أسئلة التقييم.", isError: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  // --- دالة لعرض رسائل للمستخدم وتحديث الواجهة ---
  void _showUiMessage(String message, {bool isError = false, bool isStickyLoading = false}) {
     if (!mounted) return;
     setState(() {
       _isLoading = isStickyLoading; // تستمر حالة التحميل فقط إذا كانت رسالة تحميل "لاصقة"
       _uiMessage = message;
       // أضف الرسالة للشات إذا لم تكن رسالة خطأ "فقط" أو رسالة تحميل لاصقة
       if (!isError && !isStickyLoading && !isUserMessageFromChat(message)) {
          _chatMessages.add(ChattMessage(text: message, isUserMessage: false));
       } else if (isError) { // إذا كانت رسالة خطأ ولم تكن من المستخدم أضفها
           if (!isUserMessageFromChat(message)) {
               _chatMessages.add(ChattMessage(text: message, isUserMessage: false));
           }
       }
     });
     _scrollToBottom();
  }

  // دالة مساعدة للتحقق إذا كانت الرسالة موجودة بالفعل كرسالة مستخدم في الشات
  bool isUserMessageFromChat(String text) {
    return _chatMessages.any((m) => m.isUserMessage && m.text == text);
  }


  void _startChatFlow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _chatMessages.add(ChattMessage(
          text: "أهلاً بكِ. سأطرح عليكِ بعض الأسئلة حول ملاحظاتك لطفلك. يرجى الإجابة بنص حر أو استخدام الأزرار المقترحة.",
          isUserMessage: false,
        ));
        setState(() {}); // تحديث الواجهة
        _scrollToBottom();
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) _askQuestionAtIndex(_currentIndex);
        });
      }
    });
  }

  void _askQuestionAtIndex(int index) {
    if (_isSessionProcessingComplete) return; // توقف إذا بدأت عملية الإرسال النهائي

    if (index < assessmentQuestions.length && mounted) {
      final question = assessmentQuestions[index];
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isSessionProcessingComplete) {
          _chatMessages.add(ChattMessage(
            text: question.text,
            isUserMessage: false,
            questionData: question,
          ));
          setState(() {
            _isLoading = false; // جاهز لاستقبال إجابة المستخدم
            _uiMessage = null;   // مسح أي رسالة سابقة
          });
          _scrollToBottom();
          _answerFocusNode.requestFocus(); // تركيز على حقل الإدخال
        }
      });
    } else if (mounted && index >= assessmentQuestions.length && !_isSessionProcessingComplete) {
      // تمت معالجة جميع الأسئلة (بما في ذلك التخطي)، حان وقت الإرسال النهائي
      _finalizeAndSubmitAllAnswers();
    }
  }

  void _showExplanation(Question question) {
    final explanationText = question.explanation; // الحصول على الشرح من كائن السؤال
    if (explanationText == null || explanationText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("لا يوجد شرح إضافي لهذا السؤال."), duration: Duration(seconds: 2)),
        );
      }
      return;
    }
    _answerFocusNode.unfocus();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      backgroundColor: Colors.white,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: 10),
                  Text("توضيح السؤال:", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                const Divider(height: 25, thickness: 0.8),
                Text(explanationText, textAlign: TextAlign.start, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
                const SizedBox(height: 25),
                Center(child: ElevatedButton(child: const Text("حسناً"), onPressed: () => Navigator.pop(context))),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAnswer(String answerText) async {
    final trimmedAnswer = answerText.trim();
    // التأكد أننا لم نبدأ عملية الإرسال النهائي وأن هناك أسئلة متبقية
    if (trimmedAnswer.isEmpty || _isLoading || _isSessionProcessingComplete || _currentIndex >= assessmentQuestions.length) return;

    _answerFocusNode.unfocus();
    final currentQuestion = assessmentQuestions[_currentIndex];

    // 1. التحقق من طلب الشرح
    const List<String> explanationRequests = ["مش فاهمة", "مش فاهمه", "يعنى ايه", "يعني ايه", "يعني إيه", "ايه المقصود", "إيه المقصود", "ماذا يعني", "اشرح", "شرح", "توضيح", "?", "مش فاهم", "ماذا افعل", "ماذا أفعل"];
    final lowerCaseAnswer = trimmedAnswer.toLowerCase();
    if (explanationRequests.any((request) => lowerCaseAnswer.contains(request))) {
      print("User requested explanation for Q:${currentQuestion.id}");
      _showExplanation(currentQuestion); // تمرير كائن السؤال بالكامل
      _answerController.clear();
      return;
    }

    // 2. إضافة رسالة المستخدم وبدء التحميل
    if (!mounted) return;
    _chatMessages.add(ChattMessage(text: trimmedAnswer, isUserMessage: true));
    setState(() {
      _isLoading = true; // بدء التحميل لمعالجة هذه الإجابة
      _uiMessage = null; // مسح أي رسالة خطأ سابقة
      _answerController.clear();
    });
    _scrollToBottom();

    // 3. تحديد الإجابة المصنفة
    String? classifiedAnswer;
    const validKeywords = ["نعم", "لا", "بمساعدة"];
    if (validKeywords.contains(trimmedAnswer)) {
      classifiedAnswer = trimmedAnswer;
    } else {
      await Future.delayed(const Duration(milliseconds: 100)); // إعطاء فرصة لتحديث الواجهة
      classifiedAnswer = await ApiService.classifyAnswerWithModel(trimmedAnswer);
    }

    if (!mounted) return;

    // 4. معالجة نتيجة التصنيف
    if (classifiedAnswer == null || !validKeywords.contains(classifiedAnswer)) {
      _showUiMessage("لم يتم تحليل الإجابة بشكل صحيح. حاول مرة أخرى أو استخدم الأزرار المقترحة.", isError: true);
      // إزالة رسالة المستخدم التي لم يتم معالجتها
      if (_chatMessages.isNotEmpty && _chatMessages.last.isUserMessage && _chatMessages.last.text == trimmedAnswer) {
          _chatMessages.removeLast();
      }
      setState(() { _isLoading = false; }); // إيقاف التحميل
      return;
    }

    // 5. تفعيل التخطي
    if (currentQuestion.dimension == "فهم" && classifiedAnswer == "لا") {
      _skipActive = true;
      _emotionToSkip = currentQuestion.emotion;
    }

    // --- *** تعديل: إضافة الإجابة إلى القائمة بدلاً من إرسالها فورًا *** ---
    _answersToSubmit.add(AnswerModel(
      sessionId: currentQuestion.id,
      answer: classifiedAnswer,
    ));
    print("QID ${currentQuestion.id} ('$classifiedAnswer') added to submit list. Total answers: ${_answersToSubmit.length}");

    // --- *** تعديل: الانتقال للسؤال التالي مباشرة بدون انتظار نتيجة من الخادم *** ---
    // لا يوجد `backendSuccess` هنا لأننا لم نرسل شيئًا بعد
    _moveToNextQuestionOrComplete();
  }

  void _moveToNextQuestionOrComplete() {
    if (_isSessionProcessingComplete) return; // توقف إذا بدأت عملية الإرسال النهائي

    int nextIndex = _currentIndex + 1;

    while (nextIndex < assessmentQuestions.length) {
      final nextQuestion = assessmentQuestions[nextIndex];
      if (_skipActive && nextQuestion.emotion == _emotionToSkip) {
        // --- *** تعديل: إضافة الإجابة "لا" للقائمة للأسئلة المتخطاة *** ---
        _answersToSubmit.add(AnswerModel(
          sessionId: nextQuestion.id,
          answer: "لا", // الإجابة الافتراضية للأسئلة المتخطاة
        ));
        print("Skipped QID ${nextQuestion.id} (Answer: لا) added to submit list. Total answers: ${_answersToSubmit.length}");
        nextIndex++; // الانتقال للسؤال التالي في الحلقة
      } else {
        // هذا السؤال لا يجب تخطيه
        if (nextQuestion.emotion != _emotionToSkip && _skipActive) {
          print("[Skip Logic Deactivated] Next emotion: ${nextQuestion.emotion}, Skipped emotion: $_emotionToSkip");
          _skipActive = false;
          _emotionToSkip = null;
        }
        break; // الخروج من الحلقة لعرض هذا السؤال
      }
    }

    if (nextIndex >= assessmentQuestions.length) {
      // تمت معالجة كل الأسئلة، حان وقت الإرسال النهائي
      _finalizeAndSubmitAllAnswers();
    } else {
      // هناك سؤال تالٍ يجب عرضه
      if (mounted) {
        setState(() { _currentIndex = nextIndex; });
        _askQuestionAtIndex(_currentIndex); // سيقوم هذا بتعيين _isLoading = false
      }
    }
  }

  // --- *** تعديل: دالة جديدة للإرسال النهائي والانتقال *** ---
  Future<void> _finalizeAndSubmitAllAnswers() async {
    // منع الاستدعاء المتعدد إذا كانت العملية جارية بالفعل
    if (_isSessionProcessingComplete && _isLoading) return;
    if (!mounted) return;

    setState(() {
      _isSessionProcessingComplete = true; // علامة أننا في مرحلة الإرسال النهائي
      _isLoading = true;                // تفعيل حالة التحميل للإرسال النهائي
    });
    _showUiMessage("اكتملت الأسئلة. جاري إرسال جميع الإجابات، يرجى الانتظار...", isStickyLoading: true);

    print("Finalizing assessment. Total answers to submit: ${_answersToSubmit.length}");
    // يمكنك طباعة قائمة الإجابات هنا للتأكد منها إذا أردت
    // _answersToSubmit.forEach((a) => print(" - QID: ${a.sessionId}, Ans: ${a.answer}"));

    // تأخير بسيط لإظهار رسالة "جاري الإرسال" للمستخدم (اختياري)
    // await Future.delayed(const Duration(seconds: 1));

    bool allSubmittedSuccessfully = await ApiService.submitAllAssessmentAnswers(
      _answersToSubmit, // القائمة المجمعة
      widget.jwtToken,
    );

    if (!mounted) return;

    if (allSubmittedSuccessfully) {
      _showUiMessage("تم إرسال جميع الإجابات بنجاح! شكراً لكِ.", isError: false);
      // تأخير بسيط لعرض رسالة النجاح قبل الانتقال
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()), // تأكد من استيراد HomeScreen
              (route) => false);
        }
      });
    } else {
      _showUiMessage("عذراً، حدث خطأ أثناء إرسال الإجابات. يرجى المحاولة مرة أخرى لاحقاً أو التحقق من اتصالك بالإنترنت.", isError: true);
      // هنا يمكنك إضافة خيار للمستخدم لإعادة محاولة الإرسال إذا أردت
      setState(() { _isLoading = false; }); // إيقاف التحميل للسماح بإعادة المحاولة المحتملة
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // خلفية فاتحة
      appBar: AppBar(
        title: const Text('لنتحدث عن طفلك'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C73D9), // لون أساسي
        elevation: 1, centerTitle: true, automaticallyImplyLeading: false, // لا يوجد زر رجوع
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10.0),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                final isUser = message.isUserMessage;
                // تحديد ألوان وخلفيات الرسائل
                final color = isUser ? const Color(0xFF2C73D9) : Colors.white; // لون رسالة المستخدم مقابل البوت
                final textColor = isUser ? Colors.white : Colors.black87;
                final borderRadius = isUser
                    ? const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20), topRight: Radius.circular(5))
                    : const BorderRadius.only(topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20), topLeft: Radius.circular(5));
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser) // أيقونة للبوت
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, bottom: 5),
                          child: CircleAvatar(backgroundColor: const Color(0xFF2C73D9), radius: 15, child: Icon(Icons.psychology_alt_outlined, color: Colors.white, size: 18)), // أيقونة معدلة
                        ),
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78), // عرض أقصى للرسالة
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 18.0),
                          decoration: BoxDecoration(color: color, borderRadius: borderRadius, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 1))]),
                          child: Text(message.text, textDirection: TextDirection.rtl, style: TextStyle(color: textColor, fontSize: 15.5, height: 1.45)), // حجم خط أكبر قليلاً
                        ),
                      ),
                      if (isUser) const SizedBox(width: 5), // مسافة أقل لرسالة المستخدم
                    ],
                  ),
                );
              },
            ),
          ),

          // --- عرض رسالة للمستخدم (خطأ، تحميل، إلخ) ---
          // يتم عرضها إذا كانت _uiMessage موجودة وليست رسالة مستخدم تمت إضافتها بالفعل للشات
          if (_uiMessage != null && (_isLoading || !isUserMessageFromChat(_uiMessage!)))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  _uiMessage!,
                  style: TextStyle(color: _uiMessage!.contains("خطأ") || _uiMessage!.contains("عذراً") ? Colors.redAccent : Colors.blueGrey.shade700, fontWeight: FontWeight.w600, fontSize: 13.5),
                  textAlign: TextAlign.center,
                ),
              ),

          // --- منطقة الإدخال ---
          // يتم عرضها فقط إذا لم تكتمل معالجة الجلسة (أي قبل محاولة الإرسال النهائي)
          if (!_isSessionProcessingComplete)
            Container(
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 0, blurRadius: 5, offset: const Offset(0, -1))]), // ظل أخف
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 10), // مسافة إضافية في الأسفل
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أزرار الاقتراحات
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0, left: 4, right: 4), // تعديل المسافات
                      child: Row(children: [
                        Expanded(child: _buildSuggestionButton("نعم")), const SizedBox(width: 8),
                        Expanded(child: _buildSuggestionButton("لا")), const SizedBox(width: 8),
                        Expanded(child: _buildSuggestionButton("بمساعدة")),
                      ]),
                    ),
                    // حقل الإدخال وزر الإرسال
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // محاذاة رأسية للمركز
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerController, focusNode: _answerFocusNode,
                            textDirection: TextDirection.rtl, textAlign: TextAlign.right,
                            keyboardType: TextInputType.multiline, minLines: 1, maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: _isLoading ? "لحظات..." : "...أو اكتب إجابتك هنا",
                              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14.5), // حجم خط أكبر قليلاً للتلميح
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5)), // إطار عند التركيز
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), // تعديل الحشو الداخلي
                              filled: true, fillColor: Colors.grey.shade50, // لون خلفية خفيف للحقل
                            ),
                            enabled: !_isLoading, // تعطيل الحقل أثناء التحميل
                            onSubmitted: _isLoading ? null : (value) => _handleAnswer(value.trim()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          heroTag: "sendButton", // heroTag لتجنب التعارض إذا كان هناك FAB آخر
                          mini: false, // حجم قياسي للزر
                          onPressed: (_isLoading || _isSessionProcessingComplete) ? null : () => _handleAnswer(_answerController.text.trim()), // تعطيل أثناء التحميل أو الإرسال النهائي
                          child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.send_rounded),
                          backgroundColor: (_isLoading || _isSessionProcessingComplete) ? Colors.grey.shade400 : const Color(0xFF2C73D9), // لون مختلف عند التعطيل
                          elevation: 2,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionButton(String text) {
    return ElevatedButton( // تغيير إلى ElevatedButton لتحكم أفضل في المظهر
      onPressed: (_isLoading || _isSessionProcessingComplete) ? null : () => _handleAnswer(text), // تعطيل أثناء التحميل أو الإرسال النهائي
      child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)), // خط أعرض
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // لون خلفية الزر
          foregroundColor: Theme.of(context).primaryColor, // لون النص
          side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.7), width: 1.2), // إطار الزر
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // حشو الزر
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), // شكل الزر
    );
  }
}