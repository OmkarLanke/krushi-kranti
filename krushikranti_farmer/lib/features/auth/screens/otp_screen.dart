import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../subscription/services/subscription_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  int timerSeconds = 30;
  Timer? countdownTimer;
  bool _isLoading = false;
  bool _isResending = false;
  bool _autoSubmitScheduled = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 6; i++) {
      focusNodes[i].addListener(_onFocusChanged);
    }
    startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focusNodes[0].requestFocus();
    });
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  bool get _otpComplete =>
      otpControllers.every((c) => c.text.trim().length == 1);

  void startTimer() {
    countdownTimer?.cancel();
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
    final l10n = AppLocalizations.of(context)!;
    final bool isLogin =
        ModalRoute.of(context)?.settings.arguments as bool? ?? false;
    setState(() {
      _isResending = true;
    });

    try {
      final userData = await StorageService.getUserDetails();
      final String phoneNumber = userData['phone'] ?? '';

      if (phoneNumber.isEmpty) {
        throw Exception(l10n.phoneNumberNotFound);
      }

      // Get 'isLogin' Flag to determine which endpoint to call
      final bool isLogin = ModalRoute.of(context)?.settings.arguments as bool? ?? false;

      if (isLogin) {
        await HttpService.post(
          "auth/request-login-otp",
          {"phoneNumber": phoneNumber},
        );
      } else {
        await HttpService.post(
          "auth/resend-otp",
          {"phoneNumber": phoneNumber},
        );
      }

      setState(() {
        timerSeconds = 30;
        _isResending = false;
        _autoSubmitScheduled = false;
      });
      startTimer();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.otpResentSuccess),
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
    for (var i = 0; i < 6; i++) {
      focusNodes[i].removeListener(_onFocusChanged);
      focusNodes[i].dispose();
    }
    for (var c in otpControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleOtpChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    _autoSubmitScheduled = false;

    if (digits.length > 1) {
      for (var i = 0; i < 6; i++) {
        otpControllers[i].text = i < digits.length ? digits[i] : '';
      }
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final last = digits.length >= 6 ? 5 : digits.length.clamp(0, 5);
        focusNodes[last].requestFocus();
        if (digits.length >= 6) _tryAutoSubmit();
      });
      return;
    }

    final ch = digits.isEmpty ? '' : digits[0];
    if (otpControllers[index].text != ch) {
      otpControllers[index].value = TextEditingValue(
        text: ch,
        selection: TextSelection.collapsed(offset: ch.length),
      );
    }
    setState(() {});

    if (ch.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    }
    if (_otpComplete) _tryAutoSubmit();
  }

  void _tryAutoSubmit() {
    if (!_otpComplete || _isLoading || _autoSubmitScheduled) return;
    _autoSubmitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_otpComplete && !_isLoading) {
        await _submitOtp();
      }
    });
  }

  Future<void> _submitOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final bool isLogin =
        ModalRoute.of(context)?.settings.arguments as bool? ?? false;
    String otp = otpControllers.map((e) => e.text).join();
    
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterFull6DigitOtp)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await StorageService.getUserDetails();
      final String phoneNumber = userData['phone'] ?? '';

      if (phoneNumber.isEmpty) {
        throw Exception(l10n.phoneNumberNotFound);
      }

      // 3. Get 'isLogin' Flag passed from Login/Signup screen
      // Default to false (Signup) if arguments are null
      final bool isLogin = ModalRoute.of(context)?.settings.arguments as bool? ?? false;

      if (isLogin) {
        final response = await HttpService.post(
          "auth/login",
          {
            "phoneNumber": phoneNumber,
            "otp": otp,
          },
        );

        final String accessToken = response['accessToken'] ?? '';
        final String refreshToken = response['refreshToken'] ?? '';
        final userInfo = response['user'] ?? {};

        if (accessToken.isEmpty) {
          throw Exception(l10n.loginFailedRetry);
        }

        await StorageService.saveToken(accessToken);
        if (refreshToken.isNotEmpty) {
          await StorageService.saveRefreshToken(refreshToken);
        }
        await StorageService.saveAuthDetails(
          email: userInfo['email'] ?? '',
          phone: userInfo['phoneNumber'] ?? phoneNumber,
        );

        final userRole = userInfo['role'] ?? 'FARMER';
        final userId = userInfo['id']?.toString() ?? '';
        await StorageService.saveRole(userRole);
        if (userId.isNotEmpty) {
          await StorageService.saveUserId(userId);
        }

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
          await StorageService.saveSubscriptionStatus(false);
        }

        if (!mounted) return;

        if (userRole == 'FIELD_OFFICER') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.fieldOfficerDashboard,
            (route) => false,
          );
        } else if (userRole == 'ADMIN') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        } else {
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
        // CASE B: User is Signing Up -> Call /auth/verify-otp
        // verify-otp returns AuthResponse directly (accessToken, refreshToken, user)
        final response = await HttpService.post(
          "auth/verify-otp",
          {
            "phoneNumber": phoneNumber,
            "otp": otp,
          },
        );

        final String accessToken = response['accessToken'] ?? '';
        final String refreshToken = response['refreshToken'] ?? '';
        final userInfo = response['user'] ?? {};

        if (accessToken.isEmpty) {
          throw Exception(l10n.otpVerificationFailedRetry);
        }

        await StorageService.saveToken(accessToken);
        if (refreshToken.isNotEmpty) {
          await StorageService.saveRefreshToken(refreshToken);
        }
        await StorageService.saveAuthDetails(
          email: userInfo['email'] ?? '',
          phone: userInfo['phoneNumber'] ?? phoneNumber,
        );

        await StorageService.savePersonalDetails(
          firstName: userInfo['username'] ?? '',
          lastName: "",
          dob: "",
          gender: "",
          profilePicPath: null,
        );

        final userRole = userInfo['role'] ?? 'FARMER';
        final userId = userInfo['id']?.toString() ?? '';
        await StorageService.saveRole(userRole);
        if (userId.isNotEmpty) {
          await StorageService.saveUserId(userId);
        }

        await StorageService.saveSubscriptionStatus(false);

        await StorageService.saveOnboardingPersonalSkipped(false);
        await StorageService.saveOnboardingFarmSkipped(false);
        await StorageService.saveOnboardingPersonalCompleted(false);
        await StorageService.saveOnboardingKycCompleted(false);

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.onboardingPersonal,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _autoSubmitScheduled = false;
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
          l10n.authOtpAppBarTitle,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 88,
                  height: 88,
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
                  child: Icon(Icons.lock_rounded, size: 50, color: AppColors.brandGreen),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.authOtpHeadline,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.authOtpDescription,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 32),
                
                // OTP Input Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _otpBox(i)),
                ),
                
                const SizedBox(height: 16),
                // Resend OTP - Show timer or button
                timerSeconds > 0
                    ? Text(
                        l10n.authOtpResendCountdown(timerSeconds),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                    label: Text(
                      submitButtonText[appLang]!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: l10n.authOtpSubmit,
                  icon: Icons.verified_rounded,
                  isLoading: _isLoading,
                  onPressed: (!_otpComplete || _isLoading) ? null : _submitOtp,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: index == 0 ? 0 : 4, right: 4),
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.backspace) {
              if (otpControllers[index].text.isEmpty && index > 0) {
                otpControllers[index - 1].clear();
                focusNodes[index - 1].requestFocus();
                setState(() {});
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Semantics(
            label: '${index + 1} / 6',
            textField: true,
            child: SizedBox(
              height: 56,
              child: TextField(
                controller: otpControllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade400, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.brandGreen, width: 2.4),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => _handleOtpChanged(index, v),
              ),
            ),
          ),
        ),
      ),
    );
  }
}