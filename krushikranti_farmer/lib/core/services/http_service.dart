import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'storage_service.dart'; // ✅ Import the new service

class HttpService {
  // Base URL - API Gateway with platform detection
  // ⚠️ IMPORTANT: 
  // - Web/Desktop: uses 'http://localhost:4004'
  // - Android/iOS: uses your local IP address (192.168.1.42)
  static String get baseUrl {
    if (kIsWeb) {
      // Web platform (Chrome browser, etc.)
      return "http://localhost:4004";
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platforms (Android/iOS) - use your computer's local IP
      return "http://192.168.1.42:4004"; // ✅ Your Wi-Fi IP address
    } else {
      // Desktop platforms (Windows, Mac, Linux)
      return "http://localhost:4004";
    }
  } 

  // ✅ Get saved language for Accept-Language header
  static Future<String> _getLanguageHeader() async {
    String? savedLang = await StorageService.getLanguage();
    return savedLang ?? 'en'; // Default to English
  }

  // --- GET REQUEST ---
  static Future<dynamic> get(String endpoint) async {
    final uri = endpoint.startsWith('http')
        ? Uri.parse(endpoint)
        : Uri.parse('$baseUrl/$endpoint');
    
    // ✅ ACTION: Fetch Token and Language from Storage
    String? token = await StorageService.getToken();
    String language = await _getLanguageHeader();
    
    try {
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": language, // ✅ Send language preference
          // ✅ ACTION: Attach Token if it exists
          if (token != null) "Authorization": "Bearer $token",
        },
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // --- POST REQUEST ---
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final uri = endpoint.startsWith('http')
        ? Uri.parse(endpoint)
        : Uri.parse('$baseUrl/$endpoint');
    
    // ✅ ACTION: Fetch Token and Language from Storage
    String? token = await StorageService.getToken();
    String language = await _getLanguageHeader();

    try {
      final response = await http.post(
        uri,
        body: jsonEncode(data),
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": language, // ✅ Send language preference
          // ✅ ACTION: Attach Token if it exists
          if (token != null) "Authorization": "Bearer $token",
        },
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // --- PUT REQUEST ---
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final uri = endpoint.startsWith('http')
        ? Uri.parse(endpoint)
        : Uri.parse('$baseUrl/$endpoint');
    
    // ✅ ACTION: Fetch Token and Language from Storage
    String? token = await StorageService.getToken();
    String language = await _getLanguageHeader();

    try {
      final response = await http.put(
        uri,
        body: jsonEncode(data),
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": language, // ✅ Send language preference
          // ✅ ACTION: Attach Token if it exists
          if (token != null) "Authorization": "Bearer $token",
        },
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // --- HELPER: Handle Status Codes ---
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      // Try to extract error message from ApiResponse format
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && errorBody.containsKey('message')) {
          throw Exception(errorBody['message'] ?? 'An error occurred');
        }
      } catch (_) {
        // If parsing fails, use the raw response
      }
      
      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Error: ${response.statusCode} - ${response.body}');
      }
    }
  }
}