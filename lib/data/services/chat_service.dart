import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../models/chat.dart';
import 'auth_service.dart';

class ChatService {
  static Future<List<Chat>> getMyChats() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return [];

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/chats/$userId"),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((json) => Chat.fromJson(json)).toList();
    }
    return [];
  }

  static Future<int> getOrCreatePrivateChat(int targetUserId) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/chats/get_or_create_private"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'creator_id': AuthService.currentUserId,
        'target_id': targetUserId,
      }),
    );
    return jsonDecode(response.body)['chat_id'];
  }

  static Future<int> createChat(String name, List<int> userIds) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/chats/create"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'is_group': true,
        'created_by': AuthService.currentUserId,
        'participant_ids': userIds,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['chat_id'];
    } else {
      throw Exception("Failed to create chat");
    }
  }

  static Future<void> addMember(int chatId, int userId) async {
    await http.post(
      Uri.parse("${ApiConfig.baseUrl}/chats/add_member"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'chat_id': chatId, 'user_id': userId}),
    );
  }

  static Future<bool> removeMember(int chatId, int userId) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/chats/remove_member"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'chat_id': chatId, 'user_id': userId}),
    );
    return response.statusCode == 200;
  }
}
