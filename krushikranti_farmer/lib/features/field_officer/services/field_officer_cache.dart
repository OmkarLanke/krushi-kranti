/// Simple cache service for field officer data to avoid reloading
class FieldOfficerCache {
  static List<dynamic>? _cachedAssignments;
  static Map<String, dynamic>? _cachedProfile;
  static Map<String, dynamic>? _cachedSummary;
  static DateTime? _assignmentsCacheTime;
  static DateTime? _profileCacheTime;
  static DateTime? _summaryCacheTime;

  // Fresh cache duration for active UI usage.
  static const _cacheDuration = Duration(minutes: 2);

  // Stale cache duration for stale-while-revalidate fallback.
  static const _staleDuration = Duration(minutes: 10);

  /// Get cached assignments if still valid, otherwise null
  static List<dynamic>? getCachedAssignments() {
    if (_cachedAssignments != null && _assignmentsCacheTime != null) {
      final age = DateTime.now().difference(_assignmentsCacheTime!);
      if (age < _cacheDuration) {
        return _cachedAssignments;
      }
    }
    return null;
  }

  /// Get cached assignments even if stale-but-usable (for instant UI + background refresh).
  static List<dynamic>? getCachedOrStaleAssignments() {
    if (_cachedAssignments != null && _assignmentsCacheTime != null) {
      final age = DateTime.now().difference(_assignmentsCacheTime!);
      if (age < _staleDuration) {
        return _cachedAssignments;
      }
    }
    return null;
  }

  /// Cache assignments data
  static void cacheAssignments(List<dynamic> assignments) {
    _cachedAssignments = assignments;
    _assignmentsCacheTime = DateTime.now();
  }

  /// Get cached profile if still valid, otherwise null
  static Map<String, dynamic>? getCachedProfile() {
    if (_cachedProfile != null && _profileCacheTime != null) {
      final age = DateTime.now().difference(_profileCacheTime!);
      if (age < _cacheDuration) {
        return _cachedProfile;
      }
    }
    return null;
  }

  /// Get cached summary if still valid, otherwise null
  static Map<String, dynamic>? getCachedSummary() {
    if (_cachedSummary != null && _summaryCacheTime != null) {
      final age = DateTime.now().difference(_summaryCacheTime!);
      if (age < _cacheDuration) {
        return _cachedSummary;
      }
    }
    return null;
  }

  /// Get cached summary even if stale-but-usable.
  static Map<String, dynamic>? getCachedOrStaleSummary() {
    if (_cachedSummary != null && _summaryCacheTime != null) {
      final age = DateTime.now().difference(_summaryCacheTime!);
      if (age < _staleDuration) {
        return _cachedSummary;
      }
    }
    return null;
  }

  /// Cache assignment summary data
  static void cacheSummary(Map<String, dynamic> summary) {
    _cachedSummary = summary;
    _summaryCacheTime = DateTime.now();
  }

  /// Get cached profile even if stale-but-usable (for instant UI + background refresh).
  static Map<String, dynamic>? getCachedOrStaleProfile() {
    if (_cachedProfile != null && _profileCacheTime != null) {
      final age = DateTime.now().difference(_profileCacheTime!);
      if (age < _staleDuration) {
        return _cachedProfile;
      }
    }
    return null;
  }

  /// Cache profile data
  static void cacheProfile(Map<String, dynamic> profile) {
    _cachedProfile = profile;
    _profileCacheTime = DateTime.now();
  }

  /// Clear all cached data
  static void clearCache() {
    _cachedAssignments = null;
    _cachedProfile = null;
    _cachedSummary = null;
    _assignmentsCacheTime = null;
    _profileCacheTime = null;
    _summaryCacheTime = null;
  }

  /// Clear assignments cache only
  static void clearAssignmentsCache() {
    _cachedAssignments = null;
    _assignmentsCacheTime = null;
  }

  /// Clear profile cache only
  static void clearProfileCache() {
    _cachedProfile = null;
    _profileCacheTime = null;
  }

  /// Clear summary cache only
  static void clearSummaryCache() {
    _cachedSummary = null;
    _summaryCacheTime = null;
  }
}
