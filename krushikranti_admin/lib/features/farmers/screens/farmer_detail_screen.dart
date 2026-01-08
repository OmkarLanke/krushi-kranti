import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../models/farmer_models.dart';
import '../services/farmer_service.dart';
import '../../field_officers/services/assignment_service.dart';
import '../../field_officers/models/assignment_models.dart';

class FarmerDetailDialog extends StatefulWidget {
  final int farmerId;

  const FarmerDetailDialog({super.key, required this.farmerId});

  @override
  State<FarmerDetailDialog> createState() => _FarmerDetailDialogState();
}

class _FarmerDetailDialogState extends State<FarmerDetailDialog> {
  FarmerDetail? _farmer;
  List<AssignmentResponse> _assignments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFarmerDetail();
  }

  Future<void> _loadFarmerDetail() async {
    try {
      final farmer = await AdminFarmerService.getFarmerDetail(widget.farmerId);
      
      // Fetch assignments for this farmer
      List<AssignmentResponse> assignments = [];
      try {
        assignments = await FieldOfficerAssignmentService.getAssignmentsForFarmer(
          farmer.userId,
        );
      } catch (e) {
        // If assignment fetch fails, continue without it
        print('Failed to fetch assignments: $e');
      }
      
      setState(() {
        _farmer = farmer;
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  bool _isFarmAssigned(int farmId) {
    if (_assignments.isEmpty) return false;
    
    // Check if there's an assignment for this specific farm
    // or an assignment for all farms (farmId is null)
    return _assignments.any((assignment) {
      // Assignment for all farms (farmId is null)
      if (assignment.farmId == null) {
        return true;
      }
      // Assignment for this specific farm
      return assignment.farmId == farmId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 900),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farmer Details',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (_farmer != null) ...[
                const SizedBox(height: 4),
                Text(
                  _farmer!.profile.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error Loading Data',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
              onPressed: _loadFarmerDetail,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
            ),
          ],
            ),
          ),
        ),
      );
    }

    final farmer = _farmer!;

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
            _buildSection(
              'Profile Information',
              Icons.person_outline_rounded,
              AppColors.brandGreen,
              _buildProfileContent(farmer.profile),
            ),
            const SizedBox(height: 20),

          // KYC Section
            _buildSection(
              'KYC Verification',
              Icons.verified_user_outlined,
              AppColors.success,
              _buildKycContent(farmer.kyc),
            ),
            const SizedBox(height: 20),

          // Subscription Section
            _buildSection(
              'Subscription',
              Icons.card_membership_outlined,
              AppColors.info,
              _buildSubscriptionContent(farmer.subscription),
            ),
            const SizedBox(height: 20),

          // Farms Section
            _buildSection(
              'Farms (${farmer.farms.length})',
              Icons.agriculture_rounded,
              AppColors.brandGreen,
              _buildFarmsContent(farmer.farms),
            ),
            const SizedBox(height: 20),

          // Crops Section
            _buildSection(
              'Crops (${farmer.crops.length})',
              Icons.eco_rounded,
              AppColors.success,
              _buildCropsContent(farmer.crops),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color iconColor, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildProfileContent(ProfileInfo profile) {
    return Column(
      children: [
        _buildInfoRow('Full Name', profile.fullName),
        _buildInfoRow('Username', profile.username),
        _buildInfoRow('Email', profile.email),
        _buildInfoRow('Phone', profile.phoneNumber),
        if (profile.alternatePhone != null && profile.alternatePhone!.isNotEmpty)
          _buildInfoRow('Alternate Phone', profile.alternatePhone!),
        if (profile.gender != null && profile.gender!.isNotEmpty)
          _buildInfoRow('Gender', profile.gender!),
        if (profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty)
          _buildInfoRow('Date of Birth', profile.dateOfBirth!),
        _buildInfoRow(
          'Address',
          '${profile.village ?? '-'}, ${profile.taluka ?? '-'}, ${profile.district ?? '-'}, ${profile.state ?? '-'}',
        ),
        if (profile.pincode != null && profile.pincode!.isNotEmpty)
          _buildInfoRow('Pincode', profile.pincode!),
        _buildInfoRow(
          'Profile Complete',
          profile.isProfileComplete ? 'Yes' : 'No',
          valueColor: profile.isProfileComplete ? AppColors.success : AppColors.warning,
        ),
        if (profile.createdAt != null)
        _buildInfoRow('Registered On', _formatDate(profile.createdAt)),
      ],
    );
  }

  Widget _buildKycContent(KycInfo? kyc) {
    if (kyc == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Text(
              'KYC not started',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildStatusChip('KYC Status', kyc.status, _getKycStatusColor(kyc.status)),
        const SizedBox(height: 16),
        
        // Aadhaar
        _buildVerificationCard(
          'Aadhaar Verification',
          kyc.aadhaarVerified,
          kyc.aadhaarVerified
              ? [
                  'Name: ${kyc.aadhaarName ?? '-'}',
                  'Number: ${kyc.aadhaarNumberMasked ?? '-'}',
                  'Verified: ${_formatDate(kyc.aadhaarVerifiedAt)}',
                ]
              : ['Not Verified'],
          ),
        const SizedBox(height: 12),

        // PAN
        _buildVerificationCard(
          'PAN Verification',
          kyc.panVerified,
          kyc.panVerified
              ? [
                  'Name: ${kyc.panName ?? '-'}',
                  'Number: ${kyc.panNumberMasked ?? '-'}',
                  'Verified: ${_formatDate(kyc.panVerifiedAt)}',
                ]
              : ['Not Verified'],
              ),
        const SizedBox(height: 12),

        // Bank
        _buildVerificationCard(
          'Bank Verification',
          kyc.bankVerified,
          kyc.bankVerified
              ? [
                  'Account Holder: ${kyc.bankAccountHolderName ?? '-'}',
                  'Account: ${kyc.bankAccountMasked ?? '-'}',
                  'IFSC: ${kyc.bankIfsc ?? '-'}',
                  'Bank: ${kyc.bankName ?? '-'}',
                  'Verified: ${_formatDate(kyc.bankVerifiedAt)}',
                ]
              : ['Not Verified'],
              ),
            ],
    );
  }

  Widget _buildVerificationCard(String title, bool verified, List<String> details) {
    return Container(
      padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
        gradient: verified
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.successBg,
                  AppColors.success.withOpacity(0.1),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.errorBg,
                  AppColors.error.withOpacity(0.1),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: verified
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
          width: 1,
        ),
          ),
          child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: verified
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success.withOpacity(0.3),
                        AppColors.success.withOpacity(0.1),
                  ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error.withOpacity(0.3),
                        AppColors.error.withOpacity(0.1),
                      ],
                    ),
              shape: BoxShape.circle,
          ),
            child: Icon(
              verified ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: verified ? AppColors.success : AppColors.error,
              size: 20,
            ),
              ),
          const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...details.map((detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        detail,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                ),
                    )),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildSubscriptionContent(SubscriptionInfo? subscription) {
    if (subscription == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Text(
              'No subscription',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    Color statusColor = subscription.status == 'ACTIVE'
        ? AppColors.success
        : subscription.status == 'EXPIRED'
            ? AppColors.error
            : AppColors.warning;

    return Column(
      children: [
        _buildStatusChip('Status', subscription.status, statusColor),
        const SizedBox(height: 16),
        if (subscription.startDate != null)
          _buildInfoRow('Start Date', _formatDate(subscription.startDate)),
        if (subscription.endDate != null)
          _buildInfoRow('End Date', _formatDate(subscription.endDate)),
        if (subscription.amount != null)
          _buildInfoRow('Amount', '₹${subscription.amount?.toStringAsFixed(2)}'),
        if (subscription.paymentStatus != null && subscription.paymentStatus!.isNotEmpty)
          _buildInfoRow('Payment Status', subscription.paymentStatus!),
        if (subscription.paymentTransactionId != null)
          _buildInfoRow('Transaction ID', subscription.paymentTransactionId!),
      ],
    );
  }

  Widget _buildFarmsContent(List<FarmInfo> farms) {
    if (farms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Text(
              'No farms registered',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: farms.map((farm) => _buildFarmCard(farm)).toList(),
    );
  }

  Widget _buildCropsContent(List<CropInfo> crops) {
    if (crops.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 12),
            Text(
              'No crops registered',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: crops.map((crop) => _buildCropCard(crop)).toList(),
    );
  }

  Widget _buildFarmCard(FarmInfo farm) {
    // Check if field officer is assigned to this farm:
    // 1. Check if there's an assignment for this specific farm or all farms
    // 2. Or if this farm has verifiedByOfficerId (field officer assigned/verified this farm)
    // 3. Or if the farm is verified (isVerified = true means a field officer was assigned and verified)
    final hasFieldOfficer = _isFarmAssigned(farm.farmId) ||
                            farm.verifiedByOfficerId != null ||
                            farm.isVerified;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: hasFieldOfficer
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.successBg,
                  AppColors.success.withOpacity(0.1),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.errorBg,
                  AppColors.error.withOpacity(0.1),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFieldOfficer
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  farm.farmName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildStatusChip(
                hasFieldOfficer ? 'Field Officer Assign' : 'Field Officer not assign',
                hasFieldOfficer ? 'Field Officer Assign' : 'Field Officer not assign',
                hasFieldOfficer ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Type', farm.farmType ?? '-'),
          _buildInfoRow('Area', '${farm.totalAreaAcres?.toStringAsFixed(2) ?? '-'} acres'),
          _buildInfoRow(
            'Location',
            '${farm.village ?? '-'}, ${farm.taluka ?? '-'}, ${farm.district ?? '-'}, ${farm.state ?? '-'}',
          ),
          if (farm.pincode != null && farm.pincode!.isNotEmpty)
            _buildInfoRow('Pincode', farm.pincode!),
          _buildInfoRow('Soil Type', farm.soilType ?? '-'),
          _buildInfoRow('Irrigation', farm.irrigationType ?? '-'),
          _buildInfoRow('Ownership', farm.landOwnership ?? '-'),
          if (farm.surveyNumber != null && farm.surveyNumber!.isNotEmpty)
            _buildInfoRow('Survey No', farm.surveyNumber!),
          if (farm.pattaNumber != null && farm.pattaNumber!.isNotEmpty)
            _buildInfoRow('Patta No', farm.pattaNumber!),
          if (farm.landRegistrationNumber != null && farm.landRegistrationNumber!.isNotEmpty)
            _buildInfoRow('Land Reg. No', farm.landRegistrationNumber!),
          if (farm.estimatedLandValue != null)
            _buildInfoRow('Estimated Value', '₹${farm.estimatedLandValue!.toStringAsFixed(2)}'),
          if (farm.encumbranceStatus != null && farm.encumbranceStatus!.isNotEmpty)
            _buildInfoRow('Encumbrance', farm.encumbranceStatus!),
          if (farm.encumbranceRemarks != null && farm.encumbranceRemarks!.isNotEmpty)
            _buildInfoRow('Encumbrance Remarks', farm.encumbranceRemarks!),
          if (hasFieldOfficer && farm.verifiedByOfficerName != null)
            _buildInfoRow('Field Officer', farm.verifiedByOfficerName!),
          if (hasFieldOfficer && farm.verifiedAt != null)
            _buildInfoRow('Verified On', _formatDate(farm.verifiedAt)),
        ],
      ),
    );
  }

  Widget _buildCropCard(CropInfo crop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
        ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  crop.cropDisplayName ?? crop.cropName ?? 'Crop',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildStatusChip(
                crop.cropStatus ?? 'UNKNOWN',
                (crop.cropStatus ?? 'UNKNOWN').toUpperCase(),
                _getCropStatusColor(crop.cropStatus),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Type', crop.cropTypeName ?? '-'),
          _buildInfoRow('Farm', crop.farmName ?? '-'),
          _buildInfoRow('Area', '${crop.areaAcres?.toStringAsFixed(2) ?? '-'} acres'),
          if (crop.sowingDate != null && crop.sowingDate!.isNotEmpty)
            _buildInfoRow('Sowing Date', crop.sowingDate!),
          if (crop.harvestingDate != null && crop.harvestingDate!.isNotEmpty)
            _buildInfoRow('Harvest Date', crop.harvestingDate!),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    // If value contains underscores, convert to readable format
    // Otherwise use the value as-is
    final displayText = value.contains('_')
        ? value.toLowerCase().replaceAll('_', ' ')
        : value;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getKycStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'VERIFIED':
        return AppColors.success;
      case 'PARTIAL':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getCropStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'GROWING':
      case 'SOWN':
        return AppColors.brandGreen;
      case 'HARVESTED':
        return AppColors.success;
      case 'FAILED':
        return AppColors.error;
      case 'PLANNED':
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }
}
