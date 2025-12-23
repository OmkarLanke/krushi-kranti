import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../models/farmer_models.dart';
import '../services/farmer_service.dart';

class FarmerDetailDialog extends StatefulWidget {
  final int farmerId;

  const FarmerDetailDialog({super.key, required this.farmerId});

  @override
  State<FarmerDetailDialog> createState() => _FarmerDetailDialogState();
}

class _FarmerDetailDialogState extends State<FarmerDetailDialog> {
  FarmerDetail? _farmer;
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
      setState(() {
        _farmer = farmer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Farmer Details',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.poppins(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFarmerDetail,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final farmer = _farmer!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          _buildSection('Profile Information', Icons.person, _buildProfileContent(farmer.profile)),
          const SizedBox(height: 24),

          // KYC Section
          _buildSection('KYC Verification', Icons.verified_user, _buildKycContent(farmer.kyc)),
          const SizedBox(height: 24),

          // Subscription Section
          _buildSection('Subscription', Icons.card_membership, _buildSubscriptionContent(farmer.subscription)),
          const SizedBox(height: 24),

          // Farms Section
          _buildSection('Farms (${farmer.farms.length})', Icons.landscape, _buildFarmsContent(farmer.farms)),
          const SizedBox(height: 24),

          // Crops Section
          _buildSection('Crops (${farmer.crops.length})', Icons.agriculture, _buildCropsContent(farmer.crops)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.brandGreen, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(),
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
        _buildInfoRow('Alternate Phone', profile.alternatePhone ?? '-'),
        _buildInfoRow('Gender', profile.gender ?? '-'),
        _buildInfoRow('Date of Birth', profile.dateOfBirth ?? '-'),
        _buildInfoRow('Address', '${profile.village ?? '-'}, ${profile.taluka ?? '-'}, ${profile.district ?? '-'}, ${profile.state ?? '-'}'),
        _buildInfoRow('Pincode', profile.pincode ?? '-'),
        _buildInfoRow('Profile Complete', profile.isProfileComplete ? 'Yes' : 'No'),
        _buildInfoRow('Registered On', _formatDate(profile.createdAt)),
      ],
    );
  }

