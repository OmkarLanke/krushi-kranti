import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/geotagged_photo_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/http_service.dart';
import '../services/field_officer_service.dart';
import '../../shared/widgets/photo_viewer_dialog.dart';

class FarmVerificationScreen extends StatefulWidget {
  final Map<String, dynamic>
      assignment; // Contains farms list, farmer info, etc.

  const FarmVerificationScreen({
    super.key,
    required this.assignment,
  });

  @override
  State<FarmVerificationScreen> createState() => _FarmVerificationScreenState();
}

class _FarmVerificationScreenState extends State<FarmVerificationScreen>
    with TickerProviderStateMixin {
  // Store verification state for each farm
  final Map<int, FarmVerificationState> _farmVerificationStates = {};
  String? _error;
  final Map<int, Timer> _otpCountdownTimers = {};

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    // Initialize verification states for each farm
    final farms = widget.assignment['farms'] as List? ?? [];
    for (var farm in farms) {
      if (farm is Map<String, dynamic>) {
        final farmId = farm['farmId'] ?? farm['id'];
        if (farmId != null) {
          final state = FarmVerificationState();

          // Check if farm is already verified
          final isVerified = farm['isVerified'] ?? false;
          final status = farm['status'] as String?;

          debugPrint(
              'DEBUG: Farm $farmId - isVerified: $isVerified, status: $status');

          if (isVerified == true || status == 'VERIFIED') {
            state.isVerified = true;
            state.selectedStatus = 'VERIFIED';
            debugPrint('DEBUG: Farm $farmId marked as VERIFIED');
          } else {
            debugPrint('DEBUG: Farm $farmId is NOT verified yet');
          }

          _farmVerificationStates[farmId] = state;
        }
      }
    }
  }

  @override
  void dispose() {
    // Dispose animation controllers
    _fadeController.dispose();
    _slideController.dispose();
    for (final timer in _otpCountdownTimers.values) {
      timer.cancel();
    }
    _otpCountdownTimers.clear();
    // Dispose all controllers
    for (var state in _farmVerificationStates.values) {
      state.feedbackController.dispose();
    }
    super.dispose();
  }

  /// Capture GPS location for verification
  Future<void> _captureVerificationLocation(int farmId) async {
    final l10n = AppLocalizations.of(context)!;
    final state = _farmVerificationStates[farmId];
    if (state == null) return;

    setState(() {
      state.isCapturingLocation = true;
      state.locationError = null;
    });

    try {
      Position position = await LocationService.getCurrentPositionWithAccuracy(
        maxAccuracy: 20.0, // Require accuracy better than 20 meters
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      if (mounted) {
        setState(() {
          state.verificationLatitude = position.latitude;
          state.verificationLongitude = position.longitude;
          state.verificationAccuracy = position.accuracy;
          state.locationError = null;
          state.isCapturingLocation = false;
        });

        // Validate GPS coordinates after capture and show feedback
        final farms = widget.assignment['farms'] as List? ?? [];
        final farm = farms.firstWhere(
          (f) => (f['farmId'] ?? f['id']) == farmId,
          orElse: () => <String, dynamic>{},
        );
        final validationResult = _validateGpsCoordinates(farmId, farm, l10n);

        if (validationResult['isValid']) {
          final distance = validationResult['distance'] as double?;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                distance != null
                    ? l10n.locationCapturedDistanceMeters(
                        distance.toStringAsFixed(0))
                    : l10n.locationCapturedSuccessShort,
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Show warning even after capture if validation fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationResult['errorMessage'] ??
                  l10n.gpsValidationFailedFallback),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } on LocationException catch (e) {
      if (mounted) {
        setState(() {
          state.locationError = e.message;
          state.isCapturingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          state.locationError =
              l10n.locationCaptureFailedWithError(e.toString());
          state.isCapturingLocation = false;
        });
      }
    }
  }

  /// Capture geotagged photo for verification
  Future<void> _captureGeotaggedPhoto(int farmId) async {
    final l10n = AppLocalizations.of(context)!;
    final state = _farmVerificationStates[farmId];
    if (state == null) return;

    setState(() {
      state.isCapturingPhoto = true;
      state.photoError = null;
    });

    try {
      // Add timeout to the entire photo capture process
      GeotaggedPhotoResult result =
          await GeotaggedPhotoService.captureGeotaggedPhoto(
        maxAccuracy: 20.0,
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      ).timeout(
        const Duration(seconds: 60), // Total timeout for entire process
        onTimeout: () {
          throw GeotaggedPhotoException(
            l10n.photoCaptureTimeout,
          );
        },
      );

      if (mounted) {
        // Verify photo file exists before setting it
        if (await result.photoFile.exists()) {
          setState(() {
            state.geotaggedPhoto = result.photoFile;
            // Update GPS from photo if not already captured
            if (state.verificationLatitude == null ||
                state.verificationLongitude == null) {
              state.verificationLatitude = result.effectiveLatitude;
              state.verificationLongitude = result.effectiveLongitude;
              state.verificationAccuracy = result.gpsAccuracy;
            }
            state.photoError = null;
            state.isCapturingPhoto = false;
          });

          // Validate GPS coordinates after photo capture and show feedback
          final farms = widget.assignment['farms'] as List? ?? [];
          final farm = farms.firstWhere(
            (f) => (f['farmId'] ?? f['id']) == farmId,
            orElse: () => <String, dynamic>{},
          );
          final validationResult = _validateGpsCoordinates(farmId, farm, l10n);

          if (validationResult['isValid']) {
            final distance = validationResult['distance'] as double?;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  distance != null
                      ? l10n.geotaggedPhotoCapturedDistanceMeters(
                          distance.toStringAsFixed(0))
                      : l10n.geotaggedPhotoCapturedSuccess,
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            // Show warning even after photo capture if validation fails
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(validationResult['errorMessage'] ??
                    l10n.gpsValidationFailedOtpBlocked),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } else {
          throw GeotaggedPhotoException(
            l10n.photoFileNotSavedRetry,
          );
        }
      }
    } on GeotaggedPhotoException catch (e) {
      if (mounted) {
        setState(() {
          state.photoError = e.message;
          state.isCapturingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          state.photoError = l10n.photoCaptureTimeout;
          state.isCapturingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.photoCaptureTimeout),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          state.photoError = l10n.photoCaptureFailed(e.toString());
          state.isCapturingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.photoCaptureFailed(e.toString())),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Request OTP for farm verification
  Future<void> _requestOtp(int farmId) async {
    final l10n = AppLocalizations.of(context)!;
    final state = _farmVerificationStates[farmId];
    if (state == null) {
      return;
    }

    // Get farm data for validation
    final farms = widget.assignment['farms'] as List? ?? [];
    final farm = farms.firstWhere(
      (f) => (f['farmId'] ?? f['id']) == farmId,
      orElse: () => <String, dynamic>{},
    );

    // Validate GPS coordinates before allowing OTP request
    final validationResult = _validateGpsCoordinates(farmId, farm, l10n);
    if (!validationResult['isValid']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationResult['errorMessage'] ??
              l10n.gpsValidationFailedFallback),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() {
      state.isRequestingOtp = true;
      state.otpError = null;
    });

    try {
      final response = await FieldOfficerService.requestOtp(
        farmId: farmId.toString(),
      );

      if (mounted) {
        setState(() {
          state.isRequestingOtp = false;
          state.isOtpRequested = true;
          if (response['otpExpiresAt'] != null) {
            state.otpExpiresAt = DateTime.parse(response['otpExpiresAt']);
            // Start countdown timer
            _startOtpCountdown(farmId);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.otpSentToFarmer),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Extract user-friendly error message
        String errorMessage = _extractErrorMessage(e.toString());

        setState(() {
          state.isRequestingOtp = false;
          state.otpError = errorMessage;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Validate OTP entered by field officer
  Future<void> _validateOtp(int farmId) async {
    final l10n = AppLocalizations.of(context)!;
    final state = _farmVerificationStates[farmId];
    if (state == null) {
      return;
    }

    final otp = state.otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      setState(() {
        state.otpError = l10n.pleaseEnterValidSixDigitOtp;
      });
      return;
    }

    setState(() {
      state.isValidatingOtp = true;
      state.otpError = null;
    });

    try {
      final response = await FieldOfficerService.validateOtp(
        farmId: farmId.toString(),
        otp: otp,
      );

      // Debug logging
      debugPrint('=== OTP VALIDATION RESPONSE ===');
      debugPrint('Response: $response');
      debugPrint('Response type: ${response.runtimeType}');
      debugPrint('isValid field: ${response['isValid']}');
      debugPrint('valid field: ${response['valid']}');
      debugPrint('isValid type: ${response['isValid']?.runtimeType}');
      debugPrint('valid type: ${response['valid']?.runtimeType}');

      if (mounted) {
        // Backend returns 'valid' (lowercase) due to Jackson serialization of boolean fields starting with 'is'
        // Handle both 'isValid' and 'valid' for compatibility
        final isValid = response['isValid'] ?? response['valid'] ?? false;
        debugPrint('=== SETTING OTP VALIDATION STATE ===');
        debugPrint('isValid: $isValid');
        debugPrint(
            'Before setState - state.isOtpValidated: ${state.isOtpValidated}');

        setState(() {
          state.isValidatingOtp = false;
          state.isOtpValidated = isValid;
          debugPrint('Inside setState - setting isOtpValidated to: $isValid');
          if (isValid) {
            state.otpController.clear();
            state.otpCountdownSeconds = null;
          } else {
            state.otpError =
                response['message'] ?? l10n.invalidOtpPleaseTryAgain;
          }
        });

        debugPrint(
            'After setState - state.isOtpValidated: ${state.isOtpValidated}');

        if (isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.otpValidatedSuccess),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(response['message'] ?? l10n.invalidOtpPleaseTryAgain),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Extract user-friendly error message
        String errorMessage = _extractErrorMessage(e.toString());

        setState(() {
          state.isValidatingOtp = false;
          state.otpError = errorMessage;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.verificationFailureMessage(errorMessage)),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Start OTP countdown timer
  void _startOtpCountdown(int farmId) {
    final state = _farmVerificationStates[farmId];
    if (state == null || state.otpExpiresAt == null) {
      return;
    }

    _otpCountdownTimers[farmId]?.cancel();

    // Update countdown every second
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        _otpCountdownTimers.remove(farmId);
        return;
      }

      final state = _farmVerificationStates[farmId];
      if (state == null) {
        timer.cancel();
        _otpCountdownTimers.remove(farmId);
        return;
      }

      final now = DateTime.now();
      final expiresAt = state.otpExpiresAt!;
      final difference = expiresAt.difference(now);

      if (difference.inSeconds <= 0) {
        setState(() {
          state.otpCountdownSeconds = 0;
          state.isOtpRequested = false;
        });
        timer.cancel();
        _otpCountdownTimers.remove(farmId);
      } else {
        setState(() {
          state.otpCountdownSeconds = difference.inSeconds;
        });
      }
    });

    _otpCountdownTimers[farmId] = timer;
  }

  /// Validate GPS coordinates match farm location (100m threshold)
  /// Returns a map with 'isValid' boolean and 'errorMessage' string
  Map<String, dynamic> _validateGpsCoordinates(
    int farmId,
    Map<String, dynamic> farm,
    AppLocalizations l10n,
  ) {
    final state = _farmVerificationStates[farmId];

    // Check if field officer has captured GPS location
    if (state == null ||
        state.verificationLatitude == null ||
        state.verificationLongitude == null) {
      return {
        'isValid': false,
        'errorMessage': l10n.captureGpsBeforeOtpRequest,
      };
    }

    // Get farm GPS coordinates - try multiple field name variations
    // Java BigDecimal might be serialized as number or string
    dynamic farmLat =
        farm['farmLatitude'] ?? farm['farm_latitude'] ?? farm['latitude'];
    dynamic farmLon =
        farm['farmLongitude'] ?? farm['farm_longitude'] ?? farm['longitude'];

    // Debug logging to help diagnose the issue
    debugPrint('DEBUG: Farm GPS validation for farmId: $farmId');
    debugPrint('DEBUG: Farm data keys: ${farm.keys.toList()}');
    debugPrint('DEBUG: Checking farmLatitude variations:');
    debugPrint(
        '  - farmLatitude: ${farm['farmLatitude']} (type: ${farm['farmLatitude']?.runtimeType})');
    debugPrint(
        '  - farm_latitude: ${farm['farm_latitude']} (type: ${farm['farm_latitude']?.runtimeType})');
    debugPrint(
        '  - latitude: ${farm['latitude']} (type: ${farm['latitude']?.runtimeType})');
    debugPrint('DEBUG: Checking farmLongitude variations:');
    debugPrint(
        '  - farmLongitude: ${farm['farmLongitude']} (type: ${farm['farmLongitude']?.runtimeType})');
    debugPrint(
        '  - farm_longitude: ${farm['farm_longitude']} (type: ${farm['farm_longitude']?.runtimeType})');
    debugPrint(
        '  - longitude: ${farm['longitude']} (type: ${farm['longitude']?.runtimeType})');
    debugPrint(
        'DEBUG: Final farmLat: $farmLat (type: ${farmLat?.runtimeType}), farmLon: $farmLon (type: ${farmLon?.runtimeType})');

    // Check if farm has GPS coordinates
    if (farmLat == null || farmLon == null) {
      debugPrint(
          'DEBUG: GPS coordinates are null - farmLat: $farmLat, farmLon: $farmLon');
      return {
        'isValid': false,
        'errorMessage': l10n.farmMissingGpsCoordinatesAdmin,
      };
    }

    final farmLatDouble = farmLat is double
        ? farmLat
        : (farmLat is int
            ? farmLat.toDouble()
            : double.tryParse(farmLat.toString()));
    final farmLonDouble = farmLon is double
        ? farmLon
        : (farmLon is int
            ? farmLon.toDouble()
            : double.tryParse(farmLon.toString()));

    if (farmLatDouble == null || farmLonDouble == null) {
      return {
        'isValid': false,
        'errorMessage': l10n.invalidFarmGpsCoordinatesAdmin,
      };
    }

    // Calculate distance between farm location and verification location
    final distance = Geolocator.distanceBetween(
      farmLatDouble,
      farmLonDouble,
      state.verificationLatitude!,
      state.verificationLongitude!,
    );

    // Check if within 100 meters threshold
    if (distance > 100.0) {
      return {
        'isValid': false,
        'errorMessage': l10n.tooFarFromFarmMeters(distance.toStringAsFixed(0)),
        'distance': distance,
      };
    }

    return {
      'isValid': true,
      'errorMessage': null,
      'distance': distance,
    };
  }

  Future<void> _submitVerification(
      int farmId, Map<String, dynamic> farm) async {
    final l10n = AppLocalizations.of(context)!;
    final state = _farmVerificationStates[farmId];
    if (state == null) {
      return;
    }

    if (state.selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectVerificationStatus),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // If verifying (not rejecting), require GPS, photo, and OTP validation
    if (state.selectedStatus == 'VERIFIED') {
      if (state.verificationLatitude == null ||
          state.verificationLongitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.captureGpsBeforeVerify),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (state.geotaggedPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .captureGeotaggedPhotoBeforeVerify),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Validate GPS coordinates match farm location
      final validationResult = _validateGpsCoordinates(farmId, farm, l10n);
      if (!validationResult['isValid']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationResult['errorMessage'] ??
                l10n.gpsValidationFailedFallback),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Require OTP validation before submitting verification
      debugPrint('=== SUBMIT VERIFICATION - OTP CHECK ===');
      debugPrint('state.isOtpValidated: ${state.isOtpValidated}');
      debugPrint('state.selectedStatus: ${state.selectedStatus}');

      if (!state.isOtpValidated) {
        debugPrint('ERROR: OTP not validated! Blocking submission.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.requestValidateOtpBeforeSubmit),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      debugPrint(
          'OTP validation check passed. Proceeding with verification submission...');
    }

    setState(() {
      state.isSubmitting = true;
      _error = null;
    });

    try {
      // Upload photo to file service and get URL
      List<String>? photoUrls;
      if (state.geotaggedPhoto != null) {
        try {
          // Show uploading message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.uploadingPhoto),
                duration: Duration(seconds: 2),
              ),
            );
          }

          // Upload photo to file service
          // Note: If file service is not available, we'll proceed without photo URL
          // The backend will handle the case where photoUrls is null
          try {
            final photoUrl = await HttpService.uploadFile(
              state.geotaggedPhoto!,
              folder: 'farm-verifications',
              fileName:
                  'farm_${farmId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );

            photoUrls = [photoUrl];

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.photoUploadedSuccess),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (uploadError) {
            // Log the error but don't block verification if file service is unavailable
            debugPrint('Photo upload failed: $uploadError');

            // Check if it's an authentication error
            final errorMessage = uploadError.toString();
            if (errorMessage.contains('Unauthorized') ||
                errorMessage.contains('401')) {
              if (mounted) {
                setState(() {
                  state.isSubmitting = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.authFailedRelogin),
                    backgroundColor: AppColors.error,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
              return; // Don't proceed if authentication fails
            }

            // For other errors (like file service not available), proceed without photo
            // Show a warning but allow verification to continue
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!
                      .photoUploadFailedProceeding(uploadError.toString())),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            // Continue without photo URL - backend will handle this
          }
        } catch (e) {
          // Catch any other unexpected errors
          debugPrint('Unexpected error during photo upload: $e');
          // Continue without photo URL
        }
      }

      await FieldOfficerService.verifyFarm(
        farmId: farmId.toString(),
        status: state.selectedStatus!,
        feedback: state.feedbackController.text.trim().isNotEmpty
            ? state.feedbackController.text.trim()
            : null,
        latitude: state.verificationLatitude,
        longitude: state.verificationLongitude,
        photoUrls: photoUrls,
      );

      if (mounted) {
        setState(() {
          state.isSubmitting = false;
          state.isVerified = true; // Mark as verified
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.farmVerifiedSuccess),
            backgroundColor: AppColors.success,
          ),
        );

        // Check if all farms are verified, then return true
        final farms = widget.assignment['farms'] as List? ?? [];
        bool allVerified = true;
        for (var farmData in farms) {
          if (farmData is Map<String, dynamic>) {
            final id = farmData['farmId'] ?? farmData['id'];
            final farmState = _farmVerificationStates[id];
            if (farmState == null || !farmState.isVerified) {
              allVerified = false;
              break;
            }
          }
        }

        if (allVerified) {
          // Wait a bit before navigating back
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          state.isSubmitting = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.verificationFailureMessage(_error!)),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.verifyFarmAppBarTitle,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandGreen,
                AppColors.brandGreen.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Farmer Information (if available)
                if (widget.assignment['farmerName'] != null) ...[
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.95 + (0.05 * value),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.brandGreen,
                                        AppColors.brandGreen.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.assignment['farmerName'] ??
                                            l10n.farmerLabelDefault,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      if (widget.assignment[
                                              'farmerPhoneNumber'] !=
                                          null) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              widget.assignment[
                                                  'farmerPhoneNumber'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Farms List
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.brandGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.agriculture,
                          size: 18,
                          color: AppColors.brandGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.farmsToVerifySectionTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // List of Farms
                ..._buildFarmsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFarmsList() {
    final l10n = AppLocalizations.of(context)!;
    final farms = widget.assignment['farms'] as List? ?? [];
    if (farms.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              l10n.noFarmsInAssignment,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ];
    }

    return farms.asMap().entries.map((entry) {
      final index = entry.key;
      final farm = entry.value;
      if (farm is! Map<String, dynamic>) {
        return const SizedBox.shrink();
      }

      final farmId = farm['farmId'] ?? farm['id'];
      if (farmId == null) {
        return const SizedBox.shrink();
      }

      final state = _farmVerificationStates[farmId];
      if (state == null) {
        return const SizedBox.shrink();
      }

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (index * 100)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Padding(
                padding:
                    EdgeInsets.only(bottom: index < farms.length - 1 ? 20 : 0),
                child: _buildFarmVerificationCard(farm, farmId, state, index),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildFarmVerificationCard(
    Map<String, dynamic> farm,
    int farmId,
    FarmVerificationState state,
    int index,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // Build location string
    String locationStr = l10n.locationNotAvailableShort;
    final village = farm['village'] ?? '';
    final district = farm['district'] ?? '';
    final stateName = farm['state'] ?? '';
    final pincode = farm['pincode'] ?? '';

    List<String> locationParts = [];
    if (village.isNotEmpty) locationParts.add(village);
    if (district.isNotEmpty) locationParts.add(district);
    if (stateName.isNotEmpty) locationParts.add(stateName);
    if (pincode.isNotEmpty) locationParts.add('-$pincode');

    if (locationParts.isNotEmpty) {
      locationStr = locationParts.join(', ');
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.98 + (0.02 * value),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: state.isVerified
                      ? AppColors.success.withOpacity(0.15)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
              border: state.isVerified
                  ? Border.all(
                      color: AppColors.success,
                      width: 2,
                    )
                  : Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Farm Info Header
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.brandGreen,
                                  AppColors.brandGreen.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.agriculture,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              farm['farmName'] ?? l10n.farmNameFallback,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (state.isVerified)
                            Flexible(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors:
                                              state.selectedStatus == 'VERIFIED'
                                                  ? [
                                                      AppColors.success
                                                          .withOpacity(0.15),
                                                      AppColors.success
                                                          .withOpacity(0.08),
                                                    ]
                                                  : [
                                                      AppColors.error
                                                          .withOpacity(0.15),
                                                      AppColors.error
                                                          .withOpacity(0.08),
                                                    ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              state.selectedStatus == 'VERIFIED'
                                                  ? AppColors.success
                                                      .withOpacity(0.3)
                                                  : AppColors.error
                                                      .withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            state.selectedStatus == 'VERIFIED'
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: state.selectedStatus ==
                                                    'VERIFIED'
                                                ? AppColors.success
                                                : AppColors.error,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              state.selectedStatus ??
                                                  l10n.verificationStatusVerifiedBadge,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: state.selectedStatus ==
                                                        'VERIFIED'
                                                    ? AppColors.success
                                                    : AppColors.error,
                                                letterSpacing: 0.2,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _buildInfoRow(Icons.location_on, locationStr),
                if (pincode.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      Icons.pin, l10n.pincodeRowLabel(pincode.toString())),
                ],

                // View Geo Tagged Photo button for verified farms
                if (state.isVerified && state.selectedStatus == 'VERIFIED') ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildViewPhotoButton(
                      farmId, farm['farmName'] ?? l10n.farmNameFallback),
                ],

                if (!state.isVerified) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // GPS Location & Photo Capture Section (Required for VERIFIED status)
                  _buildGpsAndPhotoSection(farmId, state, farm),
                  const SizedBox(height: 16),

                  // Verification Status Selection
                  _buildStatusSelection(farmId, state),
                  const SizedBox(height: 16),

                  // Feedback Section
                  if (state.selectedStatus != null)
                    _buildFeedbackSection(farmId, state),

                  const SizedBox(height: 16),

                  // Submit Button for this farm
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.95 + (0.05 * value),
                        child: Opacity(
                          opacity: value,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: state.isSubmitting
                                  ? null
                                  : () => _submitVerification(farmId, farm),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.brandGreen,
                                      AppColors.brandGreen.withOpacity(0.85),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.brandGreen.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: state.isSubmitting
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            l10n.submitVerificationButton,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // Show verification details if already verified
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.95 + (0.05 * value),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: state.selectedStatus == 'REJECTED'
                                    ? [
                                        AppColors.error.withOpacity(0.12),
                                        AppColors.error.withOpacity(0.06),
                                      ]
                                    : [
                                        AppColors.success.withOpacity(0.12),
                                        AppColors.success.withOpacity(0.06),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: state.selectedStatus == 'REJECTED'
                                    ? AppColors.error.withOpacity(0.3)
                                    : AppColors.success.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: state.selectedStatus == 'REJECTED'
                                        ? AppColors.error.withOpacity(0.2)
                                        : AppColors.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.farmAlreadyVerifiedNotice,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewPhotoButton(int farmId, String farmName) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showVerificationPhotos(farmId, farmName),
        icon: const Icon(Icons.photo_camera_rounded, size: 18),
        label: Text(AppLocalizations.of(context)!.viewGeoTaggedPhoto),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _showVerificationPhotos(int farmId, String farmName) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.loadingPhotos),
                ],
              ),
            ),
          ),
        ),
      );

      // Fetch photos
      final photos = await FieldOfficerService.getVerificationPhotos(farmId);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Extract photo URLs
      final photoUrls = photos
          .map((photo) => photo['photoUrl'] as String?)
          .whereType<String>()
          .toList();

      // Show photo viewer
      if (mounted && photoUrls.isNotEmpty) {
        showDialog(
          context: context,
          builder: (dialogContext) => PhotoViewerDialog(
            photoUrls: photoUrls,
            title: AppLocalizations.of(dialogContext)!
                .verificationPhotosTitle(farmName),
          ),
        );
      } else if (mounted) {
        // Show error if no photos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.noVerificationPhotosForFarm),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.errorLoadingPhotos(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.brandGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelection(int farmId, FarmVerificationState state) {
    final l10n = AppLocalizations.of(context)!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.verified_user,
                        size: 16,
                        color: AppColors.brandGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.verificationStatusSectionTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Only show Verify option - field officer can only verify farms
                _buildStatusOption(
                  farmId,
                  state,
                  'VERIFIED',
                  l10n.verifyFarmStatusOption,
                  Icons.check_circle,
                  AppColors.success,
                  state.selectedStatus == 'VERIFIED',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(
    int farmId,
    FarmVerificationState state,
    String value,
    String label,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: isSelected ? 1.0 : 0.95 + (0.05 * animValue),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  state.selectedStatus = value;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [color, color.withOpacity(0.8)],
                              )
                            : null,
                        color: isSelected ? null : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? color : AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackSection(int farmId, FarmVerificationState state) {
    final l10n = AppLocalizations.of(context)!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.note,
                        size: 16,
                        color: AppColors.brandGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.feedbackNotesSectionTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: state.feedbackController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF424242),
                  ),
                  decoration: InputDecoration(
                    hintText: state.selectedStatus == 'VERIFIED'
                        ? l10n.feedbackNotesHintVerified
                        : l10n.feedbackNotesHintRejected,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.brandGreen, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build GPS Location and Photo Capture Section
  Widget _buildGpsAndPhotoSection(
    int farmId,
    FarmVerificationState state,
    Map<String, dynamic> farm,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.location_on,
                  size: 16, color: AppColors.brandGreen),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.locationPhotoVerificationSectionTitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // GPS Location Capture
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: state.verificationLatitude != null
                ? AppColors.success.withOpacity(0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.verificationLatitude != null
                  ? AppColors.success.withOpacity(0.3)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: 18,
                    color: state.verificationLatitude != null
                        ? AppColors.success
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.gpsLocationSectionTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  const Spacer(),
                  if (state.verificationLatitude != null)
                    Icon(Icons.check_circle,
                        color: AppColors.success, size: 20),
                ],
              ),
              if (state.verificationLatitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.latitudeDisplay(
                      state.verificationLatitude!.toStringAsFixed(6)),
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  l10n.longitudeDisplay(
                      state.verificationLongitude!.toStringAsFixed(6)),
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade700),
                ),
                if (state.verificationAccuracy != null)
                  Text(
                    l10n.accuracyDisplayMeters(
                        state.verificationAccuracy!.toStringAsFixed(1)),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
              ],
              if (state.locationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.locationError!,
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: state.isCapturingLocation
                      ? null
                      : () => _captureVerificationLocation(farmId),
                  icon: state.isCapturingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          state.verificationLatitude != null
                              ? Icons.refresh
                              : Icons.my_location,
                          size: 18,
                        ),
                  label: Text(
                    state.verificationLatitude != null
                        ? l10n.retakeLocation
                        : l10n.captureFarmLocation,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Geotagged Photo Capture
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: state.geotaggedPhoto != null
                ? AppColors.success.withOpacity(0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.geotaggedPhoto != null
                  ? AppColors.success.withOpacity(0.3)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: state.geotaggedPhoto != null
                        ? AppColors.success
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.farmPhotoGeotaggedSectionTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  const Spacer(),
                  if (state.geotaggedPhoto != null)
                    Icon(Icons.check_circle,
                        color: AppColors.success, size: 20),
                ],
              ),
              if (state.geotaggedPhoto != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    state.geotaggedPhoto!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              if (state.photoError != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.photoError!,
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: state.isCapturingPhoto
                      ? null
                      : () => _captureGeotaggedPhoto(farmId),
                  icon: state.isCapturingPhoto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          state.geotaggedPhoto != null
                              ? Icons.camera_alt
                              : Icons.add_a_photo,
                          size: 18,
                        ),
                  label: Text(
                    state.geotaggedPhoto != null
                        ? l10n.retakeFarmPhotoButton
                        : l10n.captureFarmPhotoButton,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // OTP Verification Section (only for VERIFIED status)
        if (state.selectedStatus == 'VERIFIED') ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: state.isOtpValidated
                  ? AppColors.success.withOpacity(0.05)
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: state.isOtpValidated
                    ? AppColors.success.withOpacity(0.3)
                    : Colors.orange.shade300,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: state.isOtpValidated
                            ? AppColors.success.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.verified_user,
                        size: 16,
                        color: state.isOtpValidated
                            ? AppColors.success
                            : Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.otpVerificationSectionTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (state.isOtpValidated)
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                  ],
                ),
                const SizedBox(height: 12),

                // Request OTP Button
                if (!state.isOtpRequested && !state.isOtpValidated) ...[
                  Builder(
                    builder: (context) {
                      // Check GPS validation before showing button
                      final farms = widget.assignment['farms'] as List? ?? [];
                      final farm = farms.firstWhere(
                        (f) => (f['farmId'] ?? f['id']) == farmId,
                        orElse: () => <String, dynamic>{},
                      );
                      final validationResult = _validateGpsCoordinates(
                          farmId, farm, AppLocalizations.of(context)!);
                      final bool canRequestOtp =
                          validationResult['isValid'] == true;
                      final String? validationError =
                          validationResult['errorMessage'];

                      return Column(
                        children: [
                          // Show validation error/warning if GPS validation fails
                          if (!canRequestOtp && validationError != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.error.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      validationError,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  (state.isRequestingOtp || !canRequestOtp)
                                      ? null
                                      : () => _requestOtp(farmId),
                              icon: state.isRequestingOtp
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send, size: 18),
                              label: Text(
                                state.isRequestingOtp
                                    ? l10n.requestingOtpButton
                                    : (!canRequestOtp
                                        ? l10n.gpsValidationRequiredButton
                                        : l10n.fieldOfficerRequestOtpCta),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    canRequestOtp ? Colors.orange : Colors.grey,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],

                // OTP Input Section (after OTP is requested)
                if (state.isOtpRequested && !state.isOtpValidated) ...[
                  Text(
                    l10n.enterSixDigitOtpFromFarmer,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: state.otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.otpHintSixDigits,
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Colors.grey.shade400,
                      ),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.brandGreen, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.error, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                    ),
                  ),
                  if (state.otpCountdownSeconds != null &&
                      state.otpCountdownSeconds! > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.otpExpiresInCountdown(
                          _formatCountdown(state.otpCountdownSeconds!)),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (state.otpError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.otpError!,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.isValidatingOtp
                          ? null
                          : () => _validateOtp(farmId),
                      icon: state.isValidatingOtp
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified, size: 18),
                      label: Text(
                        state.isValidatingOtp
                            ? l10n.validatingOtpButton
                            : l10n.validateOtpButtonLabel,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],

                // OTP Validated Success Message
                if (state.isOtpValidated) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.otpValidatedSuccess,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Format countdown seconds to MM:SS
  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Extract user-friendly error message from exception string
  String _extractErrorMessage(String errorString) {
    try {
      // Try to extract JSON message from error string
      // Format: "Error: 500 - {"message":"...","data":null}"
      if (errorString.contains('"message"')) {
        final jsonStart = errorString.indexOf('{');
        final jsonEnd = errorString.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1) {
          final jsonStr = errorString.substring(jsonStart, jsonEnd + 1);
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map && decoded.containsKey('message')) {
            return decoded['message'] as String;
          }
        }
      }

      // Try to extract message after "message":" pattern
      final messageMatch =
          RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(errorString);
      if (messageMatch != null) {
        return messageMatch.group(1) ?? errorString;
      }

      // Remove common prefixes
      String cleaned = errorString
          .replaceAll('Exception: ', '')
          .replaceAll('Network Error: ', '')
          .replaceAll('Error: ', '');

      // If it contains status code, try to extract just the message part
      if (cleaned.contains(' - ')) {
        final parts = cleaned.split(' - ');
        if (parts.length > 1) {
          // Try to parse the JSON part
          try {
            final jsonStr = parts[1];
            final decoded = jsonDecode(jsonStr);
            if (decoded is Map && decoded.containsKey('message')) {
              return decoded['message'] as String;
            }
          } catch (_) {
            // If parsing fails, return the last part
            return parts.last;
          }
        }
      }

      return cleaned;
    } catch (_) {
      // If all parsing fails, return cleaned version
      return errorString
          .replaceAll('Exception: ', '')
          .replaceAll('Network Error: ', '')
          .replaceAll('Error: ', '');
    }
  }
}

// Helper class to store verification state for each farm
class FarmVerificationState {
  String? selectedStatus;
  final TextEditingController feedbackController = TextEditingController();
  bool isSubmitting = false;
  bool isVerified = false;

  // GPS and Photo data
  double? verificationLatitude;
  double? verificationLongitude;
  double? verificationAccuracy;
  File? geotaggedPhoto;
  bool isCapturingLocation = false;
  bool isCapturingPhoto = false;
  String? locationError;
  String? photoError;

  // OTP data
  final TextEditingController otpController = TextEditingController();
  bool isRequestingOtp = false;
  bool isValidatingOtp = false;
  bool isOtpValidated = false;
  bool isOtpRequested = false;
  String? otpError;
  DateTime? otpExpiresAt;
  int? otpCountdownSeconds;
}
