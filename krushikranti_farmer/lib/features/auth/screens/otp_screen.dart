import 'dart:async';
import 'package:flutter/material.dart';
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
      final bool isLogin = ModalRoute.of(context)?.settings.arguments as bool? ?? false;

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
      final bool isLogin = ModalRoute.of(context)?.settings.arguments as bool? ?? false;

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
        final userInfo = response['user'] ?? {};

        if (accessToken.isEmpty) {
          throw Exception("Login failed. Please try again.");
        }

        // Save token and user details
        await StorageService.saveToken(accessToken);
        await StorageService.saveAuthDetails(
          email: userInfo['email'] ?? '',
          phone: userInfo['phoneNumber'] ?? phoneNumber,
        );

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

        // Navigate based on subscription status
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
      } else {
        // CASE B: User is Signing Up -> Call /auth/verify-otp, then login to get token
        final response = await HttpService.post(
          "auth/verify-otp",
          {
            "phoneNumber": phoneNumber,
            "otp": otp,
          },
        );

        // Extract user info from response
        final data = response['data'] ?? {};
        if (data.isEmpty) {
          throw Exception("OTP verification failed. Please try again.");
        }

        // Save basic user details
        await StorageService.saveAuthDetails(
          email: data['email'] ?? '',
          phone: data['phoneNumber'] ?? phoneNumber,
        );

        // Save username as first name initially
        await StorageService.savePersonalDetails(
          firstName: data['username'] ?? '',
          lastName: "",
          dob: "",
          gender: "",
          profilePicPath: null,
        );

        // Request a new login OTP (since the registration OTP was consumed)
        await HttpService.post(
          "auth/request-login-otp",
          {"phoneNumber": phoneNumber},
        );

        // Get the new OTP for login (using test endpoint for now)
        // In production, this would be sent via SMS and user would enter it
        // For now, we'll fetch it from the test endpoint
        final otpResponse = await HttpService.get("auth/get-otp/$phoneNumber");
        final String loginOtp = otpResponse['data'] ?? '';
        
        if (loginOtp.isEmpty) {
          throw Exception("Failed to get login OTP. Please try logging in manually.");
        }

        // Use the new OTP to login and get JWT token
        final loginResp = await HttpService.post(
          "auth/login",
          {
            "phoneNumber": phoneNumber,
            "otp": loginOtp,
          },
        );
        final String accessToken = loginResp['accessToken'] ?? '';
        final userInfo = loginResp['user'] ?? {};
        if (accessToken.isEmpty) {
          throw Exception("Login failed after signup. Please try again.");
        }

        await StorageService.saveToken(accessToken);
        await StorageService.saveAuthDetails(
          email: userInfo['email'] ?? data['email'] ?? '',
          phone: userInfo['phoneNumber'] ?? phoneNumber,
        );

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 🔙 FIXED BACK BUTTON
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // MAIN CONTENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 70),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6EEB6E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      titleText[appLang]!,
                      style: const TextStyle(
                        color: AppColors.brandGreen,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      enterOtpText[appLang]!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // OTP Input Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (i) => _otpBox(i)),
                    ),
                    
                    const SizedBox(height: 10),
                    // Resend OTP - Show timer or button
                    timerSeconds > 0
                        ? Text(
                            "${resendText[appLang]}: ${timerSeconds.toString().padLeft(2, '0')}s",
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
                                    ),
                                  )
                                : Text(
                                    resendText[appLang]!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.brandGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                    const SizedBox(height: 40),
                    
                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isLoading ? null : _submitOtp, // ✅ Call logic function
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : Text(
                                submitButtonText[appLang]!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: otpControllers[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(
          counterText: "",
          border: OutlineInputBorder(),
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