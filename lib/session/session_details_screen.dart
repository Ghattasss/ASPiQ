import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'models/session_model.dart'; // تأكد من المسار الصحيح
import '../services/Api_services.dart'; // تأكد من المسار الصحيح
import 'break.dart'; // تأكد من المسار الصحيح
// import 'timetest.dart'; // إذا كنت ستستخدمها، أو StartTest بدلاً منها
import 'timetest.dart'; // <-- لاستخدام شاشة StartTest الجديدة
import 'dart:math';

class _RandomImageInfo {
  final String path;
  final String name;
  _RandomImageInfo(this.path, this.name);
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

  _RandomImageInfo? _randomImageInfo;
  List<_RandomImageInfo> _objectImageInfos = [];
  List<int> _completedDetailIds = []; // قائمة لتخزين IDs الجلسة المكتملة

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
  static Color progressBarBgColor = Colors.white.withOpacity(0.3);
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
        if (mounted) setState(() {});
      });
    } else {
      print("--- Session Details Screen Initialized ---");
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
    print("--- Session Details Screen Disposed ---");
    super.dispose();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _printSessionDetails() {
    print("--- Available Exercise Details (from details list) ---");
    for (int i = 0; i < _currentSession.details.length; i++) {
      final detail = _currentSession.details[i];
      print(
          "Exercise $i: ID=${detail.id}, Type=${detail.datatypeOfContent}, Image=${detail.hasImage}, Text=${detail.hasText}, Video=${detail.hasVideo}, Desc=${detail.hasDesc}");
    }
    if (_currentSession.newDetail != null) {
      print(
          "--- New Detail Data: ID=${_currentSession.newDetail!.id}, Type=${_currentSession.newDetail!.datatypeOfContent}, Image=${_currentSession.newDetail!.hasImage}, Text=${_currentSession.newDetail!.hasText}, Video=${_currentSession.newDetail!.hasVideo}, Desc=${_currentSession.newDetail!.hasDesc}");
    }
    print("------------------------------------------------------");
  }

  Future<void> _loadObjectImageInfos() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      _objectImageInfos = manifestMap.keys
          .where((String key) =>
              key.startsWith(objectsFolderPath) &&
              key != objectsFolderPath &&
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
        return _RandomImageInfo(path, nameWithoutExtension);
      }).toList();
      print(
          "Loaded ${_objectImageInfos.length} image infos from $objectsFolderPath");
      if (_objectImageInfos.isEmpty) {
        print("Warning: No images found in $objectsFolderPath.");
      }
    } catch (e) {
      print("Error loading object image infos: $e");
    }
  }

  void _selectRandomObjectImageInfo() {
    if (_objectImageInfos.isNotEmpty) {
      final random = Random();
      _randomImageInfo =
          _objectImageInfos[random.nextInt(_objectImageInfos.length)];
      print(
          "Selected random object: Path=${_randomImageInfo!.path}, Name=${_randomImageInfo!.name}");
    } else {
      print("Warning: Cannot select random image, info list is empty.");
      _randomImageInfo = null;
    }
  }

  void _prepareStepContent() {
    _videoController?.dispose();
    _videoController = null;
    _initializeVideoPlayerFuture = null;

    if (_currentSession.details.isEmpty ||
        _currentStepIndex >= _currentSession.details.length) return;

    final currentDetail = _currentSession.details[_currentStepIndex];

    if (currentDetail.hasVideo && currentDetail.video != null) {
      Uri? videoUri = Uri.tryParse(currentDetail.video!);
      if (videoUri != null &&
          (videoUri.isScheme('HTTP') || videoUri.isScheme('HTTPS'))) {
        _videoController = VideoPlayerController.networkUrl(videoUri);
      } else if (currentDetail.video!.startsWith('assets/')) {
        print("Attempting to load video from asset: ${currentDetail.video!}");
        _videoController = VideoPlayerController.asset(currentDetail.video!);
      } else {
        print(
            "Unsupported video URI scheme or invalid local path: ${currentDetail.video}");
        _errorMessage = "مسار الفيديو غير صالح: ${currentDetail.video}";
        return;
      }

      _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
        if (mounted) {
          setStateIfMounted(() {});
          _videoController!.play();
          _videoController!.setLooping(true);
        }
      }).catchError((error) {
        print(
            "Error initializing video player: $error for video: ${currentDetail.video}");
        if (mounted) {
          setStateIfMounted(() =>
              _errorMessage = "خطأ في تحميل الفيديو: ${currentDetail.video}");
        }
      });
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
    } else {
      currentStepDuration = textDisplayDuration;
    }

    print(
        "Starting step timer for Step Index: $_currentStepIndex (ID: ${currentDetail.id}) - Duration: ${currentStepDuration.inSeconds} sec");

    if (isLastStep) {
      _selectRandomObjectImageInfo();
    }

    _stepTimer = Timer(currentStepDuration, () {
      print("Step Timer Finished for Step Index: $_currentStepIndex.");
      if (mounted) {
        _goToNextStep();
      }
    });
  }

  Future<bool> _completeDetailApiCall(int detailId) async {
    _completedDetailIds.add(detailId); // إضافة ID الجلسة المكتمل
    print(
        "Added detail ID $detailId to session completed list. Current list: $_completedDetailIds");

    setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      print("Attempting to complete session detail ID: $detailId");
      bool success = await ApiService.completeDetail(widget.jwtToken, detailId);
      if (!mounted) return false;
      if (success) {
        print("Successfully completed session detail ID: $detailId");
      } else {
        print("Failed to complete session detail ID: $detailId via API.");
        setStateIfMounted(() => _errorMessage = "فشل حفظ التقدم.");
      }
      return success;
    } catch (e) {
      print("Error completing session detail $detailId: $e");
      if (mounted) {
        setStateIfMounted(() => _errorMessage = "خطأ في الاتصال بالخادم.");
      }
      return false;
    } finally {
      if (mounted) {
        setStateIfMounted(() => _isLoading = false);
      }
    }
  }

  Future<void> _goToNextStep() async {
    if (_isLoading || _currentSession.details.isEmpty) return;
    if (_currentStepIndex >= _currentSession.details.length) return;

    _stepTimer?.cancel();
    _stepTimer = null;
    _videoController?.pause();

    final currentDetailId = _currentSession.details[_currentStepIndex].id;
    bool success = await _completeDetailApiCall(currentDetailId);

    if (!mounted) return;

    if (success) {
      final nextIndex = _currentStepIndex + 1;
      final bool isSessionFinished =
          nextIndex >= _currentSession.details.length;

      print(
          "API call for session detail $currentDetailId successful. Starting break.");
      await _startBreakAndWait();
      if (!mounted) return;

      if (isSessionFinished) {
        print(
            "All session exercises completed! Navigating to StartTest screen.");
        print(
            "Final list of completed session detail IDs to pass: $_completedDetailIds");
        Navigator.pop(context, true); // إغلاق الشاشة الحالية

        // --- الانتقال إلى StartTest مع تمرير القائمة ---
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StartTest(
              previousSessionDetailIds: _completedDetailIds, // تمرير القائمة
            ),
          ),
        );
        // --- نهاية الانتقال ---
      } else {
        print("Break finished. Moving to session exercise index $nextIndex.");
        setStateIfMounted(() {
          _currentStepIndex = nextIndex;
          _errorMessage = null;
        });
        _prepareStepContent();
        _startStepTimer();
      }
    } else {
      print(
          "API call for session detail $currentDetailId failed. Staying on current step.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'فشل حفظ التقدم.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startBreakAndWait() async {
    print("Navigating to BreakScreen for $breakDuration...");
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BreakScreen(duration: breakDuration),
        fullscreenDialog: true,
      ),
    );
    print("Returned from BreakScreen.");
  }

  Widget _buildStepContent() {
    if (_currentStepIndex >= _currentSession.details.length) {
      return _buildGenericErrorWidget("خطأ في عرض التمرين.");
    }

    final currentDetail = _currentSession.details[_currentStepIndex];
    final int totalSteps = _currentSession.details.length;
    final bool isLastStep = _currentStepIndex == totalSteps - 1;
    final bool isSecondToLastStep = _currentStepIndex == totalSteps - 2;

    print(
        "--- Building Content for Step Index: $_currentStepIndex (ID: ${currentDetail.id}) ---");

    bool displayDoubleImage = false;
    String? imagePath1;
    String? imagePath2;
    String? text1 = currentDetail.text;
    String? text2;
    String? desc1 = currentDetail.desc;
    String? desc2;
    String? randomImageCaption;

    // Check if typeId is 2 to determine whether to show additional content
    bool showAdditionalContent = _currentSession.typeId != 2;

    if (showAdditionalContent) {
      if (isSecondToLastStep &&
          currentDetail.hasImage &&
          _currentSession.newDetail?.hasImage == true) {
        displayDoubleImage = true;
        imagePath1 = localImagePathBase + currentDetail.image!;
        imagePath2 = localImagePathBase + _currentSession.newDetail!.image!;
        text2 = _currentSession.newDetail!.text;
        desc2 = _currentSession.newDetail!.desc;
      } else if (isLastStep &&
          currentDetail.hasImage &&
          _randomImageInfo != null) {
        displayDoubleImage = true;
        imagePath1 = localImagePathBase + currentDetail.image!;
        imagePath2 = _randomImageInfo!.path;
        randomImageCaption = _randomImageInfo!.name;
      }
    }

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: LinearProgressIndicator(
            value: (_currentStepIndex + 1) / totalSteps,
            backgroundColor: progressBarBgColor,
            valueColor: const AlwaysStoppedAnimation<Color>(progressBarColor),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (currentDetail.hasImage) ...[
                    if (displayDoubleImage) ...[
                      _buildDoubleImageDisplay(
                        imagePath1!,
                        imagePath2!,
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
                        showAdditionalContent ? desc1 : null,
                      ),
                    ],
                  ] else if (currentDetail.hasVideo) ...[
                    _buildVideoDisplay(currentDetail.video!),
                  ] else if (currentDetail.hasText) ...[
                    _buildTextDisplay(text1!),
                  ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.contain,
          height: 300,
        ),
        if (text != null && text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: cardTextColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (desc != null && desc.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 16,
              color: cardTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildVideoDisplay(String videoPath) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.15),
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
                  if (_videoController == null ||
                      !_videoController!.value.isInitialized &&
                          snapshot.connectionState != ConnectionState.done) {
                    String displayMessage = "جاري تحميل الفيديو...";
                    IconData displayIcon = Icons.videocam_off_outlined;
                    if (_errorMessage != null &&
                        _errorMessage!.contains("الفيديو")) {
                      displayMessage = _errorMessage!;
                      displayIcon = Icons.error_outline;
                    } else if (snapshot.connectionState ==
                            ConnectionState.done &&
                        (_videoController == null ||
                            !_videoController!.value.isInitialized)) {
                      displayMessage = "لا يمكن تشغيل الفيديو.";
                      displayIcon = Icons.error_outline;
                    }
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: videoPlaceholderColor,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(displayIcon, color: Colors.white, size: 48),
                              const SizedBox(height: 8),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(displayMessage,
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center)),
                              if (snapshot.connectionState !=
                                      ConnectionState.done &&
                                  _videoController != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: CircularProgressIndicator(
                                        color: loadingIndicatorColor)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  if (_videoController!.value.isInitialized) {
                    return AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          VideoPlayer(_videoController!),
                          _ControlsOverlay(
                              controller: _videoController!,
                              key: ValueKey(_videoController!.textureId)),
                        ],
                      ),
                    );
                  }
                  return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                          color: videoPlaceholderColor,
                          child: const Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                Icon(Icons.error_outline,
                                    color: Colors.white, size: 48),
                                SizedBox(height: 8),
                                Text("خطأ غير متوقع في الفيديو",
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
      shadowColor: Colors.black.withOpacity(0.15),
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
        randomImageCaption != null && imagePath2 == _randomImageInfo?.path;
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
                    child: Image.asset(imagePath1,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, e, s) =>
                            _buildImageErrorWidget(imagePath1))),
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
                          color: cardTextColor.withOpacity(0.85),
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
                  child: Image.asset(imagePath2,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, e, s) => _buildImageErrorWidget(
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
                          color: cardTextColor.withOpacity(0.85),
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
                          color: cardTextColor.withOpacity(0.9),
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

  Widget _buildImageErrorWidget(String? attemptedPath) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade100)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.broken_image_outlined,
            size: 40, color: Colors.redAccent),
        const SizedBox(height: 10),
        const Text('خطأ في تحميل الصورة',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
        const SizedBox(height: 6),
        Text('(المسار: ${attemptedPath ?? "غير متوفر"})',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 10)),
      ]),
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
    bool isVideoLoading = _videoController != null &&
        !_videoController!.value.isInitialized &&
        _initializeVideoPlayerFuture != null &&
        ModalRoute.of(context)?.isCurrent == true;

    if ((_isLoading && !isVideoLoading) ||
        (_isLoading && _videoController == null)) {
      bodyContent = const Center(
          child: CircularProgressIndicator(color: loadingIndicatorColor));
    } else if (_errorMessage != null && _currentSession.details.isEmpty) {
      bodyContent = Center(child: _buildGenericErrorWidget(_errorMessage!));
    } else if (_currentSession.details.isEmpty) {
      bodyContent = Center(
          child: _buildGenericErrorWidget(
              "لا توجد تمارين متاحة في هذه الجلسة حاليًا."));
    } else if (_currentStepIndex >= _currentSession.details.length) {
      bodyContent = Center(
          child: _buildGenericErrorWidget(
              "اكتملت التمارين أو حدث خطأ غير متوقع."));
    } else {
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
          _errorMessage != null &&
                  _errorMessage!.contains('فشل حفظ التقدم') &&
                  !(_errorMessage!.contains("الفيديو"))
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(_errorMessage!,
                      style: const TextStyle(
                          color: errorTextColor, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 25.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || isVideoLoading)
                          ? null
                          : () {
                              print("Next button pressed.");
                              _stepTimer?.cancel();
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
                        shadowColor: Colors.black.withOpacity(0.2),
                        disabledBackgroundColor: buttonBgColor.withOpacity(0.7),
                        disabledForegroundColor: buttonFgColor.withOpacity(0.5),
                      ),
                      child: (_isLoading && !isVideoLoading)
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
              print("Back button pressed. Popping context with 'false'.");
              Navigator.pop(context, false);
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
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: widget.controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                      child: Icon(Icons.play_arrow,
                          color: Colors.white,
                          size: 70.0,
                          semanticLabel: 'Play'))),
        ),
        GestureDetector(
          onTap: () {
            if (widget.controller.value.isPlaying) {
              widget.controller.pause();
            } else {
              widget.controller.play();
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
                    _SessionDetailsScreenState.buttonFgColor.withOpacity(0.8),
                bufferedColor: Colors.white.withOpacity(0.4),
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
