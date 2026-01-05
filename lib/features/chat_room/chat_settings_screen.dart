import 'package:flutter/material.dart';
import '../../data/services/user_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/chat.dart';
import 'widgets/avatar.dart';

class ChatSettingsScreen extends StatefulWidget {
  final Chat chat;
  ChatSettingsScreen({required this.chat});

  @override
  _ChatSettingsScreenState createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  List<dynamic> searchResults = [];

  void _search(String q) async {
    if (q.length < 2) {
      setState(() => searchResults = []);
      return;
    }
    final allFound = await UserService.searchUsers(q);
    setState(() {
      searchResults = allFound
          .where((u) => !widget.chat.participantIds.contains(u['user_id']))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = AuthService.currentUserId;
    bool isOwner = widget.chat.createdBy == myId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Участники", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (isOwner) ...[
              _buildSectionCard(
                title: "Добавить участников",
                child: Column(
                  children: [
                    _buildSearchField(),
                    if (searchResults.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...searchResults.map((u) => _buildUserSearchTile(u)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildSectionCard(
              title: "В чате",
              child: Column(
                children: widget.chat.participantIds.map((id) => _buildMemberTile(id, isOwner, myId)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: _search,
      decoration: InputDecoration(
        hintText: "Поиск по никнейму...",
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: const Color(0xFFF1F3F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  Widget _buildUserSearchTile(dynamic u) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: buildAvatar(u['avatar_url'], radius: 20),
      title: Text(u['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Добавить"),
        onPressed: () async {
          await ChatService.addMember(widget.chat.id, u['user_id']);
          setState(() {
            widget.chat.participantIds.add(u['user_id']);
            searchResults.remove(u);
          });
        },
      ),
    );
  }

  Widget _buildMemberTile(int id, bool isOwner, int? myId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService.getUserInfo(id),
      builder: (context, snapshot) {
        final name = snapshot.data?['username'] ?? "Загрузка...";
        final avatar = snapshot.data?['avatar_url'];
        final bool itsMe = id == myId;
        final bool itsCreator = id == widget.chat.createdBy;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: buildAvatar(avatar, radius: 22),
          title: Text(
            itsMe ? "$name (Вы)" : name,
            style: TextStyle(fontWeight: itsMe ? FontWeight.bold : FontWeight.normal),
          ),
          subtitle: Text(
            itsCreator ? "Создатель" : "Участник",
            style: TextStyle(color: itsCreator ? Colors.orange : Colors.black38),
          ),
          trailing: (isOwner && !itsCreator)
              ? IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () async {
                    await ChatService.removeMember(widget.chat.id, id);
                    setState(() {
                      widget.chat.participantIds.remove(id);
                    });
                  })
              : null,
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}