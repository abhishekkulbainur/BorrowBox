// Flutter / Dart Imports
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'User',
      senderAvatarUrl: data['senderAvatarUrl'] as String?,
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] != null
              ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      text: text ?? this.text,
      imageUrl: imageUrl,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
