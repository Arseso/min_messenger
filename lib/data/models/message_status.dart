import 'package:flutter/material.dart';

enum MessageStatus {
  sent,
  delivered,
  read;

  static MessageStatus fromString(String status) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => MessageStatus.sent,
    );
  }

  IconData get icon {
    switch (this) {
      case MessageStatus.sent:
        return Icons.done;
      case MessageStatus.delivered:
      case MessageStatus.read:
        return Icons.done_all;
    }
  }

  Color get color {
    switch (this) {
      case MessageStatus.read:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
