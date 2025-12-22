import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../services/kyc_service.dart';
import 'pan_verification_screen.dart';

class AadhaarVerificationScreen extends StatefulWidget {
  const AadhaarVerificationScreen({super.key});

  @override
  State<AadhaarVerificationScreen> createState() => _AadhaarVerificationScreenState();
}

class _AadhaarVerificationScreenState extends State<AadhaarVerificationScreen> {
  final _aadhaarController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String? _requestId;
  String? _errorMessage;
  String? _successMessage;
  
  // Timer for resend OTP
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkAlreadyVerified();
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAlreadyVerified() async {
    try {
      final status = await KycService.getKycStatus();
      if (!mounted) return;

      if (status.aadhaarVerified) {
        final l10n = AppLocalizations.of(context)!;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              l10n.aadhaarAlreadyVerified,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              l10n.aadhaarAlreadyVerifiedMessage,
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

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _generateOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await KycService.generateAadhaarOtp(_aadhaarController.text.trim());
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.otpSent) {
            _otpSent = true;
            _requestId = response.requestId;
            _successMessage = response.message;
            _startResendTimer();
          } else {
            _errorMessage = response.message ?? 'Failed to send OTP';
          }
        });
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

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await KycService.verifyAadhaarOtp(
        _requestId!,
        _otpController.text.trim(),
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.verified) {
          _showSuccessDialog(response.name ?? '');
        } else {
          setState(() {
            _errorMessage = response.message ?? 'Verification failed';
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

  void _showSuccessDialog(String name) {
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
              l10n.aadhaarVerified,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (name.isNotEmpty)
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to PAN verification
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PanVerificationScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.continueToPan,
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
          l10n.aadhaarVerification,
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
                    color: AppColors.brandGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 60,
                    color: AppColors.brandGreen,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Center(
                child: Text(
                  l10n.verifyYourAadhaar,
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
                  l10n.aadhaarOtpDescription,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              
              // Error/Success Message
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
              
              if (_successMessage != null && !_otpSent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Aadhaar Input
              Text(
                l10n.aadhaarNumber,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aadhaarController,
                enabled: !_otpSent,
                keyboardType: TextInputType.number,
                maxLength: 12,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: l10n.enterAadhaarNumber,
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  counterText: '',
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.brandGreen),
                  filled: true,
                  fillColor: _otpSent ? Colors.grey.shade100 : Colors.grey.shade50,
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
                    borderSide: const BorderSide(color: AppColors.brandGreen, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterAadhaar;
                  }
                  if (value.length != 12) {
                    return l10n.aadhaarMustBe12Digits;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // OTP Section (shown after OTP sent)
              if (_otpSent) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sms, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.otpSentToMobile,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  l10n.enterOtp,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: l10n.enter6DigitOtp,
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.brandGreen),
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
                      borderSide: const BorderSide(color: AppColors.brandGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.didntReceiveOtp,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (_resendSeconds > 0)
                      Text(
                        '${l10n.resendIn} ${_resendSeconds}s',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _generateOtp,
                        child: Text(
                          l10n.resendOtp,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _generateOtp),
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
                          _otpSent ? l10n.verifyOtp : l10n.sendOtp,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              if (_otpSent) ...[
                const SizedBox(height: 16),
                // Change Aadhaar button
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _otpSent = false;
                        _requestId = null;
                        _otpController.clear();
                        _errorMessage = null;
                        _successMessage = null;
                      });
                    },
                    child: Text(
                      l10n.changeAadhaarNumber,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        decoration: TextDecoration.underline,
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
}

