import '../../../core/services/http_service.dart';

class FieldOfficerAssignmentsPage {
  final List<dynamic> assignments;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int totalElements;
  final bool hasNext;
  final bool hasPrevious;

  const FieldOfficerAssignmentsPage({
    required this.assignments,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.totalElements,
    required this.hasNext,
    required this.hasPrevious,
  });
}

class FieldOfficerService {
  /// Get assignment summary for dashboard cards.
  static Future<Map<String, dynamic>> getAssignmentSummary() async {
    try {
      final response =
          await HttpService.get('field-officer/assignments/summary');
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Get paginated assignments payload for the logged-in field officer.
  static Future<FieldOfficerAssignmentsPage> getAssignedFarmsPage({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await HttpService.get(
        'field-officer/assignments?page=$page&size=$size',
      );

      final data = response is Map<String, dynamic> ? response['data'] : null;

      // New API shape: data = { assignments: [...], currentPage, totalPages, ... }
      if (data is Map<String, dynamic>) {
        final assignments = data['assignments'];
        return FieldOfficerAssignmentsPage(
          assignments: assignments is List ? assignments : <dynamic>[],
          currentPage: (data['currentPage'] as num?)?.toInt() ?? page,
          totalPages: (data['totalPages'] as num?)?.toInt() ?? 0,
          pageSize: (data['pageSize'] as num?)?.toInt() ?? size,
          totalElements: (data['totalElements'] as num?)?.toInt() ?? 0,
          hasNext: data['hasNext'] == true,
          hasPrevious: data['hasPrevious'] == true,
        );
      }

      // Backward-compatible shape: data = [assignments]
      if (data is List) {
        return FieldOfficerAssignmentsPage(
          assignments: data,
          currentPage: 0,
          totalPages: 1,
          pageSize: data.length,
          totalElements: data.length,
          hasNext: false,
          hasPrevious: false,
        );
      }

      return FieldOfficerAssignmentsPage(
        assignments: const <dynamic>[],
        currentPage: page,
        totalPages: 0,
        pageSize: size,
        totalElements: 0,
        hasNext: false,
        hasPrevious: page > 0,
      );
    } catch (_) {
      return FieldOfficerAssignmentsPage(
        assignments: const <dynamic>[],
        currentPage: page,
        totalPages: 0,
        pageSize: size,
        totalElements: 0,
        hasNext: false,
        hasPrevious: page > 0,
      );
    }
  }

  /// Get assigned farms for the logged-in field officer
  static Future<List<dynamic>> getAssignedFarms() async {
    final page = await getAssignedFarmsPage(page: 0, size: 1000);
    return page.assignments;
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

      if (response is Map && response.containsKey('data')) {
        final data = response['data'] as Map<String, dynamic>;
        return data;
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get verification photos for a farm
  static Future<List<Map<String, dynamic>>> getVerificationPhotos(
      int farmId) async {
    try {
      final response = await HttpService.get(
          'field-officer/verifications/farms/$farmId/photos');

      if (response is Map && response.containsKey('data')) {
        final List<dynamic> photos = response['data'] as List<dynamic>;
        return photos.map((photo) => photo as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}