  Widget _buildKycContent(KycInfo? kyc) {
    if (kyc == null) {
      return const Text('KYC not started');
    }

    return Column(
      children: [
        _buildInfoRow('KYC Status', kyc.status),
        const SizedBox(height: 8),
        
        // Aadhaar
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: kyc.aadhaarVerified ? AppColors.successBg : AppColors.warningBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                kyc.aadhaarVerified ? Icons.check_circle : Icons.pending,
                color: kyc.aadhaarVerified ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aadhaar Verification', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    if (kyc.aadhaarVerified) ...[
                      Text('Name: ${kyc.aadhaarName ?? '-'}'),
                      Text('Number: ${kyc.aadhaarNumberMasked ?? '-'}'),
                      Text('Verified: ${_formatDate(kyc.aadhaarVerifiedAt)}'),
                    ] else
                      const Text('Not Verified'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // PAN
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: kyc.panVerified ? AppColors.successBg : AppColors.warningBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                kyc.panVerified ? Icons.check_circle : Icons.pending,
                color: kyc.panVerified ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAN Verification', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    if (kyc.panVerified) ...[
                      Text('Name: ${kyc.panName ?? '-'}'),
                      Text('Number: ${kyc.panNumberMasked ?? '-'}'),
                      Text('Verified: ${_formatDate(kyc.panVerifiedAt)}'),
                    ] else
                      const Text('Not Verified'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bank
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kyc.bankVerified ? AppColors.successBg : AppColors.warningBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                kyc.bankVerified ? Icons.check_circle : Icons.pending,
                color: kyc.bankVerified ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bank Verification', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    if (kyc.bankVerified) ...[
                      Text('Account Holder: ${kyc.bankAccountHolderName ?? '-'}'),
                      Text('Account: ${kyc.bankAccountMasked ?? '-'}'),
                      Text('IFSC: ${kyc.bankIfsc ?? '-'}'),
                      Text('Bank: ${kyc.bankName ?? '-'}'),
                      Text('Verified: ${_formatDate(kyc.bankVerifiedAt)}'),
                    ] else
                      const Text('Not Verified'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionContent(SubscriptionInfo? subscription) {
    if (subscription == null) {
      return const Text('No subscription');
    }

    Color statusColor = subscription.status == 'ACTIVE' ? AppColors.success : AppColors.warning;

    return Column(
      children: [
        _buildInfoRow('Status', subscription.status, valueColor: statusColor),
        if (subscription.startDate != null)
          _buildInfoRow('Start Date', _formatDate(subscription.startDate)),
        if (subscription.endDate != null)
          _buildInfoRow('End Date', _formatDate(subscription.endDate)),
        if (subscription.amount != null)
          _buildInfoRow('Amount', '₹${subscription.amount?.toStringAsFixed(2)}'),
        _buildInfoRow('Payment Status', subscription.paymentStatus ?? '-'),
        if (subscription.paymentTransactionId != null)
          _buildInfoRow('Transaction ID', subscription.paymentTransactionId!),
      ],
    );
  }

  Widget _buildFarmsContent(List<FarmInfo> farms) {
    if (farms.isEmpty) {
      return const Text('No farms registered');
    }

    return Column(
      children: farms.map((farm) => _buildFarmCard(farm)).toList(),
    );
  }

  Widget _buildCropsContent(List<CropInfo> crops) {
    if (crops.isEmpty) {
      return const Text('No crops registered');
    }

    return Column(
      children: crops.map((crop) => _buildCropRow(crop)).toList(),
    );
  }

  Widget _buildCropRow(CropInfo crop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                crop.cropDisplayName ?? crop.cropName ?? 'Crop',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCropStatusColor(crop.cropStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (crop.cropStatus ?? 'UNKNOWN').toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _getCropStatusColor(crop.cropStatus),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Type: ${crop.cropTypeName ?? '-'}',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          Text(
            'Farm: ${crop.farmName ?? '-'}',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          Text(
            'Area: ${crop.areaAcres?.toStringAsFixed(2) ?? '-'} acres',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          Text(
            'Sowing: ${crop.sowingDate ?? '-'}   |   Harvest: ${crop.harvestingDate ?? '-'}',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ],
      ),
    );
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

  Widget _buildFarmCard(FarmInfo farm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: farm.isVerified ? AppColors.successBg : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: farm.isVerified ? AppColors.success.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                farm.farmName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: farm.isVerified ? AppColors.success : AppColors.warning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  farm.isVerified ? 'Verified' : 'Pending',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Type: ${farm.farmType ?? '-'}'),
          Text('Area: ${farm.totalAreaAcres?.toStringAsFixed(2) ?? '-'} acres'),
          Text(
            'Location: ${farm.village ?? '-'}, ${farm.taluka ?? '-'}, ${farm.district ?? '-'}, ${farm.state ?? '-'} (${farm.pincode ?? '-'})',
          ),
          Text('Soil: ${farm.soilType ?? '-'}  |  Irrigation: ${farm.irrigationType ?? '-'}'),
          Text('Ownership: ${farm.landOwnership ?? '-'}'),
          const SizedBox(height: 4),
          Text('Survey No: ${farm.surveyNumber ?? '-'}'),
          Text('Patta No: ${farm.pattaNumber ?? '-'}'),
          Text('Land Reg. No: ${farm.landRegistrationNumber ?? '-'}'),
          if (farm.estimatedLandValue != null)
            Text('Estimated Value: ₹${farm.estimatedLandValue!.toStringAsFixed(2)}'),
          Text('Encumbrance: ${farm.encumbranceStatus ?? '-'}'),
          if (farm.encumbranceRemarks != null && farm.encumbranceRemarks!.isNotEmpty)
            Text('Encumbrance Remarks: ${farm.encumbranceRemarks!}'),
          if (farm.isVerified && farm.verifiedAt != null)
            Text('Verified on: ${_formatDate(farm.verifiedAt)}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 13,
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }
}

