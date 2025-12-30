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
    required String status, // VERIFIED, REJECTED
    String? feedback,
    String? rejectionReason,
    List<String>? photoUrls,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'farmId': int.parse(farmId),
        'status': status,
      };

      if (feedback != null && feedback.isNotEmpty) {
        requestBody['feedback'] = feedback;
      }

      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        requestBody['rejectionReason'] = rejectionReason;
      }

      if (photoUrls != null && photoUrls.isNotEmpty) {
        requestBody['photoUrls'] = photoUrls;
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
}

