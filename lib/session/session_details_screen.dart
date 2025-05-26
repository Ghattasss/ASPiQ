import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'models/session_model.dart'; // تأكد من المسار الصحيح
import '../services/Api_services.dart'; // تأكد من المسار الصحيح
import 'break.dart'; // تأكد من المسار الصحيح
import 'timetest.dart'; //  لاستخدام شاشة StartTest الجديدة
import 'dart:math';

class RandomImageInfo { // جعلته عامًا لتجنب library_private_types_in_public_api إذا كان سيُستخدم بشكل أوسع
  final String path;
  final String name;
  RandomImageInfo(this.path, this.name);
}

class SessionDetailsScreen extends StatefulWidget {
  final Session initialSession;
  final String jwtToken;

  const SessionDetailsScreen({
    super.key,
    required this.initialSession,
    required this.jwtToken,
  });

  @override
  _SessionDetailsScreenState createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  late Session _currentSession;
  int _currentStepIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _breakTimer;
  Timer? _stepTimer;

  RandomImageInfo? _randomImageInfo;
  List<RandomImageInfo> _objectImageInfos = []; // استخدم النوع العام
  final List<int> _completedDetailIds = []; // تم تعيينه كـ final

  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;

  static const Duration imageDisplayDuration = Duration(minutes: 7);
  static const Duration textDisplayDuration = Duration(minutes: 10);
  static const Duration videoDisplayDuration = Duration(minutes: 10);
  static const Duration breakDuration = Duration(seconds: 5);

  static const String localImagePathBase = 'assets/';
  static const String objectsFolderPath = 'assets/objects/';

  static const Color screenBgColor = Color(0xFF2C73D9);
  static const Color appBarElementsColor = Colors.white;
  static const Color cardBgColor = Colors.white;
  static const Color cardTextColor = Color(0xFF2C73D9);
  static const Color progressBarColor = Colors.white;
  static Color progressBarBgColor = Colors.white.withAlpha((0.3 * 255).round()); // استخدام withAlpha
  static const Color buttonBgColor = Colors.white;
  static const Color buttonFgColor = Color(0xFF2C73D9);
  static const Color loadingIndicatorColor = Colors.white;
  static const Color errorTextColor = Colors.redAccent;
  static const Color videoPlaceholderColor = Colors.black54;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.initialSession;

    if (_currentSession.details.isEmpty) {
      _errorMessage = "لا توجد تمارين في هذه الجلسة.";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      debugPrint("--- Session Details Screen Initialized ---");
      _printSessionDetails();
      _loadObjectImageInfos();
      _prepareStepContent();
      _startStepTimer();
    }
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    _stepTimer?.cancel();
    _videoController?.dispose();
    debugPrint("--- Session Details Screen Disposed ---");
    super.dispose();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _printSessionDetails() {
    debugPrint("--- Available Exercise Details (from details list) ---");
    for (int i = 0; i < _currentSession.details.length; i++) {
      final detail = _currentSession.details[i];
      debugPrint(
          "Exercise $i: ID=${detail.id}, Type=${detail.datatypeOfContent}, Image=${detail.hasImage}, Text=${detail.hasText}, Video=${detail.hasVideo}, Desc=${detail.hasDesc}");
      if (detail.hasVideo && detail.video != null) {
        debugPrint("  Video Path: ${detail.video}");
      }
    }
    if (_currentSession.newDetail != null) {
      debugPrint(
          "--- New Detail Data: ID=${_currentSession.newDetail!.id}, Type=${_currentSession.newDetail!.datatypeOfContent}, Image=${_currentSession.newDetail!.hasImage}, Text=${_currentSession.newDetail!.hasText}, Video=${_currentSession.newDetail!.hasVideo}, Desc=${_currentSession.newDetail!.hasDesc}");
    }
    debugPrint("------------------------------------------------------");
  }

  Widget _buildImageErrorWidget(BuildContext context, Object error, StackTrace? stackTrace, String? attemptedPath) {
     debugPrint("Error loading asset image: $attemptedPath\n$error");
     return Container(
       padding: const EdgeInsets.all(10), alignment: Alignment.center,
       decoration: BoxDecoration( color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
       child: Column( mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
           Icon(Icons.broken_image_outlined, color: Colors.red.shade400, size: 40),
           const SizedBox(height: 8),
           Text('خطأ تحميل الصورة', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
           if (attemptedPath != null) Padding( padding: const EdgeInsets.only(top: 4.0), child: Text( '(المسار: $attemptedPath)', textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 10),),),
         ],),);
   }

