class QuizManagerScreen extends StatefulWidget {
  final int sessionId;
  final int childSessionId;

  const QuizManagerScreen({
    Key? key,
    required this.sessionId,
    required this.childSessionId,
  }) : super(key: key);

  @override
  _QuizManagerScreenState createState() => _QuizManagerScreenState();
}

class _QuizManagerScreenState extends State<QuizManagerScreen> {
  int _currentQuizStep = 0;
  int _wrongAnswers = 0;
  late Future<QuizSession> _quizSessionFuture;

  @override
  void initState() {
    super.initState();
    _quizSessionFuture = ApiService.fetchNextTestDetail(
      widget.sessionId,
      widget.childSessionId,
    );
  }

  void _handleAnswer(bool isCorrect) {
    if (!isCorrect) {
      setState(() {
        _wrongAnswers++;
      });
    }

    // For sessions with sessionId > 28, complete after first step
    if (widget.sessionId > 28) {
      _navigateToEndTest();
      return;
    }

    // Original logic for other sessions
    if (_wrongAnswers >= 3) {
      _navigateToEndTest();
    } else {
      setState(() {
        _currentQuizStep++;
      });
    }
  }

  void _navigateToEndTest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EndTestScreen(
          sessionId: widget.sessionId,
          childSessionId: widget.childSessionId,
          wrongAnswers: _wrongAnswers,
        ),
      ),
    );
  }

  Widget _buildQuizContent(QuizSession quizSession) {
    // Special handling for sessions with sessionId > 28
    if (widget.sessionId > 28) {
      if (_currentQuizStep == 0) {
        // First screen: Use details[0] with fixed question
        final detail = quizSession.details[0].copyWith(
          question: "هل كان هذا التصرف صح ام خطأ",
          answer: "صح",
          rootAnswer: "صح - خطأ",
        );
        return QuizType1Screen(
          detail: detail,
          onAnswerSelected: _handleAnswer,
        );
      } else {
        // Second screen: Use details[1] with fixed question
        final detail = quizSession.details[1].copyWith(
          question: "هل كان هذا التصرف صح ام خطأ",
          answer: "صح",
          rootAnswer: "صح - خطأ",
        );
        return QuizType1Screen(
          detail: detail,
          onAnswerSelected: _handleAnswer,
        );
      }
    }

    // Original logic for other sessions
    if (_currentQuizStep == 0) {
      return QuizType1Screen(
        detail: quizSession.details[0],
        onAnswerSelected: _handleAnswer,
      );
    } else {
      return QuizType2Screen(
        rootQuestion: quizSession.question,
        option1Detail: quizSession.details[1],
        option2Detail: quizSession.newDetail!,
        rootAnswer: quizSession.answer,
        onAnswerSelected: _handleAnswer,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<QuizSession>(
        future: _quizSessionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'خطأ في تحميل البيانات: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            return _buildQuizContent(snapshot.data!);
          } else {
            return Center(child: Text('لا توجد بيانات'));
          }
        },
      ),
    );
  }
}