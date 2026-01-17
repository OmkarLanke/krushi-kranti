/// Simple cache service for field officer data to avoid reloading
class FieldOfficerCache {
  static List<dynamic>? _cachedAssignments;
  static Map<String, dynamic>? _cachedProfile;
  static DateTime? _assignmentsCacheTime;
  static DateTime? _profileCacheTime;
  
  // Cache duration: 30 seconds (short enough to stay fresh, long enough to speed up navigation)
  static const _cacheDuration = Duration(seconds: 30);

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

  /// Cache profile data
  static void cacheProfile(Map<String, dynamic> profile) {
    _cachedProfile = profile;
    _profileCacheTime = DateTime.now();
  }

  /// Clear all cached data
  static void clearCache() {
    _cachedAssignments = null;
    _cachedProfile = null;
    _assignmentsCacheTime = null;
    _profileCacheTime = null;
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
}