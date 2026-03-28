import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class HttpService {
  // Flag to prevent refresh token loops
  static bool _isRefreshing = false;
  static Future<bool>? _ongoingRefreshFuture;
  // Callback for when refresh fails (e.g., redirect to login)
  static Function? onAuthenticationFailed;

  // Base URL: production from --dart-define=BASE_URL=...; dev = localhost
  static String get baseUrl {
    const String envBaseUrl = String.fromEnvironment(
      'BASE_URL',
      defaultValue: '',
    );
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl.trim();
    }
    return "http://localhost:4004";
  }

  /// Attempt to refresh the access token using the refresh token.
  /// Returns true if successful, false otherwise.
  static Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      // If another request is already refreshing, wait for that result
      if (_ongoingRefreshFuture != null) {
        return await _ongoingRefreshFuture!;
      }
      return false;
    }

    _isRefreshing = true;
    final refreshFuture = () async {
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
        _ongoingRefreshFuture = null;
      }
    };

    _ongoingRefreshFuture = refreshFuture();
    return _ongoingRefreshFuture!;
  }

  /// Handle authentication failure - clear session and notify
  static Future<void> _handleAuthenticationFailure() async {
    await StorageService.clearSession();
    if (onAuthenticationFailed != null) {
      onAuthenticationFailed!();
    }
  }

  // GET Request
  static Future<dynamic> get(String endpoint, {bool isRetry = false}) async {
    final uri = endpoint.startsWith('http')
        ? Uri.parse(endpoint)
        : Uri.parse('$baseUrl/$endpoint');

    String? token = await StorageService.getToken();

    try {
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

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

      return _handleResponse(response);
    } on Exception {
      // Re-throw exceptions from _handleResponse (these are already formatted)
      rethrow;
    } catch (e) {
      // Only wrap non-Exception errors (like network failures) as Network Error
      throw Exception('Network Error: $e');
    }
  }

  // POST Request
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool isRetry = false,
  }) async {
    final uri = endpoint.startsWith('http')
        ? Uri.parse(endpoint)
        : Uri.parse('$baseUrl/$endpoint');

    String? token = await StorageService.getToken();

    try {
      final response = await http.post(
        uri,
        body: jsonEncode(data),
        headers: {
          "Content-Type": "application/json",
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

      return _handleResponse(response);
    } on Exception {
      // Re-throw exceptions from _handleResponse (these are already formatted)
      rethrow;
    } catch (e) {
      // Only wrap non-Exception errors (like network failures) as Network Error
      throw Exception('Network Error: $e');
    }
  }

  // PUT Request
  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool isRetry = false,
  }) async {
    final uri = endpoint.startsWith('http')
        ? Uri.parse(endpoint)
        : Uri.parse('$baseUrl/$endpoint');

    String? token = await StorageService.getToken();

    try {
      final response = await http.put(
        uri,
        body: jsonEncode(data),
        headers: {
          "Content-Type": "application/json",
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

      return _handleResponse(response);
    } on Exception {
      // Re-throw exceptions from _handleResponse (these are already formatted)
      rethrow;
    } catch (e) {
      // Only wrap non-Exception errors (like network failures) as Network Error
      throw Exception('Network Error: $e');
    }
  }

  // Response Handler
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      // Try to extract error message from response body
      String errorMessage = 'An error occurred';
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && errorBody.containsKey('message')) {
          errorMessage = errorBody['message'] ?? errorMessage;
        } else if (errorBody is Map && errorBody.containsKey('error')) {
          errorMessage = errorBody['error'] ?? errorMessage;
        }
      } catch (_) {
        // If parsing fails, use default messages based on status code
      }

      // Use backend message if available, otherwise use default
      if (response.statusCode == 401) {
        // Preserve backend's specific error message (e.g., "Invalid email or password")
        throw Exception(
          errorMessage.isNotEmpty && errorMessage != 'An error occurred'
              ? errorMessage
              : 'Invalid email or password. Please check your credentials and try again.',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          errorMessage.isNotEmpty && errorMessage != 'An error occurred'
              ? errorMessage
              : 'Access denied - Admin role required',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Service not found. Please try again later.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception(
          errorMessage.isNotEmpty && errorMessage != 'An error occurred'
              ? errorMessage
              : 'Error: ${response.statusCode}',
        );
      }
    }
  }

  // DELETE Request (with optional JSON body)
  static Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? data,
    bool isRetry = false,
  }) async {
    final uri = endpoint.startsWith('http')
        ? Uri.parse(endpoint)
        : Uri.parse('$baseUrl/$endpoint');

    String? token = await StorageService.getToken();

    try {
      final response = await http.delete(
        uri,
        body: data != null ? jsonEncode(data) : null,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      // Handle 401 with token refresh (only on first attempt)
      if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return await delete(endpoint, data: data, isRetry: true);
        } else {
          await _handleAuthenticationFailure();
          throw Exception('Session expired. Please login again.');
        }
      }

      return _handleResponse(response);
    } on Exception {
      // Re-throw exceptions from _handleResponse (these are already formatted)
      rethrow;
    } catch (e) {
      // Only wrap non-Exception errors (like network failures) as Network Error
      throw Exception('Network Error: $e');
    }
  }
}
