import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';
import '../../subscription/services/subscription_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());

  int timerSeconds = 30;
  Timer? countdownTimer;
  bool _isLoading = false;
  bool _isResending = false;

  String appLang = "en"; // default

  final Map<String, String> titleText = {
    "en": "Please Input OTP",
    "hi": "कृपया OTP दर्ज करें",
    "mr": "कृपया OTP प्रविष्ट करा",
  };

  final Map<String, String> enterOtpText = {
    "en": "Enter OTP",
    "hi": "OTP दर्ज करें",
    "mr": "OTP प्रविष्ट करा",
  };

  final Map<String, String> resendText = {
    "en": "Resend OTP",
    "hi": "OTP पुनः भेजें",
    "mr": "OTP पुन्हा पाठवा",
  };

  final Map<String, String> submitButtonText = {
    "en": "Submit OTP",
    "hi": "OTP सबमिट करें",
    "mr": "OTP सबमिट करा",
  };

  @override
  void initState() {
    super.initState();
    loadLanguage();
    startTimer();
  }

  Future<void> loadLanguage() async {
    String? lang = await StorageService.getLanguage();
    setState(() => appLang = lang ?? "en");
  }

  void startTimer() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (timerSeconds > 0) {
        setState(() => timerSeconds--);
      } else {
        countdownTimer?.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });

    try {
      // Get phone number from storage
      final userData = await StorageService.getUserDetails();
      final String phoneNumber = userData['phone'] ?? '';

      if (phoneNumber.isEmpty) {
        throw Exception("Phone number not found. Please try again.");
      }

      // Get 'isLogin' Flag to determine which endpoint to call
      final bool isLogin =
          ModalRoute.of(context)?.settings.arguments as bool? ?? false;

      if (isLogin) {
        // For login: use /auth/request-login-otp
        await HttpService.post(
          "auth/request-login-otp",
          {"phoneNumber": phoneNumber},
        );
      } else {
        // For signup: use /auth/resend-otp
        await HttpService.post(
          "auth/resend-otp",
          {"phoneNumber": phoneNumber},
        );
      }

      // Reset timer
      setState(() {
        timerSeconds = 30;
        _isResending = false;
      });
      startTimer();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OTP resent successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isResending = false;
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
  void dispose() {
    countdownTimer?.cancel();
    for (var c in otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ✅ LOGIC: Verify and Navigate based on flow
  Future<void> _submitOtp() async {
    // 1. Combine OTP from controllers
    String otp = otpControllers.map((e) => e.text).join();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter full 6-digit OTP")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Get phone number from storage
      final userData = await StorageService.getUserDetails();
      final String phoneNumber = userData['phone'] ?? '';

      if (phoneNumber.isEmpty) {
        throw Exception("Phone number not found. Please try again.");
      }

      // 3. Get 'isLogin' Flag passed from Login/Signup screen
      // Default to false (Signup) if arguments are null
      final bool isLogin =
          ModalRoute.of(context)?.settings.arguments as bool? ?? false;

      if (isLogin) {
        // CASE A: User is Logging In -> Call /auth/login with phone/OTP
        final response = await HttpService.post(
          "auth/login",
          {
            "phoneNumber": phoneNumber,
            "otp": otp,
          },
        );

        // Extract token and user info from response
        final String accessToken = response['accessToken'] ?? '';
        final String refreshToken = response['refreshToken'] ?? '';
        final userInfo = response['user'] ?? {};

        if (accessToken.isEmpty) {
          throw Exception("Login failed. Please try again.");
        }

        // Save tokens and user details
        await StorageService.saveToken(accessToken);
        if (refreshToken.isNotEmpty) {
          await StorageService.saveRefreshToken(refreshToken);
        }
        await StorageService.saveAuthDetails(
          email: userInfo['email'] ?? '',
          phone: userInfo['phoneNumber'] ?? phoneNumber,
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
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.welcome,
              (route) => false,
            );
          }
        }
      } else {
        // CASE B: User is Signing Up -> Call /auth/verify-otp (returns tokens directly)
        final response = await HttpService.post(
          "auth/verify-otp",
          {
            "phoneNumber": phoneNumber,
            "otp": otp,
          },
        );

        // verify-otp now returns AuthResponse with tokens and user info
        final String accessToken = response['accessToken'] ?? '';
        final String refreshToken = response['refreshToken'] ?? '';
        final userInfo = response['user'] ?? {};

        if (accessToken.isEmpty) {
          throw Exception("OTP verification failed. Please try again.");
        }

        // Save tokens
        await StorageService.saveToken(accessToken);
        if (refreshToken.isNotEmpty) {
          await StorageService.saveRefreshToken(refreshToken);
        }

        // Save user details
        await StorageService.saveAuthDetails(
          email: userInfo['email'] ?? '',
          phone: userInfo['phoneNumber'] ?? phoneNumber,
        );

        // Save username as first name initially
        await StorageService.savePersonalDetails(
          firstName: userInfo['username'] ?? '',
          lastName: "",
          dob: "",
          gender: "",
          profilePicPath: null,
        );

        // Save user role and ID
        final userRole = userInfo['role'] ?? 'FARMER';
        final userId = userInfo['id']?.toString() ?? '';
        await StorageService.saveRole(userRole);
        if (userId.isNotEmpty) {
          await StorageService.saveUserId(userId);
        }

        // New users are unsubscribed by default
        await StorageService.saveSubscriptionStatus(false);

        if (!mounted) return;

        // Navigate to Onboarding (then welcome will show after completion flow)
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.onboardingPersonal,
        );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titleText[appLang]!,
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
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
                        color: AppColors.brandGreen.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.lock_rounded,
                      size: 50, color: AppColors.brandGreen),
                ),
                const SizedBox(height: 24),
                Text(
                  titleText[appLang]!,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  enterOtpText[appLang]!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // OTP Input Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) => _otpBox(i)),
                ),

                const SizedBox(height: 16),
                // Resend OTP - Show timer or button
                timerSeconds > 0
                    ? Text(
                        "${resendText[appLang]}: ${timerSeconds.toString().padLeft(2, '0')}s",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      )
                    : TextButton(
                        onPressed: _isResending ? null : _resendOtp,
                        child: _isResending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.brandGreen),
                                ),
                              )
                            : Text(
                                resendText[appLang]!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.brandGreen,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                      ),
                const SizedBox(height: 32),

                // SUBMIT BUTTON
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.verified_rounded,
                            color: Colors.white, size: 20),
                    label: Text(
                      submitButtonText[appLang]!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    onPressed: _isLoading ? null : _submitOtp,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 48,
      child: TextField(
        controller: otpControllers[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.brandGreen, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }
}
