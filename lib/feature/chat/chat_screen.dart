// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/models/chat_message.dart';
import 'package:lendnborrow/core/models/conversation.dart';
import 'package:lendnborrow/core/models/report_item.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/chat_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/feature/explore/item_details_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Conversation conversation;
  final String? currentUserId;

  const ChatScreen({
    super.key,
    required this.conversation,
    this.currentUserId,
  });

  static const String path = "/chat";

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final chatService = ref.watch(chatServiceProvider);
    final myId = currentUser?.id ?? "";
    final otherName = widget.conversation.getOtherUserName(myId);
    final otherId = widget.conversation.getOtherUserId(myId);
    final isBlocked = chatService.isUserBlocked(otherId);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                otherName.isNotEmpty ? otherName[0] : "U",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isBlocked ? "Blocked User" : "Community Peer",
                    style: TextStyle(
                      fontSize: 11,
                      color: isBlocked ? Colors.red : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == "block") {
                chatService.toggleBlockUser(otherId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isBlocked
                          ? "Unblocked $otherName"
                          : "Blocked $otherName. You will no longer receive messages.",
                    ),
                  ),
                );
              } else if (val == "report") {
                _showReportDialog(context, otherId, otherName);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "block",
                child: Row(
                  children: [
                    Icon(
                      isBlocked ? Icons.lock_open : Icons.block,
                      color: isBlocked ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(isBlocked ? "Unblock User" : "Block User"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: "report",
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Text("Report Concern"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Item Context Card Header
          if (widget.conversation.itemId != null &&
              widget.conversation.itemTitle != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(50),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Symbols.category,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Item for Loan",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          widget.conversation.itemTitle!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final marketplace =
                          ref.read(marketplaceServiceProvider);
                      final item = marketplace.getItemById(
                        widget.conversation.itemId!,
                      );
                      if (item != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ItemDetailsScreen(item: item),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Item listing is no longer active."),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text("View Item", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatService.streamMessages(widget.conversation.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Symbols.handshake,
                          size: 48,
                          color: theme.colorScheme.primary.withAlpha(120),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Coordinate with $otherName",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Discuss handover location, return time, and item condition.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == myId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: isMe
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat.jm().format(msg.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? theme.colorScheme.onPrimary
                                            .withAlpha(180)
                                        : theme.colorScheme.outline,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.done_all,
                                    size: 13,
                                    color: theme.colorScheme.onPrimary
                                        .withAlpha(200),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Quick Replies Suggestions
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildQuickChip("👋 Hi! Is this still available?"),
                _buildQuickChip("📍 Where can we meet for pickup?"),
                _buildQuickChip("⏰ When would you like it returned?"),
                _buildQuickChip("✅ Handover confirmed, thank you!"),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Message Input Field
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(60),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !isBlocked,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: isBlocked
                            ? "Unblock user to reply..."
                            : "Type a message...",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withAlpha(60),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(
                        chatService,
                        myId,
                        currentUser?.name ?? "User",
                        otherId,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: isBlocked || _isSending
                        ? null
                        : () => _handleSend(
                              chatService,
                              myId,
                              currentUser?.name ?? "User",
                              otherId,
                            ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        onPressed: () {
          _textController.text = text;
        },
      ),
    );
  }

  Future<void> _handleSend(
    ChatService chatService,
    String myId,
    String myName,
    String recipientId,
  ) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      await chatService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: myId,
        senderName: myName,
        recipientId: recipientId,
        text: text,
      );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showReportDialog(
    BuildContext context,
    String otherUserId,
    String otherUserName,
  ) {
    final detailsController = TextEditingController();
    String selectedReason = "Inappropriate communication";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text("Report $otherUserName"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Please select the issue for admin review:",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                items: const [
                  DropdownMenuItem(
                    value: "Inappropriate communication",
                    child: Text("Inappropriate communication"),
                  ),
                  DropdownMenuItem(
                    value: "Harassment or Spam",
                    child: Text("Harassment or Spam"),
                  ),
                  DropdownMenuItem(
                    value: "Fraud or Suspicious Loan Request",
                    child: Text("Fraud / Suspicious Request"),
                  ),
                  DropdownMenuItem(
                    value: "Did not return item / Damaged item",
                    child: Text("Unreturned or Damaged Item"),
                  ),
                  DropdownMenuItem(
                    value: "Other",
                    child: Text("Other Concern"),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => selectedReason = val);
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Provide additional details for moderation...",
                  hintStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                final myUser = ref.read(currentUserProvider);
                if (myUser != null) {
                  final report = ReportItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    reporterId: myUser.id,
                    reporterName: myUser.name,
                    targetUserId: otherUserId,
                    targetListingId: widget.conversation.itemId,
                    targetListingTitle: widget.conversation.itemTitle,
                    reason: selectedReason,
                    details: detailsController.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await ref.read(chatServiceProvider).submitReport(report);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Report submitted to BorrowBox moderation team. Thank you.",
                      ),
                    ),
                  );
                }
              },
              child: const Text("Submit Report"),
            ),
          ],
        ),
      ),
    );
  }
}
