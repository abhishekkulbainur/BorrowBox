// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/models/app_notification.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/notification_service.dart';
import 'package:lendnborrow/core/widgets/empty_state_view.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const String path = "/notifications";

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.borrowRequest:
        return Symbols.inbox;
      case NotificationType.requestApproved:
        return Symbols.check_circle;
      case NotificationType.requestRejected:
        return Symbols.cancel;
      case NotificationType.handoverReady:
        return Symbols.qr_code;
      case NotificationType.returnReminder:
        return Symbols.alarm;
      case NotificationType.itemReturned:
        return Symbols.assignment_turned_in;
      case NotificationType.systemAlert:
        return Symbols.notifications;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.borrowRequest:
        return Colors.orange;
      case NotificationType.requestApproved:
      case NotificationType.handoverReady:
        return Colors.blue;
      case NotificationType.requestRejected:
        return Colors.red;
      case NotificationType.returnReminder:
        return Colors.amber;
      case NotificationType.itemReturned:
        return Colors.green;
      case NotificationType.systemAlert:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifService = ref.watch(notificationServiceProvider);
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? "";
    final notifications = notifService.getNotificationsForUser(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(notificationServiceProvider).markAllAsReadForUser(userId);
              },
              child: const Text("Mark All Read"),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyStateView(
              icon: Symbols.notifications_off,
              title: "No Notifications",
              message: "When peers request items or return loans, updates will appear here.",
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final color = _getColorForType(notif.type);

                return Card(
                  elevation: notif.isRead ? 0 : 1,
                  color: notif.isRead
                      ? theme.colorScheme.surface
                      : theme.colorScheme.primaryContainer.withAlpha(25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: notif.isRead
                          ? theme.colorScheme.outlineVariant.withAlpha(50)
                          : theme.colorScheme.primary.withAlpha(80),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(notif.type),
                        color: color,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notif.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat.yMMMd().add_jm().format(notif.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(notificationServiceProvider).markAsRead(notif.id);
                    },
                  ),
                );
              },
            ),
    );
  }
}
