import 'field_officer_cache.dart';
import 'field_officer_service.dart';

class FieldOfficerDashboardData {
  final Map<String, dynamic> profile;
  final List<dynamic> assignments;

  const FieldOfficerDashboardData({
    required this.profile,
    required this.assignments,
  });
}

class FieldOfficerRepository {
  static Future<FieldOfficerDashboardData>? _dashboardInFlight;
  static Future<Map<String, dynamic>>? _profileInFlight;
  static Future<List<dynamic>>? _assignmentsInFlight;
  static Future<Map<String, dynamic>>? _summaryInFlight;

  static FieldOfficerDashboardData? getCachedDashboardData({
    bool includeStale = false,
  }) {
    final profile = includeStale
        ? FieldOfficerCache.getCachedOrStaleProfile()
        : FieldOfficerCache.getCachedProfile();
    final assignments = includeStale
        ? FieldOfficerCache.getCachedOrStaleAssignments()
        : FieldOfficerCache.getCachedAssignments();

    if (profile == null && assignments == null) {
      return null;
    }

    return FieldOfficerDashboardData(
      profile: profile ?? <String, dynamic>{},
      assignments: assignments ?? <dynamic>[],
    );
  }

  static Future<FieldOfficerDashboardData> getDashboardData({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = getCachedDashboardData(includeStale: false);
      if (cached != null &&
          cached.profile.isNotEmpty &&
          cached.assignments.isNotEmpty) {
        return cached;
      }
    }

    if (!forceRefresh && _dashboardInFlight != null) {
      return _dashboardInFlight!;
    }

    final request = _fetchDashboardData();
    _dashboardInFlight = request;
    try {
      return await request;
    } finally {
      if (identical(_dashboardInFlight, request)) {
        _dashboardInFlight = null;
      }
    }
  }

  static Future<FieldOfficerDashboardData> _fetchDashboardData() async {
    final results = await Future.wait<dynamic>([
      getProfile(forceRefresh: true),
      getAssignments(forceRefresh: true),
    ]);

    return FieldOfficerDashboardData(
      profile: results[0] as Map<String, dynamic>,
      assignments: results[1] as List<dynamic>,
    );
  }

  static Future<Map<String, dynamic>> getProfile({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = FieldOfficerCache.getCachedProfile();
      if (cached != null) {
        return cached;
      }
    }

    if (!forceRefresh && _profileInFlight != null) {
      return _profileInFlight!;
    }

    final request = _fetchProfile();
    _profileInFlight = request;
    try {
      return await request;
    } finally {
      if (identical(_profileInFlight, request)) {
        _profileInFlight = null;
      }
    }
  }

  static Future<Map<String, dynamic>> _fetchProfile() async {
    final profile = await FieldOfficerService.getProfile();
    if (profile.isNotEmpty) {
      FieldOfficerCache.cacheProfile(profile);
    }
    return profile;
  }

  static Future<List<dynamic>> getAssignments({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = FieldOfficerCache.getCachedAssignments();
      if (cached != null) {
        return cached;
      }
    }

    if (!forceRefresh && _assignmentsInFlight != null) {
      return _assignmentsInFlight!;
    }

    final request = _fetchAssignments();
    _assignmentsInFlight = request;
    try {
      return await request;
    } finally {
      if (identical(_assignmentsInFlight, request)) {
        _assignmentsInFlight = null;
      }
    }
  }

  static Future<List<dynamic>> _fetchAssignments() async {
    final assignments = await FieldOfficerService.getAssignedFarms();
    FieldOfficerCache.cacheAssignments(assignments);
    return assignments;
  }

  static Future<Map<String, dynamic>> getAssignmentSummary({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = FieldOfficerCache.getCachedSummary();
      if (cached != null) {
        return cached;
      }
    }

    if (!forceRefresh && _summaryInFlight != null) {
      return _summaryInFlight!;
    }

    final request = _fetchAssignmentSummary();
    _summaryInFlight = request;
    try {
      return await request;
    } finally {
      if (identical(_summaryInFlight, request)) {
        _summaryInFlight = null;
      }
    }
  }

  static Future<Map<String, dynamic>> _fetchAssignmentSummary() async {
    final summary = await FieldOfficerService.getAssignmentSummary();
    if (summary.isNotEmpty) {
      FieldOfficerCache.cacheSummary(summary);
    }
    return summary;
  }

  static Future<FieldOfficerAssignmentsPage> getAssignmentsPage({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final result = await FieldOfficerService.getAssignedFarmsPage(
      page: page,
      size: size,
    );

    if (page == 0 && (forceRefresh || result.assignments.isNotEmpty)) {
      FieldOfficerCache.cacheAssignments(result.assignments);
    }

    return result;
  }
}
