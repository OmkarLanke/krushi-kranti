import '../models/job_application_models.dart';
import '../../../core/services/http_service.dart';

class JobApplicationService {
  // Get all applications with optional filters
  Future<List<JobApplication>> getAllApplications({
    String? status,
    String? roleType,
    String? searchQuery,
  }) async {
    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {};

      if (status != null && status.isNotEmpty && status != 'ALL') {
        queryParams['status'] = status;
      }

      if (roleType != null && roleType.isNotEmpty && roleType != 'ALL') {
        queryParams['roleType'] = roleType;
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      // Build query string
      String endpoint = 'api/applications';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      final response = await HttpService.get(endpoint);

      if (response is List) {
        return response
            .map(
              (json) => JobApplication.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
    } catch (e) {
      print('Error fetching job applications: $e');
      return [];
    }
  }

  // Get application by ID
  Future<JobApplication?> getApplicationById(String id) async {
    try {
      final response = await HttpService.get('api/applications/$id');
      return JobApplication.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching job application $id: $e');
      return null;
    }
  }

  // Get statistics
  Future<JobApplicationStats> getStats() async {
    try {
      // Get all applications and calculate stats from them
      final applications = await getAllApplications();

      return JobApplicationStats(
        total: applications.length,
        screening: applications
            .where((a) => a.currentStatus == 'SCREENING')
            .length,
        selectedForHR: applications
            .where((a) => a.currentStatus == 'SELECTED_FOR_HR')
            .length,
        selected: applications
            .where((a) => a.currentStatus == 'SELECTED')
            .length,
        rejected: applications
            .where((a) => a.currentStatus == 'REJECTED')
            .length,
      );
    } catch (e) {
      print('Error fetching job application stats: $e');
      // Return default stats on error
      return JobApplicationStats(
        total: 0,
        screening: 0,
        selectedForHR: 0,
        selected: 0,
        rejected: 0,
      );
    }
  }

  // Update application status (kept for backward compatibility, but not used anymore)
  Future<bool> updateApplicationStatus(String id, String newStatus) async {
    // This method is no longer needed as we use specific endpoints
    // (schedule-hr, send-offer, reject) from the detail screen
    return false;
  }

  // Get available status options
  List<String> getStatusOptions() {
    return ['SCREENING', 'SELECTED_FOR_HR', 'SELECTED', 'REJECTED'];
  }

  // Get available role type options
  List<String> getRoleTypeOptions() {
    return ['FIELD_OFFICER', 'KRUSHI_TADNYA', 'VENDOR'];
  }

  // Get status display text
  String getStatusDisplay(String status) {
    switch (status) {
      case 'SCREENING':
        return 'Screening';
      case 'SELECTED_FOR_HR':
        return 'Selected for HR';
      case 'SELECTED':
        return 'Selected';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }

  // Get role type display text
  String getRoleTypeDisplay(String roleType) {
    switch (roleType) {
      case 'FIELD_OFFICER':
        return 'Field Officer';
      case 'KRUSHI_TADNYA':
        return 'Krushi Tadnya';
      case 'VENDOR':
        return 'Vendor';
      default:
        return roleType;
    }
  }
}
