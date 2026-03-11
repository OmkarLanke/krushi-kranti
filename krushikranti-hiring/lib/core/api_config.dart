import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:4004';
    }
    // Android emulator uses 10.0.2.2 to reach host localhost
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:4004';
    }
    // iOS simulator, desktop, etc.
    return 'http://localhost:4004';
  }

  static String get applicationsEndpoint => '$baseUrl/api/applications';
}
