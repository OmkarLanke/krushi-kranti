import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:exif/exif.dart';
import 'location_service.dart';

/// Service for capturing geotagged photos (camera only, no gallery)
class GeotaggedPhotoService {
  static final ImagePicker _picker = ImagePicker();

  /// Capture a geotagged photo from camera only
  /// Returns GeotaggedPhotoResult with file, GPS coordinates, and EXIF data
  static Future<GeotaggedPhotoResult> captureGeotaggedPhoto({
    LocationAccuracy accuracy = LocationAccuracy.high,
    double maxAccuracy = 20.0, // Require accuracy better than 20 meters
    Duration timeLimit = const Duration(seconds: 30),
  }) async {
    // Step 1: Check camera permission
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      final requested = await Permission.camera.request();
      if (!requested.isGranted) {
        throw GeotaggedPhotoException(
          'Camera permission is required to capture farm photos. Please grant camera permission in app settings.',
        );
      }
    }

    // Step 2: Get current GPS location before capturing photo
    Position position;
    try {
      position = await LocationService.getCurrentPositionWithAccuracy(
        maxAccuracy: maxAccuracy,
        accuracy: accuracy,
        timeLimit: timeLimit,
      );
    } catch (e) {
      throw GeotaggedPhotoException(
        'Failed to get GPS location: ${e.toString()}',
      );
    }

    // Step 3: Capture photo from camera (no gallery option)
    XFile? photo;
    try {
      photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Good quality without being too large
        preferredCameraDevice: CameraDevice.rear, // Use rear camera
      ).timeout(
        const Duration(seconds: 60), // Timeout for camera capture
        onTimeout: () {
          throw GeotaggedPhotoException('Camera capture timed out. Please try again.');
        },
      );

