import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_config.dart';
import '../models/message.dart';
import 'auth_service.dart';

class MessageService {
  static Future<List<Message>> getChatMessages(int chatId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/messages/$chatId"),
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  static Future<void> sendMessage(int chatId, String content) async {
    await http.post(
      Uri.parse("${ApiConfig.baseUrl}/messages/send"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_id': AuthService.currentUserId,
        'chat_id': chatId,
        'content': content,
      }),
    );
  }

  static WebSocketChannel subscribeToChat(int chatId) {
    final wsUrl = '${ApiConfig.wsUrl}/$chatId';
    return WebSocketChannel.connect(Uri.parse(wsUrl));
  }

  static Future<String?> uploadMessageImage(XFile image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConfig.baseUrl}/upload/message_image"),
      );

      if (kIsWeb) {
        var bytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: image.name),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', image.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['image_url'];
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
    return null;
  }

  static Future<void> markMessagesAsRead(int chatId) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    await http.post(
      Uri.parse("${ApiConfig.baseUrl}/messages/read_all"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'chat_id': chatId, 'user_id': userId}),
    );
  }
}
