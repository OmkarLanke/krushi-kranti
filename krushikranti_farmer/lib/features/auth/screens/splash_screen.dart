import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart'; // update path if needed
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
      // No token → fresh user → go to language selection/login flow
      Navigator.pushReplacementNamed(context, AppRoutes.languageSelection);
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Heading
              const Text(
                "Welcome to\nKrushiKranti",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandGreen,
                ),
              ),

              const SizedBox(height: 30),

              // Logo
              Image.asset(
                'assets/images/logo/krushi_logo.png', // update to match your asset
                height: 300,
                width: 300,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 40),

              // Tagline
              const Text(
                "THE FARMER IS SELF-SUFFICIENT",
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
