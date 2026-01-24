import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/http_service.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() => _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailFormatError;
  String? _authError;
  bool _emailSent = false;

  String? _validateEmailFormat(String email) {
    final trimmedEmail = email.trim();
    
    if (trimmedEmail.isEmpty) {
      return "Email is required";
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      return "Please enter a valid email address";
    }
    
    return null;
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
        child: _emailSent ? _buildSuccessView(l10n) : _buildFormView(l10n),
      ),
    );
  }

  Widget _buildFormView(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          "Reset Password",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Enter your email address and we'll send you a link to reset your password.",
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // Email Input Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(
              color: _emailFormatError == null
                  ? Colors.grey.shade300
                  : Colors.red.shade300,
              width: _emailFormatError != null ? 1.5 : 1,
            ),
            boxShadow: _emailFormatError != null
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "your.email@example.com",
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: _emailFormatError == null
                    ? AppColors.brandGreen
                    : Colors.red.shade300,
              ),
            ),
            onChanged: (_) {
              setState(() {
                _emailFormatError = null;
                _authError = null;
              });
            },
          ),
        ),

        // Email format error
        if (_emailFormatError != null) ...[
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
                    _emailFormatError!,
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

        // Send Reset Link Button
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
                : const Icon(Icons.email_outlined, color: Colors.white, size: 20),
            label: Text(
              "Send Reset Link",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            onPressed: _isLoading ? null : () async {
              final email = _emailController.text.trim();

              setState(() {
                _emailFormatError = null;
                _authError = null;
              });

              // Validate email format
              final emailError = _validateEmailFormat(email);
              if (emailError != null) {
                setState(() {
                  _emailFormatError = emailError;
                });
                return;
              }

              setState(() {
                _isLoading = true;
              });

              try {
                await HttpService.post(
                  "${ApiEndpoints.baseUrl}/auth/forgot-password/request",
                  {"email": email},
                );

                if (!mounted) return;

                setState(() {
                  _emailSent = true;
                  _isLoading = false;
                });
              } catch (e) {
                if (!mounted) return;
                
                setState(() {
                  _isLoading = false;
                });

                final errorString = e.toString();
                final lowerError = errorString.toLowerCase();
                
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
                }
                
                if (isRealNetworkError) {
                  setState(() {
                    _authError = "Network error. Please check your connection and try again.";
                  });
                } else {
                  // Extract error message from exception
                  // The HttpService throws Exception with the message from API response
                  String errorMessage = "Failed to send reset email. Please try again.";
                  
                  // Extract message after "Exception: " if present
                  if (errorString.contains("Exception: ")) {
                    final match = RegExp(r'Exception: (.+)').firstMatch(errorString);
                    if (match != null && match.group(1) != null) {
                      errorMessage = match.group(1)!;
                    }
                  } else {
                    // If no "Exception: " prefix, use the whole error string
                    errorMessage = errorString;
                  }
                  
                  setState(() {
                    _authError = errorMessage;
                  });
                }
              }
            },
          ),
        ),

        // Authentication Error
        if (_authError != null) ...[
          const SizedBox(height: 16),
          _authErrorText(_authError!),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSuccessView(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppColors.brandGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Check Your Email",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "We've sent a password reset link to ${_emailController.text.trim()}",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
              child: Text(
                "Back to Login",
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
    );
  }

  Widget _authErrorText(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.red.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
