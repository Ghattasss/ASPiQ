import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:confetti/confetti.dart';

import 'test_group_model.dart';
import 'package:myfinalpro/services/Api_services.dart'; // Ensure this path is correct
import 'package:myfinalpro/screens/common/loading_indicator.dart'; // Ensure this path is correct
import 'package:myfinalpro/screens/home_screen.dart'; // Ensure this path is correct
import 'group_test_question_display_screen.dart';

import 'package:myfinalpro/models/notification_item.dart'
    as notif_model; // Ensure this path is correct
import 'package:myfinalpro/services/notification_manager.dart'; // Ensure this path is correct
import 'package:myfinalpro/widgets/Notifictionicon.dart'; // Ensure this path is correct

// GeneratedQuestion class
class GeneratedQuestion {
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? imagePath1;
  final String? textContent1;
  final String? imagePath2;
  final String? textContent2;
  final bool isTwoElements;
  final String? mainItemName;
  final String? secondItemName;
  final int originalDetailId;
  final String sectionTitle;
  final bool isImageOptions;
  final List<String?> optionImagePaths;
  final int parentSessionId; // <-- *** NEW FIELD ***

  GeneratedQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.originalDetailId,
    required this.sectionTitle,
    required this.parentSessionId, // <-- *** ADD TO CONSTRUCTOR ***
    this.imagePath1,
    this.textContent1,
    this.imagePath2,
    this.textContent2,
    this.isTwoElements = false,
    this.mainItemName,
    this.secondItemName,
    this.isImageOptions = false,
    this.optionImagePaths = const [],
  });
}

class GroupTestManagerScreen extends StatefulWidget {
  final TestGroupResponse testGroupData;
  final String jwtToken;
  final GlobalKey<NotificationIconState>? notificationIconKey;

  const GroupTestManagerScreen({
    super.key,
    required this.testGroupData,
    required this.jwtToken,
    this.notificationIconKey,
  });

  @override
  State<GroupTestManagerScreen> createState() => _GroupTestManagerScreenState();
}