  Future<void> _loadObjectImageInfos() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      _objectImageInfos = manifestMap.keys
          .where((String key) =>
              key.startsWith(objectsFolderPath) &&
              key != objectsFolderPath && // Avoid listing the folder itself if it appears
              (key.endsWith('.png') ||
                  key.endsWith('.jpg') ||
                  key.endsWith('.jpeg') ||
                  key.endsWith('.gif') ||
                  key.endsWith('.webp')))
          .map((path) {
        String filename = path.split('/').last;
        String nameWithoutExtension = filename.contains('.')
            ? filename.substring(0, filename.lastIndexOf('.'))
            : filename;
        nameWithoutExtension = nameWithoutExtension.replaceAll('_', ' ').trim();
        if (nameWithoutExtension.isNotEmpty) {
          nameWithoutExtension = nameWithoutExtension[0].toUpperCase() +
              nameWithoutExtension.substring(1);
        }
        return RandomImageInfo(path, nameWithoutExtension);
      }).toList();
      debugPrint(
          "Loaded ${_objectImageInfos.length} image infos from $objectsFolderPath");
      if (_objectImageInfos.isEmpty) {
        debugPrint("Warning: No images found in $objectsFolderPath. Ensure they are declared in pubspec.yaml and the path is correct.");
      }
    } catch (e) {
      debugPrint("Error loading object image infos: $e");
    }
  }

  void _selectRandomObjectImageInfo() {
    if (_objectImageInfos.isNotEmpty) {
      final random = Random();
      _randomImageInfo =
          _objectImageInfos[random.nextInt(_objectImageInfos.length)];
      debugPrint(
          "Selected random object: Path=${_randomImageInfo!.path}, Name=${_randomImageInfo!.name}");
    } else {
      debugPrint("Warning: Cannot select random image, info list is empty.");
      _randomImageInfo = null;
    }
  }

  bool _isValidUrl(String url) {
    Uri? uri = Uri.tryParse(url);
    return uri != null && (uri.isScheme('HTTP') || uri.isScheme('HTTPS'));
  }

String _normalizeAssetPath(String path) {
  String cleanPath = path.trim();
  // هذا السطر هو المفتاح هنا
  cleanPath = cleanPath.replaceAll('\\', '/'); 

  if (!cleanPath.startsWith('assets/')) {
    if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
    }
    cleanPath = 'assets/$cleanPath';
  }
  cleanPath = cleanPath.replaceAll(RegExp(r'/+'), '/');
  debugPrint("Original path: '$path' -> Normalized path: '$cleanPath'");
  return cleanPath;
}
// This function seems to be unused in the provided video loading logic,
// as _createVideoController is directly using VideoPlayerController.asset or .networkUrl.
// If it were used, it's mostly for network URLs.
// VideoPlayerController? _createVideoController(String videoPath) {
//   String normalizedPath = _normalizeAssetPath(videoPath);
//   debugPrint("Attempting to create video controller for: '$normalizedPath'");
//   if (_isValidUrl(normalizedPath)) { // This check is for absolute URLs
//     debugPrint("Creating network video controller for URL: $normalizedPath");
//     Uri videoUri = Uri.parse(normalizedPath);
//     return VideoPlayerController.networkUrl(videoUri);
//   }
//   debugPrint("Creating asset video controller for: $normalizedPath");
//   return VideoPlayerController.asset(normalizedPath);
// }

// This function is also not directly used for path validation before passing to VideoPlayerController.asset.
// _checkVideoAssetExists is used instead.
// bool _isValidAssetPath(String path) {
//   String normalizedPath = _normalizeAssetPath(path);
//   return normalizedPath.startsWith('assets/') &&
//          (normalizedPath.endsWith('.mp4') || normalizedPath.endsWith('.mov') ||
//           normalizedPath.endsWith('.avi') || normalizedPath.endsWith('.mkv') ||
//           normalizedPath.endsWith('.webm') || normalizedPath.endsWith('.3gp'));
// }

Future<bool> _checkVideoAssetExists(String assetPath) async {
  // Asset paths should be relative to the project root, e.g., "assets/videos/my_video.mp4"
  // The _normalizeAssetPath function ensures it starts with "assets/".
  try {
    // Attempt to load the asset. If it doesn't exist, this will throw an exception.
    await rootBundle.load(assetPath);
    debugPrint("Asset check: Found '$assetPath'");
    return true;
  } catch (e) {
    debugPrint("Asset check: Not found '$assetPath' - Error: $e");
    return false;
  }
}

