import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/message_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/chat.dart';
import '../../data/models/message.dart';
import '../../data/models/message_status.dart';
import 'widgets/message_bubble.dart';
import 'chat_settings_screen.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final String chatName;

  const ChatScreen({required this.chat, required this.chatName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final List<Message> _messages = [];
  late WebSocketChannel _channel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _channel = MessageService.subscribeToChat(widget.chat.id);
    MessageService.markMessagesAsRead(widget.chat.id);
  }

  void _loadHistory() async {
    final history = await MessageService.getChatMessages(widget.chat.id);
    if (mounted) {
      setState(() {
        _messages.addAll(history);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await MessageService.sendMessage(widget.chat.id, text);
    _scrollToBottom();
  }

  void _sendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      String? imageUrl = await MessageService.uploadMessageImage(image);
      if (imageUrl != null) {
        await MessageService.sendMessage(widget.chat.id, "[IMAGE]$imageUrl");
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = AuthService.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.chatName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatSettingsScreen(chat: widget.chat),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _channel.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = jsonDecode(snapshot.data as String);

                  if (data['type'] == 'message_status_update') {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        final index = _messages.indexWhere((m) => m.id == data['message_id']);
                        if (index != -1) {
                          _messages[index] = _messages[index].copyWith(
                            status: MessageStatus.fromString(data['status']),
                          );
                        }
                      });
                    });
                  } else if (data['type'] == 'messages_read') {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        for (int i = 0; i < _messages.length; i++) {
                          if (_messages[i].senderId == myId) {
                            _messages[i] = _messages[i].copyWith(status: MessageStatus.read);
                          }
                        }
                      });
                    });
                  } else if (data['type'] == 'new_message') {
                    final newMessage = Message.fromJson(data);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_messages.any((m) => m.id == newMessage.id)) {
                        setState(() {
                          _messages.add(newMessage);
                          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                        });
                        _scrollToBottom();
                      }
                    });
                  }
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return MessageBubble(
                      message: msg,
                      isMe: msg.senderId == myId,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.blueAccent, size: 28),
              onPressed: _sendImage,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "Напишите сообщение...",
                  hintStyle: TextStyle(color: Colors.black38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            GestureDetector(
              onTap: _sendMessage,
              child: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: 20,
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}