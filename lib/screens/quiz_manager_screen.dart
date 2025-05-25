import 'package:flutter/material.dart';
import 'package:myfinalpro/test/models/quiz_model.dart';
import 'package:myfinalpro/services/Api_services.dart';
import 'package:myfinalpro/test/quiz_type1_screen.dart';
import 'package:myfinalpro/test/QuizType2Screen.dart';
import 'package:myfinalpro/test/end_test_screen.dart';
import 'package:myfinalpro/screens/common/loading_indicator.dart';
import 'package:myfinalpro/screens/common/error_display.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myfinalpro/login/login_view.dart';


class QuizManagerScreen extends StatefulWidget {
  final List<int> completedSessionDetailIds;

  const QuizManagerScreen({
    super.key,
    required this.completedSessionDetailIds,
  });

  @override
  State<QuizManagerScreen> createState() => _QuizManagerScreenState();
}

class _QuizManagerScreenState extends State<QuizManagerScreen> {
  Future<QuizSession?>? _quizSessionFuture;
  QuizSession? _currentQuizSession;
  int _currentQuizStep = 0;
  String? _jwtToken;
  bool _isCompletingStep = false;
  int _wrongAnswersCount = 0;
  static const int maxWrongAnswers = 1;
  List<int> _attemptedTestDetailIds = [];

