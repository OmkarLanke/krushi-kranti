import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'storage_service.dart'; // ✅ Import the new service

class HttpService {
  // Base URL - API Gateway with platform detection
  // ⚠️ IMPORTANT: 
  // - Web/Desktop: uses 'http://localhost:4004'
  // - Android/iOS: uses your local IP address (192.168.1.45)
  static String get baseUrl {
    if (kIsWeb) {
      // Web platform (Chrome browser, etc.)
      return "http://localhost:4004";
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platforms (Android/iOS) - use your computer's local IP
      return "http://192.168.1.64:4004"; // ✅ Your Wi-Fi IP address
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

  // --- FILE UPLOAD (Multipart) ---
  /// Upload a file to the file service
  /// Returns the URL of the uploaded file
  static Future<String> uploadFile(
    File file, {
    String? folder,
    String? fileName,
  }) async {
    final uri = Uri.parse('$baseUrl/file/upload');
    
    // Get token and language
    String? token = await StorageService.getToken();
    String language = await _getLanguageHeader();
    
    // Debug: Check if token exists
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing. Please login again.');
    }
    
    // Debug logging
    print('File upload - URI: $uri');
    print('File upload - Token exists: ${token.isNotEmpty}');
    print('File upload - File path: ${file.path}');
    print('File upload - File exists: ${await file.exists()}');
    
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', uri);
      
      // Add headers - IMPORTANT: Set headers before adding files
      // Note: Some gateways require headers to be set in a specific way for multipart
      request.headers.addAll({
        'Accept-Language': language,
        'Authorization': 'Bearer $token',
      });
      
      print('File upload - Headers set: ${request.headers}');
      
      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: fileName ?? file.path.split('/').last,
        contentType: MediaType('image', 'jpeg'), // Default to JPEG, can be made dynamic
      );
      request.files.add(multipartFile);
      
      // Add optional folder parameter
      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('File upload timed out. Please check your internet connection and try again.');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      // Debug: Log response for troubleshooting
      print('File upload response status: ${response.statusCode}');
      print('File upload response body: ${response.body}');
      
      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseBody = jsonDecode(response.body);
          
          // Extract URL from response
          // Expected format: { "data": { "url": "https://..." } } or { "url": "https://..." }
          if (responseBody is Map) {
            if (responseBody.containsKey('data') && responseBody['data'] is Map) {
              final data = responseBody['data'] as Map;
              if (data.containsKey('url')) {
                return data['url'] as String;
              }
            } else if (responseBody.containsKey('url')) {
              return responseBody['url'] as String;
            }
          }
          
          throw Exception('Invalid response format from file service: ${response.body}');
        } catch (e) {
          if (e is Exception && e.toString().contains('Invalid response format')) {
            rethrow;
          }
          throw Exception('Failed to parse file upload response: $e');
        }
      } else {
        // Try to extract error message
        String errorMessage = 'File upload failed';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map) {
            if (errorBody.containsKey('message')) {
              errorMessage = errorBody['message'] as String;
            } else if (errorBody.containsKey('error')) {
              errorMessage = errorBody['error'] as String;
            }
          }
        } catch (_) {
          // If parsing fails, use the raw response
          errorMessage = response.body.isNotEmpty 
              ? response.body
              : 'File upload failed with status ${response.statusCode}';
        }
        
        if (response.statusCode == 401) {
          throw Exception('Unauthorized - Please login again. Token may have expired.');
        } else if (response.statusCode == 404) {
          throw Exception('File upload endpoint not found. Please contact support.');
        } else {
          throw Exception('$errorMessage (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('File upload error: $e');
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