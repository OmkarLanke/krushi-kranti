import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../subscription/services/subscription_service.dart';

class SplashScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Decide where to go based on existing session (token + subscription)
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Small splash delay for logo visibility
    await Future.delayed(const Duration(seconds: 2));

    // Check if token exists (user already logged in)
    final token = await StorageService.getToken();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      // No token → check if language preference exists
      final savedLanguage = await StorageService.getLanguage();
      
      if (savedLanguage == null || savedLanguage.isEmpty) {
        // First time user → show language selection screen
      Navigator.pushReplacementNamed(context, AppRoutes.languageSelection);
      } else {
        // Language already selected → go directly to login
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
      return;
    }

    // Token exists → user is logged in. Check role to decide entry screen.
    final userRole = await StorageService.getRole();

    if (!mounted) return;

    // Navigate based on user role
    if (userRole == 'FIELD_OFFICER') {
      // Field Officer → go directly to Field Officer Dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.fieldOfficerDashboard);
      return;
    } else if (userRole == 'ADMIN') {
      // Admin → go to Admin Dashboard (if implemented in this app)
      // For now, redirect to farmer dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      return;
    }

    // For FARMER role, check subscription to decide entry screen
    // Fetch fresh subscription status from API to ensure accuracy
    bool isSubscribed = false;
    try {
      final subStatus = await SubscriptionService.getSubscriptionStatus();
      // Check multiple possible fields to determine subscription status
      isSubscribed = subStatus['isSubscribed'] == true || 
                    subStatus['subscriptionStatus'] == 'ACTIVE' ||
                    subStatus['subscriptionStatus'] == 'active';
      
      if (isSubscribed) {
        final endDate = subStatus['subscriptionEndDate']?.toString() ?? 
                       subStatus['expiresAt']?.toString() ??
                       subStatus['subscriptionEndDate']?.toString();
        await StorageService.saveSubscriptionStatus(
          true,
          endDate: endDate,
        );
      } else {
        await StorageService.saveSubscriptionStatus(false);
      }
    } catch (_) {
      // If API call fails, fallback to local storage
      isSubscribed = await StorageService.isSubscribed();
    }

    if (!mounted) return;

    if (isSubscribed) {
      // Logged in & subscribed → go directly to main dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      // Logged in but not subscribed → show welcome pages first
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.brandGreen.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with gradient container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brandGreen.withOpacity(0.15),
                        AppColors.brandGreen.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandGreen.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo/krushi_logo.png',
                    height: 200,
                    width: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.agriculture_rounded, size: 100, color: AppColors.brandGreen),
                  ),
                ),

                const SizedBox(height: 32),

                // Heading
                Text(
                  "Welcome to\nKrushiKranti",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandGreen,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 24),

                // Tagline
                Text(
                  "THE FARMER IS SELF-SUFFICIENT",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    letterSpacing: 2,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                // Loading indicator
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