class _GroupTestManagerScreenState extends State<GroupTestManagerScreen> {
  int _currentGlobalQuestionIndex = 0;
  List<GeneratedQuestion> _allGeneratedQuestions = [];
  bool _isLoadingScreen = true;
  bool _isProcessingAnswer = false;
  bool _isCompletingGroup = false;
  int _totalCorrectAnswers = 0;
  List<String> _objectImagePaths = [];
  final Random _random = Random();
  int _buildCount = 0; // For debugging build cycles
  late ConfettiController _confettiController;

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    debugPrint(
        "GroupTestManager: initState - Screen Initializing. Total Sessions: ${widget.testGroupData.sessions.length}");
    _initializeScreenData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    debugPrint(
        "GroupTestManager: dispose. GroupID: ${widget.testGroupData.groupId}");
    super.dispose();
  }

  Future<void> _initializeScreenData() async {
    setStateIfMounted(() => _isLoadingScreen = true);
    await _loadObjectImagePathsFromAssets();
    _generateAllQuestionsAndRefreshUI();
    // No need to set _isLoadingScreen = false here, _generateAllQuestionsAndRefreshUI will do it
  }

  Future<void> _loadObjectImagePathsFromAssets() async {
    try {
      const String assetPathPrefix = 'assets/objects/';
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      _objectImagePaths = manifestMap.keys
          .where((String key) =>
              key.startsWith(assetPathPrefix) &&
              key !=
                  assetPathPrefix && // Exclude the directory itself if listed
              (key.endsWith('.png') ||
                  key.endsWith('.jpg') ||
                  key.endsWith('.jpeg') ||
                  key.endsWith('.gif') ||
                  key.endsWith('.webp')))
          .toList();
      debugPrint(
          "GroupTestManager: Loaded ${_objectImagePaths.length} random images from '$assetPathPrefix'");
      if (_objectImagePaths.isEmpty) {
        debugPrint(
            "GroupTestManager: Warning - No distractor images found in '$assetPathPrefix'. Image-based distractor questions might not work as expected.");
      }
    } catch (e) {
      debugPrint(
          "GroupTestManager: Error loading object image paths from assets: $e");
      _objectImagePaths = []; // Ensure it's empty on error
    }
  }

  String? _getRandomObjectImagePath() {
    if (_objectImagePaths.isEmpty) return null;
    String? randomPath;
    int attempts = 0;
    const maxAttempts =
        5; // Prevent infinite loop if all images are the same as current

    // Get current question's image path to avoid selecting the same one as distractor immediately
    String? currentComparisonPath;
    if (_currentGlobalQuestionIndex < _allGeneratedQuestions.length) {
      final currentQuestion =
          _allGeneratedQuestions[_currentGlobalQuestionIndex];
      // Prefer imagePath1, but consider optionImagePaths if relevant for the current question context
      currentComparisonPath = currentQuestion.imagePath1 ??
          (currentQuestion.optionImagePaths.isNotEmpty
              ? currentQuestion.optionImagePaths
                  .firstWhere((p) => p != null, orElse: () => null)
              : null);
    }

    do {
      randomPath = _objectImagePaths[_random.nextInt(_objectImagePaths.length)];
      attempts++;
    } while (randomPath == currentComparisonPath &&
        _objectImagePaths.length >
            1 && // Only try to avoid duplicates if there's more than one option
        attempts < maxAttempts);
    return randomPath;
  }

  void _generateAllQuestionsAndRefreshUI() {
    if (!mounted) return;
    // Ensure isLoadingScreen is true at the start of generation if it's the initial load
    if (!_isLoadingScreen &&
        _currentGlobalQuestionIndex == 0 &&
        _allGeneratedQuestions.isEmpty) {
      setStateIfMounted(() => _isLoadingScreen = true);
    }

    List<GeneratedQuestion> allQuestionsCollector = [];
    final String mainGroupName = widget.testGroupData.groupName;
    debugPrint(
        "GroupTestManager: Generating Questions for group: '$mainGroupName'. Number of Sessions: ${widget.testGroupData.sessions.length}");

    for (int sessionIdx = 0;
        sessionIdx < widget.testGroupData.sessions.length;
        sessionIdx++) {
      final currentSession = widget.testGroupData.sessions[sessionIdx];
      final String currentSessionTitle = currentSession.title.isNotEmpty
          ? currentSession.title
          : mainGroupName;
      final int currentParentSessionId =
          currentSession.sessionId; // <-- *** CAPTURE SESSION ID ***

      debugPrint(
          "  Processing Session ${sessionIdx + 1}: '$currentSessionTitle' (ID: ${currentSession.sessionId}, ParentSessionID for Qs: $currentParentSessionId) with ${currentSession.details.length} details, newDetail ID: ${currentSession.newDetail.detailId}");

      // Check if this is a special session (ID > 28)
      final bool isSpecialSession = currentSession.sessionId > 28;

      if (isSpecialSession) {
        // Handle special session format
        for (final detail in currentSession.details) {
          allQuestionsCollector.add(GeneratedQuestion(
            originalDetailId: detail.detailId,
            sectionTitle: currentSessionTitle,
            questionText:"هل هذا التصرف صح ام خطأ؟",
            options: ["صح", "خطأ"],
            correctAnswer: detail.rightAnswer,
            imagePath1: detail.localAssetPath,
            textContent1: detail.textContent,
            mainItemName: mainGroupName,
            isImageOptions: false,
            optionImagePaths: [],
            parentSessionId: currentSession.sessionId,
          ));
          debugPrint(
              "      Special Session Q: '${allQuestionsCollector.last.questionText}' (original detailId: ${detail.detailId})");
        }
      } else if (sessionIdx == 0 &&
          currentSession.title.contains("فهم") &&
          currentSession.sessionId <= 28) {
        final detailsForFahm = currentSession.details;
        final newDetailForFahm = currentSession.newDetail;

        // Fahm Question 1 (Text options)
        if (detailsForFahm.isNotEmpty) {
          final detail0 = detailsForFahm[0];
          allQuestionsCollector.add(GeneratedQuestion(
            originalDetailId: detail0.detailId,
            sectionTitle: currentSessionTitle,
            parentSessionId:
                currentParentSessionId, // <-- *** USE SESSION ID ***
            questionText: detail0.questions ?? "ما الشعور؟",
            options: detail0.answerOptions.isNotEmpty
                ? detail0.answerOptions
                : ["خيار1", "خيار2"],
            correctAnswer: detail0.rightAnswer.isNotEmpty
                ? detail0.rightAnswer
                : (detail0.answerOptions.isNotEmpty
                    ? detail0.answerOptions[0]
                    : "خيار1"),
            imagePath1: detail0.localAssetPath,
            textContent1: detail0.textContent,
            mainItemName: mainGroupName, // Group name can be part of context
            isImageOptions: false,
          ));
          debugPrint(
              "      Fahm Q1 Added: '${allQuestionsCollector.last.questionText}' (DetailID: ${detail0.detailId}, ParentSessID: $currentParentSessionId)");
        } else {
          debugPrint(
              "      Fahm Q1: SKIPPED - No details[0] in 'فهم' session.");
        }

        // Fahm Question 2 (Image options: detail[1] vs newDetail)
        if (detailsForFahm.length >= 2 &&
            newDetailForFahm.detailId != 0 &&
            newDetailForFahm.localAssetPath != null) {
          final detail1 = detailsForFahm[1];
          if (detail1.localAssetPath != null) {
            List<String?> imageOptionsPaths = [
              detail1.localAssetPath,
              newDetailForFahm.localAssetPath
            ];
            // Ensure rightAnswer for detail1 is distinct from newDetailForFahm if possible, or use fallback
            String correctAnswerValue = detail1.rightAnswer.isNotEmpty
                ? detail1.rightAnswer
                : "correct_img_${detail1.detailId}";
            // For options, we use the textual representation of the correct answer (or a placeholder if empty)
            // and a different textual representation for the distractor.
            // The actual comparison in _handleAnswer for image options will be based on these textual values.
            String distractorValue = (newDetailForFahm.rightAnswer.isNotEmpty &&
                    newDetailForFahm.rightAnswer != correctAnswerValue)
                ? newDetailForFahm.rightAnswer
                : "distractor_img_${newDetailForFahm.detailId}";

            List<String> optionValues = [correctAnswerValue, distractorValue];
            // Randomize options and paths together if needed, or keep order
            // For simplicity, let's assume the first option is correct for now, or randomize:
            // final r = Random(); if (r.nextBool()) { imageOptionsPaths = imageOptionsPaths.reversed.toList(); optionValues = optionValues.reversed.toList(); }

            allQuestionsCollector.add(GeneratedQuestion(
              originalDetailId: detail1
                  .detailId, // Or newDetailId if question is about newDetail
              sectionTitle: currentSessionTitle,
              parentSessionId:
                  currentParentSessionId, // <-- *** USE SESSION ID ***
              questionText:
                  "من يكون ${widget.testGroupData.groupName}؟", // Example question
              options: optionValues,
              correctAnswer: correctAnswerValue,
              isImageOptions: true,
              optionImagePaths: imageOptionsPaths,
              mainItemName: mainGroupName,
            ));
            debugPrint(
                "      Fahm Q2 (Image Options) Added: '${allQuestionsCollector.last.questionText}' (DetailID: ${detail1.detailId}, NewDetailID: ${newDetailForFahm.detailId}, ParentSessID: $currentParentSessionId)");
          } else {
            debugPrint(
                "      Fahm Q2: SKIPPED - detail[1].localAssetPath is null.");
          }
        } else {
          debugPrint(
              "      Fahm Q2: SKIPPED - Data insufficient. Details count: ${detailsForFahm.length}, newDetail ID: ${newDetailForFahm.detailId}, newDetail path: ${newDetailForFahm.localAssetPath}");
        }

        // Fahm Question 3 (Image options: detail[2] vs random object)
        if (detailsForFahm.length >= 3) {
          final detail2 = detailsForFahm[2];
          if (detail2.localAssetPath != null) {
            final randomImagePath = _getRandomObjectImagePath();
            if (randomImagePath != null) {
              List<String?> imageOptionsPaths = [
                detail2.localAssetPath,
                randomImagePath
              ];
              String correctAnswerValue = detail2.rightAnswer.isNotEmpty
                  ? detail2.rightAnswer
                  : "correct_img_${detail2.detailId}";
              String distractorValue =
                  "random_img_distractor"; // Placeholder for the random image
              List<String> optionValues = [correctAnswerValue, distractorValue];
              // Randomize if needed

              allQuestionsCollector.add(GeneratedQuestion(
                originalDetailId: detail2.detailId,
                sectionTitle: currentSessionTitle,
                parentSessionId:
                    currentParentSessionId, // <-- *** USE SESSION ID ***
                questionText:
                    "من يكون ${widget.testGroupData.groupName}؟", // Example question
                options: optionValues,
                correctAnswer: correctAnswerValue,
                isImageOptions: true,
                optionImagePaths: imageOptionsPaths,
                mainItemName: mainGroupName,
              ));
              debugPrint(
                  "      Fahm Q3 (Image Options) Added: '${allQuestionsCollector.last.questionText}' (DetailID: ${detail2.detailId}, ParentSessID: $currentParentSessionId)");
            } else {
              debugPrint(
                  "      Fahm Q3: SKIPPED - No random distractor image available.");
            }
          } else {
            debugPrint(
                "      Fahm Q3: SKIPPED - detail[2].localAssetPath is null.");
          }
        } else {
          debugPrint(
              "      Fahm Q3: SKIPPED - Data insufficient. Details count: ${detailsForFahm.length}");
        }
      } else {
        // For other sessions (non-"فهم" or subsequent sessions)
        int questionsAddedFromThisSession = 0;
        for (int detailIndex = 0;
            detailIndex < currentSession.details.length &&
                questionsAddedFromThisSession < 3;
            detailIndex++) {
          final detail = currentSession.details[detailIndex];
          allQuestionsCollector.add(GeneratedQuestion(
            originalDetailId: detail.detailId,
            sectionTitle: currentSessionTitle,
            parentSessionId:
                currentParentSessionId, // <-- *** USE SESSION ID ***
            questionText: detail.questions ?? "بماذا يشعر؟", // Default question
            options: detail.answerOptions.isNotEmpty
                ? detail.answerOptions
                : ["خيار1", "خيار2"],
            correctAnswer: detail.rightAnswer.isNotEmpty
                ? detail.rightAnswer
                : (detail.answerOptions.isNotEmpty
                    ? detail.answerOptions[0]
                    : "خيار1"),
            imagePath1: detail.localAssetPath,
            textContent1: detail.textContent,
            mainItemName: mainGroupName, // Group name can be part of context
            isImageOptions: false, // Assuming these are standard questions
          ));
          questionsAddedFromThisSession++;
          debugPrint(
              "      Session '$currentSessionTitle' Q$questionsAddedFromThisSession Added: '${allQuestionsCollector.last.questionText}' (DetailID: ${detail.detailId}, ParentSessID: $currentParentSessionId)");
        }
        if (questionsAddedFromThisSession == 0 &&
            currentSession.details.isEmpty) {
          debugPrint(
              "      No details to generate questions for session '$currentSessionTitle'.");
        }
      }
    }

    setStateIfMounted(() {
      _allGeneratedQuestions = allQuestionsCollector;
      _currentGlobalQuestionIndex = 0; // Reset to first question
      _isLoadingScreen = false;
      debugPrint(
          "GroupTestManager: setState after generating all questions. Total Questions: ${_allGeneratedQuestions.length}. isLoadingScreen: $_isLoadingScreen");
      if (_allGeneratedQuestions.isEmpty && mounted && !_isCompletingGroup) {
        // If no questions were generated at all, call _completeTestGroup with an error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isCompletingGroup) {
            // Double check mounted and not already completing
            _completeTestGroup(
                showError: true,
                errorMessage: "لم يتم العثور على أسئلة صالحة للاختبار.");
          }
        });
      }
    });
  }
 
  Future<void> _showInternalSuccessDialog() async {
    if (!mounted) return;
    _confettiController.play();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Stack(
            alignment: Alignment.topCenter,
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 20,
                gravity: 0.1,
                emissionFrequency: 0.03,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
              ),
              const Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text('🎉 أحسنت!',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Color(0xff2C73D9),
                          fontWeight: FontWeight.bold,
                          fontSize: 22)))
            ],
          ),
          content: const Text(
            'إجابة صحيحة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2C73D9),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                textStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              child: const Text('التالي'),
              onPressed: () {
                if (_confettiController.state ==
                    ConfettiControllerState.playing) {
                  _confettiController.stop();
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleAnswer(bool isCorrect) async {
    if (_isLoadingScreen || _isProcessingAnswer || _isCompletingGroup) return;
    setStateIfMounted(() => _isProcessingAnswer = true);

    final currentQuestionProcessed =
        _allGeneratedQuestions[_currentGlobalQuestionIndex];
    final int originalQuestionDetailId =
        currentQuestionProcessed.originalDetailId;
    final int parentSessionIdForComment = currentQuestionProcessed
        .parentSessionId; // <-- *** GET PARENT SESSION ID ***

    debugPrint(
        "GroupTestManager: _handleAnswer. Correct: $isCorrect. Q_idx: $_currentGlobalQuestionIndex. OriginalDetailID: $originalQuestionDetailId. ParentSessionID for comment: $parentSessionIdForComment. ProcessingAnswer SET TRUE.");

    // Mark test detail as attempted (not complete)
    // This API call uses the detail_ID
    await ApiService.markTestDetailAsNotComplete(
        widget.jwtToken, originalQuestionDetailId);
    debugPrint(
        "GroupTestManager: Called markTestDetailAsNotComplete for DetailID: $originalQuestionDetailId");

    if (isCorrect) {
      _totalCorrectAnswers++;
      debugPrint(
          "GroupTestManager: Correct answer. Total correct: $_totalCorrectAnswers.");
      // Ensure widget is still mounted before showing dialog and proceeding
      if (mounted) {
        _showInternalSuccessDialog().then((_) {
          if (mounted) {
            // Check mounted again after async dialog
            debugPrint(
                "GroupTestManager: Success dialog closed. Advancing to next question.");
            _advanceToNextGlobalQuestion();
            setStateIfMounted(() {
              _isProcessingAnswer = false;
              debugPrint(
                  "GroupTestManager: ProcessingAnswer SET FALSE (after success dialog).");
            });
          }
        }).catchError((error) {
          debugPrint(
              "GroupTestManager: Error or dialog dismissed unexpectedly: $error");
          if (mounted)
            setStateIfMounted(
                () => _isProcessingAnswer = false); // Reset flag on error too
        });
      } else {
        _isProcessingAnswer = false; // Reset flag if unmounted before dialog
      }
    } else {
      // Incorrect answer
      debugPrint(
          "GroupTestManager: Incorrect answer for DetailID: $originalQuestionDetailId. Calling addIncorrectAnswerComment API with SessionID: $parentSessionIdForComment.");

      if (widget.jwtToken.isNotEmpty) {
        // *** USE parentSessionIdForComment FOR THE COMMENT API ***
        bool commentAdded = await ApiService.addIncorrectAnswerComment(
            widget.jwtToken, parentSessionIdForComment);
        if (commentAdded) {
          debugPrint(
              "GroupTestManager: Successfully added comment for incorrect answer on ParentSessionID $parentSessionIdForComment (OriginalDetailID: $originalQuestionDetailId).");
        } else {
          debugPrint(
              "GroupTestManager: Failed to add comment for incorrect answer on ParentSessionID $parentSessionIdForComment (OriginalDetailID: $originalQuestionDetailId).");
        }
      } else {
        debugPrint(
            "GroupTestManager: JWT Token is empty. Cannot add incorrect answer comment.");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("إجابة خاطئة، حاول مرة أخرى!",
              textDirection: TextDirection.rtl),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 1),
        ));
        setStateIfMounted(() {
          _isProcessingAnswer = false;
          debugPrint(
              "GroupTestManager: ProcessingAnswer SET FALSE (after incorrect answer and API call).");
        });
      } else {
        _isProcessingAnswer = false; // Reset flag if unmounted
      }
    }
  }

  void _advanceToNextGlobalQuestion() {
    if (!mounted) return;
    int newGlobalIndex = _currentGlobalQuestionIndex + 1;
    if (newGlobalIndex >= _allGeneratedQuestions.length) {
      debugPrint(
          "GroupTestManager: All questions completed. Calling _completeTestGroup.");
      if (!_isCompletingGroup) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isCompletingGroup) _completeTestGroup();
        });
      }
    } else {
      debugPrint(
          "GroupTestManager: Advanced to next question. New Q_idx: $newGlobalIndex");
      setStateIfMounted(() => _currentGlobalQuestionIndex = newGlobalIndex);
    }
  }

  Future<void> _completeTestGroup(
      {bool showError = false, String? errorMessage}) async {
    if (!mounted || _isCompletingGroup) return;
    setStateIfMounted(() => _isCompletingGroup = true);
    debugPrint(
        "GroupTestManager: _completeTestGroup. GroupID: ${widget.testGroupData.groupId}. Correct: $_totalCorrectAnswers. ShowError: $showError. ErrorMsg: $errorMessage");

    bool successMarkingDone = false;
    if (!showError) {
      // Only attempt to mark group done if it's not an error completion (e.g. no questions)
      successMarkingDone = await ApiService.markTestGroupDone(
          widget.jwtToken, widget.testGroupData.groupId);
    }

    // Notification handling
    await NotificationManager.deactivateNotificationsByType(
        notif_model.NotificationType.threeMonthTestAvailable);
    await NotificationManager.setThreeMonthTestNotificationSent(
        false); // Reset the flag
    debugPrint(
        "GroupTestManagerScreen: 3-Month test notification handled and flag reset.");
    widget.notificationIconKey?.currentState
        ?.refreshNotifications(); // Update notification icon in AppBar

    if (mounted) {
      String dialogTitle = showError
          ? "خطأ بالاختبار"
          : (successMarkingDone ? "اختبار مكتمل" : "خطأ في الحفظ");
      String dialogContent = errorMessage ??
          (showError
              ? "لم يتم تحميل الأسئلة بشكل صحيح."
              : (successMarkingDone
                  ? "أحسنت! لقد أكملت هذا الاختبار بنجاح."
                  : "حدث خطأ أثناء محاولة حفظ نتيجة الاختبار."));

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(dialogTitle, style: const TextStyle(fontFamily: 'Cairo')),
          content:
              Text(dialogContent, style: const TextStyle(fontFamily: 'Cairo')),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2C73D9),
                  foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) =>
                          const HomeScreen()), // Navigate to HomeScreen
                  (Route<dynamic> route) =>
                      false, // Remove all routes below HomeScreen
                );
              },
              child: const Text("العودة للرئيسية",
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    debugPrint(
        "GroupTestManager BUILD #$_buildCount: isLoadingScreen: $_isLoadingScreen, Q_idx: $_currentGlobalQuestionIndex, TotalGenQs: ${_allGeneratedQuestions.length}, Completing: $_isCompletingGroup, ProcessingAns: $_isProcessingAnswer");

    final String appBarDefaultTitle = widget.testGroupData.groupName.isNotEmpty
        ? widget.testGroupData.groupName
        : "اختبار الـ 3 شهور";

    if (_isLoadingScreen) {
      return Scaffold(
        appBar: AppBar(
            title: Text(appBarDefaultTitle,
                style:
                    const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
            backgroundColor: const Color(0xFF2C73D9),
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false),
        body: const LoadingIndicator(
            message: "جاري تجهيز أسئلة اختبار الـ 3 شهور..."),
      );
    }

    if (_isCompletingGroup) {
      // Show loading indicator while completing
      return Scaffold(
          appBar: AppBar(
              title: Text(appBarDefaultTitle,
                  style: const TextStyle(
                      fontFamily: 'Cairo', color: Colors.white)),
              backgroundColor: const Color(0xFF2C73D9),
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false),
          body: const LoadingIndicator(
              message: "جاري إنهاء الاختبار وحفظ النتائج..."));
    }

    // This check should ideally be handled by _generateAllQuestionsAndRefreshUI triggering _completeTestGroup
    // But as a fallback UI:
    if (_allGeneratedQuestions.isEmpty &&
        !_isLoadingScreen &&
        !_isCompletingGroup) {
      // This state should ideally not be reached if _generateAllQuestionsAndRefreshUI works correctly
      // and calls _completeTestGroup on empty questions.
      // If it IS reached, it means something went wrong before _completeTestGroup was called.
      debugPrint(
          "GroupTestManager BUILD: Reached empty questions state unexpectedly. Triggering completeTestGroup.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isCompletingGroup)
          _completeTestGroup(
              showError: true,
              errorMessage: "فشل تحميل أسئلة الاختبار بشكل كامل.");
      });
      return Scaffold(
          // Fallback UI
          appBar: AppBar(
              title: Text(appBarDefaultTitle,
                  style: const TextStyle(
                      fontFamily: 'Cairo', color: Colors.white)),
              backgroundColor: const Color(0xFF2C73D9),
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false),
          body: const LoadingIndicator(
              message: "خطأ في تحميل أسئلة الاختبار..."));
    }

    if (_currentGlobalQuestionIndex >= _allGeneratedQuestions.length &&
        !_isCompletingGroup) {
      // This means all questions are answered, and we are about to complete.
      // _advanceToNextGlobalQuestion should have called _completeTestGroup.
      // This UI is a safety net or for the brief moment before _completeTestGroup's dialog.
      debugPrint(
          "GroupTestManager BUILD: Index out of bounds, should be completing. Triggering completeTestGroup.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isCompletingGroup) _completeTestGroup();
      });
      return Scaffold(
          appBar: AppBar(
              title: Text(appBarDefaultTitle,
                  style: const TextStyle(
                      fontFamily: 'Cairo', color: Colors.white)),
              backgroundColor: const Color(0xFF2C73D9),
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false),
          body: const LoadingIndicator(message: "جاري تجميع النتائج..."));
    }

    // If we reach here, it means we have a valid question to display
    final currentGeneratedQuestion =
        _allGeneratedQuestions[_currentGlobalQuestionIndex];
    final String appBarQuestionTitle =
        "${currentGeneratedQuestion.sectionTitle} (${_currentGlobalQuestionIndex + 1}/${_allGeneratedQuestions.length})";

    return GroupTestQuestionDisplayScreen(
      key: ValueKey(
          'group_q_global_${_currentGlobalQuestionIndex}_${currentGeneratedQuestion.originalDetailId}'),
      appBarTitle: appBarQuestionTitle,
      question: currentGeneratedQuestion,
      isLoading: _isProcessingAnswer ||
          _isCompletingGroup, // Pass combined loading state
      onAnswerSelected: _handleAnswer,
    );
  }
}
