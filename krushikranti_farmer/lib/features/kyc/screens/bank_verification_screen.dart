import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../services/kyc_service.dart';

class BankVerificationScreen extends StatefulWidget {
  const BankVerificationScreen({super.key});

  @override
  State<BankVerificationScreen> createState() => _BankVerificationScreenState();
}

class _BankVerificationScreenState extends State<BankVerificationScreen> {
  final _accountController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAlreadyVerified();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _checkAlreadyVerified() async {
    try {
      final status = await KycService.getKycStatus();
      if (!mounted) return;

      if (status.bankVerified) {
        final l10n = AppLocalizations.of(context)!;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              l10n.bankAlreadyVerified,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              l10n.bankAlreadyVerifiedMessage,
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.ok,
                  style: GoogleFonts.poppins(color: AppColors.brandGreen),
                ),
              ),
            ],
          ),
        );
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (_) {
      // Ignore errors here; user can proceed with normal flow
    }
  }

  Future<void> _verifyBank() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await KycService.verifyBank(
        _accountController.text.trim(),
        _ifscController.text.trim().toUpperCase(),
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.verified) {
          _showSuccessDialog(
            response.accountHolderName ?? '',
            response.bankName ?? '',
          );
        } else {
          setState(() {
            _errorMessage = response.message ?? 'Bank verification failed';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _showSuccessDialog(String accountHolderName, String bankName) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.bankVerified,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (accountHolderName.isNotEmpty)
              Text(
                accountHolderName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            if (bankName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                bankName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.celebration, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.kycCompleteMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Pop back to profile or KYC status screen
                Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == '/kyc-status');
                Navigator.pop(context); // Pop one more to go back to profile
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.done,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.bankVerification,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header illustration
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance,
                    size: 60,
                    color: Colors.orange.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Center(
                child: Text(
                  l10n.verifyYourBank,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  l10n.bankVerificationDesc,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              
              // Step indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${l10n.step} 3 ${l10n.of3} - ${l10n.finalStep}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brandGreen,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Error Message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Account Number Input
              Text(
                l10n.accountNumber,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.number,
                maxLength: 18,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: l10n.enterAccountNumber,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  counterText: '',
                  prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.orange.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAccountNumber;
                  }
                  if (value.length < 9 || value.length > 18) {
                    return l10n.accountNumberLength;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Confirm Account Number
              Text(
                l10n.confirmAccountNumber,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmAccountController,
                keyboardType: TextInputType.number,
                maxLength: 18,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: l10n.reEnterAccountNumber,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  counterText: '',
                  prefixIcon: Icon(Icons.check_circle_outline, color: Colors.orange.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseConfirmAccountNumber;
                  }
                  if (value != _accountController.text) {
                    return l10n.accountNumbersDoNotMatch;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // IFSC Code
              Text(
                l10n.ifscCode,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ifscController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 11,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  _UpperCaseTextFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: l10n.enterIfscCode,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  counterText: '',
                  prefixIcon: Icon(Icons.pin, color: Colors.orange.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterIfsc;
                  }
                  // IFSC format: XXXX0XXXXXX
                  final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
                  if (!ifscRegex.hasMatch(value.toUpperCase())) {
                    return l10n.invalidIfscFormat;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              
              // IFSC Format hint
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.ifscFormatHint,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyBank,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          l10n.verifyBank,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Text formatter to convert to uppercase
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