Future<String?> _findValidVideoPath(String originalPath) async {
  // Normalize the original path first. This handles trims, backslashes, and 'assets/' prefix.
  String normalizedOriginalPath = _normalizeAssetPath(originalPath);

  List<String> pathsToTry = [
    normalizedOriginalPath, // Try the normalized path directly
  ];

  // If the original path didn't start with 'assets/', _normalizeAssetPath added it.
  // If originalPath was like 'videos/myvideo.mp4', normalizedOriginalPath is 'assets/videos/myvideo.mp4'.
  // If originalPath was 'assets/videos/myvideo.mp4', normalizedOriginalPath is the same.

  // Add variations with common video extensions if the original path might be missing one.
  // This is useful if `originalPath` might be just "assets/videos/myvideo"
  String basePathWithoutExtension = normalizedOriginalPath;
  if (normalizedOriginalPath.contains('.')) {
      int lastDot = normalizedOriginalPath.lastIndexOf('.');
      String extension = normalizedOriginalPath.substring(lastDot);
      // Check if it's a common video extension; if not, it might be part of the name.
      if (!['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp'].contains(extension.toLowerCase())) {
          // It's not a common video extension, so don't strip it, or it's part of the name.
          // Or, we assume the original extension is what we want to try first.
      } else {
         basePathWithoutExtension = normalizedOriginalPath.substring(0, lastDot);
      }
  }
  // If basePathWithoutExtension is different from normalizedOriginalPath OR if normalizedOriginalPath had no extension
  if (basePathWithoutExtension != normalizedOriginalPath || !normalizedOriginalPath.contains('.')){
      pathsToTry.addAll([
        '$basePathWithoutExtension.mp4',
        '$basePathWithoutExtension.mov',
        '$basePathWithoutExtension.avi',
        '$basePathWithoutExtension.mkv',
        '$basePathWithoutExtension.webm',
        '$basePathWithoutExtension.3gp',
      ]);
  }


  // Remove duplicates that might have arisen
  pathsToTry = pathsToTry.toSet().toList();
  
  debugPrint("Trying video paths for '$originalPath': $pathsToTry");
  
  for (String path in pathsToTry) {
    if (await _checkVideoAssetExists(path)) {
      debugPrint("Found valid video asset path: '$path'");
      return path;
    }
  }
  
  debugPrint("No valid video asset path found for: '$originalPath'");
  return null;
}

