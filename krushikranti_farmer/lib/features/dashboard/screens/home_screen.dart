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
import 'field_officer_details_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAgentAssigned = false; 
  List<Map<String, dynamic>> fieldOfficerAssignments = [];
  bool isLoadingAssignments = true;
  bool isNavigating = false;
  bool _allFarmsVerified = false;
  bool _isLoadingFarms = false;
  int _totalFarms = 0;
  int _verifiedFarms = 0;
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<NotificationModel>? _notificationSubscription;
  Timer? _expiredNotificationCleanupTimer;

  @override
  void initState() {
    super.initState();
    // Filter any existing notifications to ensure they belong to current user (safeguard)
    // Note: We don't clear all notifications here because NotificationService is a singleton
    // and we want to preserve notifications across screen rebuilds
    _notificationService.filterNotificationsByCurrentUser();
    _checkFieldOfficerAssignments();
    _checkAllFarmsVerified();
    _setupNotificationListener();
    // Start polling for notifications from backend
    _notificationService.startPolling(interval: const Duration(seconds: 10));
    // Start periodic cleanup of expired OTP notifications (every 30 seconds)
    _expiredNotificationCleanupTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _notificationService.removeExpiredOtpNotifications();
        setState(() {}); // Refresh UI to remove expired notifications
      }
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

  void _setupNotificationListener() {
    _notificationSubscription = _notificationService.notificationStream.listen(
      (notification) {
        if (mounted && notification.type == 'FARM_VERIFICATION_OTP') {
          setState(() {}); // Refresh UI to show new notification
        }
      },
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _expiredNotificationCleanupTimer?.cancel();
    _notificationService.stopPolling();
    super.dispose();
  }

  Future<void> _checkFieldOfficerAssignments() async {
    setState(() {
      isLoadingAssignments = true;
    });
    
    try {
      final assignments = await FieldOfficerAssignmentService.getAssignments();
      // Only show ASSIGNED field officers - filter out COMPLETED and CANCELLED
      final activeAssignments = assignments.where((assignment) {
        final status = assignment['status']?.toString().toUpperCase();
        return status == 'ASSIGNED';
      }).toList();
      
      if (mounted) {
        setState(() {
          fieldOfficerAssignments = activeAssignments;
          isAgentAssigned = activeAssignments.isNotEmpty;
          isLoadingAssignments = false;
        });
      }
    } catch (e) {
      // If error, assume no assignments
      if (mounted) {
        setState(() {
          fieldOfficerAssignments = [];
          isAgentAssigned = false;
          isLoadingAssignments = false;
        });
      }
    }
  }

  Future<void> _checkAllFarmsVerified() async {
    if (_isLoadingFarms) return; // Prevent concurrent calls
    
    setState(() {
      _isLoadingFarms = true;
    });

    try {
      final response = await HttpService.get("farmer/profile/farms");
      final List<dynamic> farmsData = response['data'] ?? [];
      
      // Filter only active farms
      final activeFarms = farmsData.where((farm) {
        return farm['isActive'] == true;
      }).toList();
      
      if (activeFarms.isEmpty) {
        // No farms, so not all verified
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
      // If error, assume not all verified
      if (mounted) {
        setState(() {
          _allFarmsVerified = false;
          _isLoadingFarms = false;
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
          _buildCircleIcon(Icons.notifications_none_rounded),
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

            // B. OTP Notification Banner (if any)
            if (_notificationService.otpNotifications.isNotEmpty) ...[
              ..._buildOtpNotificationBanners(l10n),
              const SizedBox(height: 20),
            ],
            
            // C. All Farms Verified Banner (if all farms are verified)
            if (_allFarmsVerified) ...[
              _buildAllFarmsVerifiedCard(l10n),
              const SizedBox(height: 20),
            ],
            
            // D. Field Officer Banner
            if (isLoadingAssignments)
              _buildLoadingBanner(l10n)
            else if (isAgentAssigned) 
              _buildFieldOfficerAssignedCard(l10n)
            else 
              _buildFieldOfficerPendingBanner(l10n),
            
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

    // Get the first active assignment
    final assignment = fieldOfficerAssignments.first;
    final fieldOfficerName = assignment['fieldOfficerName']?.toString() ?? 'Field Officer';
    final fieldOfficerPhone = assignment['fieldOfficerPhone']?.toString() ?? '';
    final fieldOfficerPincode = assignment['fieldOfficerPincode']?.toString() ?? '';

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
        "statusColor": cropStatusColor 
      },
      {
        "icon": Icons.bar_chart, 
        "title": l10n.dailySale,
        "route": AppRoutes.sell,
        "status": l10n.pending,
        "statusColor": AppColors.pendingStatus
      },
      {
        "icon": Icons.monetization_on_outlined, 
        "title": l10n.funding,
        "route": AppRoutes.requestFunds,
        "status": l10n.pending,
        "statusColor": AppColors.pendingStatus
      },
      {
        "icon": Icons.account_balance_wallet_outlined, 
        "title": l10n.account,
        "route": null,
        "status": l10n.pending,
        "statusColor": AppColors.pendingStatus
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
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
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
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.brandGreen,
                        size: 18,
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
