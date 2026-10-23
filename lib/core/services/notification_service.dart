// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/legacy.dart';

// Project Imports
import 'package:lendnborrow/core/models/app_notification.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _initSeedNotifications();
  }

  final List<AppNotification> _notifications = [];

  List<AppNotification> get allNotifications => List.unmodifiable(_notifications);

  List<AppNotification> getNotificationsForUser(String userId) {
    if (userId.isEmpty) return [];
    return _notifications.where((n) => n.userId == userId || n.userId.isEmpty).toList();
  }

  int getUnreadCountForUser(String userId) {
    if (userId.isEmpty) return 0;
    return _notifications.where((n) => (n.userId == userId || n.userId.isEmpty) && !n.isRead).length;
  }

  void _initSeedNotifications() {
    _notifications.addAll([
      AppNotification(
        id: "notif_01",
        userId: "user_abhishek",
        title: "New Borrow Request Received",
        message: "Snehal Mascarenhas requested to borrow your 'Bosch 18V Cordless Drill'.",
        type: NotificationType.borrowRequest,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
        referenceId: "req_seed_01",
      ),
      AppNotification(
        id: "notif_02",
        userId: "user_abhishek",
        title: "Loan Approved & Ready for Handover",
        message: "Your request for 'Casio fx-991EX Calculator' was approved. Show your QR token at pickup.",
        type: NotificationType.handoverReady,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        referenceId: "req_seed_02",
      ),
      AppNotification(
        id: "notif_03",
        userId: "user_snehal",
        title: "Return Confirmed & Reviewed",
        message: "Abhishek confirmed the safe return of 'Quechua 3-Person Camping Tent' and left a 5-star review!",
        type: NotificationType.itemReturned,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isRead: true,
        referenceId: "req_seed_03",
      ),
    ]);
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsReadForUser(String userId) {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if ((_notifications[i].userId == userId || _notifications[i].userId.isEmpty) && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void addNotification(AppNotification notif) {
    _notifications.insert(0, notif);
    notifyListeners();
  }
}

final notificationServiceProvider = ChangeNotifierProvider<NotificationService>((ref) {
  return NotificationService();
});
