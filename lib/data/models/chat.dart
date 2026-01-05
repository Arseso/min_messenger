class Chat {
  final int id;
  final String? name;
  final bool isGroup;
  final int createdBy;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final int unreadCount;
  final String? lastMessageContent;
  final List<int> participantIds;

  Chat({
    required this.id,
    this.name,
    required this.isGroup,
    required this.createdBy,
    required this.lastMessageAt,
    required this.createdAt,
    this.unreadCount = 0,
    this.lastMessageContent,
    required this.participantIds,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['chat_id'],
      name: json['chat_name'] ?? "Чат",
      isGroup: json['chat_type'] == 'group',
      createdBy: json['created_by'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      unreadCount: json['unread_count'] ?? 0,
      lastMessageContent: json['last_message_content'],
      participantIds: List<int>.from(json['participant_ids'] ?? []),
    );
  }
}
