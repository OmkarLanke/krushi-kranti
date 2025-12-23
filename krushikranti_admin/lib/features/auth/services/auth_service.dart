import '../../../core/services/http_service.dart';
import '../../../core/services/storage_service.dart';

class AuthService {
  /// Login with email and password
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await HttpService.post('auth/login', {
      'email': email,
      'password': password,
    });

    if (response == null) {
      throw Exception('Login failed - no response');
    }

    // Check if user has ADMIN role
    final user = response['user'];
    if (user == null || user['role'] != 'ADMIN') {
      throw Exception('Access denied - Admin role required');
    }

    // Save token and user details
    await StorageService.saveToken(response['accessToken']);
    await StorageService.saveUserDetails(
      userId: user['id'].toString(),
      username: user['username'] ?? '',
      email: user['email'] ?? '',
      role: user['role'] ?? '',
    );

    return response;
  }

  /// Logout
  static Future<void> logout() async {
    await StorageService.clearSession();
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await StorageService.isLoggedIn();
  }

  /// Get current user role
  static Future<String?> getCurrentRole() async {
    return await StorageService.getRole();
  }
}

