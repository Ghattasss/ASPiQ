// lib/services/notification_manager.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';
import 'package:flutter/foundation.dart';

class NotificationManager {
  static const String _notificationsKey = 'app_notifications_list_v3'; // تم تحديث الإصدار
  static const String _monthlyTestNotifSentKey = 'monthly_test_notif_sent_flag_v2';
  static const String _threeMonthTestNotifSentKey = 'three_month_test_notif_sent_flag_v2';

  static Future<List<NotificationItem>> _loadAllNotificationsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? notificationsJsonList = prefs.getStringList(_notificationsKey);
    if (notificationsJsonList == null || notificationsJsonList.isEmpty) return [];
    List<NotificationItem> allItems = [];
    for (String jsonString in notificationsJsonList) {
      try {
        if (jsonString.trim().isNotEmpty) {
          allItems.add(NotificationItem.fromJson(jsonDecode(jsonString)));
        }
      } catch (e) {
        debugPrint("NotificationManager: Error parsing item: $e. Item: $jsonString");
      }
    }
    return allItems;
  }

  static Future<List<NotificationItem>> loadActiveNotifications() async {
    List<NotificationItem> allNotifications = await _loadAllNotificationsRaw();
    return allNotifications
        .where((item) => item.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> _saveNotifications(List<NotificationItem> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationsJsonList =
        notifications.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_notificationsKey, notificationsJsonList);
    debugPrint("NotificationManager: Saved ${notifications.length} total notifications.");
  }

  static Future<void> addOrUpdateNotification(NotificationItem newItem) async {
    List<NotificationItem> currentNotifications = await _loadAllNotificationsRaw();
    int existingIndexById = currentNotifications.indexWhere((n) => n.id == newItem.id);

    // إذا كان الإشعار لإشعار حالة الجلسة، اجعل أي إشعار قديم من نفس النوع غير نشط
    if (newItem.type == NotificationType.sessionEnded ||
        newItem.type == NotificationType.sessionUpcoming ||
        newItem.type == NotificationType.sessionReady) {
      for (int i = 0; i < currentNotifications.length; i++) {
        if (currentNotifications[i].type == newItem.type && currentNotifications[i].id != newItem.id) {
          currentNotifications[i].isActive = false; // إلغاء تنشيط القديم
        }
      }
    }
    
    newItem.isActive = true; // الإشعار الجديد أو المحدث يجب أن يكون نشطًا

    if (existingIndexById != -1) {
      currentNotifications[existingIndexById] = newItem; // تحديث الموجود بالـ ID
      debugPrint("NotificationManager: Updated notification by ID: '${newItem.id}', Title='${newItem.title}'");
    } else {
      currentNotifications.add(newItem); // إضافة الجديد
      debugPrint("NotificationManager: Added new notification: ID='${newItem.id}', Title='${newItem.title}'");
    }
    await _saveNotifications(currentNotifications);
  }

  static Future<void> deactivateNotificationsByType(NotificationType typeToDeactivate) async {
    List<NotificationItem> currentNotifications = await _loadAllNotificationsRaw();
    bool changed = false;
    for (int i = 0; i < currentNotifications.length; i++) {
      if (currentNotifications[i].type == typeToDeactivate && currentNotifications[i].isActive) {
        currentNotifications[i].isActive = false;
        changed = true;
        debugPrint("NotificationManager: Deactivated type $typeToDeactivate, ID: ${currentNotifications[i].id}");
      }
    }
    if (changed) await _saveNotifications(currentNotifications);
  }

  static Future<void> clearSessionStatusNotifications() async {
    List<NotificationItem> currentNotifications = await _loadAllNotificationsRaw();
    int originalCount = currentNotifications.length;
    currentNotifications.removeWhere((item) =>
        item.type == NotificationType.sessionEnded ||
        item.type == NotificationType.sessionUpcoming ||
        item.type == NotificationType.sessionReady);
    if (currentNotifications.length < originalCount) {
      await _saveNotifications(currentNotifications);
      debugPrint("NotificationManager: Cleared session status notifications.");
    }
  }

  static Future<bool> isMonthlyTestNotificationSent() async { final p = await SharedPreferences.getInstance(); return p.getBool(_monthlyTestNotifSentKey)??false; }
  static Future<void> setMonthlyTestNotificationSent(bool sent) async { final p = await SharedPreferences.getInstance(); await p.setBool(_monthlyTestNotifSentKey, sent); debugPrint("NotificationManager: Monthly flag set to $sent");}
  static Future<bool> isThreeMonthTestNotificationSent() async { final p = await SharedPreferences.getInstance(); return p.getBool(_threeMonthTestNotifSentKey)??false; }
  static Future<void> setThreeMonthTestNotificationSent(bool sent) async { final p = await SharedPreferences.getInstance(); await p.setBool(_threeMonthTestNotifSentKey, sent); debugPrint("NotificationManager: 3-Month flag set to $sent");}

  static Future<void> clearAllNotificationsAndFlagsForDebugging() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
    await prefs.remove(_monthlyTestNotifSentKey);
    await prefs.remove(_threeMonthTestNotifSentKey);
    debugPrint("NotificationManager: DEBUG - All notifications and flags cleared.");
  }
}