import '../../../core/services/http_service.dart';

class FieldOfficerAssignmentService {
  static List<Map<String, dynamic>>? _cachedAssignments;
  static DateTime? _cacheTime;
  static Future<List<Map<String, dynamic>>>? _inFlightRequest;
  static const Duration _cacheTtl = Duration(seconds: 30);

  /// Get field officer assignments for the logged-in farmer
  static Future<List<Map<String, dynamic>>> getAssignments({
    bool forceRefresh = false,
    int page = 0,
    int size = 50,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        page == 0 &&
        _cachedAssignments != null &&
        _cacheTime != null &&
        now.difference(_cacheTime!) < _cacheTtl) {
      return _cachedAssignments!;
    }

    if (!forceRefresh && _inFlightRequest != null) {
      return _inFlightRequest!;
    }

    final request = _fetchAssignments(page: page, size: size);
    _inFlightRequest = request;
    try {
      final result = await request;
      if (page == 0) {
        _cachedAssignments = result;
        _cacheTime = DateTime.now();
      }
      return result;
    } finally {
      if (identical(_inFlightRequest, request)) {
        _inFlightRequest = null;
      }
    }
  }

  static void clearCache() {
    _cachedAssignments = null;
    _cacheTime = null;
  }

  static Future<List<Map<String, dynamic>>> _fetchAssignments({
    required int page,
    required int size,
  }) async {
    try {
      final response = await HttpService.get(
        "field-officer/farmer/assignments?page=$page&size=$size",
      );

      final dynamic data = response['data'];
      List<dynamic> assignmentsData;

      if (data is List) {
        assignmentsData = data;
      } else if (data is Map<String, dynamic>) {
        final dynamic nested = data['assignments'];
        assignmentsData = nested is List ? nested : <dynamic>[];
      } else {
        assignmentsData = <dynamic>[];
      }

      return assignmentsData
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch field officer assignments: $e');
    }
  }
}
