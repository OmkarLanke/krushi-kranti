import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/kyc_models.dart';
import '../services/kyc_service.dart';
import 'aadhaar_verification_screen.dart';
import 'pan_verification_screen.dart';
import 'bank_verification_screen.dart';

class KycStatusScreen extends StatefulWidget {
  const KycStatusScreen({super.key});

  @override
  State<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends State<KycStatusScreen> {
  bool _isLoading = true;
  KycStatusResponse? _kycStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadKycStatus();
  }

  Future<void> _loadKycStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await KycService.getKycStatus();
      if (mounted) {
        setState(() {
          _kycStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          // Create empty status if API fails
          _kycStatus = KycStatusResponse();
        });
      }
    }
  }

  Future<void> _testVerifyAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await KycService.testVerifyAll();
      if (mounted) {
        setState(() {
          _kycStatus = status;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All KYC verifications completed (TEST MODE)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToNextStep() {
    if (_kycStatus == null) return;

    Widget nextScreen;
    
    if (!_kycStatus!.aadhaarVerified) {
      nextScreen = const AadhaarVerificationScreen();
    } else if (!_kycStatus!.panVerified) {
      nextScreen = const PanVerificationScreen();
    } else if (!_kycStatus!.bankVerified) {
      nextScreen = const BankVerificationScreen();
    } else {
      // All verified - show success
      _showCompletionDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    ).then((_) => _loadKycStatus());
  }

  void _showCompletionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Text(l10n.kycComplete, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          l10n.kycCompleteMessage,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok, style: GoogleFonts.poppins(color: AppColors.brandGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.kycVerification,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandGreen))
          : RefreshIndicator(
              onRefresh: _loadKycStatus,
              color: AppColors.brandGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Card
                    _buildProgressCard(l10n),
                    
                    const SizedBox(height: 24),
                    
                    // Steps
                    Text(
                      l10n.verificationSteps,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Step 1: Aadhaar
                    _buildStepCard(
                      icon: Icons.fingerprint,
                      title: l10n.aadhaarVerification,
                      subtitle: _kycStatus?.aadhaarVerified == true
                          ? '${l10n.verified}: ${_kycStatus?.aadhaarName ?? ""}'
                          : l10n.verifyAadhaarDesc,
                      isVerified: _kycStatus?.aadhaarVerified ?? false,
                      // Once verified, Aadhaar step should not be opened again
                      isEnabled: !(_kycStatus?.aadhaarVerified ?? false),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AadhaarVerificationScreen()),
                      ).then((_) => _loadKycStatus()),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Step 2: PAN
                    _buildStepCard(
                      icon: Icons.credit_card,
                      title: l10n.panVerification,
                      subtitle: _kycStatus?.panVerified == true
                          ? '${l10n.verified}: ${_kycStatus?.panName ?? ""}'
                          : l10n.verifyPanDesc,
                      isVerified: _kycStatus?.panVerified ?? false,
                      // PAN enabled only after Aadhaar is verified and until PAN is verified
                      isEnabled: (_kycStatus?.aadhaarVerified ?? false) &&
                          !(_kycStatus?.panVerified ?? false),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PanVerificationScreen()),
                      ).then((_) => _loadKycStatus()),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Step 3: Bank
                    _buildStepCard(
                      icon: Icons.account_balance,
                      title: l10n.bankVerification,
                      subtitle: _kycStatus?.bankVerified == true
                          ? '${l10n.verified}: ${_kycStatus?.bankName ?? ""}'
                          : l10n.verifyBankDesc,
                      isVerified: _kycStatus?.bankVerified ?? false,
                      // Bank enabled only after PAN is verified and until Bank is verified
                      isEnabled: (_kycStatus?.panVerified ?? false) &&
                          !(_kycStatus?.bankVerified ?? false),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BankVerificationScreen()),
                      ).then((_) => _loadKycStatus()),
                    ),
                    
                    const SizedBox(height: 32),

                    // KYC Details Section (read-only, fetched from backend)
                    _buildDetailsSection(l10n),
                    
                    // Test Button (for testing purposes)
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _testVerifyAll,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.orange.shade400, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bug_report, color: Colors.orange.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Test: Verify All KYC',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    // Continue Button
                    if (!(_kycStatus?.isComplete ?? false)) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _navigateToNextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _kycStatus?.completedSteps == 0 
                                ? l10n.startVerification 
                                : l10n.continueVerification,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailsSection(AppLocalizations l10n) {
    final status = _kycStatus;
    if (status == null) return const SizedBox.shrink();

    final hasAnyDetails = (status.aadhaarVerified ?? false) ||
        (status.panVerified ?? false) ||
        (status.bankVerified ?? false);

    if (!hasAnyDetails) return const SizedBox.shrink();

    String _formatDate(DateTime? dt) {
      if (dt == null) return '';
      // Simple formatted date; you can replace with intl if needed
      return '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourKycDetails,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // Aadhaar details
        if (status.aadhaarVerified ?? false)
          _buildDetailCard(
            icon: Icons.fingerprint,
            title: l10n.aadhaarDetails,
            lines: [
              if ((status.aadhaarName ?? '').isNotEmpty)
                '${l10n.nameLabel}: ${status.aadhaarName}',
              if ((status.aadhaarNumberMasked ?? '').isNotEmpty)
                '${l10n.aadhaarMasked}: ${status.aadhaarNumberMasked}',
              if (status.aadhaarVerifiedAt != null)
                '${l10n.verifiedOn}: ${_formatDate(status.aadhaarVerifiedAt)}',
            ],
          ),

        if (status.aadhaarVerified ?? false) const SizedBox(height: 8),

        // PAN details
        if (status.panVerified ?? false)
          _buildDetailCard(
            icon: Icons.credit_card,
            title: l10n.panDetails,
            lines: [
              if ((status.panName ?? '').isNotEmpty)
                '${l10n.nameLabel}: ${status.panName}',
              if ((status.panNumberMasked ?? '').isNotEmpty)
                '${l10n.panMasked}: ${status.panNumberMasked}',
              if (status.panVerifiedAt != null)
                '${l10n.verifiedOn}: ${_formatDate(status.panVerifiedAt)}',
            ],
          ),

        if (status.panVerified ?? false) const SizedBox(height: 8),

        // Bank details
        if (status.bankVerified ?? false)
          _buildDetailCard(
            icon: Icons.account_balance,
            title: l10n.bankDetails,
            lines: [
              if ((status.bankAccountHolderName ?? '').isNotEmpty)
                '${l10n.accountHolder}: ${status.bankAccountHolderName}',
              if ((status.bankAccountMasked ?? '').isNotEmpty)
                '${l10n.accountMasked}: ${status.bankAccountMasked}',
              if ((status.bankIfsc ?? '').isNotEmpty)
                '${l10n.ifscCode}: ${status.bankIfsc}',
              if ((status.bankName ?? '').isNotEmpty)
                '${l10n.bankNameLabel}: ${status.bankName}',
              if (status.bankVerifiedAt != null)
                '${l10n.verifiedOn}: ${_formatDate(status.bankVerifiedAt)}',
            ],
          ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required List<String> lines,
  }) {
    final filtered = lines.where((e) => e.trim().isNotEmpty).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brandGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                ...filtered.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      line,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(AppLocalizations l10n) {
    final completedSteps = _kycStatus?.completedSteps ?? 0;
    final progress = completedSteps / 3;
    final isComplete = _kycStatus?.isComplete ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete 
              ? [Colors.green.shade400, Colors.green.shade600]
              : [AppColors.brandGreen, AppColors.brandGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isComplete ? Colors.green : AppColors.brandGreen).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isComplete ? l10n.kycComplete : l10n.kycInProgress,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedSteps ${l10n.of3StepsCompleted}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isComplete
                      ? const Icon(Icons.check, color: Colors.white, size: 32)
                      : Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isVerified,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isVerified 
                  ? Colors.green.shade200 
                  : (isEnabled ? Colors.grey.shade200 : Colors.grey.shade100),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isVerified 
                      ? Colors.green.shade50 
                      : (isEnabled ? AppColors.brandGreen.withOpacity(0.1) : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isVerified 
                      ? Colors.green 
                      : (isEnabled ? AppColors.brandGreen : Colors.grey),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isVerified ? Colors.green : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status Icon
              if (isVerified)
                const Icon(Icons.check_circle, color: Colors.green, size: 24)
              else if (isEnabled)
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
              else
                Icon(Icons.lock, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

