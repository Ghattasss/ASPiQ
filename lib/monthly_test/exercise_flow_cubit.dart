// lib/monthly_test/exercise_flow_cubit.dart
import 'dart:async';
import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myfinalpro/core/errors/failures.dart';

import 'package:myfinalpro/monthly_test/test_detail.dart';
import 'package:myfinalpro/services/Api_services.dart';
import 'package:myfinalpro/services/asset_service.dart';

import 'package:flutter/foundation.dart';

import 'exercise_flow_state.dart';
import '../models/notification_item.dart' as notif_model;
import '../services/notification_manager.dart';
import 'monthly_test_response.dart';


class ExerciseFlowCubit extends Cubit<ExerciseFlowState> {
  final ApiService apiService;
  final String randomAssetFolderPath;

  List<TestDetail> _detailsList = [];
  List<TestDetail> _newDetailsList = [];

  int? _mainSessionId;
  String? _monthlyTestTitle;
  int _currentStepIndex = -1;

  // We will dynamically determine total steps based on session type
  // final int totalSteps = 4; // Remove this fixed value

  ExerciseFlowCubit(this.apiService, {this.randomAssetFolderPath = 'assets/objects/'})
      : super(const ExerciseFlowInitial()) {
    debugPrint("onCreate -- ExerciseFlowCubit initialized with randomAssetFolderPath: $randomAssetFolderPath");
  }

  Future<void> fetchMonthlyTest() async {
    debugPrint("Cubit: Fetching monthly test details...");
    emit(const ExerciseFlowLoading());

    final Either<Failure, MonthlyTestResponse> result =
    await apiService.getMonthlyTestDetails();

    result.fold(
      (failure) {
        debugPrint("Cubit Error fetching monthly test: ${failure.message}");
        emit(ExerciseFlowError("فشل تحميل الاختبار الشهري: ${failure.message}"));
      },
      (testResponse) {
        _detailsList = testResponse.details;
        _newDetailsList = testResponse.newDetails;
        _mainSessionId = testResponse.sessionId;
        _monthlyTestTitle = testResponse.title;

        debugPrint(
            "Cubit: Fetched monthly test. Details: ${_detailsList.length}, NewDetails: ${_newDetailsList.length}. Session ID: $_mainSessionId, Title: $_monthlyTestTitle");

        if (_detailsList.isEmpty) {
          debugPrint("Cubit Error: 'details' list is empty. Cannot proceed with the test.");
          emit(const ExerciseFlowError("لا توجد بيانات أساسية (details) متاحة للاختبار الشهري."));
          return;
        }

        _currentStepIndex = -1; // Reset step index
        _prepareExerciseStep(0); // Start with the first step
      },
    );
  }

