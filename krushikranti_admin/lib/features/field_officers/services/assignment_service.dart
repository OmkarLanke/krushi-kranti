import '../../../core/services/http_service.dart';
import '../models/assignment_models.dart';

class FieldOfficerAssignmentService {
  static const String _basePath = 'admin/field-officers';

  /// Get suggested field officers for a farmer based on pincode matching
  static Future<List<SuggestedFieldOfficer>> getSuggestedFieldOfficers(
      int farmerUserId) async {
    try {
      final response = await HttpService.get('$_basePath/suggestions/$farmerUserId');

      if (response is Map && response.containsKey('data')) {
        final data = response['data'] as List;
        return data
            .map((e) => SuggestedFieldOfficer.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to get suggested field officers: ${e.toString()}');
    }
  }

  /// Assign a field officer to a farmer
  static Future<AssignmentResponse> assignFieldOfficer(
      AssignFieldOfficerRequest request) async {
    try {
      final response = await HttpService.post(
        '$_basePath/assign',
        request.toJson(),
      );

      if (response is Map && response.containsKey('data')) {
        return AssignmentResponse.fromJson(response['data'] as Map<String, dynamic>);
      }

      // Check if there's an error message in the response
      if (response is Map && response.containsKey('message')) {
        throw Exception(response['message'] as String);
      }

      throw Exception('Invalid response format');
    } catch (e) {
      // HttpService already extracts error messages, so just re-throw
      rethrow;
    }
  }

  /// Get all assignments for a farmer
  static Future<List<AssignmentResponse>> getAssignmentsForFarmer(
      int farmerUserId) async {
    try {
      final response = await HttpService.get(
        '$_basePath/assignments?farmerUserId=$farmerUserId',
      );

      if (response is Map && response.containsKey('data')) {
        final data = response['data'] as List;
        return data
            .map((e) => AssignmentResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to get assignments: ${e.toString()}');
    }
  }
}

