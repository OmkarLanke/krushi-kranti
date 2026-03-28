import 'package:flutter/material.dart';
import 'dart:isolate';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../services/field_officer_cache.dart';
import '../services/field_officer_repository.dart';
import 'farm_verification_screen.dart';

class FieldOfficerHomeScreen extends StatefulWidget {
  const FieldOfficerHomeScreen({super.key});

  @override
  State<FieldOfficerHomeScreen> createState() => _FieldOfficerHomeScreenState();
}

class _FieldOfficerHomeScreenState extends State<FieldOfficerHomeScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  int _activeLoadToken = 0;
  bool _hasAssignmentDrivenStats = false;
  String _userName = 'Field Officer';
  String _userId = '';
  String _region = '';
  Map<String, dynamic> _profileData = {};

  // Statistics
  int _totalAssignedFarmers = 0;
  int _approvedFarms = 0;
  int _pendingFarms = 0;
  List<Map<String, dynamic>> _assignedVillages =
      []; // Changed to store village info with pincode
  List<dynamic> _pendingVerifications = [];
  List<dynamic> _priorityFarms = [];
  static const int _assignmentPageSize = 1000;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Faster animation
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // Faster animation
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

    // Start animations immediately for better perceived performance
    _fadeController.forward();
    _slideController.forward();

    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final int loadToken = ++_activeLoadToken;
    _hasAssignmentDrivenStats = false;

    try {
      // Load user data from storage (fast, synchronous)
      final userData = await StorageService.getUserDetails();

      // Set initial user data immediately for faster UI update
      if (!mounted || loadToken != _activeLoadToken) return;
      setState(() {
        _userName =
            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                .trim();
        if (_userName.isEmpty) {
          _userName = 'Field Officer';
        }
        _userId = userData['userId']?.toString() ?? '';
        _region = userData['district']?.toString() ?? 'Region';
      });

      // Show stale cache instantly while fetching a fresh copy.
      final cached = FieldOfficerRepository.getCachedDashboardData(
        includeStale: true,
      );
      if (cached != null && mounted) {
        if (cached.assignments.isNotEmpty) {
          await _applyDashboardData(
            profile: cached.profile,
            assignments: cached.assignments,
            isLoading: false,
            loadToken: loadToken,
          );
        } else if (cached.profile.isNotEmpty) {
          setState(() {
            _profileData = cached.profile;
            _region = cached.profile['district']?.toString() ??
                cached.profile['state']?.toString() ??
                _region;
            _userId = cached.profile['fieldOfficerId']?.toString() ?? _userId;
          });
        }
      }

      // Load lightweight summary first for fast home-card paint.
      final summary = await FieldOfficerRepository.getAssignmentSummary(
        forceRefresh: cached != null,
      );
      if (mounted && loadToken == _activeLoadToken && summary.isNotEmpty) {
        _applySummaryData(summary, loadToken: loadToken);
      }

      // Load first page of assignments for details, then lazy-load next pages.
      final firstPage = await FieldOfficerRepository.getAssignmentsPage(
        page: 0,
        size: _assignmentPageSize,
        forceRefresh: cached != null,
      );
      if (!mounted || loadToken != _activeLoadToken) return;

      await _applyDashboardData(
        profile: await FieldOfficerRepository.getProfile(
          forceRefresh: cached != null,
        ),
        assignments: firstPage.assignments,
        isLoading: false,
        loadToken: loadToken,
      );

      // Home cards and pending-verification list must be based on complete data.
      // Use a large page size to avoid partial page-derived empty states.
    } catch (e) {
      // Error logged by services
      if (mounted && loadToken == _activeLoadToken) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applySummaryData(
    Map<String, dynamic> summary, {
    required int loadToken,
  }) {
    if (!mounted ||
        loadToken != _activeLoadToken ||
        _hasAssignmentDrivenStats) {
      return;
    }

    int parseCount(String key) => (summary[key] as num?)?.toInt() ?? 0;

    final int summaryApproved = parseCount('verifiedFarms');
    final int summaryPending = parseCount('pendingFarms');
    final int summaryTotal =
        (summary['activeFarmAssignments'] as num?)?.toInt() ??
            parseCount('totalAssignments');

    // Avoid a temporary 0/0/0 flash if summary returns empty/zero while
    // we already have meaningful counters on screen and assignment hydration is pending.
    final bool isTransientZeroSummary =
        summaryApproved == 0 && summaryPending == 0 && summaryTotal == 0;
    final bool hasExistingNonZeroCounters =
        _approvedFarms > 0 || _pendingFarms > 0 || _totalAssignedFarmers > 0;
    if (!_isLoading && isTransientZeroSummary && hasExistingNonZeroCounters) {
      return;
    }

    setState(() {
      _approvedFarms = summaryApproved;
      _pendingFarms = summaryPending;
      _totalAssignedFarmers = summaryTotal;
      if (_isLoading) {
        _isLoading = false;
      }
    });
  }

  Future<void> _applyDashboardData({
    required Map<String, dynamic> profile,
    required List<dynamic> assignments,
    required bool isLoading,
    required int loadToken,
  }) async {
    if (!mounted || loadToken != _activeLoadToken) return;

    final statistics = await _calculateStatistics(assignments);

    if (!mounted || loadToken != _activeLoadToken) return;

    setState(() {
      if (profile.isNotEmpty) {
        _profileData = profile;
        _region = profile['district']?.toString() ??
            profile['state']?.toString() ??
            _region;
        _userId = profile['fieldOfficerId']?.toString() ?? _userId;
      }

      _totalAssignedFarmers = statistics['totalAssignedFarmers'] as int;
      _approvedFarms = statistics['approvedFarms'] as int;
      _pendingFarms = statistics['pendingFarms'] as int;
      _assignedVillages =
          statistics['assignedVillages'] as List<Map<String, dynamic>>;
      _pendingVerifications =
          statistics['pendingVerifications'] as List<dynamic>;
      _priorityFarms = statistics['priorityFarms'] as List<dynamic>;
      _isLoading = isLoading;
      _hasAssignmentDrivenStats = true;
    });
  }

  Future<Map<String, dynamic>> _calculateStatistics(
    List<dynamic> assignments,
  ) async {
    if (assignments.length < 50) {
      return _calculateStatisticsSync(assignments);
    }

    try {
      return await Isolate.run(() => _calculateStatisticsPayload(assignments));
    } catch (_) {
      // Fallback to sync processing if isolate cannot process payload.
      return _calculateStatisticsSync(assignments);
    }
  }

  /// Calculate statistics synchronously without setState for better performance
  Map<String, dynamic> _calculateStatisticsSync(List<dynamic> assignments) {
    Set<String> uniqueFarmers = {};
    Map<String, Map<String, dynamic>> villagesMap = {};
    int approved = 0;
    int pending = 0;
    List<dynamic> pendingVerifs = [];
    List<dynamic> priorityFarms = [];

    for (var assignment in assignments) {
      if (assignment is! Map<String, dynamic>) continue;

      final farmerUserId = assignment['farmerUserId']?.toString() ?? '';
      if (farmerUserId.isNotEmpty) {
        uniqueFarmers.add(farmerUserId);
      }

      final farms = assignment['farms'] as List? ?? [];
      final farmerName = assignment['farmerName'] ?? 'Unknown Farmer';
      final assignedAt = assignment['assignedAt'];

      for (var farm in farms) {
        if (farm is! Map<String, dynamic>) continue;

        final village = farm['village']?.toString() ?? '';
        final pincode = farm['pincode']?.toString() ?? '';
        final district = farm['district']?.toString() ?? '';
        final state = farm['state']?.toString() ?? '';

        if (village.isNotEmpty) {
          if (!villagesMap.containsKey(village)) {
            villagesMap[village] = {
              'village': village,
              'pincode': pincode,
              'district': district,
              'state': state,
              'farms': <Map<String, dynamic>>[],
              'farmers': <String>{},
            };
          }
          villagesMap[village]!['farms'].add(farm as Map<String, dynamic>);
          if (farmerName.isNotEmpty) {
            (villagesMap[village]!['farmers'] as Set<String>).add(farmerName);
          }
        }

        final status = farm['status']?.toString().toUpperCase() ?? 'PENDING';
        final isVerified = farm['isVerified'] ?? false;

        if (status == 'VERIFIED' || isVerified == true) {
          approved++;
        } else {
          pending++;
          pendingVerifs.add({
            'farmerName': farmerName,
            'village': village,
            'farm': farm,
            'assignment': assignment,
            'assignedAt': assignedAt,
          });

          if (assignedAt != null) {
            try {
              final assignedDate = DateTime.parse(assignedAt);
              final daysPending =
                  DateTime.now().difference(assignedDate).inDays;
              if (daysPending > 4) {
                priorityFarms.add({
                  'farmerName': farmerName,
                  'village': village,
                  'farm': farm,
                  'assignment': assignment,
                  'daysPending': daysPending,
                });
              }
            } catch (e) {
              // Skip invalid dates
            }
          }
        }
      }
    }

    // Convert villages map to list and sort
    final villagesList = villagesMap.values.toList();
    villagesList.sort(
        (a, b) => (a['village'] as String).compareTo(b['village'] as String));

    // Convert Set to List for farmers
    for (var village in villagesList) {
      village['farmers'] = (village['farmers'] as Set<String>).toList();
    }

    return {
      'totalAssignedFarmers': uniqueFarmers.length,
      'approvedFarms': approved,
      'pendingFarms': pending,
      'assignedVillages': villagesList,
      'pendingVerifications': pendingVerifs,
      'priorityFarms': priorityFarms,
    };
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: Text(
          'KrushiKranti',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Handle notification tap
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
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
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.brandGreen,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Profile Card
                        _buildProfileCard(),
                        const SizedBox(height: 16),

                        // Assigned Villages
                        _buildAssignedVillages(),
                        const SizedBox(height: 24),

                        // Summary Statistics
                        _buildStatisticsCards(),
                        const SizedBox(height: 24),

                        // Pending Verification Section
                        _buildPendingVerificationSection(),
                        const SizedBox(height: 24),

                        // Priority Farm Section
                        _buildPriorityFarmSection(),
                        const SizedBox(height: 24),

                        // Additional Analytics Section
                        _buildAdditionalAnalyticsSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Image at Top
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/field_officer/farm.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF81C784),
                        const Color(0xFF66BB6A),
                        AppColors.brandGreen,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // User Info Overlay at Bottom (Left side, near profile picture)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(
                  left: 16, right: 120, top: 7, bottom: 7),
              decoration: BoxDecoration(
                color: const Color(
                    0xFFFFFBF0), // Very pale cream/off-white background
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _userName,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ID : ${_userId.isNotEmpty ? _userId : 'N/A'}',
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        _region,
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.brandGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Profile Picture on Right
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset(
                  'assets/images/field_officer/krushifarmer.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to initials if image fails to load
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: AppColors.brandGreen.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_userName),
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandGreen,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.brandGreen,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildAssignedVillages() {
    if (_assignedVillages.isEmpty) {
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250), // Faster animation
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          VillagesListScreen(villages: _assignedVillages),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOutCubic,
                          )),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                          Icons.location_on,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned Villages',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_assignedVillages.length} ${_assignedVillages.length == 1 ? 'village' : 'villages'} assigned',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: AppColors.brandGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Assigned Farmer',
            _totalAssignedFarmers.toString(),
            Icons.people,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Approved Farms',
            _approvedFarms.toString(),
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending Farms',
            _pendingFarms.toString(),
            Icons.pending,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.brandGreen,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppColors.brandGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Pending Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to first pending verification or show list
                if (_pendingVerifications.isNotEmpty) {
                  final firstPending = _pendingVerifications[0];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FarmVerificationScreen(
                        assignment: firstPending['assignment'],
                      ),
                    ),
                  ).then((_) {
                    // Clear cache and reload after verification
                    FieldOfficerCache.clearAssignmentsCache();
                    _loadData();
                  });
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                'Visit Now',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_hasAssignmentDrivenStats)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.brandGreen,
                strokeWidth: 2.5,
              ),
            ),
          )
        else if (_pendingVerifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: AppColors.brandGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending verifications',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_pendingVerifications
              .take(2)
              .map((item) => _buildPendingVerificationItem(item))),
      ],
    );
  }

  Widget _buildPendingVerificationItem(dynamic item) {
    final farmerName = item['farmerName'] ?? 'Unknown';
    final village = item['village'] ?? '';
    final assignment = item['assignment'];
    final assignedAt = item['assignedAt'];

    String timeStr = 'Today';
    if (assignedAt != null) {
      try {
        final date = DateTime.parse(assignedAt);
        final now = DateTime.now();
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          timeStr = 'Today ${_formatTime(date)}';
        } else {
          timeStr = _formatDate(date);
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FarmVerificationScreen(
                  assignment: assignment,
                ),
              ),
            ).then((_) => _loadData());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brandGreen,
                        AppColors.brandGreen.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(farmerName),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmerName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              village,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.brandGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityFarmSection() {
    if (_priorityFarms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7043).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.priority_high,
                      size: 18,
                      color: Color(0xFFFF7043),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Priority Farm',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF7043).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'High Priority',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF7043),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${_priorityFarms.length} Farms pending for over 4 days',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        if (_priorityFarms.isNotEmpty)
          Container(
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final firstPriority = _priorityFarms[0];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FarmVerificationScreen(
                        assignment: firstPriority['assignment'],
                      ),
                    ),
                  ).then((_) {
                    // Clear cache and reload after verification
                    FieldOfficerCache.clearAssignmentsCache();
                    _loadData();
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFFF7043),
                              const Color(0xFFFF7043).withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(_priorityFarms[0]['farmerName'] ?? ''),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _priorityFarms[0]['farmerName'] ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_priorityFarms[0]['village'] ?? ''}, ${_priorityFarms[0]['farm']?['cropName'] ?? 'Farm'}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF7043),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pending for ${_priorityFarms[0]['daysPending']} days',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFFFF7043),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: const Color(0xFFFF7043),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdditionalAnalyticsSection() {
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
              child: Icon(
                Icons.analytics_outlined,
                size: 18,
                color: AppColors.brandGreen,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Additional Analytics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(32),
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
          child: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: AppColors.brandGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Analytics content will be shown here',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')} ${date.year}';
  }
}

