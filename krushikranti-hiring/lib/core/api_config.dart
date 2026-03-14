import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    const String envBaseUrl = String.fromEnvironment('BASE_URL', defaultValue: '');
    if (envBaseUrl.isNotEmpty) return envBaseUrl.trim();

    if (kIsWeb) return 'http://localhost:4004';
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:4004';
    return 'http://localhost:4004';
  }

  static String get applicationsEndpoint => '$baseUrl/api/applications';
}
