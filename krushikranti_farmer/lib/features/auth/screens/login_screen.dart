import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';
import '../../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;

  String? phoneFormatError; // Format validation errors (shown on phone field)
  String? authError; // Authentication error (shown at bottom)

  @override
  void initState() {
    super.initState();
  }

  bool validatePhoneNumber(String phone) {
    final regex = RegExp(r"^[0-9]{10}$");
    return regex.hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.languageSelection,
              (route) => false,
            );
          },
        ),
        title: Text(
          l10n.loginWithPhone,
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER IMAGE & TAGLINE ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        "assets/images/auth/farmer_logo.jpg",
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.brandGreen.withOpacity(0.2),
                                  AppColors.brandGreen.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Icon(Icons.image_rounded, size: 60, color: AppColors.brandGreen),
                          ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.reconnectWithGoodness,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.brandGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // --- SCROLLABLE FORM ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.letsGetYouStarted,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- PHONE INPUT ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: phoneFormatError == null
                                ? Colors.grey.shade300
                                : Colors.red.shade300,
                            width: phoneFormatError != null ? 1.5 : 1,
                          ),
                          boxShadow: phoneFormatError != null
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
                                controller: phoneController,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                style: GoogleFonts.poppins(fontSize: 14),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  counterText: "",
                                  hintText: l10n.phoneHintYourNumber,
                                  border: InputBorder.none,
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    // Clear errors when user types
                                    phoneFormatError = null;
                                    authError = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (phoneFormatError != null) ...[
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
                                  phoneFormatError!,
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

                      const SizedBox(height: 12),

                      Text(
                        l10n.otpSentToThisNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- GET OTP BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          label: Text(
                            l10n.getOtp,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          onPressed: _isLoading ? null : () async {
                            final phone = phoneController.text.trim();

                            // Clear previous errors
                            setState(() {
                              phoneFormatError = null;
                              authError = null;
                            });

                            // Validate phone format
                            if (!validatePhoneNumber(phone)) {
                              setState(() {
                                phoneFormatError = l10n.phoneFormatError;
                              });
                              return;
                            }

                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              // 1. Save language preference
                              await StorageService.saveLanguage(langCode);

                              // 2. Save phone number for OTP screen
                              await StorageService.saveAuthDetails(
                                email: "",
                                phone: phone,
                              );

                              // 3. Request OTP from backend
                              await HttpService.post(
                                "auth/request-login-otp",
                                {"phoneNumber": phone},
                              );

                              if (!mounted) return;

                              // 4. Navigate to OTP screen (pass true for login flow)
                              Navigator.pushNamed(context, AppRoutes.otp, arguments: true);
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
                                  authError = l10n.networkError;
                                });
                              } else {
                                // ✅ For ALL authentication failures (phone not found, etc.):
                                // Show generic "Incorrect phone number. Please try again" message
                                setState(() {
                                  authError = l10n.incorrectPhoneError;
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
                      if (authError != null) ...[
                        const SizedBox(height: 16),
                        _authErrorText(authError!),
                      ],

                      const SizedBox(height: 15),

                      // --- EMAIL LOGIN LINK ---
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.emailLogin);
                          },
                          child: Text(
                            l10n.emailLoginLink,
                            style: GoogleFonts.poppins(
                              color: AppColors.brandGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        l10n.termsAgreementLogin,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.orSeparator,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.signup);
                              },
                              child: Text(
                                l10n.signUpCta,
                                style: GoogleFonts.poppins(
                                  color: AppColors.brandGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
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