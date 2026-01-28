import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart'; 
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../dashboard/services/crop_service.dart';
import '../../dashboard/services/field_officer_assignment_service.dart';
import '../../dashboard/services/notification_service.dart';
import '../../../core/services/http_service.dart';
import '../../../core/services/storage_service.dart';
import '../../subscription/widgets/subscription_guard.dart' show showSubscriptionRequiredDialog;
import 'field_officer_details_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAgentAssigned = false; 
  List<Map<String, dynamic>> fieldOfficerAssignments = [];
  Map<int, String> _farmNames = {}; // Map of farmId -> farmName
  List<Map<String, dynamic>> _unassignedFarms = []; // Farms without field officer assignment
  bool isLoadingAssignments = true;
  bool isNavigating = false;
  bool _allFarmsVerified = false;
  bool _isLoadingFarms = false;
  int _totalFarms = 0;
  int _verifiedFarms = 0;
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<NotificationModel>? _notificationSubscription;
  Timer? _expiredNotificationCleanupTimer;
  VoidCallback? _notificationServiceListener;
  int _previousNotificationCount = 0;

  // Onboarding/completion flags
  bool _hasPersonalDetails = true;
  bool _hasCrops = true;

  @override
  void initState() {
    super.initState();
    // Filter any existing notifications to ensure they belong to current user (safeguard)
    _notificationService.filterNotificationsByCurrentUser();
    
    // Load initial data in parallel
    Future.wait([
      _checkFieldOfficerAssignments(),
      _checkAllFarmsVerified(),
      _checkPersonalDetailsCompletion(),
      _checkHasCrops(),
    ]);
    
    _setupNotificationListener();
    // Start polling for notifications from backend
    _notificationService.startPolling(interval: const Duration(seconds: 10));
    
    // Optimized: Combine cleanup and farm check into a single timer
    // Reduces number of timers and improves battery efficiency
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Cleanup expired notifications
      _notificationService.removeExpiredOtpNotifications();
    });
    
    // Check farm verification status periodically (every 60 seconds)
    Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _checkAllFarmsVerified();
      } else {
        timer.cancel();
      }
    });
  }

  void _showOtpReceivedPopup() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'You will get the OTP. Please check it at notification',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: AppColors.brandGreen,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  void _setupNotificationListener() {
    // Optimized: Only update UI when relevant notifications change
    _notificationSubscription = _notificationService.notificationStream.listen(
      (notification) {
        if (mounted && notification.type == 'FARM_VERIFICATION_OTP') {
          final now = DateTime.now();
          final age = now.difference(notification.timestamp);
          if (age < const Duration(minutes: 10)) {
            // Only update state if widget is still mounted
            if (mounted) {
              setState(() {});
              // Show a visual cue that an OTP has arrived
              _showOtpReceivedPopup();
            }
          }
        }
      },
    );
    
    // Listen to notification service changes (when notifyListeners is called)
    _notificationServiceListener = () {
      if (mounted) setState(() {});
    };
    _notificationService.addListener(_notificationServiceListener!);
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _expiredNotificationCleanupTimer?.cancel();
    if (_notificationServiceListener != null) {
      _notificationService.removeListener(_notificationServiceListener!);
    }
    _notificationService.stopPolling();
    super.dispose();
  }

  // Cache farms data to avoid duplicate API calls
  List<dynamic>? _cachedFarmsData;
  DateTime? _farmsDataCacheTime;
  static const _farmsCacheDuration = Duration(minutes: 1);

  /// Fetch farms data with caching to prevent duplicate API calls
  Future<List<dynamic>?> _fetchFarmsData({bool forceRefresh = false}) async {
    // Return cached data if still valid and not forcing refresh
    if (!forceRefresh && 
        _cachedFarmsData != null && 
        _farmsDataCacheTime != null &&
        DateTime.now().difference(_farmsDataCacheTime!) < _farmsCacheDuration) {
      return _cachedFarmsData;
    }

    try {
      final response = await HttpService.get("farmer/profile/farms");
      final List<dynamic> farmsData = response['data'] ?? [];
      _cachedFarmsData = farmsData;
      _farmsDataCacheTime = DateTime.now();
      return farmsData;
    } catch (e) {
      // Return cached data if available, even if expired
      return _cachedFarmsData;
    }
  }

  /// Optimized: Check field officer assignments and load all related data in parallel
  Future<void> _checkFieldOfficerAssignments() async {
    if (!mounted) return;
    
    setState(() {
      isLoadingAssignments = true;
    });
    
    try {
      // Run both operations in parallel
      final results = await Future.wait([
        FieldOfficerAssignmentService.getAssignments(),
        _fetchFarmsData(),
      ]);
      
      final assignments = results[0] as List<dynamic>;
      final farmsData = results[1] as List<dynamic>? ?? [];
      
      // Only show ASSIGNED field officers - filter out COMPLETED and CANCELLED
      final activeAssignments = assignments.where((assignment) {
        final status = assignment['status']?.toString().toUpperCase();
        return status == 'ASSIGNED';
      }).map((assignment) => assignment as Map<String, dynamic>).toList();
      
      // Check if there's an assignment with null farmId (all farms assigned)
      bool allFarmsAssigned = activeAssignments.any((assignment) => assignment['farmId'] == null);
      
      // Extract assigned farm IDs from assignments
      final Set<int> assignedFarmIds = {};
      for (var assignment in activeAssignments) {
        final farmId = assignment['farmId'];
        if (farmId != null) {
          final farmIdInt = farmId is int ? farmId : int.tryParse(farmId.toString());
          if (farmIdInt != null) {
            assignedFarmIds.add(farmIdInt);
          }
        }
      }
      
      // Build farm names map from cached farms data
      final Map<int, String> farmNamesMap = {};
      if (farmsData.isNotEmpty) {
        for (var farmData in farmsData) {
          final farmId = farmData['id'];
          final farmName = farmData['farmName'] ?? 'Farm $farmId';
          if (farmId != null) {
            final id = farmId is int ? farmId : int.tryParse(farmId.toString());
            if (id != null && assignedFarmIds.contains(id)) {
              farmNamesMap[id] = farmName.toString();
            }
          }
        }
      }
      
      // Find unassigned farms (active farms without assignments)
      // If allFarmsAssigned is true (null farmId assignment exists), no farms are unassigned
      final List<Map<String, dynamic>> unassignedFarms = [];
      if (!allFarmsAssigned) {
        // Filter only active farms
        final activeFarms = farmsData.where((farm) {
          return farm['isActive'] == true;
        }).toList();
        
        for (var farm in activeFarms) {
          final farmId = farm['id'];
          final farmIdInt = farmId is int ? farmId : int.tryParse(farmId.toString());
          // Only add to unassigned if it's not already assigned AND not already verified
          if (farmIdInt != null && !assignedFarmIds.contains(farmIdInt) && (farm['isVerified'] == false || farm['isVerified'] == null)) {
            unassignedFarms.add({
              'id': farmIdInt,
              'farmName': farm['farmName'] ?? 'Farm ${farmIdInt}',
            });
          }
        }
      }
      
      if (mounted) {
        setState(() {
          fieldOfficerAssignments = activeAssignments;
          _unassignedFarms = unassignedFarms;
          isAgentAssigned = activeAssignments.isNotEmpty;
          _farmNames = farmNamesMap;
          isLoadingAssignments = false;
        });
      }
    } catch (e) {
      // If error, assume no assignments
      if (mounted) {
        setState(() {
          fieldOfficerAssignments = [];
          _unassignedFarms = [];
          isAgentAssigned = false;
          isLoadingAssignments = false;
        });
      }
    }
  }

  /// Optimized: Check all farms verified status using cached data
  Future<void> _checkAllFarmsVerified() async {
    if (_isLoadingFarms || !mounted) return; // Prevent concurrent calls
    
    setState(() {
      _isLoadingFarms = true;
    });

    try {
      final farmsData = await _fetchFarmsData();
      
      if (farmsData == null || farmsData.isEmpty) {
      if (mounted) {
        setState(() {
            _allFarmsVerified = false;
            _totalFarms = 0;
            _verifiedFarms = 0;
            _isLoadingFarms = false;
    });
        }
        return;
      }
      
      // Filter only active farms
      final activeFarms = farmsData.where((farm) {
        return farm['isActive'] == true;
      }).toList();
      
      if (activeFarms.isEmpty) {
        if (mounted) {
          setState(() {
            _allFarmsVerified = false;
            _totalFarms = 0;
            _verifiedFarms = 0;
            _isLoadingFarms = false;
          });
        }
        return;
      }

      final totalFarms = activeFarms.length;
      final verifiedFarms = activeFarms.where((farm) {
        return farm['isVerified'] == true;
      }).length;

      if (mounted) {
        setState(() {
          _totalFarms = totalFarms;
          _verifiedFarms = verifiedFarms;
          _allFarmsVerified = totalFarms > 0 && verifiedFarms == totalFarms;
          _isLoadingFarms = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allFarmsVerified = false;
          _isLoadingFarms = false;
        });
      }
    }
  }

  /// Check if personal details look complete based on locally stored data.
  Future<void> _checkPersonalDetailsCompletion() async {
    try {
      final userData = await StorageService.getUserDetails();
      final firstName = (userData['firstName'] ?? '').toString().trim();
      final lastName = (userData['lastName'] ?? '').toString().trim();
      final dob = (userData['dob'] ?? '').toString().trim();
      final gender = (userData['gender'] ?? '').toString().trim();

      final hasPersonal = firstName.isNotEmpty &&
          lastName.isNotEmpty &&
          dob.isNotEmpty &&
          gender.isNotEmpty;

      if (mounted) {
        setState(() {
          _hasPersonalDetails = hasPersonal;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasPersonalDetails = false;
        });
      }
    }
  }

  /// Check if user has added at least one crop.
  Future<void> _checkHasCrops() async {
    try {
      final crops = await CropService.getCrops();
      if (mounted) {
        setState(() {
          _hasCrops = crops.isNotEmpty;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasCrops = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
      // --- 1. HEADER ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, 
        titleSpacing: 20,
        title: Text(
          l10n.krushiKranti, 
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700, 
            height: 1.0, 
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          _buildCircleIcon(Icons.search_rounded),
          const SizedBox(width: 12),
          _buildNotificationIcon(),
          const SizedBox(width: 20),
        ],
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

      // --- 2. BODY ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. Weather
            _buildWeatherHeader(l10n),
            const SizedBox(height: 20),

            // Profile completion nudges (non-blocking)
            if (!_hasPersonalDetails) ...[
              _buildCompletionCard(
                icon: Icons.person_outline_rounded,
                title: 'Complete your profile',
                message:
                    'Add your basic details so we can personalise Krushi Kranti for you.',
                ctaLabel: 'Complete now',
                onTap: () => Navigator.pushNamed(context, AppRoutes.myDetails),
              ),
              const SizedBox(height: 16),
            ],
            if (_totalFarms == 0) ...[
              _buildCompletionCard(
                icon: Icons.agriculture_rounded,
                title: 'Add your first farm',
                message:
                    'Add at least one farm to see farm-specific insights and crops.',
                ctaLabel: 'Add farm',
                onTap: () => Navigator.pushNamed(context, AppRoutes.addFarm),
              ),
              const SizedBox(height: 16),
            ],
            if (_totalFarms > 0 && !_hasCrops) ...[
              _buildCompletionCard(
                icon: Icons.grass_rounded,
                title: 'Add your first crop',
                message:
                    'Add at least one crop to start getting guidance and forecasts.',
                ctaLabel: 'Add crop',
                onTap: () => Navigator.pushNamed(context, AppRoutes.addCrop),
              ),
              const SizedBox(height: 16),
            ],
            
            // B. All Farms Verified Banner (if all farms are verified)
            if (_allFarmsVerified) ...[
              _buildAllFarmsVerifiedCard(l10n),
              const SizedBox(height: 20),
            ],
            
            // D. Field Officer Banner (only show if not all farms are verified)
            if (!_allFarmsVerified) ...[
              if (isLoadingAssignments)
                _buildLoadingBanner(l10n)
              else ...[
                // Show assigned field officer card if there are assignments
                if (isAgentAssigned) ...[
                  _buildFieldOfficerAssignedCard(l10n),
                  const SizedBox(height: 16),
                ],
                // Show pending banner for unassigned farms
                if (_unassignedFarms.isNotEmpty) ...[
                  _buildFieldOfficerPendingBanner(l10n),
                ],
              ],
            ],
            
            const SizedBox(height: 24),

            // E. Quick Action Title
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
              l10n.quickAction,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // F. Grid
            _buildQuickActionGrid(context, l10n),
            
            const SizedBox(height: 24),

            // G. Alerts
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
              l10n.alerts,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildAlertCard(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS
  // ===========================================================================

  Widget _buildCircleIcon(IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Add navigation/action
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
      decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
      ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    final unreadCount = _notificationService.unreadOtpNotificationsCount;
    final hasUnreadNotifications = unreadCount > 0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.notifications);
        },
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            // Red badge when unread OTP notifications exist
            if (hasUnreadNotifications)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.creamBackground,
            AppColors.creamBackground.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${l10n.hello} Ramesh,", 
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandGreen,
                    height: 1.2,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.currentLocation, 
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500, 
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "28°", 
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w700, 
                      color: AppColors.textPrimary,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "High: 30° / Low: 15°", 
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade700, 
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_rounded,
                  size: 40,
                  color: Color(0xFF29B6F6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], 
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildFieldOfficerPendingBanner(AppLocalizations l10n) {
    // Get farm names for unassigned farms
    final List<String> unassignedFarmNames = [];
    for (var farm in _unassignedFarms) {
      final farmId = farm['id'];
      final farmName = farm['farmName'] ?? 'Farm ${farmId}';
      unassignedFarmNames.add(farmName.toString());
    }
    
    final String farmNamesText = unassignedFarmNames.isEmpty
        ? ''
        : unassignedFarmNames.length == 1
            ? unassignedFarmNames.first
            : unassignedFarmNames.join(', ');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.fieldOfficerAssignMsg,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.fieldOfficerSoonMsg,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          if (farmNamesText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.agriculture_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'For: $farmNamesText',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllFarmsVerifiedCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Farms Verified!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Congratulations! All your $_totalFarms farm${_totalFarms > 1 ? 's' : ''} ($_verifiedFarms/$_totalFarms verified) have been successfully verified by field officers.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldOfficerAssignedCard(AppLocalizations l10n) {
    if (fieldOfficerAssignments.isEmpty) {
      return _buildFieldOfficerPendingBanner(l10n);
    }

    // Get the first active assignment (all should have same field officer)
    final assignment = fieldOfficerAssignments.first;
    final fieldOfficerName = assignment['fieldOfficerName']?.toString() ?? 'Field Officer';
    final fieldOfficerPhone = assignment['fieldOfficerPhone']?.toString() ?? '';
    final fieldOfficerPincode = assignment['fieldOfficerPincode']?.toString() ?? '';
    
    // Get all farm IDs from assignments and their names
    final List<String> assignedFarmNames = [];
    for (var assign in fieldOfficerAssignments) {
      final farmId = assign['farmId'];
      if (farmId != null) {
        final farmIdInt = farmId is int ? farmId : int.tryParse(farmId.toString());
        if (farmIdInt != null && _farmNames.containsKey(farmIdInt)) {
          assignedFarmNames.add(_farmNames[farmIdInt]!);
        } else {
          assignedFarmNames.add('Farm $farmId');
        }
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
      onTap: () {
        _showFieldOfficerDetailsDialog(l10n);
      },
        borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandGreen,
                      AppColors.brandGreen.withOpacity(0.6),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 28,
              backgroundColor: AppColors.creamBackground,
                  child: Icon(Icons.person_rounded, color: Colors.brown, size: 30),
                ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.fieldOfficerAssignedMsg,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                  ),
                    const SizedBox(height: 6),
                  Text(
                    fieldOfficerName,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 0.2,
                      ),
                  ),
                    if (fieldOfficerPincode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.pin_drop_rounded,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                    Text(
                      "Pincode: $fieldOfficerPincode",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                    ),
                          ),
                        ],
                      ),
                    ],
                    if (fieldOfficerPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                    Text(
                      fieldOfficerPhone,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                    ),
                          ),
                        ],
                      ),
                    ],
                    if (assignedFarmNames.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.agriculture_rounded,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Assigned to: ${assignedFarmNames.join(', ')}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  if (fieldOfficerAssignments.length > 1)
                    Padding(
                        padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "+ ${fieldOfficerAssignments.length - 1} more",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.brandGreen,
                            fontWeight: FontWeight.w600,
                          ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brandGreen.withOpacity(0.3),
                    width: 1.5,
                  ),
              ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.brandGreen,
                  size: 18,
                ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  /// Build OTP notification banners
  List<Widget> _buildOtpNotificationBanners(AppLocalizations l10n) {
    final otpNotifications = _notificationService.otpNotifications;
    if (otpNotifications.isEmpty) {
      return [];
    }

    return otpNotifications.map((notification) {
      return _OtpNotificationBanner(
        notification: notification,
        notificationService: _notificationService,
        onExpired: () {
          if (mounted) {
            setState(() {}); // Refresh UI when notification expires
          }
        },
      );
    }).toList();
  }

  void _showFieldOfficerDetailsDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => FieldOfficerDetailsDialog(
        assignments: fieldOfficerAssignments,
      ),
    );
  }

  Widget _buildQuickActionGrid(BuildContext context, AppLocalizations l10n) {
    final String cropStatus = isAgentAssigned ? l10n.active : l10n.pending; 
    final Color cropStatusColor = isAgentAssigned ? AppColors.brandGreen : AppColors.pendingStatus;

    final items = [
      {
        "icon": Icons.grass, 
        "title": l10n.cropDetail,
        "route": AppRoutes.cropList,
        "status": cropStatus, 
        "statusColor": cropStatusColor,
        "isPremium": false,
        "requiresPersonal": false,
        "requiresFarm": true,
        "requiresCrop": true,
      },
      {
        "icon": Icons.bar_chart, 
        "title": l10n.dailySale,
        "route": AppRoutes.sell,
        "status": l10n.pending,
        "statusColor": AppColors.pendingStatus,
        // Advanced sales workflow – treated as premium for free users
        "isPremium": true,
        "requiresPersonal": false,
        "requiresFarm": true,
        "requiresCrop": true,
      },
      {
        "icon": Icons.monetization_on_outlined, 
        "title": l10n.funding,
        "route": AppRoutes.requestFunds,
        "status": l10n.pending,
        "statusColor": AppColors.pendingStatus,
        "isPremium": true,
        "requiresPersonal": false,
        "requiresFarm": true,
        "requiresCrop": false,
      },
      {
        "icon": Icons.account_balance_wallet_outlined, 
        "title": l10n.account,
        "route": null,
        "status": l10n.pending,
        "statusColor": AppColors.pendingStatus,
        "isPremium": true,
        "requiresPersonal": true,
        "requiresFarm": false,
        "requiresCrop": false,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95, 
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        return _buildActionCard(
          context,
          items[index]['icon'] as IconData,
          items[index]['title'] as String,
          items[index]['route'] as String?,
          items[index]['status'] as String,
          items[index]['statusColor'] as Color,
          items[index]['isPremium'] as bool,
          items[index]['requiresPersonal'] as bool,
          items[index]['requiresFarm'] as bool,
          items[index]['requiresCrop'] as bool,
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, 
    IconData icon, 
    String title, 
    String? route, 
    String status, 
    Color statusColor,
    bool isPremium,
    bool requiresPersonal,
    bool requiresFarm,
    bool requiresCrop,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Onboarding locks: explain missing details before navigating
          if (requiresPersonal && !_hasPersonalDetails) {
            await _showOnboardingDialog(
              context: context,
              icon: Icons.person_outline_rounded,
              title: 'Complete your profile',
              message:
                  'Before using this feature, please add your basic personal details.',
              ctaLabel: 'Complete now',
              routeName: AppRoutes.myDetails,
            );
            return;
          }

          if (requiresFarm && _totalFarms == 0) {
            await _showOnboardingDialog(
              context: context,
              icon: Icons.agriculture_rounded,
              title: 'Add your first farm',
              message:
                  'Add at least one farm to start using this feature for your land.',
              ctaLabel: 'Add farm',
              routeName: AppRoutes.addFarm,
            );
            return;
          }

          if (requiresCrop && !_hasCrops) {
            await _showOnboardingDialog(
              context: context,
              icon: Icons.grass_rounded,
              title: 'Add your first crop',
              message:
                  'Add at least one crop on your farm to start tracking it here.',
              ctaLabel: 'Add crop',
              routeName: AppRoutes.addCrop,
            );
            return;
          }

          // Premium quick actions: soft paywall for free users (after onboarding checks)
          if (isPremium) {
            final isSubscribed = await StorageService.isSubscribed();
            if (!isSubscribed) {
              await showSubscriptionRequiredDialog(
                context,
                featureName: title,
              );
              return;
            }
          }

          if (route != null && !isNavigating) {
            setState(() {
              isNavigating = true;
            });
            
            // Show loading dialog
            _showLoadingDialog(context);
            
            // Small delay to show loading animation
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Hide loading dialog and navigate
            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              await Navigator.pushNamed(context, route);
              _checkFieldOfficerAssignments();
              
              setState(() {
                isNavigating = false;
              });
            }
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.3,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status, 
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.brandGreen,
                            size: 18,
                          ),
                          if (isPremium)
                            const Positioned(
                              right: -1,
                              top: -1,
                              child: Icon(
                                Icons.lock,
                                size: 12,
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "Lorem Ipsum is simply dummy text of the printing.",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.alertText, 
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      letterSpacing: 0.2,
                    ), 
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // TODO: Navigate to ThynkChat
            },
            borderRadius: BorderRadius.circular(32),
            child: Container(
              width: 64, 
              height: 64,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/ai_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (c, o, s) => const Icon(
                  Icons.smart_toy_rounded,
                  color: AppColors.brandGreen,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Compact card to nudge user to complete missing profile/farm/crop details.
  Widget _buildCompletionCard({
    required IconData icon,
    required String title,
    required String message,
    required String ctaLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brandGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandGreen,
              textStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(ctaLabel),
          ),
        ],
      ),
    );
  }

  /// Friendly dialog used when a user taps a feature that requires
  /// missing onboarding (personal, farm, or crop details).
  Future<void> _showOnboardingDialog({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    required String ctaLabel,
    required String routeName,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(icon, color: AppColors.brandGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLocalizations.of(context)!.later,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, routeName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                ctaLabel,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget for displaying OTP notification with countdown timer
class _OtpNotificationBanner extends StatefulWidget {
  final NotificationModel notification;
  final NotificationService notificationService;
  final VoidCallback onExpired;

  const _OtpNotificationBanner({
    required this.notification,
    required this.notificationService,
    required this.onExpired,
  });

  @override
  State<_OtpNotificationBanner> createState() => _OtpNotificationBannerState();
}

class _OtpNotificationBannerState extends State<_OtpNotificationBanner> {
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration();

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRemainingTime();
        if (_remainingTime.isNegative || _remainingTime.inSeconds <= 0) {
          timer.cancel();
          widget.notificationService.removeExpiredOtpNotifications();
          widget.onExpired();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _updateRemainingTime() {
    if (!mounted) return;
    
    final now = DateTime.now();
    const otpExpirationDuration = Duration(minutes: 10);
    final age = now.difference(widget.notification.timestamp);
    final remaining = otpExpirationDuration - age;
    
    setState(() {
      _remainingTime = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final otp = widget.notification.data?['otp'] ?? '';
    final farmName = widget.notification.data?['farmName'] ?? 'Farm';
    final fieldOfficerName = widget.notification.data?['fieldOfficerName'] ?? 'Field Officer';
    
    final isExpiringSoon = _remainingTime.inMinutes < 2;
    final isExpired = _remainingTime.inSeconds <= 0;

    if (isExpired) {
      return const SizedBox.shrink(); // Don't show expired notifications
    }

    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isExpiringSoon
                ? [Colors.red.shade400, Colors.red.shade600]
                : [Colors.orange.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isExpiringSoon ? Colors.red : Colors.orange).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farm Verification OTP',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fieldOfficerName is verifying "$farmName"',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () {
                    widget.notificationService.removeNotification(widget.notification.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your OTP Code',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        otp,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white, size: 24),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: otp));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('OTP copied to clipboard: $otp'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy OTP',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Countdown Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Expires in: ${_formatDuration(_remainingTime)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please share this OTP with the field officer to complete verification.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withOpacity(0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
  }
}
