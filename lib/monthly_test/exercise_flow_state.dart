// lib/monthly_test/exercise_flow_state.dart
import 'package:equatable/equatable.dart';

// --- Helper class to represent an item to be displayed ---
class DisplayItem extends Equatable {
  final String type; // 'Img' or 'Text'
  final String? content; // Asset path for Img, text content for Text
  final String identifier; // Unique identifier for selection
  final int originalDetailIdForApi; // The original ID from the backend TestDetail

  const DisplayItem({
    required this.type,
    required this.content,
    required this.identifier,
    required this.originalDetailIdForApi, // Required for API calls if needed
  });

  @override
  List<Object?> get props => [type, content, identifier, originalDetailIdForApi];
}

// --- Enum for how the step should be displayed ---
enum StepDisplayType {
  singleItemWithOptions, // Show item1 + text options
  twoItemsChoice, // Show item1 and item2, user chooses one
}

// Base State
abstract class ExerciseFlowState extends Equatable {
  const ExerciseFlowState();
  @override
  List<Object?> get props => [];
}

// --- Basic States ---
class ExerciseFlowInitial extends ExerciseFlowState {
  const ExerciseFlowInitial();
}
class ExerciseFlowLoading extends ExerciseFlowState {
  const ExerciseFlowLoading();
}
class ExerciseFlowLoadingDistractor extends ExerciseFlowState {
  const ExerciseFlowLoadingDistractor();
}
class ExerciseFlowError extends ExerciseFlowState {
  final String message;
  const ExerciseFlowError(this.message);
  @override
  List<Object> get props => [message];
}
class ExerciseFlowFinished extends ExerciseFlowState {
  const ExerciseFlowFinished();
}
class ExerciseFlowUpdatingSession extends ExerciseFlowState {
  const ExerciseFlowUpdatingSession();
}

// --- State for displaying a step ---
class ExerciseStepLoaded extends ExerciseFlowState {
  final int currentStepIndex;
  final StepDisplayType displayType;
  final String? question; // نص السؤال
  final int? mainSessionId;

  final DisplayItem item1;
  final DisplayItem? item2;

  final List<String> answerOptions;
  final String correctAnswerIdentifier;

  const ExerciseStepLoaded({
    required this.currentStepIndex,
    required this.displayType,
    required this.question,
    required this.mainSessionId,
    required this.item1,
    this.item2,
    required this.answerOptions,
    required this.correctAnswerIdentifier,
  });

  @override
  List<Object?> get props => [
    currentStepIndex, displayType, question, mainSessionId,
    item1, item2, answerOptions, correctAnswerIdentifier,
  ];
}

// --- Answer States ---
class ExerciseCorrectAnswer extends ExerciseFlowState {
  final ExerciseStepLoaded previousState;
  const ExerciseCorrectAnswer(this.previousState);
  @override
  List<Object?> get props => [previousState];
}

class ExerciseIncorrectAnswer extends ExerciseFlowState {
  final ExerciseStepLoaded previousState;
  const ExerciseIncorrectAnswer(this.previousState);
  @override
  List<Object?> get props => [previousState];
}