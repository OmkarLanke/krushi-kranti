import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.passwordRecovery, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              l10n.verifyNumber,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.verifyNumberSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Phone Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
                border: Border.all(
                  color: _phoneFormatError == null
                      ? Colors.transparent
                      : Colors.red,
                  width: _phoneFormatError != null ? 1.5 : 0,
                ),
              ),
              child: Row(
                children: [
                   const Text("+91", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(width: 10),
                   Container(width: 1, height: 24, color: Colors.grey), // Divider
                   const SizedBox(width: 10),
                   Expanded(
                     child: TextField(
                       controller: _phoneController,
                       keyboardType: TextInputType.number,
                       maxLength: 10,
                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                       decoration: InputDecoration(
                         border: InputBorder.none,
                         counterText: "",
                         hintText: l10n.phoneHint,
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
            if (_phoneFormatError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  _phoneFormatError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const Spacer(),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        l10n.nextBtn,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
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