      if (photo == null) {
        throw GeotaggedPhotoException('Photo capture was cancelled');
      }
    } catch (e) {
      if (e is GeotaggedPhotoException) {
        rethrow;
      }
      if (e is TimeoutException) {
        throw GeotaggedPhotoException('Camera capture timed out. Please try again.');
      }
      throw GeotaggedPhotoException(
        'Failed to capture photo: ${e.toString()}',
      );
    }

    // Step 4: Create photo file and return immediately
    // EXIF reading is optional and non-critical - we have GPS from LocationService
    File photoFile = File(photo.path);
    
    // Return immediately with photo file and GPS coordinates
    // EXIF data is optional and not required for verification
    // The GPS coordinates from LocationService are sufficient

    return GeotaggedPhotoResult(
      photoFile: photoFile,
      gpsLatitude: position.latitude,
      gpsLongitude: position.longitude,
      gpsAccuracy: position.accuracy,
      capturedAt: DateTime.now(),
      // EXIF data is optional - not reading it to prevent blocking
      exifLatitude: null,
      exifLongitude: null,
      exifDateTime: null,
      exifData: null,
    );
  }

  /// Read EXIF data asynchronously (non-blocking)
  static Future<Map<String, dynamic?>> _readExifDataAsync(File photoFile) async {
    Map<String, dynamic>? exifData;
    double? exifLatitude;
    double? exifLongitude;
    DateTime? exifDateTime;

    try {
      if (!await photoFile.exists()) {
        return {
          'exifData': null,
          'latitude': null,
          'longitude': null,
          'dateTime': null,
        };
      }

      final bytes = await photoFile.readAsBytes().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw TimeoutException('Reading photo file timed out');
        },
      );

      final exifMap = await readExifFromBytes(bytes).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          return <String, IfdTag>{}; // Return empty map on timeout
        },
      );

      if (exifMap.isNotEmpty) {
        exifData = {};
        exifMap.forEach((key, value) {
          exifData![key] = value.toString();
        });

        // Extract GPS coordinates from EXIF
        if (exifMap.containsKey('GPS GPSLatitude') &&
            exifMap.containsKey('GPS GPSLatitudeRef') &&
            exifMap.containsKey('GPS GPSLongitude') &&
            exifMap.containsKey('GPS GPSLongitudeRef')) {
          try {
            exifLatitude = _parseExifCoordinate(
              exifMap['GPS GPSLatitude'],
              exifMap['GPS GPSLatitudeRef'],
            );
            exifLongitude = _parseExifCoordinate(
              exifMap['GPS GPSLongitude'],
              exifMap['GPS GPSLongitudeRef'],
            );
          } catch (e) {
            print('Warning: Could not parse EXIF GPS coordinates: $e');
          }
        }

        // Extract date/time from EXIF
        if (exifMap.containsKey('EXIF DateTimeOriginal')) {
          try {
            final dateTimeStr = exifMap['EXIF DateTimeOriginal'].toString();
            exifDateTime = _parseExifDateTime(dateTimeStr);
          } catch (e) {
            print('Warning: Could not parse EXIF DateTime: $e');
          }
        }
      }
    } catch (e) {
      // EXIF reading failed, but that's okay
      print('Info: EXIF reading failed (non-critical): $e');
    }

    return {
      'exifData': exifData,
      'latitude': exifLatitude,
      'longitude': exifLongitude,
      'dateTime': exifDateTime,
    };
  }

  /// Parse EXIF GPS coordinate (degrees, minutes, seconds format)
  static double _parseExifCoordinate(dynamic coordinate, dynamic ref) {
    if (coordinate == null || ref == null) return 0.0;

    try {
      // EXIF GPS coordinates are in format: [degrees, minutes, seconds]
      List<double> parts = [];
      if (coordinate is List) {
        for (var part in coordinate) {
           if (part is List && part.isNotEmpty) {
             // Rational number: [numerator, denominator]
             if (part.length >= 2) {
               final numerator = part[0] as num;
               final denominator = part[1] as num;
               parts.add(numerator / denominator);
             }
           } else if (part is num) {
             parts.add(part.toDouble());
           }
        }
      }

      if (parts.length >= 3) {
        double decimal = parts[0] + (parts[1] / 60.0) + (parts[2] / 3600.0);
        // Apply reference (N/S for latitude, E/W for longitude)
        if (ref.toString().toUpperCase() == 'S' ||
            ref.toString().toUpperCase() == 'W') {
          decimal = -decimal;
        }
        return decimal;
      }
    } catch (e) {
      print('Error parsing EXIF coordinate: $e');
    }

    return 0.0;
  }

  /// Parse EXIF DateTime string
  static DateTime? _parseExifDateTime(String dateTimeStr) {
    try {
      // EXIF format: "YYYY:MM:DD HH:MM:SS"
      final parts = dateTimeStr.split(' ');
      if (parts.length == 2) {
        final dateParts = parts[0].split(':');
        final timeParts = parts[1].split(':');
        if (dateParts.length == 3 && timeParts.length == 3) {
          return DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            int.parse(timeParts[2]),
          );
        }
      }
    } catch (e) {
      print('Error parsing EXIF DateTime: $e');
    }
    return null;
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}

/// Result of geotagged photo capture
class GeotaggedPhotoResult {
  final File photoFile;
  final double gpsLatitude;
  final double gpsLongitude;
  final double gpsAccuracy;
  final DateTime capturedAt;
  final double? exifLatitude;
  final double? exifLongitude;
  final DateTime? exifDateTime;
  final Map<String, dynamic>? exifData;

  GeotaggedPhotoResult({
    required this.photoFile,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.gpsAccuracy,
    required this.capturedAt,
    this.exifLatitude,
    this.exifLongitude,
    this.exifDateTime,
    this.exifData,
  });

  /// Check if EXIF GPS coordinates match the captured GPS coordinates
  /// Returns true if they match within the threshold (default 50 meters)
  bool hasMatchingExifGps({double thresholdMeters = 50.0}) {
    if (exifLatitude == null || exifLongitude == null) {
      return false; // No EXIF GPS data
    }

    final distance = Geolocator.distanceBetween(
      gpsLatitude,
      gpsLongitude,
      exifLatitude!,
      exifLongitude!,
    );

    return distance <= thresholdMeters;
  }

  /// Get the GPS coordinates (prefer EXIF if available, otherwise use captured GPS)
  double get effectiveLatitude => exifLatitude ?? gpsLatitude;
  double get effectiveLongitude => exifLongitude ?? gpsLongitude;
}

/// Exception for geotagged photo operations
class GeotaggedPhotoException implements Exception {
  final String message;
  GeotaggedPhotoException(this.message);
  @override
  String toString() => message;
}

