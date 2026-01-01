import '../../../core/services/http_service.dart';
import '../models/assignment_models.dart';

class FieldOfficerAssignmentService {
  static const String _basePath = 'admin/field-officers';

  /// Get suggested field officers for a farmer based on pincode matching.
  /// If farmId is provided, only field officers matching that specific farm's pincode are returned.
  static Future<List<SuggestedFieldOfficer>> getSuggestedFieldOfficers(
      int farmerUserId, {int? farmId}) async {
    try {
      String url = '$_basePath/suggestions/$farmerUserId';
      if (farmId != null) {
        url += '?farmId=$farmId';
      }
      final response = await HttpService.get(url);

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

  /// Get all assignments for a field officer (with farmer and farm details)
  static Future<List<AssignmentResponse>> getAssignmentsForFieldOfficer(
      int fieldOfficerId) async {
    try {
      final response = await HttpService.get(
        '$_basePath/assignments?fieldOfficerId=$fieldOfficerId&page=0&size=1000',
      );

      if (response is Map && response.containsKey('data')) {
        final data = response['data'] as Map<String, dynamic>;
        if (data.containsKey('assignments')) {
          final assignments = data['assignments'] as List;
          return assignments
              .map((e) => AssignmentResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        // Fallback: if data is directly a list
        if (data is List) {
          return (data as List)
              .map((e) => AssignmentResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to get assignments for field officer: ${e.toString()}');
    }
  }
}

