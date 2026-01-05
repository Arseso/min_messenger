import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'storage_service.dart';

class AuthService {
  static Map<String, dynamic>? currentUser;

  static int? get currentUserId => currentUser?['user_id'];

  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        currentUser = jsonDecode(response.body);
        await StorageService.saveUser(currentUser!);
        return true;
      }
    } catch (e) {
      print("Login error: $e");
    }
    return false;
  }

  static Future<bool> register(String username, String password) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/register"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> tryAutoLogin() async {
    currentUser = await StorageService.getUser();
    return currentUser != null;
  }

  static Future<void> logout() async {
    await StorageService.clear();
    currentUser = null;
  }
}
