import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/message.dart';
import '../../../data/models/message_status.dart';
import '../../../core/api_config.dart';
import 'avatar.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bool isImage = message.content.startsWith("[IMAGE]");
    final String timeString = DateFormat(
      'HH:mm',
    ).format(message.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            buildAvatar(message.senderAvatar, radius: 18),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMe)
                      Text(
                        message.senderName ?? "Пользователь",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    if (!isMe) const SizedBox(width: 8),
                    Text(
                      timeString,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),

              Stack(
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                      minWidth: 60,
                    ),
                    padding: isImage
                        ? const EdgeInsets.all(4)
                        : const EdgeInsets.fromLTRB(14, 10, 30, 10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blueAccent : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: isImage
                        ? _buildImageContent(message.content)
                        : Text(
                            message.content,
                            style: TextStyle(
                              fontSize: 15,
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                  ),

                  if (isMe)
                    Positioned(
                      bottom: 6,
                      right: 8,
                      child: _buildStatusIcon(message.status),
                    ),
                ],
              ),
            ],
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return const Icon(Icons.done, size: 14, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Color(0xFF00E5FF),
        );
      default:
        return const Icon(Icons.access_time, size: 12, color: Colors.white70);
    }
  }

  Widget _buildImageContent(String content) {
    final String imagePath = content.replaceFirst("[IMAGE]", "");
    final cleanBase = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final String fullUrl = imagePath.startsWith('http')
        ? imagePath
        : "$cleanBase$imagePath";

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(fullUrl, width: 250, fit: BoxFit.cover),
    );
  }
}
