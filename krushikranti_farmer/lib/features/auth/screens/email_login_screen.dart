import 'package:flutter/material.dart';
// ✅ 1. Import Localization
import '../../../l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';
import '../../subscription/services/subscription_service.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    // ✅ Access localization for logic (SnackBar)
    final l10n = AppLocalizations.of(context)!;

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        // ✅ Replaced hardcoded error with "Please fill all fields" key
        SnackBar(content: Text(l10n.fillAllFields)), 
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call /auth/login endpoint with email/password
      final response = await HttpService.post(
        "auth/login",
        {
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        },
      );

      // Extract token and user info from response
      final String accessToken = response['accessToken'] ?? '';
      final userInfo = response['user'] ?? {};

      if (accessToken.isEmpty) {
        throw Exception("Login failed. Please try again.");
      }

      // Save token and user details
      await StorageService.saveToken(accessToken);
      await StorageService.saveAuthDetails(
        email: userInfo['email'] ?? _emailController.text.trim(),
        phone: userInfo['phoneNumber'] ?? "",
      );

      // Save user role and ID
      final userRole = userInfo['role'] ?? 'FARMER';
      final userId = userInfo['id']?.toString() ?? '';
      await StorageService.saveRole(userRole);
      if (userId.isNotEmpty) {
        await StorageService.saveUserId(userId);
      }

      // Check subscription status
      bool isSubscribed = false;
      try {
        final subStatus = await SubscriptionService.getSubscriptionStatus();
        // Check multiple possible fields to determine subscription status
        isSubscribed = subStatus['isSubscribed'] == true || 
                      subStatus['subscriptionStatus'] == 'ACTIVE' ||
                      subStatus['subscriptionStatus'] == 'active';
        
        if (isSubscribed) {
          final endDate = subStatus['subscriptionEndDate']?.toString() ?? 
                         subStatus['expiresAt']?.toString();
          await StorageService.saveSubscriptionStatus(
            true,
            endDate: endDate,
          );
        } else {
          await StorageService.saveSubscriptionStatus(false);
        }
      } catch (_) {
        // If we can't determine, treat as not subscribed to show welcome
        await StorageService.saveSubscriptionStatus(false);
      }

      if (!mounted) return;

      // Navigate based on user role
      if (userRole == 'FIELD_OFFICER') {
        // Field Officer -> Navigate to Field Officer Dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.fieldOfficerDashboard,
          (route) => false,
        );
      } else if (userRole == 'ADMIN') {
        // Admin -> Navigate to Admin Dashboard (if implemented in this app)
        // For now, redirect to farmer dashboard or show error
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (route) => false,
        );
      } else {
        // Farmer -> Navigate based on subscription status
        if (isSubscribed) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        } else {
          // Not subscribed - show welcome pages
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.welcome,
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. Initialize Localization Helper
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),

                // ✅ 3. Localized Header
                Text(
                  l10n.welcomeBack, // "Welcome Back!"
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  l10n.emailLoginTitle, // "Log in with Email"
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.brandGreen),
                ),

                const SizedBox(height: 40),

                // Email Field
                _inputField(
                  controller: _emailController,
                  hint: l10n.emailHint, // ✅ "Enter Email Address"
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),

                // Password Field
                _inputField(
                  controller: _passwordController,
                  hint: l10n.passwordHint, // ✅ "Enter Password"
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                // ✅ NEW: FORGOT PASSWORD LINK ADDED HERE
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // ✅ UPDATED: Navigate to Forgot Password Phone Screen
                      Navigator.pushNamed(context, AppRoutes.forgotPasswordPhone);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, // Remove default padding to align perfectly
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.forgotPassword, // Uses the localization key
                      style: const TextStyle(
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30), // Adjusted spacing

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black, // Ensure text is visible on primary color
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          l10n.loginBtn, // ✅ "Log In"
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.brandGreen, width: 1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.brandGreen),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              decoration: InputDecoration(
                hintText: hint, // This hint is now localized when passed from build()
                border: InputBorder.none,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}