import 'package:flutter/material.dart';
import '../../../core/api_config.dart';

Widget buildAvatar(String? url, {double radius = 20}) {
  if (url == null || url.isEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, color: Colors.grey[600], size: radius),
    );
  }

  final cleanBase = ApiConfig.baseUrl.endsWith('/')
      ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
      : ApiConfig.baseUrl;

  final cleanUrl = url.startsWith('/') ? url : '/$url';

  String fullUrl = url.startsWith('http') ? url : "$cleanBase$cleanUrl";

  return CircleAvatar(
    radius: radius,
    backgroundColor: Colors.blueAccent.withOpacity(0.1),
    backgroundImage: NetworkImage(fullUrl),
    onBackgroundImageError: (exception, stackTrace) {
      print("Ошибка загрузки аватара: $exception");
    },
    child: null,
  );
}