  Future<void> _prepareExerciseStep(int stepIndex) async {
    // Determine total steps based on session type
    final bool isSpecialSession = _mainSessionId != null && _mainSessionId! > 28;
    final int totalSteps = isSpecialSession ? _detailsList.length : 4; // Assume 4 steps for old logic, details.length for new

    if (stepIndex >= totalSteps) {
      debugPrint("Cubit: All steps completed ($stepIndex / $totalSteps). Attempting to complete session.");
      await _completeSession(_mainSessionId);
      return;
    }
    if (stepIndex < 0) {
      emit(const ExerciseFlowError("خطأ داخلي: رقم خطوة التمرين غير صالح."));
      return;
    }

    _currentStepIndex = stepIndex;
    final int detailsSize = _detailsList.length;
    final int newDetailsSize = _newDetailsList.length;
    debugPrint("Cubit: Preparing exercise step $stepIndex... (Details available: $detailsSize, NewDetails available: $newDetailsSize, IsSpecialSession: $isSpecialSession)");

    if (detailsSize == 0) {
      emit(const ExerciseFlowError("لا توجد بيانات أساسية (details) للاختبار."));
      return;
    }

    try {
      StepDisplayType displayType;
      String? question;
      DisplayItem item1;
      DisplayItem? item2;
      List<String> answerOptions = [];
      String correctAnswerIdentifier;
      TestDetail detailForStep; // Use a single variable for the current detail

      if (isSpecialSession) {
        // Handle special session (ID > 28) - always use single item with options
        if (stepIndex >= detailsSize) {
           throw Exception("خطأ: بيانات غير كافية للخطوة $stepIndex في الاختبار الخاص.");
        }
        detailForStep = _detailsList[stepIndex];
        displayType = StepDisplayType.singleItemWithOptions;
        question = detailForStep.question ?? "هل كان هذاالتصرف صح ام خطأ"; // Use fixed question
        item1 = _createDisplayItem(detailForStep);
        answerOptions = ["صح", "خطأ"]; // Use fixed options
        correctAnswerIdentifier = detailForStep.rightAnswer ?? "صح"; // Use provided answer or default

         if (correctAnswerIdentifier.isEmpty) { // Ensure correct answer is not empty
           correctAnswerIdentifier = "صح";
           debugPrint("Warning (Special Session Step $stepIndex): rightAnswer was null or empty, defaulting to '$correctAnswerIdentifier'");
         }

      } else {
        // Keep existing logic for other sessions
        TestDetail detailItem1ForStep0, detailItem1ForStep1, detailItem1ForStep2, primaryItemForStep3;


        switch (stepIndex) {
          case 0:
            detailItem1ForStep0 = _detailsList[0];
            displayType = StepDisplayType.singleItemWithOptions;
            question = detailItem1ForStep0.question ?? "ما هو شعور هذا الشخص؟";
            item1 = _createDisplayItem(detailItem1ForStep0);
            answerOptions = detailItem1ForStep0.answerOptions;
            correctAnswerIdentifier = detailItem1ForStep0.rightAnswer ?? '';
            if (correctAnswerIdentifier.isEmpty && answerOptions.isNotEmpty) {
              correctAnswerIdentifier = answerOptions[0];
              debugPrint("Warning (Step 0): rightAnswer was null or empty, defaulting to first option: '$correctAnswerIdentifier'");
            } else if (correctAnswerIdentifier.isEmpty || answerOptions.isEmpty) {
              throw Exception("بيانات الخطوة 1 مفقودة (الاختبار الشهري - سؤال أو خيارات).");
            }
            break;

          case 1:
            if (detailsSize < 2) {
              emit(const ExerciseFlowError("لا توجد بيانات كافية للخطوة 2 (تحتاج عنصرين في details).")); return;
            }
            detailItem1ForStep1 = _detailsList[1];
            displayType = StepDisplayType.singleItemWithOptions;
            question = detailItem1ForStep1.question ?? "ما هو شعور هذا الشخص؟";
            item1 = _createDisplayItem(detailItem1ForStep1);
            answerOptions = detailItem1ForStep1.answerOptions;
            correctAnswerIdentifier = detailItem1ForStep1.rightAnswer ?? '';
             if (correctAnswerIdentifier.isEmpty && answerOptions.isNotEmpty) {
               correctAnswerIdentifier = answerOptions[0];
               debugPrint("Warning (Step 1): rightAnswer was null or empty, defaulting to first option: '$correctAnswerIdentifier'");
            } else if (correctAnswerIdentifier.isEmpty || answerOptions.isEmpty) {
              throw Exception("بيانات الخطوة 2 مفقودة (الاختبار الشهري - سؤال أو خيارات).");
            }
            break;

           case 2:
          if (newDetailsSize == 0) {
            emit(const ExerciseFlowError("لا توجد بيانات (newDetails) للخطوة 3.")); return;
          }
          detailItem1ForStep2 = _detailsList[min(2, detailsSize - 1)];
          final TestDetail newItemForDistractionStep2 = _newDetailsList[0];

          displayType = StepDisplayType.twoItemsChoice;
          String tempRightAnswerTextForQ2 = detailItem1ForStep2.rightAnswer?.trim() ?? '';
          String rightAnswerTextForQuestion2 = tempRightAnswerTextForQ2.isNotEmpty ? tempRightAnswerTextForQ2 : (_monthlyTestTitle ?? "المطلوب");
          question = "من يكون $rightAnswerTextForQuestion2؟";

          item1 = _createDisplayItem(detailItem1ForStep2);
          item2 = _createDisplayItem(newItemForDistractionStep2);
          correctAnswerIdentifier = item1.identifier;

          if (item1.identifier == item2.identifier) {
            debugPrint("Warning (Cubit - Step 2/Q3): Correct item and distractor might be identical: '${item1.identifier}'. Consider providing distinct newDetail.");
          }
          break;

        case 3:
          primaryItemForStep3 = _detailsList[min(3, detailsSize - 1)];
          // dataTypeOfContent in TestDetail is String?, so ?. is correct and safe.
          // If analyzer still warns, it might be a false positive or overly aggressive.
          // ignore: invalid_null_aware_operator
          final String primaryType = primaryItemForStep3.dataTypeOfContent?.toLowerCase() ?? 'img';

          String tempRightAnswerTextForQ3 = primaryItemForStep3.rightAnswer?.trim() ?? '';
          String rightAnswerTextForQuestion3 = tempRightAnswerTextForQ3.isNotEmpty ? tempRightAnswerTextForQ3 : (_monthlyTestTitle ?? "المطلوب");
          question = "من يكون $rightAnswerTextForQuestion3؟";

          displayType = StepDisplayType.twoItemsChoice;
          item1 = _createDisplayItem(primaryItemForStep3);
          correctAnswerIdentifier = item1.identifier;

          if (primaryType == 'text') {
            debugPrint("Cubit: Step 3 (idx 3/Q4) - Text primary. Finding text distractor.");
            TestDetail? textDistractor;
            if (newDetailsSize > 0) {
              for (var ndItem in _newDetailsList) {
                // ignore: invalid_null_aware_operator
                if (ndItem.dataTypeOfContent?.toLowerCase() == 'text' && _createDisplayItem(ndItem).identifier != item1.identifier) {
                  textDistractor = ndItem;
                  break;
                }
              }
            }
            if (textDistractor == null && detailsSize > 0) {
                for(var dItem in _detailsList) {
                    // ignore: invalid_null_aware_operator
                    if (dItem.id != primaryItemForStep3.id && dItem.dataTypeOfContent?.toLowerCase() == 'text') {
                        if(_createDisplayItem(dItem).identifier != item1.identifier) {
                           textDistractor = dItem;
                           break;
                        }
                    }
                }
            }

            if (textDistractor != null) {
              item2 = _createDisplayItem(textDistractor);
              debugPrint("Cubit: Step 3 (idx 3/Q4) - Text vs Text. Correct: '${item1.identifier}', Distractor: '${item2?.identifier}'");
            } else {
              debugPrint("Cubit Error: No suitable text distractor found for step 3 (idx 3/Q4).");
              emit(const ExerciseFlowError("لا توجد بيانات نصية كافية (كمشتت) للخطوة الرابعة."));
              return;
            }
          } else {
            debugPrint("Cubit: Step 3 (idx 3/Q4) - Image primary. Requesting random image distractor from service path: $randomAssetFolderPath");
            emit(const ExerciseFlowLoadingDistractor());

            String? randomAssetPath;
            try {
              randomAssetPath = await getRandomAssetPathFromFolder(randomAssetFolderPath);

              if (randomAssetPath == null) {
                debugPrint("Cubit Error: getRandomAssetPathFromFolder returned null for folder: $randomAssetFolderPath");
                throw Exception("فشل تحميل صورة المشتت العشوائية (المجلد فارغ أو خطأ في المسار).");
              }

              int attemptsToGetDifferent = 0;
              while(randomAssetPath == item1.identifier && attemptsToGetDifferent < 3) {
                  debugPrint("Cubit Warning: Random distractor '$randomAssetPath' is same as correct item '${item1.identifier}'. Retrying...");
                  await Future.delayed(const Duration(milliseconds: 50));
                  randomAssetPath = await getRandomAssetPathFromFolder(randomAssetFolderPath);
                  attemptsToGetDifferent++;
                  if(randomAssetPath == null) {
                      throw Exception("فشل تحميل صورة المشتت العشوائية بعد محاولات التفادي.");
                  }
              }
              if(randomAssetPath == item1.identifier) {
                  debugPrint("Cubit Warning: Could not get a different distractor after $attemptsToGetDifferent attempts. Proceeding with potentially same image.");
              }

              // After the checks, if randomAssetPath is not null, we can use '!'
              // This assumes DisplayItem constructor expects String for content and identifier
              if (randomAssetPath == null) { // Final safety check, should be caught above
                  throw Exception("فشل نهائي في تحميل مسار المشتت العشوائي.");
              }
              item2 = DisplayItem(type: 'Img', content: randomAssetPath!, identifier: randomAssetPath!, originalDetailIdForApi: -99);
              debugPrint("Cubit: Step 3 (idx 3/Q4) - Image vs Image. Correct: '${item1.identifier}', Distractor: '${item2.identifier}'");
            } catch (e) {
              debugPrint("Cubit Error (Step 3 Img Distractor via service): $e");
              emit(ExerciseFlowError("خطأ تحميل صورة المشتت: ${e.toString().replaceFirst("Exception: ", "")}"));
              return;
            }
          }
          break;

          default:
            throw Exception("رقم خطوة غير صالح: $stepIndex");
        }
      }

      // Emit the loaded state
      emit(ExerciseStepLoaded(
        currentStepIndex: _currentStepIndex,
        displayType: displayType, question: question,
        mainSessionId: _mainSessionId, item1: item1, item2: item2,
        answerOptions: answerOptions, correctAnswerIdentifier: correctAnswerIdentifier,
      ));
      debugPrint("Cubit: Emitted Loaded for step $_currentStepIndex. Q: '$question'. CorrectID: '$correctAnswerIdentifier'. DisplayType: $displayType");

    } catch (e, s) {
      debugPrint("Cubit Error preparing step $_currentStepIndex: $e\n$s");
      emit(ExerciseFlowError("خطأ تحضير الخطوة ${_currentStepIndex + 1}: ${e.toString().replaceFirst("Exception: ", "")}"));
    }
  }

