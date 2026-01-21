import '../../../core/services/http_service.dart';

class FieldOfficerService {
  /// Get assigned farms for the logged-in field officer
  static Future<List<dynamic>> getAssignedFarms() async {
    try {
      // GET /field-officer/assignments
      final response = await HttpService.get('field-officer/assignments');
      print('DEBUG: Full response: $response');
      
      // Response structure: { "message": "...", "data": [assignments] }
      // Each assignment has: assignmentId, farmerUserId, status, farms: [...]
      final data = response['data'];
      print('DEBUG: Response data type: ${data.runtimeType}');
      print('DEBUG: Response data: $data');
      
      if (data == null) {
        print('DEBUG: Response data is null');
        return [];
      }
      
      if (data is List) {
        print('DEBUG: Data is a List with ${data.length} items');
        return data;
      }
      
      print('DEBUG: Data is not a List, returning empty list');
      return [];
    } catch (e) {
      print('Error fetching assigned farms: $e');
      print('Error type: ${e.runtimeType}');
      return [];
    }
  }

  /// Verify a farm
  static Future<Map<String, dynamic>> verifyFarm({
    required String farmId,
    required String status, // VERIFIED only
    String? feedback,
    List<String>? photoUrls,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'farmId': int.parse(farmId),
        'status': status, // Only VERIFIED is allowed
      };

      if (feedback != null && feedback.isNotEmpty) {
        requestBody['feedback'] = feedback;
      }

      if (photoUrls != null && photoUrls.isNotEmpty) {
        requestBody['photoUrls'] = photoUrls;
      }

      // Add GPS coordinates
      if (latitude != null && longitude != null) {
        requestBody['latitude'] = latitude;
        requestBody['longitude'] = longitude;
      }

      final response = await HttpService.post(
        'field-officer/verify-farm',
        requestBody,
      );

      if (response is Map && response.containsKey('data')) {
        return response['data'] as Map<String, dynamic>;
      }

      return response as Map<String, dynamic>;
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

  /// Request OTP for farm verification
  static Future<Map<String, dynamic>> requestOtp({
    required String farmId,
  }) async {
    try {
      // POST /field-officer/farms/{farmId}/request-otp
      final response = await HttpService.post(
        'field-officer/farms/$farmId/request-otp',
        {},
      );

      if (response is Map && response.containsKey('data')) {
        return response['data'] as Map<String, dynamic>;
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error requesting OTP: $e');
      rethrow;
    }
  }

  /// Validate OTP for farm verification
  static Future<Map<String, dynamic>> validateOtp({
    required String farmId,
    required String otp,
  }) async {
    try {
      // POST /field-officer/farms/{farmId}/validate-otp
      final response = await HttpService.post(
        'field-officer/farms/$farmId/validate-otp',
        {
          'farmId': int.parse(farmId),
          'otp': otp,
        },
      );

      print('=== FieldOfficerService.validateOtp ===');
      print('Raw response: $response');
      print('Response type: ${response.runtimeType}');
      print('Has data key: ${response is Map && response.containsKey('data')}');

      if (response is Map && response.containsKey('data')) {
        final data = response['data'] as Map<String, dynamic>;
        print('Extracted data: $data');
        print('Data isValid: ${data['isValid']}');
        return data;
      }

      print('Returning response directly: $response');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error validating OTP: $e');
      rethrow;
    }
  }

  /// Get verification photos for a farm
  static Future<List<Map<String, dynamic>>> getVerificationPhotos(int farmId) async {
    try {
      final response = await HttpService.get('field-officer/verifications/farms/$farmId/photos');
      
      if (response is Map && response.containsKey('data')) {
        final List<dynamic> photos = response['data'] as List<dynamic>;
        return photos.map((photo) => photo as Map<String, dynamic>).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching verification photos: $e');
      return [];
    }
  }
}

