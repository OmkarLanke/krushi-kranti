import '../../../core/services/http_service.dart';

class FieldOfficerService {
  /// Get assigned farms for the logged-in field officer
  static Future<List<dynamic>> getAssignedFarms() async {
    try {
      // TODO: Implement API call to field-officer-service
      // GET /field-officer/assignments
      final response = await HttpService.get('field-officer/assignments');
      return response['data'] ?? [];
    } catch (e) {
      print('Error fetching assigned farms: $e');
      return [];
    }
  }

  /// Verify a farm
  static Future<Map<String, dynamic>> verifyFarm({
    required String farmId,
    required String status, // VERIFIED, REJECTED
    String? feedback,
    List<String>? photoUrls,
  }) async {
    try {
      // TODO: Implement API call to field-officer-service
      // POST /field-officer/verify-farm
      final response = await HttpService.post(
        'field-officer/verify-farm',
        {
          'farmId': farmId,
          'status': status,
          'feedback': feedback,
          'photoUrls': photoUrls,
        },
      );
      return response;
    } catch (e) {
      print('Error verifying farm: $e');
      rethrow;
    }
  }

  /// Get field officer profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      // GET /field-officer/profile
      final response = await HttpService.get('field-officer/profile');
      
      // Handle different response structures
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          return response['data'] ?? {};
        } else {
          return response;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching profile: $e');
      return {};
    }
  }
}