void _prepareStepContent() async {
  _videoController?.dispose();
  _videoController = null;
  _initializeVideoPlayerFuture = null;
  _errorMessage = null; // مسح أي رسالة خطأ سابقة

  // --- بداية كود الاختبار بمسار ثابت ---
  String testVideoAssetPath = "assets/testvid/1.mp4"; // المسار داخل مجلد assets
  debugPrint("--- ATTEMPTING TO PLAY TEST VIDEO: $testVideoAssetPath ---");
  // --- نهاية كود الاختبار بمسار ثابت ---

  // لا نحتاج إلى _findValidVideoPath هنا لأننا نستخدم مسارًا ثابتًا ومباشرًا.
  // يتم استخدام _normalizeAssetPath للتأكد من إضافة "assets/" إذا لم تكن موجودة.
  String fullTestAssetPath = _normalizeAssetPath(testVideoAssetPath); 

  // التحقق مما إذا كان ملف الاختبار موجودًا بالفعل باستخدام الدالة التي لديك
  bool testAssetExists = await _checkVideoAssetExists(fullTestAssetPath);

  if (testAssetExists) {
    debugPrint("Test video asset '$fullTestAssetPath' found by _checkVideoAssetExists. Proceeding to initialize.");
    _videoController = VideoPlayerController.asset(fullTestAssetPath);

    _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
      debugPrint("TEST VIDEO controller initialized successfully for: $fullTestAssetPath");
      if (mounted) {
        setStateIfMounted(() {
          _errorMessage = null;
        });
        _videoController!.play();
        _videoController!.setLooping(true);
      }
    }).catchError((error) {
      debugPrint("Error initializing TEST VIDEO player: $error for video: $fullTestAssetPath");
      if (mounted) {
        String errorMsg = "خطأ في تحميل فيديو الاختبار: $fullTestAssetPath";
        if (error.toString().toLowerCase().contains('source error') || error.toString().toLowerCase().contains('exoplaybackexception')) {
          errorMsg = "تنسيق فيديو الاختبار غير مدعوم أو الملف تالف: ${fullTestAssetPath.split('/').last}";
        } else if (error.toString().toLowerCase().contains('filenotfoundexception')) {
          errorMsg = "ملف فيديو الاختبار غير موجود بالحزمة: ${fullTestAssetPath.split('/').last}";
        }
        setStateIfMounted(() => _errorMessage = errorMsg);
      }
    });
  } else {
    // إذا لم يتم العثور على ملف الاختبار بواسطة _checkVideoAssetExists
    debugPrint("TEST VIDEO asset '$fullTestAssetPath' NOT FOUND by _checkVideoAssetExists. Ensure it's in pubspec.yaml and the path is correct.");
    if (mounted) {
      setStateIfMounted(() {
        _errorMessage = "ملف فيديو الاختبار '$testVideoAssetPath' غير موجود. تأكد من إضافته للمشروع وتحديث pubspec.yaml.";
      });
    }
  }

  // إذا لم يتم تشغيل فيديو الاختبار لأي سبب، تأكد من أن واجهة المستخدم تعكس ذلك
  // أو يمكنك إضافة منطق للعودة إلى الفيديو الأصلي إذا فشل الاختبار.
  // حاليًا، إذا فشل الاختبار، ستبقى رسالة الخطأ الخاصة بالاختبار.

  // استدعاء setState لضمان تحديث واجهة المستخدم (مهم إذا كان _buildVideoDisplay يعتمد على _errorMessage)
  if (mounted) {
    setStateIfMounted(() {});
  }
}
  void _startStepTimer() {
    _stepTimer?.cancel();
    if (_currentSession.details.isEmpty ||
        _currentStepIndex >= _currentSession.details.length) {
      return;
    }

    final currentDetail = _currentSession.details[_currentStepIndex];
    Duration currentStepDuration;
    final bool isLastStep =
        _currentStepIndex == _currentSession.details.length - 1;

    if (currentDetail.hasVideo) {
      currentStepDuration = videoDisplayDuration;
    } else if (currentDetail.hasImage) {
      currentStepDuration = imageDisplayDuration;
    } else { // Assumed to be text if not image or video
      currentStepDuration = textDisplayDuration;
    }

    debugPrint(
        "Starting step timer for Step Index: $_currentStepIndex (ID: ${currentDetail.id}) - Type: ${currentDetail.datatypeOfContent} - Duration: ${currentStepDuration.inSeconds} sec");

    if (isLastStep) {
      _selectRandomObjectImageInfo(); // Selects info, used when building last step content
    }

    _stepTimer = Timer(currentStepDuration, () {
      debugPrint("Step Timer Finished for Step Index: $_currentStepIndex.");
      if (mounted) {
        _goToNextStep();
      }
    });
  }

  Future<bool> _completeDetailApiCall(int detailId) async {
    if (!_completedDetailIds.contains(detailId)) { 
        _completedDetailIds.add(detailId);
    }
    debugPrint(
        "Added detail ID $detailId to session completed list. Current list: $_completedDetailIds");

    setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null; // Clear general error message before API call
    });
    try {
      debugPrint("Attempting to complete session detail ID: $detailId");
      bool success = await ApiService.completeDetail(widget.jwtToken, detailId);
      if (!mounted) {
        return false;
      }
      if (success) {
        debugPrint("Successfully completed session detail ID: $detailId");
      } else {
        debugPrint("Failed to complete session detail ID: $detailId via API.");
        // Don't overwrite a video-specific error message if one exists.
        if (_errorMessage == null || !_errorMessage!.contains("الفيديو")) {
          setStateIfMounted(() => _errorMessage = "فشل حفظ التقدم.");
        }
      }
      return success;
    } catch (e) {
      debugPrint("Error completing session detail $detailId: $e");
      if (mounted) {
         if (_errorMessage == null || !_errorMessage!.contains("الفيديو")) {
            setStateIfMounted(() => _errorMessage = "خطأ في الاتصال بالخادم.");
         }
      }
      return false;
    } finally {
      if (mounted) {
        setStateIfMounted(() => _isLoading = false);
      }
    }
  }

  Future<void> _goToNextStep() async {
    if (_isLoading || _currentSession.details.isEmpty) {
      return;
    }
    // This check might be redundant if _currentStepIndex is always managed, but safe
    if (_currentStepIndex >= _currentSession.details.length) { 
      debugPrint("Attempted to go to next step, but already past the end or no details.");
      // Potentially navigate to end screen or handle as session completion
      if (mounted && _currentSession.details.isNotEmpty) { // Ensure there were details to begin with
          _navigateToTestScreen();
      }
      return;
    }

    _stepTimer?.cancel();
    _stepTimer = null;
    _videoController?.pause(); // Pause video before API call and break

    final currentDetailId = _currentSession.details[_currentStepIndex].id;
    bool success = await _completeDetailApiCall(currentDetailId);

    if (!mounted) {
      return;
    }

    if (success) {
      final nextIndex = _currentStepIndex + 1;
      final bool isSessionFinished =
          nextIndex >= _currentSession.details.length;

      debugPrint(
          "API call for session detail $currentDetailId successful. Starting break.");
      await _startBreakAndWait();
      if (!mounted) {
        return;
      }

      if (isSessionFinished) {
        _navigateToTestScreen();
      } else {
        debugPrint("Break finished. Moving to session exercise index $nextIndex.");
        setStateIfMounted(() {
          _currentStepIndex = nextIndex;
          _errorMessage = null; // Clear error from previous step
        });
        _prepareStepContent(); // Prepare content for the new step
        _startStepTimer();     // Start timer for the new step
      }
    } else {
      debugPrint(
          "API call for session detail $currentDetailId failed. Staying on current step. Error: $_errorMessage");
      // Error message should have been set by _completeDetailApiCall or _prepareStepContent
      // Optionally, restart timer for current step or allow user to retry "Next"
       _startStepTimer(); // Restart timer for current step if API fails, allowing user to see content longer.
      if (mounted && (_errorMessage != null && _errorMessage!.isNotEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _navigateToTestScreen() {
    debugPrint(
        "All session exercises completed or end of session reached! Navigating to StartTest screen.");
    debugPrint(
        "Final list of completed session detail IDs to pass: $_completedDetailIds");
    if (mounted) { 
        Navigator.pop(context, true); 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StartTest(
              previousSessionDetailIds: List<int>.from(_completedDetailIds),
            ),
          ),
        );
    }
  }

  Future<void> _startBreakAndWait() async {
    debugPrint("Navigating to BreakScreen for $breakDuration...");
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BreakScreen(duration: breakDuration),
        fullscreenDialog: true,
      ),
    );
    debugPrint("Returned from BreakScreen.");
  }

  Widget _buildStepContent() {
    if (_currentStepIndex >= _currentSession.details.length) {
       // This case should ideally be handled by _goToNextStep navigating away
       // or by the main build method showing a completion/error state.
      return _buildGenericErrorWidget("اكتملت التمارين أو لا يمكن عرض التمرين الحالي.");
    }

    final currentDetail = _currentSession.details[_currentStepIndex];
    final int totalSteps = _currentSession.details.length;
    final bool isLastStep = _currentStepIndex == totalSteps - 1;
    final bool isSecondToLastStep = (totalSteps > 1) && (_currentStepIndex == totalSteps - 2) ;


    debugPrint(
        "--- Building Content for Step Index: $_currentStepIndex (ID: ${currentDetail.id}), Type: ${currentDetail.datatypeOfContent} ---");
    debugPrint(
        "  Detail: Image=${currentDetail.hasImage}, Text=${currentDetail.hasText}, Video=${currentDetail.hasVideo}, Desc=${currentDetail.hasDesc}");
    if (currentDetail.hasImage) debugPrint("  Image Path: ${currentDetail.image}");
    if (currentDetail.hasVideo) debugPrint("  Video Path: ${currentDetail.video}");


    bool displayDoubleImage = false;
    String? imagePath1;
    String? imagePath2;
    String? text1 = currentDetail.text;
    String? text2;
    String? desc1 = currentDetail.desc;
    String? desc2;
    String? randomImageCaption;

    // typeId == 2 is 'listening and imitation' according to previous context
    // This logic implies that for typeId 2, we don't show the 'newDetail' or 'randomImage'
    bool showAdditionalContentForNonTypeId2 = _currentSession.typeId != 2; 

    if (showAdditionalContentForNonTypeId2) {
      if (isSecondToLastStep &&
          currentDetail.hasImage && currentDetail.image != null &&
          _currentSession.newDetail?.hasImage == true && _currentSession.newDetail?.image != null ) {
        displayDoubleImage = true;
        imagePath1 = localImagePathBase + currentDetail.image!;
        imagePath2 = localImagePathBase + _currentSession.newDetail!.image!;
        text2 = _currentSession.newDetail!.text;
        desc2 = _currentSession.newDetail!.desc;
        debugPrint("Displaying double image: current + newDetail");
      } else if (isLastStep &&
          currentDetail.hasImage && currentDetail.image != null &&
          _randomImageInfo != null && _randomImageInfo!.path.isNotEmpty ) {
        displayDoubleImage = true;
        imagePath1 = localImagePathBase + currentDetail.image!;
        imagePath2 = _randomImageInfo!.path; // This path is already full, like 'assets/objects/...'
        randomImageCaption = _randomImageInfo!.name;
        debugPrint("Displaying double image: current + random image '${_randomImageInfo!.name}'");
      }
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (currentDetail.hasImage && currentDetail.image != null && currentDetail.image!.isNotEmpty) ...[
                    if (displayDoubleImage && imagePath1 != null && imagePath2 != null) ...[
                      _buildDoubleImageDisplay(
                        imagePath1, 
                        imagePath2, 
                        text1,
                        text2,
                        desc1,
                        desc2,
                        randomImageCaption,
                      ),
                    ] else ...[
                      _buildSingleImageDisplay(
                        localImagePathBase + currentDetail.image!, 
                        text1,
                        // Only show description for typeId != 2 if showAdditionalContentForNonTypeId2 is true,
                        // or always show if it's not typeId 2. The logic seems to be:
                        // desc1 is shown if it exists and it's not type 2, or if it's type 2 and showAdditionalContentForNonTypeId2 is false (which means it is type 2)
                        // This simplifies to: show desc1 if it exists. The typeId check might be for something else.
                        // The current code has `showAdditionalContent ? desc1 : null`. This means desc1 is only shown if typeId != 2.
                        // Let's stick to the original logic:
                        showAdditionalContentForNonTypeId2 ? desc1 : null,
                      ),
                    ],
                  ] else if (currentDetail.hasVideo && currentDetail.video != null && currentDetail.video!.isNotEmpty) ...[
                    _buildVideoDisplay(currentDetail.video!),
                  ] else if (currentDetail.hasText && currentDetail.text != null && currentDetail.text!.isNotEmpty) ...[
                    _buildTextDisplay(currentDetail.text!),
                  ]
                  else if (!currentDetail.hasImage && !currentDetail.hasVideo && !currentDetail.hasText && _errorMessage == null) ...[
                     // If there's an _errorMessage (e.g. video failed to load), that will be shown by the main build method.
                     // This widget is for when there's genuinely no content defined for the step.
                     _buildGenericErrorWidget("لا يوجد محتوى لهذا التمرين."),
                  ] else if (_errorMessage != null && _errorMessage!.contains("الفيديو")) ... [
                    // This is a special case where _buildVideoDisplay will show its own error/loading state,
                    // but if _errorMessage is set from _prepareStepContent because validVideoPath was null,
                    // _buildVideoDisplay might not be called. So, show error here too.
                    // However, _buildVideoDisplay IS called, and it will show the error.
                    // This part could be removed if _buildVideoDisplay robustly shows errors.
                    // For now, let _buildVideoDisplay handle its own errors.
                    // The main build method will show _errorMessage if it's not related to video UI itself.
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleImageDisplay(
      String imagePath, String? text, String? desc) {
    debugPrint("Building single image display for: $imagePath");
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      elevation: 6,
      shadowColor: Colors.black.withAlpha((0.15 * 255).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      color: cardBgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, (text != null && text.isNotEmpty || desc != null && desc.isNotEmpty) ? 8 : 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(
                _normalizeAssetPath(imagePath), // Normalize just in case
                fit: BoxFit.contain,
                height: 300, 
                errorBuilder: (context, error, stackTrace) => 
                  _buildImageErrorWidget(context, error, stackTrace, imagePath),
              ),
            ),
          ),
          if (text != null && text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: (desc != null && desc.isNotEmpty) ? 4.0 : 12.0, left: 16.0, right: 16.0),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  color: cardTextColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'cairo',
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (desc != null && desc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0, top: 2.0),
              child: Text(
                desc,
                style: TextStyle(
                  fontSize: 16,
                  color: cardTextColor.withAlpha((0.9 * 255).round()), 
                  fontFamily: 'cairo',
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoDisplay(String videoPathOriginalData) {
    // Note: videoPathOriginalData is from currentDetail.video
    // _initializeVideoPlayerFuture and _videoController are set up in _prepareStepContent
    // using the resolved path from _findValidVideoPath.
    debugPrint("Building video display. Controller initialized: ${_videoController?.value.isInitialized}, Error: $_errorMessage");

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      elevation: 6,
      shadowColor: Colors.black.withAlpha((0.15 * 255).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      color: cardBgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  // Case 1: Video controller could not be created at all (e.g., validVideoPath was null, _prepareStepContent set _errorMessage)
                  // or if _videoController is null for any other reason.
                  if (_videoController == null) {
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: videoPlaceholderColor,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 48),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  _errorMessage ?? "فشل في تهيئة مشغل الفيديو.", // Show specific error if available
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Case 2: Video controller exists, but initialization is in progress
                  if (snapshot.connectionState == ConnectionState.waiting || !_videoController!.value.isInitialized && snapshot.connectionState != ConnectionState.done) {
                     return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: videoPlaceholderColor,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: loadingIndicatorColor),
                              SizedBox(height: 8),
                              Text("جاري تحميل الفيديو...",
                                  style: TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Case 3: Initialization finished, but failed (e.g., ExoPlayer source error)
                  // _errorMessage should be set by _prepareStepContent's catchError
                  if (snapshot.hasError || !_videoController!.value.isInitialized) {
                    String errorToShow = _errorMessage ?? "لا يمكن تشغيل الفيديو.";
                    if(snapshot.hasError) {
                       debugPrint("FutureBuilder snapshot error for video: ${snapshot.error}");
                       // errorToShow might be refined here based on snapshot.error if _errorMessage isn't specific enough
                    }
                     return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: videoPlaceholderColor,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 48),
                              const SizedBox(height: 8),
                              Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(errorToShow,
                                      style: const TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  
                  // Case 4: Successfully initialized
                  if (_videoController!.value.isInitialized) {
                    return AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          VideoPlayer(_videoController!),
                          _ControlsOverlay(
                              controller: _videoController!,
                              // Using a ValueKey ensures the overlay rebuilds if the controller instance changes
                              key: ValueKey(_videoController.hashCode)), 
                        ],
                      ),
                    );
                  }
                  
                  // Fallback: Should not be reached if logic above is complete
                  return const AspectRatio(
                      aspectRatio: 16 / 9,
                      child: DecoratedBox(
                          decoration: BoxDecoration(color: videoPlaceholderColor),
                          child: Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                Icon(Icons.hourglass_empty,
                                    color: Colors.white, size: 48),
                                SizedBox(height: 8),
                                Text("حالة غير معروفة للفيديو",
                                    style: TextStyle(color: Colors.white))
                              ]))));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextDisplay(String text) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      elevation: 6,
      shadowColor: Colors.black.withAlpha((0.15 * 255).round()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 25.0),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20,
                color: cardTextColor,
                fontWeight: FontWeight.w500,
                fontFamily: 'cairo',
                height: 1.6)),
      ),
    );
  }

  Widget _buildDoubleImageDisplay(
      String imagePath1,
      String imagePath2,
      String? text1,
      String? text2,
      String? desc1,
      String? desc2,
      String? randomImageCaption) {
    bool isSecondImageRandom =
        randomImageCaption != null && _randomImageInfo != null && imagePath2 == _randomImageInfo!.path;
    
    debugPrint("Building double image display. Image1: $imagePath1, Image2: $imagePath2 (Random: $isSecondImageRandom)");

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          color: cardBgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    (text1 != null && text1.isNotEmpty ||
                            desc1 != null && desc1.isNotEmpty)
                        ? 8
                        : 12),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(_normalizeAssetPath(imagePath1), // Normalize just in case
                        fit: BoxFit.contain,
                        height: 200, 
                        errorBuilder: (ctx, e, s) =>
                            _buildImageErrorWidget(ctx, e, s, imagePath1))),
              ),
              if (text1 != null && text1.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                      bottom: (desc1 != null && desc1.isNotEmpty) ? 4.0 : 12.0,
                      left: 12.0,
                      right: 12.0),
                  child: Text(text1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 17,
                          color: cardTextColor,
                          fontFamily: 'cairo',
                          height: 1.3)),
                ),
              if (desc1 != null && desc1.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 12.0, left: 12.0, right: 12.0, top: 2.0),
                  child: Text(desc1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          color: cardTextColor.withAlpha((0.85 * 255).round()), 
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.normal,
                          height: 1.2)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          color: cardBgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    (text2 != null && text2.isNotEmpty ||
                            desc2 != null && desc2.isNotEmpty ||
                            isSecondImageRandom)
                        ? 8
                        : 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(_normalizeAssetPath(imagePath2), // Normalize just in case
                      fit: BoxFit.contain,
                      height: 200, 
                      errorBuilder: (ctx, e, s) => _buildImageErrorWidget( 
                          ctx, e, s,
                          isSecondImageRandom
                              ? "صورة عشوائية ($imagePath2)"
                              : imagePath2)),
                ),
              ),
              if (text2 != null && text2.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                      bottom: (desc2 != null && desc2.isNotEmpty ||
                              isSecondImageRandom)
                          ? 4.0
                          : 12.0,
                      left: 12.0,
                      right: 12.0),
                  child: Text(text2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 17,
                          color: cardTextColor,
                          fontFamily: 'cairo',
                          height: 1.3)),
                ),
              if (desc2 != null && desc2.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                      bottom: isSecondImageRandom ? 4.0 : 12.0,
                      left: 12.0,
                      right: 12.0,
                      top: 2.0),
                  child: Text(desc2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          color: cardTextColor.withAlpha((0.85 * 255).round()),
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.normal,
                          height: 1.2)),
                ),
              if (isSecondImageRandom && randomImageCaption != null)
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 12.0, left: 12.0, right: 12.0, top: 4.0),
                  child: Text(randomImageCaption,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          color: cardTextColor.withAlpha((0.9 * 255).round()),
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.w500,
                          height: 1.3)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericErrorWidget(String message) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange.shade100)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.warning_amber_rounded,
            size: 45, color: Colors.orangeAccent),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.orange)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    // isVideoLoading is true if a video is actively being initialized by the FutureBuilder
    bool isVideoLoading = _videoController != null &&
        _initializeVideoPlayerFuture != null && // Ensure future exists
        ModalRoute.of(context)?.isCurrent == true && // Only consider loading if this screen is current
        // Check snapshot state if possible, but FutureBuilder handles this.
        // More directly, check if controller is not yet initialized but we expect it to be.
        !_videoController!.value.isInitialized;


    if ((_isLoading && !isVideoLoading) || (_isLoading && _videoController == null)) {
       // Show general loading indicator if _isLoading is true,
       // UNLESS it's specifically for video loading which FutureBuilder handles.
       // If _videoController is null, then it's not video loading, so general loader is fine.
      bodyContent = const Center(
          child: CircularProgressIndicator(color: loadingIndicatorColor));
    } else if (_errorMessage != null && _currentSession.details.isEmpty) {
      // Error message when there are no details at all (e.g., initial load failed)
      bodyContent = Center(child: _buildGenericErrorWidget(_errorMessage!));
    } else if (_currentSession.details.isEmpty) {
      // No details, and no specific error message (e.g. session legitimately empty)
      bodyContent = Center(
          child: _buildGenericErrorWidget(
              "لا توجد تمارين متاحة في هذه الجلسة حاليًا."));
    } else if (_currentStepIndex >= _currentSession.details.length) {
      // Should have navigated away, but as a fallback:
      bodyContent = Center(
          child: _buildGenericErrorWidget(
              "اكتملت التمارين أو حدث خطأ غير متوقع في تدفق الجلسة."));
    } else {
      // Normal content display
      bodyContent = Column(
        children: [
          if (_currentSession.details.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                    value: (_currentStepIndex + 1) /
                        _currentSession.details.length,
                    minHeight: 10,
                    backgroundColor: progressBarBgColor,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(progressBarColor)),
              ),
            ),
          Expanded(child: _buildStepContent()),
          // Display error messages that are not handled within _buildStepContent (e.g. API errors)
          // Video errors are typically shown within _buildVideoDisplay.
          if (_errorMessage != null && 
              !_errorMessage!.contains("الفيديو") && // Don't show if it's a video error handled by _buildVideoDisplay
              !_errorMessage!.contains("ملف الفيديو") // Also for specific video file not found message
              ) 
              Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(_errorMessage!,
                      style: const TextStyle(
                          color: errorTextColor, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center))
           else 
             const SizedBox(height: 20), // Maintain spacing if no error

          Padding( 
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 25.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || isVideoLoading) // Disable button if general loading or video specifically is loading
                      ? null
                      : () {
                          debugPrint("Next button pressed. Current step timer will be cancelled by _goToNextStep.");
                          // _stepTimer?.cancel(); // _goToNextStep already cancels it.
                          _goToNextStep();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonBgColor,
                    foregroundColor: buttonFgColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'cairo'),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0)),
                    elevation: 4,
                    shadowColor: Colors.black.withAlpha((0.2 * 255).round()),
                    disabledBackgroundColor: buttonBgColor.withAlpha((0.7 * 255).round()),
                    disabledForegroundColor: buttonFgColor.withAlpha((0.5 * 255).round()),
                  ),
                  child: (_isLoading && !isVideoLoading) // Show spinner in button only for non-video loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  buttonFgColor)))
                      : const Text('التالي'),
                ),
              ),
            ),
        ],
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: screenBgColor,
        appBar: AppBar(
          title: Text(
            _currentSession.title ?? 'تمارين الجلسة',
            style: const TextStyle(
                color: appBarElementsColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'cairo'),
          ),
          backgroundColor: screenBgColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: appBarElementsColor),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                size: 24, color: appBarElementsColor),
            tooltip: 'العودة',
            onPressed: () {
              debugPrint("Back button pressed. Popping context with 'false'.");
              Navigator.pop(context, false); // Indicate session was not completed.
            },
          ),
        ),
        body: bodyContent,
      ),
    );
  }
}

