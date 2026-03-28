import '../../../core/services/http_service.dart';
import '../models/assignment_models.dart';

class _AssignmentPageCacheEntry {
  final PagedAssignmentsResponse data;
  final DateTime cachedAt;

  const _AssignmentPageCacheEntry({required this.data, required this.cachedAt});
}

class FieldOfficerAssignmentService {
  static const String _basePath = 'admin/field-officers';
  static final Map<String, _AssignmentPageCacheEntry> _assignmentPageCache = {};
  static const Duration _assignmentsCacheTtl = Duration(seconds: 90);

  static String _cacheKey(int fieldOfficerId, int page, int size) =>
      '$fieldOfficerId:$page:$size';

  static PagedAssignmentsResponse? getCachedAssignmentsForFieldOfficer(
    int fieldOfficerId, {
    int page = 0,
    int size = 20,
  }) {
    final key = _cacheKey(fieldOfficerId, page, size);
    final entry = _assignmentPageCache[key];
    if (entry == null) {
      return null;
    }

    final isExpired =
        DateTime.now().difference(entry.cachedAt) > _assignmentsCacheTtl;
    if (isExpired) {
      _assignmentPageCache.remove(key);
      return null;
    }

    return entry.data;
  }

  static void invalidateAssignmentsCache({int? fieldOfficerId}) {
    if (fieldOfficerId == null) {
      _assignmentPageCache.clear();
      return;
    }

    final prefix = '$fieldOfficerId:';
    _assignmentPageCache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Get suggested field officers for a farmer based on pincode matching.
  /// If farmId is provided, only field officers matching that specific farm's pincode are returned.
  static Future<List<SuggestedFieldOfficer>> getSuggestedFieldOfficers(
    int farmerUserId, {
    int? farmId,
  }) async {
    try {
      String url = '$_basePath/suggestions/$farmerUserId';
      if (farmId != null) {
        url += '?farmId=$farmId';
      }
      final response = await HttpService.get(url);

      if (response is Map && response.containsKey('data')) {
        final data = response['data'] as List;
        return data
            .map(
              (e) => SuggestedFieldOfficer.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception(
        'Failed to get suggested field officers: ${e.toString()}',
      );
    }
  }

  /// Assign a field officer to a farmer
  static Future<AssignmentResponse> assignFieldOfficer(
    AssignFieldOfficerRequest request,
  ) async {
    try {
      final response = await HttpService.post(
        '$_basePath/assign',
        request.toJson(),
      );

      if (response is Map && response.containsKey('data')) {
        invalidateAssignmentsCache(fieldOfficerId: request.fieldOfficerId);
        return AssignmentResponse.fromJson(
          response['data'] as Map<String, dynamic>,
        );
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
    int farmerUserId,
  ) async {
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

  /// Get paginated assignments for a field officer (with farmer and farm details)
  static Future<PagedAssignmentsResponse> getAssignmentsForFieldOfficer(
    int fieldOfficerId, {
    int page = 0,
    int size = 20,
    bool useCache = true,
  }) async {
    try {
      if (useCache) {
        final cached = getCachedAssignmentsForFieldOfficer(
          fieldOfficerId,
          page: page,
          size: size,
        );
        if (cached != null) {
          return cached;
        }
      }

      final response = await HttpService.get(
        '$_basePath/assignments?fieldOfficerId=$fieldOfficerId&page=$page&size=$size',
      );

      if (response is Map && response.containsKey('data')) {
        final data = response['data'];

        if (data is Map<String, dynamic>) {
          final parsed = PagedAssignmentsResponse.fromJson(data);
          _assignmentPageCache[_cacheKey(fieldOfficerId, page, size)] =
              _AssignmentPageCacheEntry(data: parsed, cachedAt: DateTime.now());
          return parsed;
        }

        // Legacy fallback: handle list response shape.
        if (data is List) {
          final assignments = data
              .map(
                (e) => AssignmentResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList();
          final parsed = PagedAssignmentsResponse(
            assignments: assignments,
            currentPage: 0,
            totalPages: 1,
            totalElements: assignments.length,
            pageSize: assignments.length,
            hasNext: false,
            hasPrevious: false,
          );
          _assignmentPageCache[_cacheKey(fieldOfficerId, page, size)] =
              _AssignmentPageCacheEntry(data: parsed, cachedAt: DateTime.now());
          return parsed;
        }
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception(
        'Failed to get assignments for field officer: ${e.toString()}',
      );
    }
  }

  /// Get verification photos for a farm
  static Future<List<Map<String, dynamic>>> getVerificationPhotos(
    int farmId,
  ) async {
    try {
      final response = await HttpService.get(
        'admin/field-officers/verifications/farms/$farmId/photos',
      );

      if (response is Map && response.containsKey('data')) {
        final List<dynamic> photos = response['data'] as List<dynamic>;
        return photos.map((photo) => photo as Map<String, dynamic>).toList();
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to get verification photos: ${e.toString()}');
    }
  }
}
