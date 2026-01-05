import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/api_config.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../data/models/chat.dart';
import '../auth/login_screen.dart';
import '../chat_room/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../chat_room/widgets/avatar.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Chat> _chats = [];
  WebSocketChannel? _notificationChannel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _initNotificationSocket();
  }

  void _initNotificationSocket() {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    _notificationChannel = WebSocketChannel.connect(
      Uri.parse("${ApiConfig.wsUrl}/notifications/$userId"),
    );

    _notificationChannel!.stream.listen(
      (event) {
        _loadChats();
      },
      onError: (error) {
        Future.delayed(
          const Duration(seconds: 5),
          () => _initNotificationSocket(),
        );
      },
    );
  }

  @override
  void dispose() {
    _notificationChannel?.sink.close();
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await ChatService.getMyChats();
      chats.sort((a, b) {
        final DateTime timeA = a.lastMessageAt ?? a.createdAt;
        final DateTime timeB = b.lastMessageAt ?? b.createdAt;
        return timeB.compareTo(timeA);
      });

      if (mounted) {
        setState(() {
          _chats = List.from(chats);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Ошибка загрузки: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  void _onPlusPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _buildBottomSheetItem(
              icon: Icons.group_add_rounded,
              color: Colors.blueAccent,
              text: 'Создать группу',
              onTap: () {
                Navigator.pop(context);
                _showCreateChatDialog();
              },
            ),
            const Divider(height: 1),
            _buildBottomSheetItem(
              icon: Icons.person_add_alt_1_rounded,
              color: Colors.green,
              text: 'Найти собеседника',
              onTap: () {
                Navigator.pop(context);
                _showSearchUserDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  ListTile _buildBottomSheetItem({
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  void _showSearchUserDialog() {
    final controller = TextEditingController();
    List<dynamic> results = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Поиск людей"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Введите ник...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (val) async {
                    if (val.length > 1) {
                      final users = await UserService.searchUsers(val);
                      setDialogState(() => results = users);
                    }
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final user = results[index];
                      if (user['user_id'] == AuthService.currentUserId)
                        return const SizedBox();
                      return ListTile(
                        title: Text(
                          user['username'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        leading: buildAvatar(user['avatar_url'], radius: 20),
                        onTap: () async {
                          final chatId =
                              await ChatService.getOrCreatePrivateChat(
                                user['user_id'],
                              );
                          Navigator.pop(context);
                          _openChat(chatId, user['username']);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(int chatId, String title) async {
    await _loadChats();
    try {
      final chat = _chats.firstWhere((c) => c.id == chatId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(chat: chat, chatName: title),
          ),
        ).then((_) => _loadChats());
      }
    } catch (e) {
      print("Ошибка открытия: $e");
    }
  }

  void _showCreateChatDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Новая группа"),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Название группы",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final chatId = await ChatService.createChat(
                  nameController.text,
                  [],
                );
                if (mounted) {
                  Navigator.pop(context);
                  await _openChat(chatId, nameController.text);
                }
              }
            },
            child: const Text("Создать"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            "Чаты",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.black54),
            onPressed: _logout,
          ),
        ],
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
            child: Hero(
              tag: 'profile_avatar',
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: buildAvatar(
                  AuthService.currentUser?['avatar_url'],
                  radius: 18,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        child: _chats.isEmpty
            ? _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const Center(
                      child: Text(
                        "Нет активных чатов",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _ChatTile(
                      chat: chat,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chat: chat,
                              chatName: chat.name ?? "Чат",
                            ),
                          ),
                        ).then((_) => _loadChats());
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onPlusPressed,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        child: const Icon(
          Icons.add_comment_rounded,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const _ChatTile({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String rawContent = chat.lastMessageContent ?? "";
    final bool isImage = rawContent.contains("[IMAGE]");
    final String displaySubtitle = isImage
        ? "Фотография"
        : (rawContent.isEmpty ? "Нет сообщений" : rawContent);

    if (!chat.isGroup) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: UserService.getOtherParticipantInfo(chat.participantIds),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final String displayName = data?['username'] ?? "Загрузка...";
          final String? avatarUrl = data?['avatar_url'];

          return _buildDesignTile(
            title: displayName,
            subtitle: displaySubtitle,
            isItalic: isImage,
            leading: buildAvatar(avatarUrl, radius: 26),
            unreadCount: chat.unreadCount,
          );
        },
      );
    }

    return _buildDesignTile(
      title: chat.name ?? "Групповой чат",
      subtitle: displaySubtitle,
      isItalic: isImage,
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            chat.name != null && chat.name!.isNotEmpty
                ? chat.name![0].toUpperCase()
                : "G",
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
      unreadCount: chat.unreadCount,
    );
  }

  Widget _buildDesignTile({
    required String title,
    required String subtitle,
    required Widget leading,
    required int unreadCount,
    bool isItalic = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unreadCount > 0
                              ? Colors.black87
                              : Colors.black45,
                          fontWeight: unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                          fontSize: 14,
                          fontStyle: isItalic
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black12,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}