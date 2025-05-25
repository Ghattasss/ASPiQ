import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myfinalpro/services/Api_services.dart';
import 'package:myfinalpro/services/sucess_popup.dart';

import 'exercise_flow_cubit.dart';
import 'exercise_flow_state.dart'; // Assuming this handles the popup

class ExerciseFlowScreen extends StatefulWidget {
  const ExerciseFlowScreen({super.key});

  @override
  State<ExerciseFlowScreen> createState() => _ExerciseFlowScreenState();
}

class _ExerciseFlowScreenState extends State<ExerciseFlowScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    print("--- ExerciseFlowScreen initState ---");
  }

  @override
  void dispose() {
    print("--- ExerciseFlowScreen dispose ---");
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExerciseFlowCubit>(
      create: (context) {
        try {
          final apiService = context.read<ApiService>();
          return ExerciseFlowCubit(apiService)..fetchMonthlyTest();
        } catch (e) {
          print(
              "!!!!!!!! FATAL ERROR: ApiService not found! Check Provider setup. !!!!!!!!");
          // Provide a default/dummy service or handle error appropriately
          // For now, emit an error state immediately
          return ExerciseFlowCubit(
              ApiService()) // Replace with dummy if possible
            ..emit(const ExerciseFlowError(
                "خطأ في إعداد التطبيق: خدمة API غير متوفرة."));
        }
      },
      child: BlocConsumer<ExerciseFlowCubit, ExerciseFlowState>(
        listener: (context, state) {
          print("Listener received state: ${state.runtimeType}");
          if (!mounted) return; // Avoid acting on unmounted widgets

          if (state is ExerciseCorrectAnswer) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              print("State is ExerciseCorrectAnswer, calling showSuccessPopup...");
              showSuccessPopup(context, _confettiController, () {
                if (mounted) {
                  print("Popup closed, proceeding to next exercise...");
                  context.read<ExerciseFlowCubit>().proceedToNextExercise();
                }
              });
            });
          } else if (state is ExerciseIncorrectAnswer) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              print("State is ExerciseIncorrectAnswer, showing SnackBar...");
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text("إجابة غير صحيحة، حاول مرة أخرى!",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                backgroundColor: Colors.orange.shade700,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(15, 5, 15, 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 6,
              ));
              // --- Optional: Trigger retry automatically or wait for user interaction ---
              // If you want the user to explicitly tap again, do nothing here.
              // If you want to automatically reset to the interactive state:
              // Future.delayed(Duration(milliseconds: 500), () {
              //    if (mounted) context.read<ExerciseFlowCubit>().retryCurrentStep();
              // });
            });
          } else if (state is ExerciseFlowError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              print("State is ExerciseFlowError, showing error SnackBar: ${state.message}");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("خطأ: ${state.message}"),
                    backgroundColor: Colors.red.shade800,
                    duration: const Duration(seconds: 4)),
              );
              // Optionally pop after error
              Future.delayed(const Duration(seconds: 4), () {
                if (mounted && Navigator.canPop(context)) {
                  print("Popping screen due to error state.");
                  Navigator.pop(context);
                }
              });
            });
          } else if (state is ExerciseFlowFinished) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print("Listener: Exercise Flow Finished state detected. Attempting to pop.");
              if (mounted && Navigator.canPop(context)) {
                print("Popping context.");
                Navigator.pop(
                    context, true); // Pass true to indicate completion
              } else {
                print("Cannot pop context after finishing or widget unmounted.");
              }
            });
          }
        },
        builder: (context, state) {
          print("Builder received state: ${state.runtimeType}");
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              Scaffold(
                backgroundColor: const Color(0xff2C73D9),
                appBar: _buildAppBar(context, state),
                body: SafeArea(child: _buildBody(context, state)),
              ),
              ConfettiWidget(
                // Confetti layer
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [ Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple ],
                emissionFrequency: 0.04,
                numberOfParticles: 20,
                gravity: 0.1,
                maxBlastForce: 10,
                minBlastForce: 5,
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Build AppBar ---
  PreferredSizeWidget? _buildAppBar(BuildContext context, ExerciseFlowState state) {
    String title = "الاختبار الشهري";
    int current = 0;
    int total = 4; // Total steps defined in Cubit

    ExerciseStepLoaded? loadedState;
    if (state is ExerciseStepLoaded) {
      loadedState = state;
    } else if (state is ExerciseCorrectAnswer) {
      loadedState = state.previousState;
    } else if (state is ExerciseIncorrectAnswer) {
      loadedState = state.previousState;
    }

    if (loadedState != null) {
      current = loadedState.currentStepIndex + 1; // UI is 1-based
      title = 'الاختبار ($current / $total)';
    } else if (state is ExerciseFlowLoading || state is ExerciseFlowInitial) {
      title = "جاري تحميل الاختبار...";
    } else if (state is ExerciseFlowLoadingDistractor) {
      title = "جاري تحميل البيانات...";
    } else if (state is ExerciseFlowUpdatingSession) {
      title = "جاري حفظ النتائج...";
    } else if (state is ExerciseFlowFinished) {
      return null; // No app bar when finished
    } else if (state is ExerciseFlowError) {
      title = "حدث خطأ";
    }

    // Disable exit button during critical operations
    bool enableExitButton = state is! ExerciseFlowUpdatingSession && state is! ExerciseFlowFinished;

    return AppBar(
      backgroundColor: Colors.transparent,
      // Make AppBar transparent
      elevation: 0,
      automaticallyImplyLeading: false,
      // Remove default back button
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
        tooltip: 'إنهاء الاختبار',
        onPressed: enableExitButton ? () => _showExitConfirmationDialog(context) : null,
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
      centerTitle: true,
    );
  }

  // --- Build Main Body Content ---
  Widget _buildBody(BuildContext context, ExerciseFlowState state) {
    if (state is ExerciseFlowLoading || state is ExerciseFlowInitial || state is ExerciseFlowLoadingDistractor) {
      return _buildLoadingUI(
          state is ExerciseFlowLoadingDistractor ? "جاري تحميل الصورة..." : "جاري تحميل الاختبار...");
    } else if (state is ExerciseStepLoaded || state is ExerciseCorrectAnswer || state is ExerciseIncorrectAnswer) {
      // Extract the core data state
      final loadedState = (state is ExerciseStepLoaded) ? state :
      (state is ExerciseCorrectAnswer) ? state.previousState :
      (state as ExerciseIncorrectAnswer).previousState;

      // Determine if interaction should be allowed
      final bool enableInteraction = state is ExerciseStepLoaded || state is ExerciseIncorrectAnswer;
      // Key for AnimatedSwitcher to force rebuild when interaction state changes
      final keySuffix = enableInteraction ? 'enabled' : 'disabled';

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart)),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey('step_${loadedState.currentStepIndex}_$keySuffix'),
          // Unique key per step and interaction state
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child:
            _buildExerciseStepUI(context, loadedState, enableInteraction),
          ),
        ),
      );
    } else if (state is ExerciseFlowError) {
      return _buildErrorUI(
          context, state.message); // Use the error message from the state
    } else if (state is ExerciseFlowFinished || state is ExerciseFlowUpdatingSession) {
      return _buildFinishedUI(context, state is ExerciseFlowUpdatingSession);
    }

    // Fallback for any unexpected state
    return _buildErrorUI(context, "حالة غير متوقعة: ${state.runtimeType}");
  }

  // --- Build UI for a Specific Step ---
  Widget _buildExerciseStepUI(BuildContext context,
      ExerciseStepLoaded loadedState, bool enableInteraction) {
    print(
        "Building Step UI for step ${loadedState.currentStepIndex}. Interaction: $enableInteraction. Type: ${loadedState.displayType}");

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // --- Question Text ---
        Text(
          loadedState.question ?? 'ما المطلوب؟', // Default question
          style: const TextStyle(
              fontSize: 23, color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        // --- Content Area (depends on displayType) ---
        if (loadedState.displayType == StepDisplayType.singleItemWithOptions)
          _buildSingleItemWithOptionsContent(
              context, loadedState, enableInteraction),

        if (loadedState.displayType == StepDisplayType.twoItemsChoice)
          _buildTwoItemsChoiceContent(context, loadedState, enableInteraction),

        const SizedBox(height: 20), // Bottom padding
      ],
    );
  }

  // --- Build UI for Single Item + Options ---
  Widget _buildSingleItemWithOptionsContent(
      BuildContext context, ExerciseStepLoaded state, bool enableInteraction) {
    final item = state.item1;

    return Column(
      children: [
        // Display Item (Image or Text)
        _buildDisplayItemWidget(item, context: context, isSelectable: false),
        // Not selectable itself
        const SizedBox(height: 35),

        // Answer Options Buttons
        if (state.answerOptions.isNotEmpty)
          ...state.answerOptions.map((optionText) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child: SizedBox(
                width: 310, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    enableInteraction ? Colors.white : Colors.grey.shade300,
                    foregroundColor: enableInteraction
                        ? const Color(0xff2C73D9)
                        : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: const Color(0xff2C73D9)
                                .withOpacity(enableInteraction ? 0.4 : 0.1),
                            width: 1.5)),
                    elevation: enableInteraction ? 4 : 0,
                  ),
                  onPressed: enableInteraction
                      ? () {
                    print("Button '$optionText' pressed. Submitting...");
                    context.read<ExerciseFlowCubit>().submitAnswer(
                        optionText); // Submit the text option
                  }
                      : null, // Disable button if interaction is not enabled
                  child: Text(optionText,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList()
        else
          const Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: Text("لا توجد خيارات متاحة لهذه الخطوة.", style: TextStyle(color: Colors.yellow)),
          ),
      ],
    );
  }

  // --- Build UI for Two Items Choice ---
  Widget _buildTwoItemsChoiceContent(
      BuildContext context, ExerciseStepLoaded state, bool enableInteraction) {
    final item1 = state.item1;
    final item2 =
        state.item2; // This should not be null for twoItemsChoice type

    if (item2 == null) {
      return const Center(
          child: Text("خطأ: العنصر الثاني مفقود لهذه الخطوة.",
              style: TextStyle(color: Colors.yellow)));
    }

    // Optional: Randomize display order
    // bool showItem1First = Random().nextBool();
    // final firstItem = showItem1First ? item1 : item2;
    // final secondItem = showItem1First ? item2 : item1;
    // Keep order for simplicity now: item1 then item2

    return Column(
      children: [
        _buildDisplayItemWidget(item1,
            context: context,
            isSelectable: true,
            enableInteraction: enableInteraction),
        const SizedBox(height: 24),
        _buildDisplayItemWidget(item2,
            context: context,
            isSelectable: true,
            enableInteraction: enableInteraction),
      ],
    );
  }

  // --- Unified Widget to Build Either Image or Text Display Item ---
  Widget _buildDisplayItemWidget(DisplayItem item,
      {required BuildContext context,
        required bool isSelectable,
        bool enableInteraction = true}) {
    // enableInteraction needed only if selectable

    final double contentWidth = MediaQuery.of(context).size.width * 0.8;
    // Adjust height based on type? Image might need more fixed height.
    final double imgHeight = MediaQuery.of(context).size.height * 0.29;
    final double clampedWidth = contentWidth.clamp(280, 340);
    final double clampedHeight =
    imgHeight.clamp(220, 300); // Primarily for images

    Widget contentWidget;

    if (item.type == 'Img') {
      contentWidget = _buildImageAsset(item.content, // Asset path
          width: clampedWidth,
          height: clampedHeight);
    } else {
      // Text
      contentWidget = Container(
        width: clampedWidth,
        constraints: BoxConstraints(minHeight: clampedHeight / 2),
        // Min height for text
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: Text(
            item.content ?? "[نص فارغ]",
            style: const TextStyle(
                fontSize: 18, color: Colors.black87, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Wrap in InkWell if it's selectable
    if (isSelectable) {
      return InkWell(
        onTap: enableInteraction
            ? () {
          print(
              "Selectable item tapped. Identifier: '${item.identifier}'. Submitting...");
          context.read<ExerciseFlowCubit>().submitAnswer(
              item.identifier); // Submit the item's unique identifier
        }
            : null,
        // Disable tap if interaction not enabled
        borderRadius: BorderRadius.circular(14),
        splashColor: enableInteraction
            ? const Color(0xff2C73D9).withOpacity(0.4)
            : Colors.transparent,
        highlightColor: enableInteraction
            ? const Color(0xff2C73D9).withOpacity(0.2)
            : Colors.transparent,
        child: Opacity(
          opacity: enableInteraction ? 1.0 : 0.6, // Dim if not interactive
          child: Container(
            // Add outer container for shadow/border maybe
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: item.type == 'Img' ? Colors.white : Colors.transparent,
                // White bg for image clipping, none needed for text container
                boxShadow: [
                  if (enableInteraction)
                    const BoxShadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 4))
                ]),
            child: ClipRRect(
              // Clip image content
                borderRadius: BorderRadius.circular(14),
                child: contentWidget),
          ),
        ),
      );
    } else {
      // Not selectable, just return the content widget possibly wrapped for consistency
      return Container(
        width: item.type == 'Img' ? clampedWidth : null,
        // Width primarily for image
        height: item.type == 'Img' ? clampedHeight : null,
        // Height primarily for image
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: item.type == 'Img' ? Colors.white : Colors.transparent,
            boxShadow: const [
              // Consistent shadow even if not selectable
              BoxShadow(
                  color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
            ]),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(14), child: contentWidget),
      );
    }
  }

  // --- Helper to Build Image Asset with Error Handling ---
  Widget _buildImageAsset(String? assetPath, {double? width, double? height}) {
    if (assetPath == null || assetPath.isEmpty) {
      print("Error: Attempted to load image with null or empty path.");
      return _buildErrorImagePlaceholder(width, height);
    }

    // Ensure path starts with 'assets/' - redundant if localAssetPath is correct, but safe.
    final String finalAssetPath =
    assetPath.startsWith('assets/') ? assetPath : 'assets/$assetPath';
    print(
        "Attempting to load ASSET image: $finalAssetPath (Original: $assetPath)");

    return Image.asset(
      finalAssetPath,
      key: ValueKey(finalAssetPath),
      // Use path as key
      width: width,
      height: height,
      fit: BoxFit.contain,
      // Contain ensures the whole image is visible
      errorBuilder: (ctx, error, stackTrace) {
        print("--- ERROR Loading Asset Image ---");
        print("Path Attempted: $finalAssetPath");
        print("Error: $error");
        // print("StackTrace: $stackTrace"); // Can be verbose
        print("---------------------------------");
        return _buildErrorImagePlaceholder(width, height);
      },
    );
  }

  // --- Placeholder for Image Loading Errors ---
  Widget _buildErrorImagePlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
          child: Icon(Icons.broken_image_outlined, // More specific icon
              color: Colors.grey.shade400,
              size: (width ?? 60) * 0.4) // Adjust size based on width
      ),
    );
  }

  // --- UI for Loading State ---
  Widget _buildLoadingUI(String message) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(message,
                style: const TextStyle(color: Colors.white70, fontSize: 16))
          ],
        ));
  }

  // --- UI for Error State ---
  Widget _buildErrorUI(BuildContext context, String message) {
    return Center(
      child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: Colors.yellow.shade600, size: 60),
              const SizedBox(height: 20),
              Text(
                message, // Display the error message from the state
                style: const TextStyle(
                    color: Colors.white, fontSize: 17, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  // Retry fetching the initial data
                  context.read<ExerciseFlowCubit>().fetchMonthlyTest();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("إعادة المحاولة"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xff2C73D9),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10)),
              )
            ],
          )),
    );
  }

  // --- UI for Finished/Updating State ---
  Widget _buildFinishedUI(BuildContext context, bool isUpdating) {
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isUpdating) ...[
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 25),
                const Text("جاري حفظ النتائج...",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center),
              ] else ...[
                const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.lightGreenAccent, size: 90),
                const SizedBox(height: 25),
                const Text("لقد أكملت الاختبار بنجاح!",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),
                const Text("سيتم العودة للشاشة الرئيسية...",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center),
                // The listener handles the actual pop
              ]
            ],
          ),
        ));
  }

  // --- Exit Confirmation Dialog ---
  void _showExitConfirmationDialog(BuildContext context) {
    // Get the cubit instance outside the builder
    final cubit = context.read<ExerciseFlowCubit>();

    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an action
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الإنهاء',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
              'هل أنت متأكد من رغبتك في إنهاء الاختبار الآن؟ لن يتم حفظ تقدمك الحالي.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actionsPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          actions: <Widget>[
            TextButton(
              child: Text('إلغاء', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(), // Close the dialog
            ),
            TextButton(
              child: Text('إنهاء الاختبار', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog first
                // --- No need to manually call _completeSession ---
                // Just pop the screen. If the session wasn't finished naturally,
                // it shouldn't be marked as complete.
                if (Navigator.canPop(context)) {
                  print("User confirmed exit. Popping screen.");
                  Navigator.pop(context); // Pop the ExerciseFlowScreen
                }
              },
            ),
          ],
        );
      },
    );
  }

} // End of _ExerciseFlowScreenState