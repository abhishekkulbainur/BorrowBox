import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import 'package:lendnborrow/core/models/chat_message.dart';
import 'package:lendnborrow/core/models/conversation.dart';
import 'package:lendnborrow/core/models/report_item.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/firebase_service.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final List<Conversation> _localConversations = [];
  final Map<String, List<ChatMessage>> _localMessages = {};
  final Set<String> _blockedUserIds = {};

  StreamSubscription<QuerySnapshot>? _convSub;
  String? _activeUserId;

  void initSync(String userId) {
    if (!FirebaseService().isInitialized || userId.isEmpty) return;
    _activeUserId = userId;
    _convSub?.cancel();

    _convSub = FirebaseService()
        .firestore!
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _localConversations.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _localConversations.add(Conversation.fromMap(doc.id, data));
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint("Conversations stream error: $e");
      },
    );
  }

  void disposeSync() {
    _convSub?.cancel();
    _convSub = null;
    _activeUserId = null;
  }

  List<Conversation> getConversations(String userId) {
    return _localConversations.where((c) {
      final other = c.getOtherUserId(userId);
      return !_blockedUserIds.contains(other);
    }).toList();
  }

  int getTotalUnreadCount(String userId) {
    int count = 0;
    for (var c in _localConversations) {
      if (!_blockedUserIds.contains(c.getOtherUserId(userId))) {
        count += c.getUnreadCount(userId);
      }
    }
    return count;
  }

  bool isUserBlocked(
    String userId, {
    String? currentUserId,
    String? targetUserId,
  }) {
    final idToCheck = targetUserId ?? userId;
    return _blockedUserIds.contains(idToCheck);
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    _blockedUserIds.add(blockedUserId);
    notifyListeners();
  }

  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    _blockedUserIds.remove(blockedUserId);
    notifyListeners();
  }

  int getUnreadCountForUser(String userId) => getTotalUnreadCount(userId);

  Future<void> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    await markAsRead(conversationId, userId);
  }

  Future<ReportItem> reportItemOrUser({
    required String reporterId,
    String? reporterName,
    required String targetId,
    required String type,
    required String reason,
    required String details,
  }) async {
    final report = ReportItem(
      id: const Uuid().v4(),
      reporterId: reporterId,
      reporterName: reporterName ?? 'BorrowBox User',
      targetUserId: type == 'user' ? targetId : null,
      targetListingId: type == 'item' ? targetId : null,
      reason: reason,
      details: details,
      createdAt: DateTime.now(),
      status: ReportStatus.pending,
    );
    await submitReport(report);
    return report;
  }

  void toggleBlockUser(String userId) {
    if (_blockedUserIds.contains(userId)) {
      _blockedUserIds.remove(userId);
    } else {
      _blockedUserIds.add(userId);
    }
    notifyListeners();

    if (FirebaseService().isInitialized && _activeUserId != null) {
      final userDoc = FirebaseService()
          .firestore!
          .collection('users')
          .doc(_activeUserId);
      if (_blockedUserIds.contains(userId)) {
        userDoc.collection('blocked_users').doc(userId).set({
          'blockedAt': FieldValue.serverTimestamp(),
        });
      } else {
        userDoc.collection('blocked_users').doc(userId).delete();
      }
    }
  }

  /// Get or create conversation between two users for a specific item/loan
  Future<Conversation> getOrCreateConversation({
    String? myUserId,
    String? myName,
    String? currentUserId,
    String? currentUserName,
    String? currentUserAvatar,
    String? myAvatar,
    required String otherUserId,
    String? otherName,
    String? otherUserName,
    String? otherAvatar,
    String? itemId,
    String? itemTitle,
    String? itemImageUrl,
    String? requestId,
  }) async {
    final effectiveMyId = myUserId ?? currentUserId ?? "";
    final effectiveMyName = myName ?? currentUserName ?? "User";
    final effectiveMyAvatar = myAvatar ?? currentUserAvatar;
    final effectiveOtherName = otherName ?? otherUserName ?? "Peer";

    // Check if exists locally
    for (var c in _localConversations) {
      if (c.participantIds.contains(effectiveMyId) &&
          c.participantIds.contains(otherUserId)) {
        if (itemId == null || c.itemId == itemId) {
          return c;
        }
      }
    }

    final convId = itemId != null
        ? "conv_${effectiveMyId.compareTo(otherUserId) < 0 ? '${effectiveMyId}_$otherUserId' : '${otherUserId}_$effectiveMyId'}_$itemId"
        : const Uuid().v4();

    final newConv = Conversation(
      id: convId,
      participantIds: [effectiveMyId, otherUserId],
      participantNames: {
        effectiveMyId: effectiveMyName,
        otherUserId: effectiveOtherName,
      },
      participantAvatars: {
        effectiveMyId: effectiveMyAvatar,
        otherUserId: otherAvatar,
      },
      lastMessage: "Conversation opened",
      lastMessageSenderId: effectiveMyId,
      lastMessageTime: DateTime.now(),
      unreadCounts: {
        effectiveMyId: 0,
        otherUserId: 0,
      },
      itemId: itemId,
      itemTitle: itemTitle,
      itemImageUrl: itemImageUrl,
      requestId: requestId,
    );

    _localConversations.insert(0, newConv);
    notifyListeners();

    if (FirebaseService().isInitialized) {
      try {
        final ref =
            FirebaseService().firestore!.collection('conversations').doc(convId);
        final doc = await ref.get();
        if (!doc.exists) {
          await ref.set(newConv.toMap());
        }
      } catch (e) {
        debugPrint("Error creating conversation in Firestore: $e");
      }
    }

    return newConv;
  }

  /// Stream real-time messages for a conversation
  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    if (FirebaseService().isInitialized) {
      return FirebaseService()
          .firestore!
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ChatMessage.fromMap(doc.id, doc.data());
        }).toList();
      });
    }

    // Offline / unit test stream
    final controller = StreamController<List<ChatMessage>>.broadcast();
    final list = _localMessages[conversationId] ?? [];
    controller.add(List.unmodifiable(list));
    return controller.stream;
  }

  /// Send message in conversation
  Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    String? recipientId,
    required String text,
    String? imageUrl,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && imageUrl == null) return null;

    String targetRecipient = recipientId ?? "";
    if (targetRecipient.isEmpty) {
      final conv = _localConversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => Conversation(
          id: conversationId,
          participantIds: [senderId],
          participantNames: {},
          lastMessageTime: DateTime.now(),
        ),
      );
      targetRecipient = conv.getOtherUserId(senderId);
    }

    if (_blockedUserIds.contains(senderId) ||
        _blockedUserIds.contains(targetRecipient)) {
      return null;
    }

    final msgId = const Uuid().v4();
    final msg = ChatMessage(
      id: msgId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatar,
      text: cleanText,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      isRead: false,
    );

    // Update in-memory
    _localMessages.putIfAbsent(conversationId, () => []).add(msg);

    final idx = _localConversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final c = _localConversations[idx];
      final unread = Map<String, int>.from(c.unreadCounts);
      unread[targetRecipient] = (unread[targetRecipient] ?? 0) + 1;

      _localConversations[idx] = Conversation(
        id: c.id,
        participantIds: c.participantIds,
        participantNames: c.participantNames,
        participantAvatars: c.participantAvatars,
        lastMessage: cleanText,
        lastMessageSenderId: senderId,
        lastMessageTime: DateTime.now(),
        unreadCounts: unread,
        itemId: c.itemId,
        itemTitle: c.itemTitle,
        itemImageUrl: c.itemImageUrl,
        requestId: c.requestId,
      );
    }
    notifyListeners();

    if (FirebaseService().isInitialized) {
      try {
        final firestore = FirebaseService().firestore!;
        final convRef =
            firestore.collection('conversations').doc(conversationId);

        final batch = firestore.batch();
        final msgRef = convRef.collection('messages').doc(msgId);
        batch.set(msgRef, msg.toMap());

        batch.update(convRef, {
          'lastMessage': cleanText,
          'lastMessageSenderId': senderId,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCounts.$targetRecipient': FieldValue.increment(1),
        });

        // Trigger in-app notification for recipient
        final notifRef = firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': targetRecipient,
          'title': 'New Message from $senderName',
          'message': cleanText.length > 60
              ? '${cleanText.substring(0, 57)}...'
              : cleanText,
          'type': 'newChatMessage',
          'isRead': false,
          'referenceId': conversationId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
      } catch (e) {
        debugPrint("Error sending message to Firebase: $e");
      }
    }
    return msg;
  }

  /// Mark conversation messages as read
  Future<void> markAsRead(String conversationId, String userId) async {
    final idx = _localConversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final c = _localConversations[idx];
      if ((c.unreadCounts[userId] ?? 0) > 0) {
        final unread = Map<String, int>.from(c.unreadCounts);
        unread[userId] = 0;
        _localConversations[idx] = Conversation(
          id: c.id,
          participantIds: c.participantIds,
          participantNames: c.participantNames,
          participantAvatars: c.participantAvatars,
          lastMessage: c.lastMessage,
          lastMessageSenderId: c.lastMessageSenderId,
          lastMessageTime: c.lastMessageTime,
          unreadCounts: unread,
          itemId: c.itemId,
          itemTitle: c.itemTitle,
          itemImageUrl: c.itemImageUrl,
          requestId: c.requestId,
        );
        notifyListeners();
      }
    }

    if (FirebaseService().isInitialized) {
      try {
        final convRef = FirebaseService()
            .firestore!
            .collection('conversations')
            .doc(conversationId);
        await convRef.update({'unreadCounts.$userId': 0});
      } catch (e) {
        debugPrint("Error marking conversation as read: $e");
      }
    }
  }

  /// Report inappropriate user or listing
  Future<void> submitReport(ReportItem report) async {
    if (FirebaseService().isInitialized) {
      try {
        await FirebaseService()
            .firestore!
            .collection('reports')
            .add(report.toMap());
      } catch (e) {
        debugPrint("Error submitting report: $e");
      }
    }
  }
}

final chatServiceProvider = ChangeNotifierProvider<ChatService>((ref) {
  return ChatService();
});

final unreadMessagesCountProvider = Provider<int>((ref) {
  final chat = ref.watch(chatServiceProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return chat.getTotalUnreadCount(user.id);
});
