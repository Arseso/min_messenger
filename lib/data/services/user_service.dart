import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../core/api_config.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class UserService {
  static Future<List<dynamic>> searchUsers(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse("${ApiConfig.baseUrl}/users/search/$query"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Search error: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getUserInfo(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/users/$userId"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  static Future<String?> updateProfile(
    String username,
    String? avatarUrl,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/profile/update"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': AuthService.currentUserId,
          'username': username,
          'avatar_url': avatarUrl,
        }),
      );

      if (response.statusCode == 200) {
        AuthService.currentUser!['username'] = username;
        await StorageService.saveUser(AuthService.currentUser!);
        return null;
      } else {
        final data = jsonDecode(response.body);
        return data['detail'] ?? "Ошибка обновления";
      }
    } catch (e) {
      return "Ошибка сети или сервера";
    }
  }

  static Future<bool> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/profile/change_password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": AuthService.currentUserId,
          "old_password": oldPassword,
          "new_password": newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> uploadAvatar(XFile image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          "${ApiConfig.baseUrl}/upload/avatar/${AuthService.currentUserId}",
        ),
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
        final data = jsonDecode(response.body);
        AuthService.currentUser!['avatar_url'] = data['avatar_url'];
        return data['avatar_url'];
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getOtherParticipantInfo(
    List<int> participantIds,
  ) async {
    final myId = AuthService.currentUserId;
    final otherId = participantIds.firstWhere(
      (id) => id != myId,
      orElse: () => -1,
    );
    if (otherId == -1) return null;
    return await getUserInfo(otherId);
  }
}
