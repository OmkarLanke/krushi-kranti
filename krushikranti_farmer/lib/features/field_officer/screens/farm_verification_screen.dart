import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../services/field_officer_service.dart';

class FarmVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> assignment; // Contains farms list, farmer info, etc.

  const FarmVerificationScreen({
    super.key,
    required this.assignment,
  });

  @override
  State<FarmVerificationScreen> createState() => _FarmVerificationScreenState();
}

class _FarmVerificationScreenState extends State<FarmVerificationScreen> {
  // Store verification state for each farm
  final Map<int, FarmVerificationState> _farmVerificationStates = {};
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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
          
          print('DEBUG: Farm $farmId - isVerified: $isVerified, status: $status');
          
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
    // Dispose all controllers
    for (var state in _farmVerificationStates.values) {
      state.feedbackController.dispose();
      state.rejectionReasonController.dispose();
    }
    super.dispose();
  }

  Future<void> _submitVerification(int farmId, Map<String, dynamic> farm) async {
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
            content: Text('Please provide feedback or rejection reason when rejecting a farm'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farmer Information (if available)
            if (widget.assignment['farmerName'] != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: AppColors.brandGreen, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.assignment['farmerName'] ?? 'Farmer',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          if (widget.assignment['farmerPhoneNumber'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.assignment['farmerPhoneNumber'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Farms List
            Text(
              'Farms to Verify',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // List of Farms
            ..._buildFarmsList(),
          ],
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

      return Padding(
        padding: EdgeInsets.only(bottom: index < farms.length - 1 ? 24 : 0),
        child: _buildFarmVerificationCard(farm, farmId, state),
      );
    }).toList();
  }

  Widget _buildFarmVerificationCard(
    Map<String, dynamic> farm,
    int farmId,
    FarmVerificationState state,
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: state.isVerified
            ? Border.all(color: AppColors.success, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farm Info Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.agriculture,
                  color: AppColors.brandGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  farm['farmName'] ?? 'Farm',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (state.isVerified)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: state.selectedStatus == 'VERIFIED'
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          state.selectedStatus == 'VERIFIED' ? Icons.check_circle : Icons.cancel,
                          color: state.selectedStatus == 'VERIFIED' ? AppColors.success : AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            state.selectedStatus ?? 'Verified',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: state.selectedStatus == 'VERIFIED' ? AppColors.success : AppColors.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
            if (state.selectedStatus != null) _buildFeedbackSection(farmId, state),

            // Rejection Reason Section
            if (state.selectedStatus == 'REJECTED') ...[
              const SizedBox(height: 16),
              _buildRejectionReasonSection(farmId, state),
            ],

            const SizedBox(height: 16),

            // Submit Button for this farm
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isSubmitting ? null : () => _submitVerification(farmId, farm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        state.selectedStatus == 'REJECTED' 
                            ? 'Submit Rejection' 
                            : 'Submit Verification',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ] else ...[
            // Show verification details if already verified
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This farm has already been ${state.selectedStatus == 'REJECTED' ? 'rejected' : 'verified'}.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.success,
                      ),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelection(int farmId, FarmVerificationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Status *',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
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
    return InkWell(
      onTap: () {
        setState(() {
          state.selectedStatus = value;
          // Clear rejection reason if switching to verified
          if (value == 'VERIFIED') {
            state.rejectionReasonController.clear();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(int farmId, FarmVerificationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feedback / Notes',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: state.feedbackController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: state.selectedStatus == 'VERIFIED' 
                ? 'Add any notes or observations about the farm verification...'
                : 'Add feedback about why the farm is being rejected...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.brandGreen),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildRejectionReasonSection(int farmId, FarmVerificationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rejection Reason *',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please provide a specific reason for rejection (or use the feedback field above)',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: state.rejectionReasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g., Farm details do not match, Location mismatch, Documents missing, etc.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}

// Helper class to store verification state for each farm
class FarmVerificationState {
  String? selectedStatus;
  final TextEditingController feedbackController = TextEditingController();
  final TextEditingController rejectionReasonController = TextEditingController();
  bool isSubmitting = false;
  bool isVerified = false;
}
