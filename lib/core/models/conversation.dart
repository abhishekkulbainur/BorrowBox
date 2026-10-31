// Flutter / Dart Imports
import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final String? itemId;
  final String? itemTitle;
  final String? itemImageUrl;
  final String? requestId;

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.participantAvatars = const {},
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    required this.lastMessageTime,
    this.unreadCounts = const {},
    this.itemId,
    this.itemTitle,
    this.itemImageUrl,
    this.requestId,
  });

  String getOtherUserId(String myUserId) {
    return participantIds.firstWhere(
      (id) => id != myUserId,
      orElse: () => myUserId,
    );
  }

  String getOtherUserName(String myUserId) {
    final otherId = getOtherUserId(myUserId);
    return participantNames[otherId] ?? 'Community Peer';
  }

  int getUnreadCount(String myUserId) {
    return unreadCounts[myUserId] ?? 0;
  }

  List<String> get participants => participantIds;

  factory Conversation.fromMap(String id, Map<String, dynamic> data) {
    return Conversation(
      id: id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantAvatars: Map<String, String?>.from(data['participantAvatars'] ?? {}),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] as String? ?? '',
      lastMessageTime: (data['lastMessageTime'] is Timestamp)
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : (data['lastMessageTime'] != null
              ? DateTime.tryParse(data['lastMessageTime'].toString()) ?? DateTime.now()
              : DateTime.now()),
      unreadCounts: (data['unreadCounts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      itemId: data['itemId'] as String?,
      itemTitle: data['itemTitle'] as String?,
      itemImageUrl: data['itemImageUrl'] as String?,
      requestId: data['requestId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'itemImageUrl': itemImageUrl,
      'requestId': requestId,
    };
  }
}
