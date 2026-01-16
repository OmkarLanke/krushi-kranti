import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/http_service.dart';
import '../../../core/services/storage_service.dart';

class ForgotPasswordPhoneScreen extends StatefulWidget {
  const ForgotPasswordPhoneScreen({super.key});

  @override
  State<ForgotPasswordPhoneScreen> createState() => _ForgotPasswordPhoneScreenState();
}

class _ForgotPasswordPhoneScreenState extends State<ForgotPasswordPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _phoneFormatError; // Format validation errors (shown on phone field)
  String? _authError; // Authentication error (shown at bottom)

  bool _validatePhoneNumber(String phone) {
    final regex = RegExp(r"^[0-9]{10}$");
    return regex.hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.passwordRecovery,
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              l10n.verifyNumber,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.verifyNumberSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Phone Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                border: Border.all(
                  color: _phoneFormatError == null
                      ? Colors.grey.shade300
                      : Colors.red.shade300,
                  width: _phoneFormatError != null ? 1.5 : 1,
                ),
                boxShadow: _phoneFormatError != null
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "+91",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.brandGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: "",
                        hintText: l10n.phoneHint,
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {
                          // Clear errors when user types
                          _phoneFormatError = null;
                          _authError = null;
                        });
                      },
                    ),
                  )
                ],
              ),
            ),

            // Phone format error (shown below phone field)
            if (_phoneFormatError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.error_outline_rounded, size: 16, color: Colors.red.shade700),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _phoneFormatError!,
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                label: Text(
                  l10n.nextBtn,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                onPressed: _isLoading ? null : () async {   
                  final phone = _phoneController.text.trim();

                  // Clear previous errors
                  setState(() {
                    _phoneFormatError = null;
                    _authError = null;
                  });

                  // Validate phone format
                  if (!_validatePhoneNumber(phone)) {
                    setState(() {
                      _phoneFormatError = l10n.phoneFormatError;
                    });
                    return;
                  }

                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // Save phone number for OTP screen
                    await StorageService.saveAuthDetails(
                      email: "",
                      phone: phone,
                    );

                    // Request OTP for password recovery
                    await HttpService.post(
                      "auth/request-login-otp",
                      {"phoneNumber": phone},
                    );

                    if (!mounted) return;

                    // Navigate to OTP screen
                    Navigator.pushNamed(context, AppRoutes.forgotPasswordOtp);
                  } catch (e) {
                    if (!mounted) return;
                    
                    setState(() {
                      _isLoading = false;
                    });

                    // ✅ Industry-standard error handling
                    final errorString = e.toString();
                    final lowerError = errorString.toLowerCase();
                    
                    // Check if it's a REAL network error
                    bool isRealNetworkError = false;
                    
                    if (e is SocketException) {
                      isRealNetworkError = true;
                    } else if (errorString.contains('Network Error:') || 
                               errorString.contains('Network error:')) {
                      if (lowerError.contains('socketexception') ||
                          lowerError.contains('timeoutexception') ||
                          lowerError.contains('timeout') ||
                          lowerError.contains('connection refused') ||
                          lowerError.contains('failed host lookup') ||
                          lowerError.contains('connection timed out') ||
                          lowerError.contains('network is unreachable')) {
                        isRealNetworkError = true;
                      }
                    } else if (lowerError.contains('timeout') && 
                               (lowerError.contains('connection') || 
                                lowerError.contains('socket'))) {
                      isRealNetworkError = true;
                    }
                    
                    if (isRealNetworkError) {
                      setState(() {
                        _authError = l10n.networkError;
                      });
                    } else {
                      // ✅ For ALL authentication failures (phone not found, etc.):
                      // Show generic "Incorrect phone number. Please try again." message
                      setState(() {
                        _authError = l10n.incorrectPhoneError;
                      });
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
              ),
            ),

            // ✅ Authentication Error (shown at bottom)
            if (_authError != null) ...[
              const SizedBox(height: 16),
              _authErrorText(_authError!),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ Authentication error text (shown at bottom)
  Widget _authErrorText(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}