  DisplayItem _createDisplayItem(TestDetail detail) {
    final int originalApiId = detail.detailId ?? detail.id ?? 0;
    // ignore: invalid_null_aware_operator
    final String type = detail.dataTypeOfContent?.toLowerCase() == 'text' ? 'Text' : 'Img';
    String? content = (type == 'Img') ? detail.localAssetPath : detail.textContent;

    String identifier;
    String nonNullContent;

    if (content == null || (type == 'Text' && content.trim().isEmpty) || (type == 'Img' && content.trim().isEmpty)) {
        nonNullContent = (type == 'Img') ? "assets/images/placeholder.png" : "[نص غير متوفر]";
        identifier = "missing_content_${type.toLowerCase()}_${originalApiId}_${DateTime.now().millisecondsSinceEpoch}";
        debugPrint("Warning: Content for detail ID $originalApiId ($type) is missing or empty. Using placeholder/fallback: '$nonNullContent'");
    } else {
        nonNullContent = content;
        identifier = content;
    }

    return DisplayItem(
        type: type,
        content: nonNullContent,
        identifier: identifier,
        originalDetailIdForApi: originalApiId
    );
  }

  void submitAnswer(String selectedIdentifier) {
    final currentState = state;
    ExerciseStepLoaded? loadedState;

    if (currentState is ExerciseStepLoaded) {
      loadedState = currentState;
    } else if (currentState is ExerciseCorrectAnswer) {
      debugPrint("Cubit: submitAnswer called while in ExerciseCorrectAnswer state. Ignoring.");
      return;
    } else if (currentState is ExerciseIncorrectAnswer) {
      loadedState = currentState.previousState;
    } else {
      debugPrint("Cubit: submitAnswer called in an unexpected state (${currentState.runtimeType}). Ignoring.");
      return;
    }

    final String correctAnswerId = loadedState.correctAnswerIdentifier;
    final bool isCorrect = (selectedIdentifier == correctAnswerId);

    emit(isCorrect ? ExerciseCorrectAnswer(loadedState) : ExerciseIncorrectAnswer(loadedState));
  }