Map<String, dynamic> _calculateStatisticsPayload(List<dynamic> assignments) {
  Set<String> uniqueFarmers = {};
  Map<String, Map<String, dynamic>> villagesMap = {};
  int approved = 0;
  int pending = 0;
  List<dynamic> pendingVerifs = [];
  List<dynamic> priorityFarms = [];

  for (var assignment in assignments) {
    if (assignment is! Map<String, dynamic>) continue;

    final farmerUserId = assignment['farmerUserId']?.toString() ?? '';
    if (farmerUserId.isNotEmpty) {
      uniqueFarmers.add(farmerUserId);
    }

    final farms = assignment['farms'] as List? ?? [];
    final farmerName = assignment['farmerName'] ?? 'Unknown Farmer';
    final assignedAt = assignment['assignedAt'];

    for (var farm in farms) {
      if (farm is! Map<String, dynamic>) continue;

      final village = farm['village']?.toString() ?? '';
      final pincode = farm['pincode']?.toString() ?? '';
      final district = farm['district']?.toString() ?? '';
      final state = farm['state']?.toString() ?? '';

      if (village.isNotEmpty) {
        if (!villagesMap.containsKey(village)) {
          villagesMap[village] = {
            'village': village,
            'pincode': pincode,
            'district': district,
            'state': state,
            'farms': <Map<String, dynamic>>[],
            'farmers': <String>{},
          };
        }
        villagesMap[village]!['farms'].add(farm);
        if (farmerName.isNotEmpty) {
          (villagesMap[village]!['farmers'] as Set<String>).add(farmerName);
        }
      }

      final status = farm['status']?.toString().toUpperCase() ?? 'PENDING';
      final isVerified = farm['isVerified'] ?? false;

      if (status == 'VERIFIED' || isVerified == true) {
        approved++;
      } else {
        pending++;
        pendingVerifs.add({
          'farmerName': farmerName,
          'village': village,
          'farm': farm,
          'assignment': assignment,
          'assignedAt': assignedAt,
        });

        if (assignedAt != null) {
          try {
            final assignedDate = DateTime.parse(assignedAt);
            final daysPending = DateTime.now().difference(assignedDate).inDays;
            if (daysPending > 4) {
              priorityFarms.add({
                'farmerName': farmerName,
                'village': village,
                'farm': farm,
                'assignment': assignment,
                'daysPending': daysPending,
              });
            }
          } catch (_) {
            // Skip invalid dates
          }
        }
      }
    }
  }

  final villagesList = villagesMap.values.toList();
  villagesList.sort(
      (a, b) => (a['village'] as String).compareTo(b['village'] as String));

  for (var village in villagesList) {
    village['farmers'] = (village['farmers'] as Set<String>).toList();
  }

  return {
    'totalAssignedFarmers': uniqueFarmers.length,
    'approvedFarms': approved,
    'pendingFarms': pending,
    'assignedVillages': villagesList,
    'pendingVerifications': pendingVerifs,
    'priorityFarms': priorityFarms,
  };
}

