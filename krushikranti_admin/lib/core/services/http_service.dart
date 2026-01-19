import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class HttpService {
  // Base URL - API Gateway
  // For web: uses localhost or production URL
  static const String baseUrl = "http://localhost:4004";

  // GET Request
  static Future<dynamic> get(String endpoint) async {
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
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
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
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
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
        throw Exception(errorMessage.isNotEmpty && errorMessage != 'An error occurred' 
            ? errorMessage 
            : 'Invalid email or password. Please check your credentials and try again.');
      } else if (response.statusCode == 403) {
        throw Exception(errorMessage.isNotEmpty && errorMessage != 'An error occurred'
            ? errorMessage
            : 'Access denied - Admin role required');
      } else if (response.statusCode == 404) {
        throw Exception('Service not found. Please try again later.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception(errorMessage.isNotEmpty && errorMessage != 'An error occurred'
            ? errorMessage
            : 'Error: ${response.statusCode}');
      }
    }
  }
}