  @override
  void initState() {
    super.initState();
    _attemptedTestDetailIds = [];
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    setStateIfMounted(() {
      _quizSessionFuture = null;
      _currentQuizSession = null;
      _currentQuizStep = 0;
      _isCompletingStep = false;
      _wrongAnswersCount = 0;
      _attemptedTestDetailIds = [];
    });
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('auth_token');
    if (!mounted) return;
    if (_jwtToken == null || _jwtToken!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginView()));
      });
      setStateIfMounted(
          () => _quizSessionFuture = Future.error("Token required"));
    } else {
      _loadQuizData();
    }
  }

  void _loadQuizData() {
    if (_jwtToken == null) return;
    setStateIfMounted(() {
      _quizSessionFuture = ApiService.fetchNextTestDetail(_jwtToken!);
    });
  }

  void _handleIncorrectAnswerLocally() {
    setStateIfMounted(() => _wrongAnswersCount++);
    debugPrint(
        "QuizManager: Incorrect answer processed. Total wrong answers: $_wrongAnswersCount");
  }

  Future<void> _completeQuizStep(QuizDetail detailToComplete,
      {bool wasCorrect = true}) async {
    if (_jwtToken == null || _isCompletingStep || _currentQuizSession == null) return;
    setStateIfMounted(() => _isCompletingStep = true);

    if (!wasCorrect) {
      _handleIncorrectAnswerLocally();
    }

    int idToMark = detailToComplete.id;
    if (!_attemptedTestDetailIds.contains(idToMark) && idToMark > 0) {
      _attemptedTestDetailIds.add(idToMark);
      debugPrint(
          "QuizManager: Added TEST detail ID $idToMark to _attemptedTestDetailIds. Current list: $_attemptedTestDetailIds");
    }

    if (_wrongAnswersCount > maxWrongAnswers) {
      debugPrint(
          "QuizManager: Test failed due to too many wrong answers ($_wrongAnswersCount).");
      await _markRelevantDetailsAsNotCompleteOnFailure();
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => EndTestScreen(testPassed: false)));
      }
      setStateIfMounted(() => _isCompletingStep = false);
      return;
    }

    debugPrint(
        "QuizManager: Completing Step ${_currentQuizStep + 1}. Sending TEST Item ID: $idToMark. Correct: $wasCorrect");
    if (idToMark <= 0) {
      debugPrint(
          "QuizManager Error: Attempting to complete step with invalid TEST ID ($idToMark).");
      setStateIfMounted(() => _isCompletingStep = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ في بيانات الخطوة الحالية.')));
      return;
    }

    bool success =
        await ApiService.markTestDetailComplete(_jwtToken!, idToMark);
    if (!mounted) {
      _isCompletingStep = false;
      return;
    }

    if (success) {
      debugPrint(
          "QuizManager: API complete for TEST detail ID $idToMark successful.");
      // Determine if there's a next step based on session type and current step
      bool hasNextStep = false;
      final bool isSpecialSession = _currentQuizSession!.sessionId > 28;
      if (isSpecialSession) {
        // Special sessions have exactly 2 steps (details[0] and details[1])
        hasNextStep = _currentQuizStep < 1; // Steps 0 and 1
      } else {
        // Other sessions use details[0] and newDetail
        hasNextStep = _currentQuizStep == 0; // Only one more step (newDetail)
      }

      if (hasNextStep) {
        setStateIfMounted(() {
          _currentQuizStep++;
          _isCompletingStep = false;
        });
      } else {
        debugPrint("QuizManager: Quiz finished successfully.");
        debugPrint(
            "QuizManager: Original Session Detail IDs passed: ${widget.completedSessionDetailIds}");
        debugPrint(
            "QuizManager: Attempted Test Detail IDs: $_attemptedTestDetailIds");
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => EndTestScreen(testPassed: true)));
      }
    } else {
      debugPrint(
          "QuizManager: API complete failed for TEST detail ID $idToMark.");
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('خطأ في حفظ التقدم.')));
      setStateIfMounted(() => _isCompletingStep = false);
    }
  }

  Future<void> _markRelevantDetailsAsNotCompleteOnFailure() async {
    if (_jwtToken == null) {
      debugPrint(
          "QuizManager: Cannot mark details as not complete. Token missing.");
      return;
    }

    bool allSessionMarkingSucceeded = true;
    bool allTestMarkingSucceeded = true;

    if (widget.completedSessionDetailIds.isNotEmpty) {
      debugPrint(
          "QuizManager: Marking ORIGINAL session details as NOT complete. IDs: ${widget.completedSessionDetailIds}");
      for (int sessionDetailId in widget.completedSessionDetailIds) {
        if (sessionDetailId <= 0) continue;
        try {
          bool success = await ApiService.markSessionDetailAsNotComplete(
              _jwtToken!, sessionDetailId);
          if (!success) allSessionMarkingSucceeded = false;
        } catch (e) {
          debugPrint(
              "QuizManager: Error marking original session detail ID $sessionDetailId as not complete: $e");
          allSessionMarkingSucceeded = false;
        }
      }
    }

    if (_attemptedTestDetailIds.isNotEmpty) {
      debugPrint(
          "QuizManager: Marking ATTEMPTED test details as NOT complete. IDs: $_attemptedTestDetailIds");
      for (int testDetailId in _attemptedTestDetailIds) {
        if (testDetailId <= 0) continue;
        try {
          bool success = await ApiService.markTestDetailAsNotComplete(
              _jwtToken!, testDetailId);
          if (!success) allTestMarkingSucceeded = false;
        } catch (e) {
          debugPrint(
              "QuizManager: Error marking attempted test detail ID $testDetailId as not complete: $e");
          allTestMarkingSucceeded = false;
        }
      }
    }

    if (allSessionMarkingSucceeded && allTestMarkingSucceeded) {
      debugPrint(
          "QuizManager: All relevant details (session & test) successfully processed for NotComplete status.");
    } else {
      debugPrint(
          "QuizManager: One or more details failed to be processed for NotComplete status.");
    }
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuizSession?>(
      future: _quizSessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator(message: 'جاري تحميل الاختبار...');
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          String errorMsg = 'فشل تحميل بيانات الاختبار.';
          if (snapshot.error != null) {
            if (snapshot.error.toString().contains("Token required"))
              errorMsg = "خطأ مصادقة.";
            else if (snapshot.error.toString().contains("Unauthorized")) {
              errorMsg = "انتهت صلاحية الدخول.";
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted)
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginView()));
              });
            } else
              errorMsg += '\n(${snapshot.error})';
          }
          return ErrorDisplay(
              message: errorMsg, onRetry: _loadTokenAndFetchData);
        }

        final quizSession = snapshot.data!;
        _currentQuizSession = quizSession;

        // Check if this is a special session (ID > 28)
        final bool isSpecialSession = quizSession.sessionId > 28;

        if (isSpecialSession) {
          // Handle special session with QuizType1Screen for both details
          if (quizSession.details.length < 2) {
            return ErrorDisplay(
                message: 'خطأ: بيانات الاختبار الخاص غير مكتملة.',
                onRetry: _loadQuizData);
          }
          if (_currentQuizStep == 0) {
            final step1Detail = quizSession.details[0];
            return QuizType1Screen(
              key: const ValueKey('quiz_step_0_special'),
              detail: step1Detail,
              onAnswerSelected: (bool isCorrect) =>
                  _completeQuizStep(step1Detail, wasCorrect: isCorrect),
              isCompleting: _isCompletingStep,
            );
          } else if (_currentQuizStep == 1) {
            final step2Detail = quizSession.details[1];
            return QuizType1Screen(
              key: const ValueKey('quiz_step_1_special'),
              detail: step2Detail,
              onAnswerSelected: (bool isCorrect) =>
                  _completeQuizStep(step2Detail, wasCorrect: isCorrect),
              isCompleting: _isCompletingStep,
            );
          } else {
            // Should not happen if test has only 2 steps
            return ErrorDisplay(
                message: "خطأ غير متوقع في خطوات الاختبار الخاص.",
                onRetry: _loadQuizData);
          }
        } else {
          // Keep existing logic for other sessions
          if (_currentQuizStep == 0) {
            if (quizSession.details.isEmpty)
              return ErrorDisplay(
                  message: "لا توجد بيانات للخطوة الأولى.",
                  onRetry: _loadQuizData);
            final step1Detail = quizSession.details[0];
            return QuizType1Screen(
              key: const ValueKey('quiz_step_0'),
              detail: step1Detail,
              onAnswerSelected: (bool isCorrect) =>
                  _completeQuizStep(step1Detail, wasCorrect: isCorrect),
              isCompleting: _isCompletingStep,
            );
          } else {
            if (quizSession.details.length < 2 ||
                quizSession.newDetail == null) {
              return ErrorDisplay(
                  message: 'خطأ: بيانات الاختبار غير كافية للخطوة الثانية.',
                  onRetry: _loadQuizData);
            }
            final option1 = quizSession.details[1];
            final option2 = quizSession.newDetail;
            return QuizType2Screen(
              key: const ValueKey('quiz_step_1'),
              rootQuestion: quizSession.question,
              option1Detail: option1,
              option2Detail: option2,
              rootAnswer: quizSession.answer,
              onAnswerSelected: (QuizDetail chosenDetail, bool isCorrect) =>
                  _completeQuizStep(chosenDetail, wasCorrect: isCorrect),
              isCompleting: _isCompletingStep,
            );
          }
        }
      },
    );
  }
}
