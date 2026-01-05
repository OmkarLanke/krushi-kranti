import '../../../core/services/http_service.dart';

class FieldOfficerAssignmentService {
  /// Get field officer assignments for the logged-in farmer
  static Future<List<Map<String, dynamic>>> getAssignments() async {
    try {
      final response = await HttpService.get("field-officer/farmer/assignments");
      final List<dynamic> assignmentsData = response['data'] ?? [];
      
      return assignmentsData.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to fetch field officer assignments: $e');
    }
  }
}
