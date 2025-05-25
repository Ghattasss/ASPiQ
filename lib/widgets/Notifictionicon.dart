// lib/widgets/notifictionicon.dart (أو المسار الذي تستخدمينه)
import 'package:badges/badges.dart' as badges; // تأكدي أن هذه الحزمة مضافة في pubspec.yaml
import 'package:flutter/material.dart';
import '../models/notification_item.dart'; // تأكدي من المسار الصحيح لـ NotificationItem
import '../services/notification_manager.dart'; // تأكدي من المسار الصحيح لـ NotificationManager

class NotificationIcon extends StatefulWidget {
  final Function? onNotificationsUpdated; // Callback عند إغلاق قائمة الإشعارات أو تحديثها

  const NotificationIcon({super.key, this.onNotificationsUpdated});

  @override
  NotificationIconState createState() => NotificationIconState();
}

class NotificationIconState extends State<NotificationIcon> {
  final GlobalKey _iconKey = GlobalKey(); // مفتاح للوصول إلى موقع وحجم الأيقونة
  bool _isNotificationPopupOpen = false;
  List<NotificationItem> _activeNotifications = [];
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadAndRefreshNotifications();
  }

  Future<void> _loadAndRefreshNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoadingNotifications = true;
    });
    try {
      _activeNotifications = await NotificationManager.loadActiveNotifications();
      debugPrint("NotificationIcon: Loaded ${_activeNotifications.length} active notifications.");
    } catch (e) {
      debugPrint("NotificationIcon: Error loading notifications: $e");
      _activeNotifications = [];
    }
    if (mounted) {
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  void refreshNotifications() {
    debugPrint("NotificationIcon: refreshNotifications() called.");
    _loadAndRefreshNotifications();
  }

  void _toggleNotificationPopup(BuildContext context) {
    if (_isLoadingNotifications) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("جاري تحميل الإشعارات...", textDirection: TextDirection.rtl)),
      );
      return;
    }

    _loadAndRefreshNotifications().then((_) {
      if (!mounted) return;
      setState(() {
        _isNotificationPopupOpen = !_isNotificationPopupOpen;
      });

      if (_isNotificationPopupOpen) {
        final RenderBox? renderBox = _iconKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) {
          debugPrint("NotificationIcon: Could not find renderBox. Popup won't show correctly.");
          setState(() => _isNotificationPopupOpen = false);
          return;
        }
        final Offset position = renderBox.localToGlobal(Offset.zero);
        final Size iconSize = renderBox.size;

        showDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder: (BuildContext dialogContext) {
            return GestureDetector(
              onTap: () {
                if (mounted) {
                  setState(() { _isNotificationPopupOpen = false; });
                }
                Navigator.of(dialogContext).pop();
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.3)),
                  ),
                  Positioned(
                    top: position.dy + iconSize.height + 5, // مسافة 5 أسفل الأيقونة
                    right: 16,
                    left: 16,
                    child: Material(
                      color: Colors.transparent, // لجعل الـ Container هو الذي يظهر اللون
                      elevation: 8.0, // إضافة ظل للـ Material
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9, // الحفاظ على العرض
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration( // الديكور ينتقل للـ Container الداخلي
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          // الظل الآن على Material
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text( // العنوان
                              "الإشعارات",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor, // استخدام لون التطبيق الرئيسي
                                  fontFamily: 'Cairo'),
                              textAlign: TextAlign.right,
                            ),
                            const Divider(height: 15, thickness: 0.7), // فاصل أنحف

                            if (_isLoadingNotifications)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_activeNotifications.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: Center(
                                  child: Text(
                                    "لا توجد إشعارات حاليًا.",
                                    style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Cairo'),
                                  ),
                                ),
                              )
                            else
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.55, // يمكن تعديل الارتفاع
                                ),
                                child: ListView.builder( // استخدام ListView.builder كما هو
                                  shrinkWrap: true,
                                  itemCount: _activeNotifications.length,
                                  itemBuilder: (ctx, index) {
                                    final notification = _activeNotifications[index];
                                    return Container( // الحفاظ على تصميم عنصر الإشعار
                                      margin: const EdgeInsets.symmetric(vertical: 5),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white, // يمكنك تغييره إذا أردت خلفية مختلفة للعنصر
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(color: Colors.grey.shade300),
                                         boxShadow: [ // ظل خفيف للعناصر
                                           BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: Offset(0,1))
                                        ]
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  notification.title,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Theme.of(context).primaryColorDark, // لون أغمق قليلاً
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Cairo'),
                                                  textAlign: TextAlign.right,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  // ---!!! استخدام timeAgoDisplay !!!---
                                                  notification.timeAgoDisplay,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade600, // لون رمادي أغمق
                                                      fontFamily: 'Cairo'),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          CircleAvatar(
                                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                            child: Icon(_getIconForNotificationType(notification.type), color: Theme.of(context).primaryColor, size: 22),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ).then((_) {
          if (mounted) {
            setState(() {
              _isNotificationPopupOpen = false;
            });
          }
          if (widget.onNotificationsUpdated != null) {
            widget.onNotificationsUpdated!();
          }
        });
      }
    });
  }

  IconData _getIconForNotificationType(NotificationType type) {
  switch (type) {
    case NotificationType.sessionEnded: return Icons.check_circle_outline_rounded;
    case NotificationType.sessionUpcoming: return Icons.update_rounded;
    case NotificationType.sessionReady: return Icons.play_circle_fill_rounded;
    case NotificationType.monthlyTestAvailable: return Icons.assignment_turned_in_outlined; // أو أي أيقونة أخرى صحيحة
    case NotificationType.threeMonthTestAvailable: return Icons.event_note_outlined;
    // لا يوجد default هنا لأن جميع الحالات مغطاة
  }
  // إذا كان المحلل لا يزال يطلب return statement هنا (لأنه لا يدرك أن الـ switch شامل)،
  // يمكنك إضافة return لأيقونة افتراضية كحل أخير، لكن من المفترض ألا تحتاجي لذلك.
  // return Icons.notifications_none_rounded;
}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0), // تعديل ليتناسب مع AppBar (إذا كان في الـ leading أو actions)
      child: Center( // لضمان توسط الأيقونة رأسيًا
        child: IconButton(
          key: _iconKey,
          tooltip: "الإشعارات",
          icon: badges.Badge(
            position: badges.BadgePosition.topEnd(top: -10, end: -8), // تعديل موقع الشارة
            showBadge: !_isLoadingNotifications && _activeNotifications.isNotEmpty,
            badgeContent: Text(
              _isLoadingNotifications ? "" : _activeNotifications.length.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: Colors.red.shade700,
              padding: const EdgeInsets.all(5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.notifications_none_rounded, color: Theme.of(context).primaryColor, size: 28),
          ),
          onPressed: () => _toggleNotificationPopup(context),
        ),
      ),
    );
  }
}