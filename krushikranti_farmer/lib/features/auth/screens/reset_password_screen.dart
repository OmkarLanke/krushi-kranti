import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/http_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token; // Token from email link
  
  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                l10n.resetPassword,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Create a new secure password",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 32),

            _buildPasswordField(l10n.newPassword, _passController, _passwordVisible, () {
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            }),
            const SizedBox(height: 16),
            _buildPasswordField(l10n.confirmPassword, _confirmController, _confirmPasswordVisible, () {
              setState(() {
                _confirmPasswordVisible = !_confirmPasswordVisible;
              });
            }),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
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
                        _error!,
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
                    : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                label: Text(
                  _isLoading ? "Resetting..." : l10n.submitBtn,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                onPressed: _isLoading ? null : () async {
                  final password = _passController.text.trim();
                  final confirmPassword = _confirmController.text.trim();

                  // Validation
                  if (password.isEmpty || confirmPassword.isEmpty) {
                    setState(() {
                      _error = "Please fill in all fields";
                    });
                    return;
                  }

                  if (password.length < 8) {
                    setState(() {
                      _error = "Password must be at least 8 characters long";
                    });
                    return;
                  }

                  if (password != confirmPassword) {
                    setState(() {
                      _error = l10n.passwordsDoNotMatch;
                    });
                    return;
                  }

                  if (widget.token == null || widget.token!.isEmpty) {
                    setState(() {
                      _error = "Invalid reset link. Please request a new one.";
                    });
                    return;
                  }

                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });

                  try {
                    await HttpService.post(
                      ApiEndpoints.forgotPasswordReset,
                      {
                        "token": widget.token,
                        "newPassword": password,
                      },
                    );

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.passwordResetSuccess),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.emailLogin,
                      (route) => false,
                    );
                  } catch (e) {
                    if (!mounted) return;

                    setState(() {
                      _isLoading = false;
                    });

                    final errorString = e.toString();
                    String errorMessage = "Failed to reset password. Please try again.";

                    if (errorString.contains("Invalid or expired token") ||
                        errorString.contains("expired")) {
                      errorMessage = "This reset link has expired. Please request a new one.";
                    } else if (errorString.contains("Invalid") || 
                               errorString.contains("invalid")) {
                      errorMessage = "Invalid reset link. Please request a new one.";
                    } else if (e is SocketException) {
                      errorMessage = "Network error. Please check your connection and try again.";
                    }

                    setState(() {
                      _error = errorMessage;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hint, TextEditingController controller, bool isVisible, VoidCallback onToggleVisibility) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.brandGreen),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: !isVisible,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                  onChanged: (_) {
                    if (_error != null) {
                      setState(() {
                        _error = null;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: onToggleVisibility,
              ),
            ],
          ),
        ),
      ],
    );
  }
}