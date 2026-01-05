import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000";
    } else {
      return "http://10.0.2.2:8000";
    }
  }

  static String get wsUrl {
    final host = baseUrl
        .replaceFirst('http://', '')
        .replaceFirst('https://', '');
    return 'ws://$host/ws';
  }
}
