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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // Response Handler
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map && errorBody.containsKey('message')) {
          throw Exception(errorBody['message'] ?? 'An error occurred');
        }
      } catch (_) {}
      
      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied - Admin role required');
      } else {
        throw Exception('Error: ${response.statusCode} - ${response.body}');
      }
    }
  }
}

