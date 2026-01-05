import 'message_status.dart';

class Message {
  final int id;
  final int senderId;
  final int chatId;
  final String content;
  final MessageStatus status;
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatar;

  Message({
    required this.id,
    required this.senderId,
    required this.chatId,
    required this.content,
    required this.status,
    required this.createdAt,
    this.senderName,
    this.senderAvatar,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['message_id'],
      senderId: json['sender_id'],
      chatId: json['chat_id'],
      content: json['content'],
      status: MessageStatus.fromString(json['status'] ?? 'sent'),
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
    );
  }

  Message copyWith({
    int? id,
    int? senderId,
    int? chatId,
    String? content,
    MessageStatus? status,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }
}
