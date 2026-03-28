import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/onboarding/onboarding_controller.dart';
import '../../../core/models/setup_state.dart';
import '../../../core/services/setup_state_service.dart';
import '../../dashboard/services/field_officer_assignment_service.dart';
import '../../dashboard/services/notification_service.dart';
import '../../../core/services/http_service.dart';
import '../../subscription/widgets/subscription_guard.dart'
    show showSubscriptionRequiredDialog;
import 'field_officer_details_dialog.dart';
import '../../farm_management/widgets/weather_card.dart';
import '../widgets/hero_card.dart';
import '../widgets/setup_progress_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAgentAssigned = false;
  List<Map<String, dynamic>> fieldOfficerAssignments = [];
  Map<int, String> _farmNames = {}; // Map of farmId -> farmName
  List<Map<String, dynamic>> _unassignedFarms =
      []; // Farms without field officer assignment
  bool isLoadingAssignments = true;
  bool isNavigating = false;
  bool _allFarmsVerified = false;
  bool _isLoadingFarms = false;
  int _totalFarms = 0;
  int _verifiedFarms = 0;
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<NotificationModel>? _notificationSubscription;
  Timer? _expiredNotificationCleanupTimer;
  Timer? _farmVerificationRefreshTimer;
  VoidCallback? _notificationServiceListener;
  int _lastUnreadOtpCount = 0;

  SetupState _setupState = const SetupState();
  bool _isInitialLoadComplete = false; // Track if initial data load is complete
  bool _isSubscribed = false; // Track subscription status
  bool _hasPersonalDetails = false; // Track if personal details are completed
  bool _hasCrops = false; // Track if user has crops
  Map<String, dynamic>? _cachedHomeSummary;
  DateTime? _homeSummaryCacheTime;
  static const Duration _homeSummaryCacheTtl = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    // Filter any existing notifications to ensure they belong to current user (safeguard)
    _notificationService.filterNotificationsByCurrentUser();

    // Load initial data and wait for it to complete before showing UI
    _loadInitialData();

    _setupNotificationListener();

    // Cleanup expired notifications on a light cadence.
    _expiredNotificationCleanupTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _notificationService.removeExpiredOtpNotifications();
    });
    // After first frame, check if there are any OTPs that haven't shown popup yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final newForPopup = _notificationService.newOtpNotificationsForPopup;
      if (newForPopup.isNotEmpty) {
        _notificationService.markPopupShownForNotifications(newForPopup);
        _showOtpReceivedPopup();
      }
    });
    // Refresh farm verification status periodically without frequent wakeups.
    _farmVerificationRefreshTimer =
        Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _loadHomeSummary();
      } else {
        timer.cancel();
      }
    });
  }

  /// Load initial data - called once on initState
  Future<void> _loadInitialData() async {
    if (!mounted) return;

    // Add a small delay to ensure any previous API calls have completed
    // This is especially important when coming from onboarding
    await Future.delayed(const Duration(milliseconds: 100));

    // Force refresh farms cache to get latest data
    await _fetchFarmsData(forceRefresh: true);

    // Then check all statuses in parallel
    await Future.wait<void>([
      _checkFieldOfficerAssignments(),
      _checkAllFarmsVerified(),
      _loadSetupState(),
      _loadHomeSummary(forceRefresh: true),
      _checkSubscriptionStatus(),
    ]);

    // Mark initial load as complete and update UI
    if (mounted) {
      setState(() {
        _isInitialLoadComplete = true;
      });
    }
  }

  /// Refresh all data checks - called when screen becomes visible or after navigation
  Future<void> _refreshAllData() async {
    if (!mounted) return;

    // Force refresh farms cache to get latest data
    await _fetchFarmsData(forceRefresh: true);

    // Then check all statuses in parallel
    await Future.wait<void>([
      _checkFieldOfficerAssignments(),
      _checkAllFarmsVerified(),
      _loadSetupState(),
      _loadHomeSummary(forceRefresh: true),
      _checkSubscriptionStatus(),
    ]);

    // Ensure UI is updated after all checks complete
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadHomeSummary({bool forceRefresh = false}) async {
    if (!mounted) return;

    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedHomeSummary != null &&
        _homeSummaryCacheTime != null &&
        now.difference(_homeSummaryCacheTime!) < _homeSummaryCacheTtl) {
      final summary = _cachedHomeSummary!;
      if (mounted) {
        setState(() {
          _hasPersonalDetails = summary['hasPersonalDetails'] == true;
          _hasCrops = summary['hasCrops'] == true;
          _allFarmsVerified = summary['allFarmsVerified'] == true;
          _totalFarms = (summary['totalFarms'] as num?)?.toInt() ?? 0;
          _verifiedFarms = (summary['verifiedFarms'] as num?)?.toInt() ?? 0;
        });
      }
      return;
    }

    try {
      final response = await HttpService.get("farmer/profile/home-summary");
      final summary =
          response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      _cachedHomeSummary = summary;
      _homeSummaryCacheTime = DateTime.now();

      if (mounted) {
        setState(() {
          _hasPersonalDetails = summary['hasPersonalDetails'] == true;
          _hasCrops = summary['hasCrops'] == true;
          _allFarmsVerified = summary['allFarmsVerified'] == true;
          _totalFarms = (summary['totalFarms'] as num?)?.toInt() ?? 0;
          _verifiedFarms = (summary['verifiedFarms'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {
      await Future.wait<void>([
        _checkAllFarmsVerified(),
        _checkPersonalDetailsCompletion(),
        _checkHasCrops(),
      ]);
    }
  }

  void _showOtpReceivedPopup() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            l10n.otpCheckNotificationSnackbar,
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
        duration: const Duration(seconds: 10),
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
      final unreadCount = _notificationService.unreadOtpNotificationsCount;
      if (mounted && unreadCount != _lastUnreadOtpCount) {
        _lastUnreadOtpCount = unreadCount;
        setState(() {});
      }
    };
    _notificationService.addListener(_notificationServiceListener!);
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _expiredNotificationCleanupTimer?.cancel();
    _farmVerificationRefreshTimer?.cancel();
    if (_notificationServiceListener != null) {
      _notificationService.removeListener(_notificationServiceListener!);
    }
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
      final l10n = AppLocalizations.of(context)!;
      // Run both operations in parallel
      final results = await Future.wait([
        FieldOfficerAssignmentService.getAssignments(),
        _fetchFarmsData(),
      ]);

      final assignments = results[0] as List<dynamic>;
      final farmsData = results[1] ?? [];

      // Only show ASSIGNED field officers - filter out COMPLETED and CANCELLED
      final activeAssignments = assignments
          .where((assignment) {
            final status = assignment['status']?.toString().toUpperCase();
            return status == 'ASSIGNED';
          })
          .map((assignment) => assignment as Map<String, dynamic>)
          .toList();

      // Check if there's an assignment with null farmId (all farms assigned)
      bool allFarmsAssigned =
          activeAssignments.any((assignment) => assignment['farmId'] == null);

      // Extract assigned farm IDs from assignments
      final Set<int> assignedFarmIds = {};
      for (var assignment in activeAssignments) {
        final farmId = assignment['farmId'];
        if (farmId != null) {
          final farmIdInt =
              farmId is int ? farmId : int.tryParse(farmId.toString());
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
          final farmName =
              farmData['farmName'] ?? l10n.farmFallbackName('$farmId');
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
          final farmIdInt =
              farmId is int ? farmId : int.tryParse(farmId.toString());
          // Only add to unassigned if it's not already assigned AND not already verified
          if (farmIdInt != null &&
              !assignedFarmIds.contains(farmIdInt) &&
              (farm['isVerified'] == false || farm['isVerified'] == null)) {
            unassignedFarms.add({
              'id': farmIdInt,
              'farmName':
                  farm['farmName'] ?? l10n.farmFallbackName('$farmIdInt'),
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

  Future<void> _loadSetupState() async {
    final state = await SetupStateService.load();
    if (!mounted) return;
    setState(() {
      _setupState = state;
    });
  }

  /// Check subscription status
  Future<void> _checkSubscriptionStatus() async {
    if (!mounted) return;
    // This method is called but subscription checking is handled elsewhere
    // Placeholder for future subscription validation logic
  }

  /// Check personal details completion
  Future<void> _checkPersonalDetailsCompletion() async {
    if (!mounted) return;
    try {
      final response = await HttpService.get("farmer/profile/home-summary");
      final summary =
          response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      if (mounted) {
        setState(() {
          _hasPersonalDetails = summary['hasPersonalDetails'] == true;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check if user has crops
  Future<void> _checkHasCrops() async {
    if (!mounted) return;
    try {
      final response = await HttpService.get("farmer/profile/home-summary");
      final summary =
          response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      if (mounted) {
        setState(() {
          _hasCrops = summary['hasCrops'] == true;
        });
      }
    } catch (e) {
      // Handle error silently
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
      body: _isInitialLoadComplete
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Weather
                  _buildWeatherHeader(l10n),
                  const SizedBox(height: 20),

                  // Setup Progress Card replacing individual nudges
                  if (_isInitialLoadComplete &&
                      (!_setupState.hasProfile ||
                          !_setupState.hasFarm ||
                          !_setupState.hasCrop ||
                          !_setupState.hasSubscription)) ...[
                    SetupProgressCard(
                      hasPersonalDetails: _setupState.hasProfile,
                      hasFarm: _setupState.hasFarm,
                      hasCrop: _setupState.hasCrop,
                      isSubscribed: _setupState.hasSubscription,
                      onContinueSetup: () async {
                        if (!_setupState.hasProfile) {
                          await context
                              .read<OnboardingController>()
                              .allowPersonalOnboardingFromHome(context);
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.onboardingPersonal,
                          );
                        } else if (!_setupState.hasFarm) {
                          await context
                              .read<OnboardingController>()
                              .allowPersonalOnboardingFromHome(context);
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.addFarm,
                            arguments: {'fromOnboarding': true},
                          );
                        } else if (!_setupState.hasCrop) {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.addCrop,
                            arguments: {'fromOnboarding': true},
                          );
                        } else if (!_setupState.hasSubscription) {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.subscription,
                          );
                        }
                        await Future.delayed(const Duration(milliseconds: 300));
                        if (mounted) {
                          await _refreshAllData();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  ..._buildOtpNotificationBanners(l10n),
                  if (_buildOtpNotificationBanners(l10n).isNotEmpty)
                    const SizedBox(height: 16),

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

                  // Removed redundant sticky Subscribe CTA for unsubscribed users

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
            )
          : const Center(
              child: CircularProgressIndicator(color: AppColors.brandGreen),
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
    if (_isInitialLoadComplete && !_setupState.hasFarm) {
      return HeroCard(
        showAddFarmCta: _setupState.hasProfile,
        onAddFarm: _setupState.hasProfile
            ? () async {
                await context
                    .read<OnboardingController>()
                    .allowPersonalOnboardingFromHome(context);
                await Navigator.pushNamed(
                  context,
                  AppRoutes.addFarm,
                  arguments: {'fromOnboarding': true},
                );
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  await _refreshAllData();
                }
              }
            : null,
      );
    }

    // Normal WeatherCard if farm exists
    return WeatherCard(
      farmId: null, // null means use primary farm
      showForecast: true,
      onAddFarm: null, // HeroCard handles the empty state now
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
      final farmName = farm['farmName'] ?? l10n.farmFallbackName('$farmId');
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
                      '${l10n.forFarm} $farmNamesText',
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
                  l10n.allFarmsVerifiedTitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.allFarmsVerifiedBody(
                    _totalFarms,
                    _totalFarms > 1
                        ? l10n.farmWordPlural
                        : l10n.farmWordSingular,
                    _verifiedFarms,
                  ),
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
    final fieldOfficerName = assignment['fieldOfficerName']?.toString() ??
        l10n.fieldOfficerDefaultName;
    final fieldOfficerPhone = assignment['fieldOfficerPhone']?.toString() ?? '';
    final fieldOfficerPincode =
        assignment['fieldOfficerPincode']?.toString() ?? '';

    // Get all farm IDs from assignments and their names
    final List<String> assignedFarmNames = [];
    for (var assign in fieldOfficerAssignments) {
      final farmId = assign['farmId'];
      if (farmId != null) {
        final farmIdInt =
            farmId is int ? farmId : int.tryParse(farmId.toString());
        if (farmIdInt != null && _farmNames.containsKey(farmIdInt)) {
          assignedFarmNames.add(_farmNames[farmIdInt]!);
        } else {
          assignedFarmNames.add(l10n.farmFallbackName('$farmId'));
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
                  child:
                      Icon(Icons.person_rounded, color: Colors.brown, size: 30),
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
                            "${l10n.pincodeLabel} $fieldOfficerPincode",
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
                              '${l10n.assignedTo} ${assignedFarmNames.join(', ')}',
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
                          l10n.moreAssignments(
                              fieldOfficerAssignments.length - 1),
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
    final Color cropStatusColor =
        isAgentAssigned ? AppColors.brandGreen : AppColors.pendingStatus;

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

    final double width = MediaQuery.of(context).size.width;
    final String languageCode = Localizations.localeOf(context).languageCode;
    final bool isSmallScreen = width < 380;
    final bool isLongTextLocale = languageCode == 'en' || languageCode == 'hi';

    final double horizontalSpacing = isSmallScreen ? 12 : 16;
    final double verticalSpacing = isSmallScreen ? 12 : 16;
    final double childAspectRatio = isSmallScreen
        ? (isLongTextLocale ? 0.74 : 0.79)
        : (isLongTextLocale ? 0.81 : 0.86);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: horizontalSpacing,
        mainAxisSpacing: verticalSpacing,
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
    // Dynamic status calculation
    bool isLocked = (requiresPersonal && !_setupState.hasProfile) ||
        (requiresFarm && _totalFarms == 0) ||
        (requiresCrop && !_setupState.hasCrop) ||
        (isPremium && !_setupState.hasSubscription);

    final l10n = AppLocalizations.of(context)!;
    String displayStatus = isLocked ? l10n.statusLocked : status;
    Color displayStatusColor = isLocked ? Colors.grey.shade600 : statusColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Onboarding locks: explain missing details before navigating
          if (requiresPersonal && !_setupState.hasProfile) {
            await _showOnboardingDialog(
              context: context,
              icon: Icons.person_outline_rounded,
              title: l10n.homeOnboardingCompleteProfileTitle,
              message: l10n.homeOnboardingCompleteProfileMessage,
              ctaLabel: l10n.homeOnboardingCompleteProfileCta,
              routeName: AppRoutes.onboardingPersonal,
            );
            return;
          }

          if (requiresFarm && _totalFarms == 0) {
            await _showOnboardingDialog(
              context: context,
              icon: Icons.agriculture_rounded,
              title: l10n.homeOnboardingAddFarmTitle,
              message: l10n.homeOnboardingAddFarmMessage,
              ctaLabel: l10n.homeOnboardingAddFarmCta,
              routeName: AppRoutes.addFarm,
            );
            return;
          }

          if (requiresCrop && !_setupState.hasCrop) {
            await _showOnboardingDialog(
              context: context,
              icon: Icons.grass_rounded,
              title: l10n.homeOnboardingAddCropTitle,
              message: l10n.homeOnboardingAddCropMessage,
              ctaLabel: l10n.homeOnboardingAddCropCta,
              routeName: AppRoutes.addCrop,
            );
            return;
          }

          // Premium quick actions: soft paywall for free users (after onboarding checks)
          if (isPremium && !_setupState.hasSubscription) {
            await showSubscriptionRequiredDialog(
              context,
              featureName: title,
            );
            return;
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
              // Refresh all data when returning from navigation
              // Add small delay to ensure data is saved
              await Future.delayed(const Duration(milliseconds: 300));
              if (mounted) {
                await _refreshAllData();
                setState(() {
                  isNavigating = false;
                });
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Opacity(
            opacity: isLocked ? 0.6 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            statusColor,
                            statusColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isLocked)
                            BoxShadow(
                              color: statusColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    if (isLocked)
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: AutoSizeText(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            height: 1.3,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: displayStatusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AutoSizeText(
                          displayStatus,
                          style: GoogleFonts.poppins(
                            color: displayStatusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context) {
    // Alerts placeholder removed.
    // This widget should eventually render real alerts from NotificationService.
    return const SizedBox.shrink();
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.loading,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              onPressed: () async {
                Navigator.pop(ctx);
                if (routeName == AppRoutes.onboardingPersonal) {
                  await context
                      .read<OnboardingController>()
                      .allowPersonalOnboardingFromHome(context);
                }

                await Navigator.pushNamed(context, routeName);
                // Refresh data when returning from onboarding screens
                // Add small delay to ensure data is saved
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  await _refreshAllData();
                }
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
    final l10n = AppLocalizations.of(context)!;
    final otp = widget.notification.data?['otp'] ?? '';
    final farmName =
        widget.notification.data?['farmName'] ?? l10n.farmWordSingular;
    final fieldOfficerName = widget.notification.data?['fieldOfficerName'] ??
        l10n.fieldOfficerDefaultName;

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
            color:
                (isExpiringSoon ? Colors.red : Colors.orange).withOpacity(0.3),
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
                      l10n.farmVerificationOtpTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.fieldOfficerVerifyingFarm(
                          fieldOfficerName, farmName),
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
                  widget.notificationService
                      .removeNotification(widget.notification.id);
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
                      l10n.yourOtpCodeLabel,
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
                        content: Text(l10n.otpCopiedToClipboard(otp)),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: l10n.copyOtpTooltip,
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
                  l10n.expiresInTimer(_formatDuration(_remainingTime)),
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
            l10n.shareOtpWithFieldOfficer,
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
