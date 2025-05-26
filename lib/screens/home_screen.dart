/// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myfinalpro/screens/start_test_screen.dart';
//import 'package:myfinalpro/monthly_test/exercise_flow_screen.dart';
import 'package:myfinalpro/screens/skills.dart';
import 'package:myfinalpro/widget/side_bar_menu.dart.dart'; // تأكد من اسم الملف
import 'package:myfinalpro/widgets/Notifictionicon.dart';
import 'package:myfinalpro/services/Api_services.dart';
import 'package:myfinalpro/login/login_view.dart';
import 'package:myfinalpro/session/session_intro_screen.dart';
import 'package:myfinalpro/session/models/session_model.dart';
import 'package:myfinalpro/emotion/sequential_session_screen.dart'; // افترضت أن هذا موجود
import 'package:myfinalpro/test3months/test_group_model.dart';
import 'package:myfinalpro/test3months/group_test_manager_screen.dart';
import 'package:myfinalpro/emotion/training_sessions_screen_v2.dart';
import 'package:myfinalpro/models/notification_item.dart' as notif_model;
import 'package:myfinalpro/services/notification_manager.dart';

// --- (اختياري) استيراد لخدمة الإشعارات المحلية ---
// import '../services/local_notification_service.dart'; // تأكد من المسار الصحيح

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSessionAvailable = false;
  bool isSessionInProgressOrCoolingDown = true;
  Duration remainingTime = Duration.zero;
  Timer? cooldownTimer;
  bool _isLoading = true;
  String? _errorMessage;
  String? _jwtToken;
  Session? _nextSessionData;
  bool _isFetchingTestGroup = false;

  final GlobalKey<NotificationIconState> _notificationIconKey = GlobalKey<NotificationIconState>();
  // static const sessionCooldownDuration = Duration(minutes: 1); // للتجربة
  static const sessionCooldownDuration = Duration(seconds:10); // مثال: ساعة واحدة

  // --- (اختياري) ---
  // late final LocalNotificationService _localNotificationService;

  @override
  void initState() {
    super.initState();
    debugPrint("--- HomeScreen initState START ---");
    // --- (اختياري) ---
    // _localNotificationService = LocalNotificationService();
    // LocalNotificationService.initialize(); // يجب أن تكون هذه دالة static أو يتم تهيئة الكائن هنا
    _loadTokenAndInitialData();
    debugPrint("--- HomeScreen initState END ---");
  }

  @override
  void dispose() {
    debugPrint("--- HomeScreen dispose ---");
    cooldownTimer?.cancel();
    super.dispose();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _updateSessionNotifications() async {
    if (!mounted) return;
    await NotificationManager.clearSessionStatusNotifications();
    final prefs = await SharedPreferences.getInstance();
    final lastSessionTimestamp = prefs.getInt('lastSessionStartTime') ?? 0;

    if (isSessionInProgressOrCoolingDown && lastSessionTimestamp > 0) {
      await NotificationManager.addOrUpdateNotification(notif_model.NotificationItem(
        id: 'session_status_ended_${lastSessionTimestamp}',
        title: "انتهت الجلسة ${notif_model.formatTimeAgo(DateTime.fromMillisecondsSinceEpoch(lastSessionTimestamp))}",
        createdAt: DateTime.now(),
        type: notif_model.NotificationType.sessionEnded,
      ));
      if (remainingTime.inSeconds > 0) {
        await NotificationManager.addOrUpdateNotification(notif_model.NotificationItem(
          id: 'session_status_upcoming_${lastSessionTimestamp}',
          title: "الجلسة القادمة بعد ${_convertToArabicNumbers(formatDuration(remainingTime))}",
          createdAt: DateTime.now(),
          type: notif_model.NotificationType.sessionUpcoming,
        ));
      }
    } else if (isSessionAvailable && _nextSessionData != null && _nextSessionData!.typeId != 99) {
      await NotificationManager.addOrUpdateNotification(notif_model.NotificationItem(
        id: 'session_status_ready_${_nextSessionData!.id}',
        title: "حان وقت الجلسة! (${_nextSessionData?.title ?? 'غير محدد'})",
        createdAt: DateTime.now(),
        type: notif_model.NotificationType.sessionReady,
      ));
    }
    _notificationIconKey.currentState?.refreshNotifications();
  }

  Future<void> _loadTokenAndInitialData() async {
    if (!mounted) return;
    if (!_isLoading && !_isFetchingTestGroup && (cooldownTimer == null || !cooldownTimer!.isActive)) {
      setStateIfMounted(() => _isLoading = true);
    }
    setStateIfMounted(() => _errorMessage = null);

    try {
      final prefs = await SharedPreferences.getInstance();
      _jwtToken = prefs.getString('auth_token');
      if (!mounted) return;

      if (_jwtToken == null || _jwtToken!.isEmpty) {
        debugPrint("HomeScreen: Token not found. Redirecting to Login.");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (context) => const LoginView()), (route) => false);
          }
        });
        if (mounted) setStateIfMounted(() => _isLoading = false);
        return;
      }
      debugPrint("HomeScreen: Token loaded successfully.");
      await _loadSessionCooldownDataFromPrefs(prefs);
    } catch (e, s) {
      debugPrint("HomeScreen: Error during initial data load: $e\n$s");
      if (mounted) {
        setStateIfMounted(() {
          _errorMessage = "حدث خطأ أثناء تحميل البيانات الأولية.";
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && !_isFetchingTestGroup && (cooldownTimer == null || !cooldownTimer!.isActive || !isSessionInProgressOrCoolingDown)) {
        setStateIfMounted(() => _isLoading = false);
      }
      await _updateSessionNotifications();
      debugPrint("HomeScreen: Load finished. Loading: $_isLoading, ErrorMsg: $_errorMessage, SessionAvailable: $isSessionAvailable, CoolingDown: $isSessionInProgressOrCoolingDown, FetchingGroup: $_isFetchingTestGroup");
    }
  }

  Future<void> _loadSessionCooldownDataFromPrefs(SharedPreferences prefs) async {
    // (الكود كما هو من الردود السابقة)
    final lastSessionTimestamp = prefs.getInt('lastSessionStartTime') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (lastSessionTimestamp == 0) {
      debugPrint("HomeScreen: Cooldown not active (first time/reset). Fetching.");
      if (mounted) setStateIfMounted(() {isSessionInProgressOrCoolingDown = false; remainingTime = Duration.zero;});
      cooldownTimer?.cancel();
      await _fetchNextSessionDataFromApi(); return;
    }
    final elapsedTime = currentTime - lastSessionTimestamp;
    if (elapsedTime >= sessionCooldownDuration.inMilliseconds) {
      debugPrint("HomeScreen: Cooldown completed. Fetching.");
       if (mounted) setStateIfMounted(() {isSessionInProgressOrCoolingDown = false; remainingTime = Duration.zero; isSessionAvailable = false; _nextSessionData = null;});
      cooldownTimer?.cancel();
      await _fetchNextSessionDataFromApi();
    } else {
      final remainingMs = sessionCooldownDuration.inMilliseconds - elapsedTime;
      debugPrint("HomeScreen: Cooldown active. Remaining: ${Duration(milliseconds: remainingMs)}");
      if (mounted) {
        if (isSessionAvailable) isSessionAvailable = false; if (_nextSessionData != null) _nextSessionData = null;
        setStateIfMounted(() {isSessionInProgressOrCoolingDown = true; remainingTime = Duration(milliseconds: remainingMs);});
      }
      _startUiUpdateTimer(lastSessionTimestamp);
    }
  }

  Future<void> _fetchNextSessionDataFromApi() async {
    // (الكود كما هو من الردود السابقة، مع التأكد من استدعاء _checkAndGenerateTestNotificationsBasedOnSessionObject)
    if (isSessionInProgressOrCoolingDown && cooldownTimer != null && cooldownTimer!.isActive) { debugPrint("HomeScreen: Cooldown active via timer, skipping fetch."); return; }
    if (_jwtToken == null || _jwtToken!.isEmpty) { if (mounted) setStateIfMounted(() => _errorMessage = "Token مفقود."); if (mounted && !_isFetchingTestGroup) setStateIfMounted(() => _isLoading = false); return; }
    if (!_isLoading && !_isFetchingTestGroup) setStateIfMounted(() => _isLoading = true);
    try {
      _nextSessionData = await ApiService.getNextPendingSession(_jwtToken!);
      if (!mounted) return;
      if (_nextSessionData != null) {
        debugPrint("HomeScreen: Fetched _nextSessionData: ID=${_nextSessionData!.sessionId}, Title='${_nextSessionData!.title}', TypeID=${_nextSessionData!.typeId}, Attrs=${_nextSessionData!.attributes}");
        await _checkAndGenerateTestNotificationsBasedOnSessionObject(_nextSessionData!); // <--- الاستدعاء هنا
        if (_nextSessionData!.typeId != 99 && _nextSessionData!.title != null && _nextSessionData!.title != "رسالة نظام" && _nextSessionData!.title != "تنبيه هام") {
          setStateIfMounted(() {isSessionAvailable = true; _errorMessage = null;});
        } else {
          setStateIfMounted(() { isSessionAvailable = false;
            if (_errorMessage == null && (_nextSessionData!.attributes == null || _nextSessionData!.attributes!.isEmpty || (_nextSessionData!.attributes!['monthly_test_message'] == null && _nextSessionData!.attributes!['three_month_test_message'] == null))) {
                 _errorMessage = _nextSessionData!.description ?? _nextSessionData!.title ?? "لا توجد مهام جديدة.";
            } else if (_nextSessionData!.attributes != null && (_nextSessionData!.attributes!['monthly_test_message'] != null || _nextSessionData!.attributes!['three_month_test_message'] != null)) {
                 _errorMessage = null;
            }});
        }
      } else {
        setStateIfMounted(() {isSessionAvailable = false; if (_errorMessage == null) _errorMessage = "اكتملت الخطة التدريبية.";});
      }
    } on Exception catch (e) {
      if (!mounted) return; String errorMsg = "خطأ جلب الجلسة.";
      if (e.toString().contains('Unauthorized')) { errorMsg = "انتهت صلاحية الدخول."; WidgetsBinding.instance.addPostFrameCallback((_){ if(mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>const LoginView()), (route)=>false);});}
      else if (e.toString().toLowerCase().contains('network') || e.toString().toLowerCase().contains('socket')) { errorMsg = "خطأ في الشبكة.";}
      else if (e.toString().toLowerCase().contains('timeout')) { errorMsg = "انتهت مهلة الطلب.";}
      debugPrint("HomeScreen _fetchNextSessionDataFromApi Error: $e");
      setStateIfMounted(() {_nextSessionData = null; isSessionAvailable = false; _errorMessage = errorMsg;});
    } finally {
      if (mounted && !_isFetchingTestGroup) setStateIfMounted(() => _isLoading = false);
      await _updateSessionNotifications();
    }
  }

  Future<void> _checkAndGenerateTestNotificationsBasedOnSessionObject(Session sessionData) async {
    // (الكود كما هو من الردود السابقة، مع أماكن تعليق لاستدعاء LocalNotificationService)
    if (!mounted) return; bool inAppNotificationCreated = false;
    final monthlyTestMessage = sessionData.attributes?['monthly_test_message'] as String?;
    if (monthlyTestMessage != null && monthlyTestMessage.isNotEmpty) {
      bool alreadySent = await NotificationManager.isMonthlyTestNotificationSent();
      if (!alreadySent) {
        final String id = 'monthly_test_available_${sessionData.attributes?['monthly_test_session_id'] ?? sessionData.sessionId ?? DateTime.now().millisecondsSinceEpoch}';
        await NotificationManager.addOrUpdateNotification(notif_model.NotificationItem(id:id, title:monthlyTestMessage, createdAt:DateTime.now(), type:notif_model.NotificationType.monthlyTestAvailable));
        await NotificationManager.setMonthlyTestNotificationSent(true); inAppNotificationCreated = true;
        debugPrint("HomeScreen: Monthly Test IN-APP Notification CREATED: $monthlyTestMessage");
        // await LocalNotificationService.showNotification(id: 101, title: "تذكير باختبار شهري", body: monthlyTestMessage, payload: 'monthly_test_route');
      } else { debugPrint("HomeScreen: Monthly Test Notification was ALREADY SENT."); }
    }
    final threeMonthTestMessage = sessionData.attributes?['three_month_test_message'] as String?;
    if (threeMonthTestMessage != null && threeMonthTestMessage.isNotEmpty) {
      bool alreadySent = await NotificationManager.isThreeMonthTestNotificationSent();
      if (!alreadySent) {
        final String id = '3_month_test_available_${DateTime.now().millisecondsSinceEpoch}';
        await NotificationManager.addOrUpdateNotification(notif_model.NotificationItem(id:id, title:threeMonthTestMessage, createdAt:DateTime.now(), type:notif_model.NotificationType.threeMonthTestAvailable));
        await NotificationManager.setThreeMonthTestNotificationSent(true); inAppNotificationCreated = true;
        debugPrint("HomeScreen: 3-Month Test IN-APP Notification CREATED: $threeMonthTestMessage");
        // await LocalNotificationService.showNotification(id: 102, title: "تذكير باختبار تطوري", body: threeMonthTestMessage, payload: 'three_month_test_route');
      } else { debugPrint("HomeScreen: 3-Month Test Notification was ALREADY SENT."); }
    }
    if (inAppNotificationCreated) _notificationIconKey.currentState?.refreshNotifications();
  }

  void _startUiUpdateTimer(int sessionStartTimeReferenceMillis) {
    // (الكود كما هو من الردود السابقة)
    cooldownTimer?.cancel();
    updateRemainingTimeCallback() async {
      if (!mounted) { cooldownTimer?.cancel(); return; }
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final elapsedMillis = nowMillis - sessionStartTimeReferenceMillis;
      if (elapsedMillis >= sessionCooldownDuration.inMilliseconds) {
        cooldownTimer?.cancel();
        if (mounted) {
          setStateIfMounted(() { isSessionInProgressOrCoolingDown = false; remainingTime = Duration.zero; isSessionAvailable = false; _nextSessionData = null; });
        }
        await _fetchNextSessionDataFromApi();
      } else {
        final newRemainingTime = sessionCooldownDuration - Duration(milliseconds: elapsedMillis);
        if (mounted && isSessionInProgressOrCoolingDown) {
           if (remainingTime.inSeconds != newRemainingTime.inSeconds) {
             setStateIfMounted(() => remainingTime = newRemainingTime);
           }
        } else if (mounted && !isSessionInProgressOrCoolingDown) {
            cooldownTimer?.cancel();
        }
      }
      if (mounted) await _updateSessionNotifications();
    }
    if (isSessionInProgressOrCoolingDown) {
      updateRemainingTimeCallback();
      cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) => updateRemainingTimeCallback());
    }
  }

  String formatDuration(Duration duration) { /* ... (نفس الكود) ... */ duration = duration.isNegative ? Duration.zero : duration; String td(int n)=>n.toString().padLeft(2,'0'); final h=td(duration.inHours); final m=td(duration.inMinutes.remainder(60)); final s=td(duration.inSeconds.remainder(60)); return '$h:$m:$s'; }
  String _convertToArabicNumbers(String number) { /* ... (نفس الكود) ... */ const e=['0','1','2','3','4','5','6','7','8','9',':']; const a=['٠','١','٢','٣','٤','٥','٦','٧','٨','٩',':']; String r=number; for(int i=0;i<e.length;i++){r=r.replaceAll(e[i],a[i]);} return r; }

  Future<void> _startSession() async {
    // (الكود كما هو، مع التأكد من التحقق من typeId != 99)
    if (!isSessionAvailable || _nextSessionData == null || _jwtToken == null || _nextSessionData!.typeId == 99) {
      debugPrint("HomeScreen: Cannot start session. Available: $isSessionAvailable, Data: ${_nextSessionData != null}, Token: ${_jwtToken != null}, Type: ${_nextSessionData?.typeId}");
      if(_nextSessionData?.typeId == 99 && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("هذا تنبيه لاختبار، يرجى الذهاب للاختبار من الزر المخصص.", textDirection: TextDirection.rtl)));
      else if (!isSessionAvailable && _errorMessage == null && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد جلسة متاحة.", textDirection: TextDirection.rtl)));
      return;
    }
    try {
      if (!mounted) return;
      final sessionResult = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => SessionIntroScreen(session: _nextSessionData!, jwtToken: _jwtToken!)));
      if (sessionResult == true && mounted) {
        final prefs = await SharedPreferences.getInstance();
        final nowMillis = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt('lastSessionStartTime', nowMillis);
        setStateIfMounted(() { isSessionAvailable = false; isSessionInProgressOrCoolingDown = true; remainingTime = sessionCooldownDuration; _nextSessionData = null; _errorMessage = null; });
        _startUiUpdateTimer(nowMillis);
      } else if (mounted && !isSessionInProgressOrCoolingDown) {
        await _fetchNextSessionDataFromApi();
      }
    } catch (e) { debugPrint("HomeScreen: Error in _startSession nav: $e"); }
    if (mounted) await _updateSessionNotifications();
  }

  Future<void> _startThreeMonthTest() async {
    // --- تم حذف منطق إنشاء الإشعار من هنا ---
    if (_jwtToken == null || _jwtToken!.isEmpty) { if(mounted) _showLoginRedirectSnackbar(); return; }
    if (_isFetchingTestGroup) return;
    setStateIfMounted(() => _isFetchingTestGroup = true);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري تحميل اختبار الـ 3 شهور...", textDirection: TextDirection.rtl), duration: Duration(seconds: 2)));
    try {
      final TestGroupResponse? testGroupData = await ApiService.fetchNextTestGroup(_jwtToken!);
      if (!mounted) return;
      if (testGroupData != null && testGroupData.sessions.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => GroupTestManagerScreen(testGroupData: testGroupData, jwtToken: _jwtToken!, notificationIconKey: _notificationIconKey)))
        .then((_) => _loadTokenAndInitialData());
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا يوجد اختبار 3 شهور متاح حاليًا.", textDirection: TextDirection.rtl)));
      }
    } catch (e) {
      debugPrint("HomeScreen: Error starting 3-month test: $e");
      if (mounted) {
        String msg = "خطأ تحميل اختبار الـ 3 شهور.";
        if (e.toString().contains('Unauthorized')) msg = "انتهت صلاحية الدخول.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, textDirection: TextDirection.rtl)));
      }
    } finally {
      if (mounted) setStateIfMounted(() => _isFetchingTestGroup = false);
    }
  }

  void _showLoginRedirectSnackbar(){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى تسجيل الدخول أولاً.", textDirection: TextDirection.rtl))); }

  @override
  Widget build(BuildContext context) {
    // ... (الكود الخاص بـ build كما قدمته في الرد السابق، مع التأكد من استخدام المتغيرات المحدثة)
    // ... (وأن الأزرار تستدعي الدوال الصحيحة)
    // ... (وأن SequentialSessionScreen يتم استدعاؤها بشكل صحيح إذا قررت استخدامها)
    const Color primaryBlue = Color(0xFF2C73D9);
    bool showAppLoadingIndicator = _isLoading && !_isFetchingTestGroup && (cooldownTimer == null || !cooldownTimer!.isActive);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        endDrawer: const SideBarMenuTest(),
        appBar: AppBar(
          backgroundColor: Colors.grey[100], elevation: 0,
          actions: [ Padding( padding: const EdgeInsets.only(left: 16.0, top: 8), child: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: primaryBlue, size: 32), onPressed: () => Scaffold.of(context).openEndDrawer(), tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip))), ],
          leading: NotificationIcon(key: _notificationIconKey, onNotificationsUpdated: _loadTokenAndInitialData),
        ),
        body: showAppLoadingIndicator
            ? const Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 3.0))
            : RefreshIndicator(
          onRefresh: _loadTokenAndInitialData, color: primaryBlue,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Center(child: Text('مرحبا !', style: TextStyle(fontSize: 28, color: primaryBlue, fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),
              if (_errorMessage != null && !isSessionInProgressOrCoolingDown && !_isFetchingTestGroup && !_isLoading)
                Padding(padding: const EdgeInsets.only(bottom: 15.0), child: Center(child: Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: _errorMessage!.contains("اكتملت") || _errorMessage!.contains("متاحة") ? Colors.green.shade700 : Colors.redAccent, fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w500)))),
              Container(
                width: double.infinity, constraints: const BoxConstraints(minHeight: 112),
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0,2))]),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(opacity: animation, child: child),
                  child: isSessionInProgressOrCoolingDown
                      ? Column(key: const ValueKey('timer_view'), mainAxisSize: MainAxisSize.min, children: [ const Text('تبقى على الجلسة القادمة', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(_convertToArabicNumbers(formatDuration(remainingTime)), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'monospace'), textDirection: TextDirection.ltr, textAlign: TextAlign.center), const SizedBox(height: 6), const Text('ساعة : دقيقة : ثانية', style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Cairo'), textAlign: TextAlign.center)])
                      : Container(key: const ValueKey('start_session_view'), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [ Expanded(flex: 5, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [ Text((isSessionAvailable && _nextSessionData != null && _nextSessionData!.typeId != 99) ? 'حان وقت الجلسة${_nextSessionData!.title != null && _nextSessionData!.title!.isNotEmpty ? " (${_nextSessionData!.title})" : "!"}' : (_errorMessage != null && (_errorMessage!.contains("اكتملت") || _errorMessage!.contains("متاحة")) ? _errorMessage! : "لا توجد جلسات تدريبية متاحة حاليًا"), style: const TextStyle(color: Colors.white, fontSize: 19, fontFamily: 'Cairo', fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 18), ElevatedButton(onPressed: (isSessionAvailable && _nextSessionData != null && _nextSessionData!.typeId != 99 && !_isFetchingTestGroup) ? _startSession : null, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), disabledBackgroundColor: Colors.white.withAlpha(178), disabledForegroundColor: primaryBlue.withAlpha(128), elevation: 3), child: Text('لنبدأ', style: TextStyle(color: (isSessionAvailable && _nextSessionData != null && _nextSessionData!.typeId != 99 && !_isFetchingTestGroup) ? primaryBlue : Colors.grey.shade400, fontSize: 17, fontFamily: 'Cairo', fontWeight: FontWeight.bold)))])), Expanded(flex: 4, child: Image.asset("assets/images/session.png", height: 90, fit: BoxFit.contain, errorBuilder: (ctx, err, st) => const SizedBox( height: 90, child: Center(child: Icon(Icons.image_not_supported, color: Colors.white54, size: 50)))))]))
                ),
              ),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _buildAssessmentCard(title: 'التقييم الشهري', subtitle: 'تقييم شهري لمتابعة التطورات خطوة بخطوة.', buttonText: 'ابدأ الاختبار', onPressed: _isFetchingTestGroup ? null : () { Navigator.push(context, MaterialPageRoute(builder: (context) => const Timetest())).then((_) => _loadTokenAndInitialData()); }, isLoading: false)),
                const SizedBox(width: 12),
                Expanded(child: _buildAssessmentCard(title: 'اختبار الـ 3 شهور', subtitle: 'تقييم شامل كل ثلاثة أشهر لقياس التقدم العام.', buttonText: 'ابدأ الاختبار', onPressed: _startThreeMonthTest, isLoading: _isFetchingTestGroup)),
              ]),
              const SizedBox(height: 24),
              const Padding(padding: EdgeInsets.only(right: 8.0, bottom: 6.0), child: Text('تطوير المهارات وإدارة الانفعالات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: primaryBlue))),
              _buildProgressCard('الانفعالات', 'تمارين للتعرف على المشاعر وإدارتها بفعالية.',/* emotionProgress*/ primaryBlue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrainingSessionsScreen()))),
              const SizedBox(height: 12),
              _buildProgressCard('تنمية المهارات', 'استكشف تمارين قيمة لتطوير مهاراتك الشخصية والاجتماعية!', primaryBlue, () => Navigator.push(context, MaterialPageRoute(builder: (context) =>  TrainingSessionsScreenV2()))),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentCard({ required String title, required String subtitle, required String buttonText, required VoidCallback? onPressed, required bool isLoading, Color cardBgColor = const Color(0xFFE3F2FD), Color textColor = const Color(0xFF2C73D9), Color buttonBgColor = const Color(0xFF2C73D9), Color buttonFgColor = Colors.white, }) {
    // ... (نفس الكود)
    return Container(constraints:const BoxConstraints(minHeight:175),padding:const EdgeInsets.fromLTRB(12,14,12,10),decoration:BoxDecoration(color:cardBgColor,borderRadius:BorderRadius.circular(12),boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:4,offset:const Offset(0,1))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(fontSize:17,fontWeight:FontWeight.bold,fontFamily:'Cairo',color:textColor)),const SizedBox(height:5),Text(subtitle,style:TextStyle(color:textColor.withAlpha(191),fontSize:13,fontFamily:'Cairo',height:1.3))]),const SizedBox(height:12),Align(alignment:Alignment.centerLeft,child:ElevatedButton(onPressed:onPressed,child:isLoading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(buttonText,style:const TextStyle(fontFamily:'Cairo',fontWeight:FontWeight.w600,fontSize:13)),style:ElevatedButton.styleFrom(backgroundColor:buttonBgColor,foregroundColor:buttonFgColor,padding:const EdgeInsets.symmetric(horizontal:20,vertical:9),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)))))]));
  }

  Widget _buildProgressCard(String title, String subtitle, Color color, VoidCallback onTap) {
    // ... (نفس الكود)
    return Card(color:Colors.white,elevation:1.5,margin:const EdgeInsets.symmetric(vertical:6),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(12),child:Padding(padding:const EdgeInsets.symmetric(horizontal:16.0,vertical:14.0),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(title,style:TextStyle(fontWeight:FontWeight.bold,color:color,fontFamily:'Cairo',fontSize:17)),Icon(Icons.arrow_forward_ios,size:18,color:color.withAlpha(204))]),const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:Color(0xff555555),fontSize:14,fontFamily:'Cairo',height:1.3))]))));
  }
}