class _ControlsOverlay extends StatefulWidget {
  const _ControlsOverlay({required this.controller, super.key});
  final VideoPlayerController controller;
  @override
  State<_ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  // Listener is added to rebuild the overlay when play/pause state changes.
  // Using a ValueKey on the _ControlsOverlay instance in the parent
  // can also help ensure it rebuilds if the controller itself changes.
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    // This is called for many updates, including position.
    // We only need to rebuild if isPlaying or isInitialized changes for the play/pause icon.
    // However, VideoProgressIndicator relies on frequent updates.
    if (mounted) {
      setState(() {}); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the controller is initialized before trying to access value.isPlaying
    if (!widget.controller.value.isInitialized) {
      return const SizedBox.shrink(); // Or a loading indicator if preferred
    }

    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: widget.controller.value.isPlaying
              ? const SizedBox.shrink() // Don't show play button if playing
              : DecoratedBox( 
                  key: const ValueKey<String>('playButton'), // Key for AnimatedSwitcher
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(30)), // Added borderRadius
                  child: const Center(
                      child: Icon(Icons.play_arrow,
                          color: Colors.white,
                          size: 70.0,
                          semanticLabel: 'Play'))),
        ),
        GestureDetector(
          onTap: () {
            if (widget.controller.value.isInitialized) { 
              if (widget.controller.value.isPlaying) {
                widget.controller.pause();
              } else {
                widget.controller.play();
              }
              // setState is called by the listener _onControllerUpdate
            }
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: VideoProgressIndicator(
              widget.controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor:
                    _SessionDetailsScreenState.buttonFgColor.withAlpha((0.8 * 255).round()), 
                bufferedColor: Colors.white.withAlpha((0.4 * 255).round()), 
                backgroundColor: Colors.white.withAlpha((0.2 * 255).round()), 
              ),
            ),
          ),
        ),
      ],
    );
  }
}