// Villages List Screen
class VillagesListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> villages;

  const VillagesListScreen({super.key, required this.villages});

  @override
  State<VillagesListScreen> createState() => _VillagesListScreenState();
}

class _VillagesListScreenState extends State<VillagesListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Faster animation
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // Faster animation
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

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assigned Villages',
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
      body: widget.villages.isEmpty
          ? Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Text(
                      'No villages assigned',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.villages.length,
                  itemBuilder: (context, index) {
                    final village = widget.villages[index];
                    return _buildAnimatedVillageCard(village, index);
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildAnimatedVillageCard(Map<String, dynamic> village, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            VillageDetailScreen(village: village),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOutCubic,
                            )),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.brandGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.location_city,
                                  color: AppColors.brandGreen,
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                village['village'] ?? 'Unknown Village',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.pin,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pincode: ${village['pincode']?.toString().isNotEmpty == true ? village['pincode'] : 'N/A'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Village Detail Screen
class VillageDetailScreen extends StatefulWidget {
  final Map<String, dynamic> village;

  const VillageDetailScreen({super.key, required this.village});

  @override
  State<VillageDetailScreen> createState() => _VillageDetailScreenState();
}

class _VillageDetailScreenState extends State<VillageDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Faster animation
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // Faster animation
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

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final villageName = widget.village['village'] ?? 'Unknown Village';
    final pincode = widget.village['pincode']?.toString() ?? 'N/A';
    final district = widget.village['district']?.toString() ?? 'N/A';
    final state = widget.village['state']?.toString() ?? 'N/A';
    final farms = widget.village['farms'] as List<dynamic>? ?? [];
    final farmers = (widget.village['farmers'] as List<dynamic>? ?? [])
        .map((f) => f.toString())
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          villageName,
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
                // Village Info Card
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 250),
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
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandGreen
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.location_city,
                                            color: AppColors.brandGreen,
                                            size: 28,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          villageName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$district, $state',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(Icons.pin, 'Pincode', pincode),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                  Icons.location_on, 'District', district),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.map, 'State', state),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Statistics
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Farms',
                                farms.length.toString(),
                                Icons.agriculture,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Total Farmers',
                                farmers.length.toString(),
                                Icons.people,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Farmers List
                if (farmers.isNotEmpty) ...[
                  Text(
                    'Farmers',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...farmers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final farmer = entry.value;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(
                          milliseconds:
                              150 + (index * 30)), // Faster staggered animation
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 15 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 5,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        AppColors.brandGreen.withOpacity(0.1),
                                    child: Text(
                                      farmer.toString().isNotEmpty
                                          ? farmer.toString()[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.brandGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      farmer.toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
                const SizedBox(height: 24),
                // Farms List
                if (farms.isNotEmpty) ...[
                  Text(
                    'Farms',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...farms.asMap().entries.map((entry) {
                    final index = entry.key;
                    final farm = entry.value as Map<String, dynamic>;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(
                          milliseconds:
                              200 + (index * 50)), // Faster staggered animation
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Transform.scale(
                              scale: 0.95 + (0.05 * value),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 1),
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
                                            color: AppColors.brandGreen
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.agriculture,
                                            color: AppColors.brandGreen,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            farm['farmName']?.toString() ??
                                                'Farm ${index + 1}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (farm['isVerified'] == true ||
                                            farm['status']
                                                    ?.toString()
                                                    .toUpperCase() ==
                                                'VERIFIED')
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.success
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Verified',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.success,
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Pending',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (farm['cropName']
                                            ?.toString()
                                            .isNotEmpty ==
                                        true) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Crop: ${farm['cropName']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brandGreen),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandGreen, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