  void retryCurrentStep() {
    if (state is ExerciseIncorrectAnswer) {
      emit((state as ExerciseIncorrectAnswer).previousState);
    }
  }

  void proceedToNextExercise() {
    if (state is ExerciseCorrectAnswer) {
      final nextStep = (state as ExerciseCorrectAnswer).previousState.currentStepIndex + 1;
      _prepareExerciseStep(nextStep);
    }
  }

  Future<void> _completeSession(int? sessionId) async {
    if (sessionId == null) {
      debugPrint("Cubit: _completeSession called with null sessionId. Emitting ExerciseFlowFinished.");
      if (mounted && state is! ExerciseFlowFinished) emit(const ExerciseFlowFinished());
      return;
    }

    debugPrint("Cubit: Attempting to complete session ID: $sessionId");
    if (mounted && state is! ExerciseFlowUpdatingSession) emit(const ExerciseFlowUpdatingSession());

    final Either<Failure, bool> result = await apiService.markSessionDone(sessionId);
    result.fold(
      (failure) {
        debugPrint("Cubit Error: Failed to mark session $sessionId done: ${failure.message}");
        if (mounted) emit(ExerciseFlowError("فشل تحديث حالة الاختبار: ${failure.message}"));
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && (state is ExerciseFlowError || state is ExerciseFlowUpdatingSession) && state is! ExerciseFlowFinished) {
            emit(const ExerciseFlowFinished());
          }
        });
      },
      (success) async {
        debugPrint("Cubit: Successfully marked session $sessionId done. Success: $success");
        await NotificationManager.deactivateNotificationsByType(notif_model.NotificationType.monthlyTestAvailable);
        await NotificationManager.setMonthlyTestNotificationSent(false);
        debugPrint("Cubit: Monthly test notification flag reset.");
        if (mounted && state is! ExerciseFlowError && state is! ExerciseFlowFinished) {
           emit(const ExerciseFlowFinished());
        }
      },
    );
  }

  @override
  Future<void> close() {
    debugPrint("onClose -- ExerciseFlowCubit closing.");
    return super.close();
  }

  bool get mounted => !isClosed;
}