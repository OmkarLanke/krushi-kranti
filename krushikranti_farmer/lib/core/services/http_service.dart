import 'dart:convert';
import 'dart:io' show Platform, File;
import 'dart:isolate';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'storage_service.dart'; // ✅ Import the new service

class HttpService {
  // Flag to prevent refresh token loops
  static bool _isRefreshing = false;
  // Callback for when refresh fails (e.g., redirect to login)
  static Function? onAuthenticationFailed;
  // Base URL: production from --dart-define=BASE_URL=...; dev = localhost / local IP
  static String get baseUrl {
    const String envBaseUrl = String.fromEnvironment(
      'BASE_URL',
      defaultValue: '',
    );
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl.trim();
    }
    // Development: platform-based URLs
    if (kIsWeb) {
      return "http://localhost:4004";
    } else if (Platform.isAndroid || Platform.isIOS) {
      return "http://192.168.1.120:4004"; // Your Wi-Fi IP for device testing
    } else {
      return "http://localhost:4004";
    }
  }

  // ✅ Get saved language for Accept-Language header
  static Future<String> _getLanguageHeader() async {
    String? savedLang = await StorageService.getLanguage();
    return savedLang ?? 'en'; // Default to English
  }

  /// Attempt to refresh the access token using the refresh token.
  /// Returns true if successful, false otherwise.
  static Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      return false; // Prevent concurrent refresh attempts
    }

    _isRefreshing = true;
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('No refresh token available');
        return false;
      }

      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await http.post(
        uri,
        body: jsonEncode({'refreshToken': refreshToken}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = jsonDecode(response.body);
        final newAccessToken = responseBody['accessToken'] as String?;
        final newRefreshToken = responseBody['refreshToken'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await StorageService.saveToken(newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await StorageService.saveRefreshToken(newRefreshToken);
          }
          debugPrint('Token refreshed successfully');
          return true;
        }
      }

      debugPrint('Token refresh failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Handle authentication failure - clear session and notify
  static Future<void> _handleAuthenticationFailure() async {
    await StorageService.clearSession();
    if (onAuthenticationFailed != null) {
      onAuthenticationFailed!();
    }
  }

  // --- GET REQUEST ---
  static Future<dynamic> get(String endpoint, {bool isRetry = false}) async {
    final uri = endpoint.startsWith('http')
        ? Uri.parse(endpoint)
        : Uri.parse('$baseUrl/$endpoint');

    // ✅ ACTION: Fetch Token and Language from Storage
    String? token = await StorageService.getToken();
    String language = await _getLanguageHeader();

    // Optimized: Removed debug logging that exposes sensitive token information

    try {
      final headers = <String, String>{
        "Content-Type": "application/json",
        "Accept-Language": language,
      };

      // ✅ ACTION: Attach Token if it exists
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }

      final response = await http.get(uri, headers: headers);

      // Optimized: Only log in debug mode and for specific endpoints
      if (kDebugMode && endpoint.contains('notification')) {
        debugPrint('Response Status: ${response.statusCode}');
      }

      // Handle 401 with token refresh (only on first attempt)
      if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return await get(endpoint, isRetry: true);
        } else {
          await _handleAuthenticationFailure();
          throw Exception('Session expired. Please login again.');
        }
      }

      return await _handleResponse(response);
    } catch (e) {
      if (endpoint.contains('notification')) {
        debugPrint('Error in GET request: $e');
      }
      if (e is Exception) rethrow;
      throw Exception('Network Error: $e');
    }
  }

  // --- POST REQUEST ---
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data,
      {bool isRetry = false}) async {
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

      // Handle 401 with token refresh (only on first attempt, skip for auth endpoints)
      if (response.statusCode == 401 &&
          !isRetry &&
          !endpoint.contains('auth/')) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return await post(endpoint, data, isRetry: true);
        } else {
          await _handleAuthenticationFailure();
          throw Exception('Session expired. Please login again.');
        }
      }

      return await _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network Error: $e');
    }
  }

  // --- PUT REQUEST ---
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data,
      {bool isRetry = false}) async {
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

      // Handle 401 with token refresh (only on first attempt)
      if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return await put(endpoint, data, isRetry: true);
        } else {
          await _handleAuthenticationFailure();
          throw Exception('Session expired. Please login again.');
        }
      }

      return await _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
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
    bool isRetry = false,
  }) async {
    final uri = Uri.parse('$baseUrl/file/upload');

    // Get token and language
    String? token = await StorageService.getToken();
    String language = await _getLanguageHeader();

    // Check if token exists
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing. Please login again.');
    }

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add headers - IMPORTANT: Set headers before adding files
      // Note: Some gateways require headers to be set in a specific way for multipart
      request.headers.addAll({
        'Accept-Language': language,
        'Authorization': 'Bearer $token',
      });

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: fileName ?? file.path.split('/').last,
        contentType:
            MediaType('image', 'jpeg'), // Default to JPEG, can be made dynamic
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
          throw Exception(
              'File upload timed out. Please check your internet connection and try again.');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseBody = jsonDecode(response.body);

          // Extract URL from response
          // Expected format: { "data": { "url": "https://..." } } or { "url": "https://..." }
          if (responseBody is Map) {
            if (responseBody.containsKey('data') &&
                responseBody['data'] is Map) {
              final data = responseBody['data'] as Map;
              if (data.containsKey('url')) {
                return data['url'] as String;
              }
            } else if (responseBody.containsKey('url')) {
              return responseBody['url'] as String;
            }
          }

          throw Exception(
              'Invalid response format from file service: ${response.body}');
        } catch (e) {
          if (e is Exception &&
              e.toString().contains('Invalid response format')) {
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
          // Handle 401 with token refresh (only on first attempt)
          if (!isRetry) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              return await uploadFile(file,
                  folder: folder, fileName: fileName, isRetry: true);
            } else {
              await _handleAuthenticationFailure();
              throw Exception('Session expired. Please login again.');
            }
          }
          throw Exception(
              'Unauthorized - Please login again. Token may have expired.');
        } else if (response.statusCode == 404) {
          throw Exception(
              'File upload endpoint not found. Please contact support.');
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

  // --- HELPER: Parse JSON in isolate for large responses (prevents UI freezes) ---
  static Future<dynamic> _parseJsonInIsolate(String jsonString) async {
    // For small responses, parse on main thread (faster)
    // For large responses (> 100KB), use isolate to prevent UI freezes
    if (jsonString.length < 100000) {
      return jsonDecode(jsonString);
    }

    // Use isolate for large JSON parsing
    return await Isolate.run(() => jsonDecode(jsonString));
  }

  // --- HELPER: Handle Status Codes ---
  static Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Optimized: Use isolate for large JSON responses to prevent UI freezes
      return await _parseJsonInIsolate(response.body);
    } else {
      // Try to extract error message from ApiResponse format
      String? errorMessage;
      try {
        final errorBody = await _parseJsonInIsolate(response.body);
        if (errorBody is Map && errorBody.containsKey('message')) {
          errorMessage = errorBody['message'] as String?;
        }
      } catch (e) {
        // If parsing fails, errorMessage remains null
        debugPrint('Failed to parse error response: $e');
      }

      // Use extracted message or default based on status code
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Resource not found');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    }
  }
}
