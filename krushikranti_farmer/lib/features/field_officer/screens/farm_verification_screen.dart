import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../services/field_officer_service.dart';

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
  bool _isSubmitting = false;
  String? _error;

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

          print(
              'DEBUG: Farm $farmId - isVerified: $isVerified, status: $status');

          if (isVerified == true || status == 'VERIFIED') {
            state.isVerified = true;
            state.selectedStatus = 'VERIFIED';
            print('DEBUG: Farm $farmId marked as VERIFIED');
          } else if (status == 'REJECTED') {
            state.isVerified = true;
            state.selectedStatus = 'REJECTED';
            print('DEBUG: Farm $farmId marked as REJECTED');
          } else {
            print('DEBUG: Farm $farmId is NOT verified yet');
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
    // Dispose all controllers
    for (var state in _farmVerificationStates.values) {
      state.feedbackController.dispose();
      state.rejectionReasonController.dispose();
    }
    super.dispose();
  }

  Future<void> _submitVerification(
      int farmId, Map<String, dynamic> farm) async {
    final state = _farmVerificationStates[farmId];
    if (state == null) {
      return;
    }

    if (state.selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select verification status (Verify or Reject)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // If rejected, require feedback or rejection reason
    if (state.selectedStatus == 'REJECTED') {
      if (state.feedbackController.text.trim().isEmpty &&
          state.rejectionReasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please provide feedback or rejection reason when rejecting a farm'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() {
      state.isSubmitting = true;
      _error = null;
    });

    try {
      await FieldOfficerService.verifyFarm(
        farmId: farmId.toString(),
        status: state.selectedStatus!,
        feedback: state.feedbackController.text.trim().isNotEmpty
            ? state.feedbackController.text.trim()
            : null,
        rejectionReason: state.rejectionReasonController.text.trim().isNotEmpty
            ? state.rejectionReasonController.text.trim()
            : null,
      );

      if (mounted) {
        setState(() {
          state.isSubmitting = false;
          state.isVerified = true; // Mark as verified
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.selectedStatus == 'VERIFIED'
                  ? 'Farm verified successfully!'
                  : 'Farm rejection recorded successfully!',
            ),
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
            content: Text(_error!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verify Farm',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
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
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.brandGreen.withOpacity(0.12),
                                  AppColors.brandGreen.withOpacity(0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.brandGreen.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandGreen.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.brandGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.brandGreen,
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
                                            'Farmer',
                                        style: GoogleFonts.poppins(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF212121),
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
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
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
                  child: Text(
                    'Farms to Verify',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121),
                      letterSpacing: 0.2,
                    ),
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
    final farms = widget.assignment['farms'] as List? ?? [];
    if (farms.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'No farms found in this assignment',
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
    // Build location string
    String locationStr = 'Location not available';
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
                  blurRadius: state.isVerified ? 15 : 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
              border: state.isVerified
                  ? Border.all(
                      color: AppColors.success,
                      width: 2.5,
                    )
                  : Border.all(
                      color: const Color(0xFFE8E8E8),
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.brandGreen.withOpacity(0.2),
                                  AppColors.brandGreen.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.agriculture,
                              color: AppColors.brandGreen,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              farm['farmName'] ?? 'Farm',
                              style: GoogleFonts.poppins(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF212121),
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
                                                  'Verified',
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
                  _buildInfoRow(Icons.pin, 'Pincode: $pincode'),
                ],

                if (!state.isVerified) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Verification Status Selection
                  _buildStatusSelection(farmId, state),
                  const SizedBox(height: 16),

                  // Feedback Section
                  if (state.selectedStatus != null)
                    _buildFeedbackSection(farmId, state),

                  // Rejection Reason Section
                  if (state.selectedStatus == 'REJECTED') ...[
                    const SizedBox(height: 16),
                    _buildRejectionReasonSection(farmId, state),
                  ],

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
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.brandGreen,
                                      AppColors.brandGreen.withOpacity(0.85),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.brandGreen.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: state.isSubmitting
                                    ? const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
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
                                            state.selectedStatus == 'REJECTED'
                                                ? Icons.cancel
                                                : Icons.check_circle,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            state.selectedStatus == 'REJECTED'
                                                ? 'Submit Rejection'
                                                : 'Submit Verification',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
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
                                    state.selectedStatus == 'REJECTED'
                                        ? Icons.cancel
                                        : Icons.check_circle,
                                    color: state.selectedStatus == 'REJECTED'
                                        ? AppColors.error
                                        : AppColors.success,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This farm has already been ${state.selectedStatus == 'REJECTED' ? 'rejected' : 'verified'}.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: state.selectedStatus == 'REJECTED'
                                          ? AppColors.error
                                          : AppColors.success,
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.08),
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
                fontSize: 14,
                color: const Color(0xFF424242),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelection(int farmId, FarmVerificationState state) {
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
                    Icon(
                      Icons.verified_user,
                      size: 18,
                      color: AppColors.brandGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verification Status *',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212121),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusOption(
                        farmId,
                        state,
                        'VERIFIED',
                        'Verify',
                        Icons.check_circle,
                        AppColors.success,
                        state.selectedStatus == 'VERIFIED',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatusOption(
                        farmId,
                        state,
                        'REJECTED',
                        'Reject',
                        Icons.cancel,
                        AppColors.error,
                        state.selectedStatus == 'REJECTED',
                      ),
                    ),
                  ],
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
                  // Clear rejection reason if switching to verified
                  if (value == 'VERIFIED') {
                    state.rejectionReasonController.clear();
                  }
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE8E8E8),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
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
                        color: isSelected ? color : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? color : const Color(0xFF616161),
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
                    Icon(
                      Icons.note,
                      size: 18,
                      color: AppColors.brandGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Feedback / Notes',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212121),
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
                        ? 'Add any notes or observations about the farm verification...'
                        : 'Add feedback about why the farm is being rejected...',
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

  Widget _buildRejectionReasonSection(int farmId, FarmVerificationState state) {
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
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rejection Reason *',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212121),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Please provide a specific reason for rejection (or use the feedback field above)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: state.rejectionReasonController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF424242),
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'e.g., Farm details do not match, Location mismatch, Documents missing, etc.',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.error.withOpacity(0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.error.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.error.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.error, width: 2),
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
}

// Helper class to store verification state for each farm
class FarmVerificationState {
  String? selectedStatus;
  final TextEditingController feedbackController = TextEditingController();
  final TextEditingController rejectionReasonController =
      TextEditingController();
  bool isSubmitting = false;
  bool isVerified = false;
}
