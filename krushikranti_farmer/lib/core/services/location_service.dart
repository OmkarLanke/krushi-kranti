import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling GPS location operations
class LocationService {
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  static Future<PermissionStatus> checkLocationPermission() async {
    return await Permission.location.status;
  }

  /// Request location permission
  static Future<PermissionStatus> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status;
  }

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    final status = await checkLocationPermission();
    return status.isGranted;
  }

  /// Get current GPS position with high accuracy
  /// Returns Position object with latitude, longitude, and accuracy
  static Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 30),
  }) async {
    // Check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Location services are disabled. Please enable location services in your device settings.',
      );
    }

    // Check and request permission
    PermissionStatus permission = await checkLocationPermission();
    if (permission.isDenied) {
      permission = await requestLocationPermission();
    }

    if (permission.isPermanentlyDenied) {
      throw LocationException(
        'Location permission is permanently denied. Please enable it in app settings.',
      );
    }

    if (!permission.isGranted) {
      throw LocationException(
        'Location permission is required to capture GPS coordinates.',
      );
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit,
      );

      // Validate accuracy
      if (position.accuracy > 50) {
        throw LocationException(
          'GPS signal is weak. Accuracy: ${position.accuracy.toStringAsFixed(1)}m. Please move to an open area and try again.',
        );
      }

      return position;
    } on TimeoutException {
      throw LocationException(
        'Location request timed out. Please ensure you have a clear view of the sky and try again.',
      );
    } catch (e) {
      throw LocationException(
        'Failed to get location: ${e.toString()}',
      );
    }
  }

  /// Get current position with custom accuracy requirement
  /// Throws exception if accuracy is worse than required
  static Future<Position> getCurrentPositionWithAccuracy({
    required double maxAccuracy, // in meters
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 30),
  }) async {
    Position position = await getCurrentPosition(
      accuracy: accuracy,
      timeLimit: timeLimit,
    );

    if (position.accuracy > maxAccuracy) {
      throw LocationException(
        'GPS accuracy (${position.accuracy.toStringAsFixed(1)}m) is worse than required (${maxAccuracy}m). Please move to an open area and try again.',
      );
    }

    return position;
  }

  /// Calculate distance between two GPS coordinates in meters
  /// Uses Haversine formula
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if two locations are within specified distance threshold
  static bool isWithinDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double thresholdMeters,
  ) {
    double distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= thresholdMeters;
  }

  /// Open location settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permission)
  /// Use this when permission is permanently denied
  static Future<bool> openAppSettings() async {
    try {
      // Open app settings - permission_handler provides this functionality
      // Note: This will open device settings where user can grant permission
      return await Geolocator.openLocationSettings();
    } catch (e) {
      // If location settings can't be opened, return false
      return false;
    }
  }
}

/// Custom exception for location-related errors
class LocationException implements Exception {
  final String message;

  LocationException(this.message);

  @override
  String toString() => message;
}
