// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/chat_service.dart';
import 'package:lendnborrow/core/widgets/app_logo.dart';
import 'package:lendnborrow/core/widgets/empty_state_view.dart';
import 'package:lendnborrow/feature/auth/auth_screen.dart';
import 'package:lendnborrow/feature/chat/chat_screen.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  static const String path = "/conversations";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final chatService = ref.watch(chatServiceProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Messages"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 90, borderRadius: 16),
                const SizedBox(height: 16),
                Text(
                  "Sign in to Chat",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Connect with borrowers and lenders to coordinate item handovers.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AuthScreen.path),
                  icon: const Icon(Icons.login),
                  label: const Text("Sign In or Register"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final conversations = chatService.getConversations(currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AppLogo.icon(size: 28, borderRadius: 6),
            SizedBox(width: 10),
            Text(
              "Messages & Handover",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: conversations.isEmpty
          ? const EmptyStateView(
              icon: Symbols.chat_bubble_outline,
              title: "No Conversations Yet",
              message:
                  "When you request an item or accept a loan, you can coordinate pick-up and returns directly with your peer here.",
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final otherName = conv.getOtherUserName(currentUser.id);
                final unread = conv.getUnreadCount(currentUser.id);
                final hasUnread = unread > 0;

                return Card(
                  elevation: hasUnread ? 1 : 0.5,
                  color: hasUnread
                      ? theme.colorScheme.primaryContainer.withAlpha(30)
                      : theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: hasUnread
                          ? theme.colorScheme.primary.withAlpha(90)
                          : theme.colorScheme.outlineVariant.withAlpha(50),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          theme.colorScheme.primary.withAlpha(40),
                      child: Text(
                        otherName.isNotEmpty ? otherName[0] : "U",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            style: TextStyle(
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(conv.lastMessageTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (conv.itemTitle != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Symbols.category,
                                  size: 12,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    conv.itemTitle!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conv.lastMessage.isNotEmpty
                                    ? conv.lastMessage
                                    : "Conversation started",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: hasUnread
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "$unread",
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      chatService.markAsRead(conv.id, currentUser.id);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(conversation: conv),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(time);
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(time);
    } else {
      return DateFormat.MMMd().format(time);
    }
  }
}
