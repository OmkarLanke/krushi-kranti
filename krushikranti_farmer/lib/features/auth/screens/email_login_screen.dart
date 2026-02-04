import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _EmailLoginScreenState extends State<EmailLoginScreen> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // ✅ ADDED: Password visibility toggle
  
  // ✅ Error states
  String? _emailFormatError; // Format validation errors (shown on email field)
  String? _passwordFormatError; // Format validation errors (shown on password field)
  String? _authError; // Authentication error (shown at bottom)
  
  // ✅ ADDED: Animation controllers for shake effect (separate for email and password)
  late AnimationController _emailShakeController;
  late Animation<double> _emailShakeAnimation;
  late AnimationController _passwordShakeController;
  late Animation<double> _passwordShakeAnimation;

  @override
  void initState() {
    super.initState();
    // ✅ Initialize shake animation controllers for both fields
    _emailShakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _passwordShakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // ✅ Create oscillating shake animation for email
    _emailShakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _emailShakeController, curve: Curves.easeInOut));
    
    // ✅ Create oscillating shake animation for password
    _passwordShakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _passwordShakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _emailShakeController.dispose();
    _passwordShakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ Industry-standard email format validation with generic error message
  String? _validateEmailFormat(String email, AppLocalizations l10n) {
    final trimmedEmail = email.trim();
    
    // Check if empty
    if (trimmedEmail.isEmpty) {
      return l10n.emailRequired;
    }
    
    // Check for @ symbol
    if (!trimmedEmail.contains('@')) {
      return l10n.incorrectEmailFormat;
    }
    
    // Check for multiple @ symbols
    final atCount = trimmedEmail.split('@').length - 1;
    if (atCount > 1) {
      return l10n.incorrectEmailFormat;
    }
    
    // Split into local and domain parts
    final parts = trimmedEmail.split('@');
    final localPart = parts[0];
    final domainPart = parts.length > 1 ? parts[1] : '';
    
    // Validate local part (before @)
    if (localPart.isEmpty) {
      return l10n.incorrectEmailFormat;
    }
    
    if (localPart.length > 64) {
      return l10n.incorrectEmailFormat;
    }
    
    // Validate domain part (after @)
    if (domainPart.isEmpty) {
      return l10n.incorrectEmailFormat;
    }
    
    // Check for . in domain (required for valid email)
    if (!domainPart.contains('.')) {
      return l10n.incorrectEmailFormat;
    }
    
    // Check if domain has valid TLD (at least 2 characters after last dot)
    final lastDotIndex = domainPart.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == domainPart.length - 1) {
      return l10n.incorrectEmailFormat;
    }
    
    final tld = domainPart.substring(lastDotIndex + 1);
    if (tld.isEmpty || tld.length < 2) {
      return l10n.incorrectEmailFormat;
    }
    
    // Check for consecutive dots
    if (trimmedEmail.contains('..')) {
      return l10n.incorrectEmailFormat;
    }
    
    // Check for leading/trailing dots
    if (trimmedEmail.startsWith('.') || trimmedEmail.endsWith('.')) {
      return l10n.incorrectEmailFormat;
    }
    
    // Check for @ at start or end
    if (trimmedEmail.startsWith('@') || trimmedEmail.endsWith('@')) {
      return l10n.incorrectEmailFormat;
    }
    
    // Check length limits
    if (trimmedEmail.length > 254) {
      return l10n.incorrectEmailFormat;
    }
    
    // Final comprehensive regex validation
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9](?:[a-zA-Z0-9._-]*[a-zA-Z0-9])?@[a-zA-Z0-9](?:[a-zA-Z0-9.-]*[a-zA-Z0-9])?\.[a-zA-Z]{2,}$",
    );
    
    if (!emailRegex.hasMatch(trimmedEmail)) {
      return l10n.incorrectEmailFormat;
    }
    
    return null; // Valid email format
  }
  
  // ✅ Industry-standard password format validation
  String? _validatePasswordFormat(String password) {
    // Check if empty
    if (password.isEmpty) {
      return "Password is required";
    }
    
    // Check minimum length
    if (password.length < 6) {
      return "Password must be at least 6 characters";
    }
    
    // Check maximum length (prevent DoS attacks)
    if (password.length > 128) {
      return "Password is too long (maximum 128 characters)";
    }
    
    return null; // Valid password format
  }

  // ✅ ADDED: Shake animation for email field
  Future<void> _triggerEmailShakeAnimation() async {
    _emailShakeController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 500));
    _emailShakeController.reset();
  }

  // ✅ ADDED: Shake animation for password field
  Future<void> _triggerPasswordShakeAnimation() async {
    _passwordShakeController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 500));
    _passwordShakeController.reset();
  }


  Future<void> _handleLogin() async {
    // ✅ Access localization for logic (SnackBar)
    final l10n = AppLocalizations.of(context)!;

    // ✅ Clear previous errors
    setState(() {
      _emailFormatError = null;
      _passwordFormatError = null;
      _authError = null;
    });

    // ✅ Step 1: Validate email FORMAT (show specific format errors on email field)
    final emailFormatError = _validateEmailFormat(_emailController.text, l10n);
    if (emailFormatError != null) {
      setState(() {
        _emailFormatError = emailFormatError;
      });
      _triggerEmailShakeAnimation();
      return;
    }

    // ✅ Step 2: Validate password FORMAT (show specific format errors on password field)
    final passwordFormatError = _validatePasswordFormat(_passwordController.text);
    if (passwordFormatError != null) {
      setState(() {
        _passwordFormatError = passwordFormatError;
      });
      _triggerPasswordShakeAnimation();
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

      // ✅ Industry-standard: Show generic error for ALL authentication failures
      // This prevents revealing whether email exists or not (security best practice)
      // Only show specific errors for format validation (already done above)
      
      // ✅ Industry-standard error handling:
      // 1. Network errors (connection issues) -> Show network error
      // 2. Authentication errors (wrong credentials) -> Show "Invalid email or password"
      
      final errorString = e.toString();
      final lowerError = errorString.toLowerCase();
      
      // ✅ Check if it's a REAL network error (connection issues)
      // Network errors: SocketException or explicit "Network Error:" prefix with network keywords
      // HttpService throws "Network Error: ..." for network issues
      // HttpService throws "Error: {statusCode} - ..." for HTTP errors (auth failures)
      
      bool isRealNetworkError = false;
      
      // Check exception type (most reliable)
      if (e is SocketException) {
        isRealNetworkError = true;
      } 
      // Check if error message explicitly says "Network Error:" (from HttpService catch block)
      else if (errorString.contains('Network Error:') || 
               errorString.contains('Network error:')) {
        // Check if it's a real network issue (not just any error)
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
      // Also check for timeout errors in the message (even without "Network Error:" prefix)
      else if (lowerError.contains('timeout') && 
               (lowerError.contains('connection') || 
                lowerError.contains('socket'))) {
        isRealNetworkError = true;
      }
      
      // If it's a clear network error, show network message at bottom
      if (isRealNetworkError) {
        setState(() {
          _authError = l10n.networkError;
        });
        return;
      }

      // ✅ For ALL other errors (including authentication failures):
      // - HTTP 401, 404, 400 errors from server
      // - "Unauthorized" messages
      // - Any error from login endpoint
      // Show generic "Invalid email or password" message at bottom
      // This is the industry standard for security (don't reveal if email exists)
      setState(() {
        _authError = l10n.invalidEmailOrPassword;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. Initialize Localization Helper
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
          l10n.emailLoginTitle,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ✅ 3. Localized Header
                Text(
                  l10n.welcomeBack, // "Welcome Back!"
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.emailLoginTitle, // "Log in with Email"
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 32),

                // Email Field with shake animation
                AnimatedBuilder(
                  animation: _emailShakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_emailShakeAnimation.value, 0),
                      child: _inputField(
                        controller: _emailController,
                        hint: l10n.emailHint, // ✅ "Enter Email Address"
                        icon: Icons.email_outlined,
                        hasError: _emailFormatError != null,
                      ),
                    );
                  },
                ),
                if (_emailFormatError != null) _errorText(_emailFormatError!),
                const SizedBox(height: 20),

                // Password Field with shake animation
                AnimatedBuilder(
                  animation: _passwordShakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_passwordShakeAnimation.value, 0),
                      child: _inputField(
                        controller: _passwordController,
                        hint: l10n.passwordHint, // ✅ "Enter Password"
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        hasError: _passwordFormatError != null,
                        onTogglePassword: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    );
                  },
                ),
                if (_passwordFormatError != null) _errorText(_passwordFormatError!),

                // ✅ NEW: FORGOT PASSWORD LINK ADDED HERE
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to Forgot Password Email Screen
                      Navigator.pushNamed(context, AppRoutes.forgotPasswordEmail);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.forgotPassword,
                      style: GoogleFonts.poppins(
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30), // Adjusted spacing

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                    label: Text(
                      l10n.loginBtn, // ✅ "Log In"
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                
                // ✅ Authentication Error (shown at bottom)
                if (_authError != null) ...[
                  const SizedBox(height: 16),
                  _authErrorText(_authError!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 0),
      child: Container(
        padding: const EdgeInsets.all(12),
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
                message,
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

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    bool hasError = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: hasError ? Colors.red.shade300 : Colors.grey.shade300, 
          width: hasError ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: hasError
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
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasError
                  ? Colors.red.shade50
                  : AppColors.brandGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: hasError ? Colors.red.shade700 : AppColors.brandGreen,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword ? obscureText : false,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                suffixIcon: isPassword && onTogglePassword != null
                    ? IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: hasError ? Colors.red.shade700 : AppColors.brandGreen,
                          size: 20,
                        ),
                        onPressed: onTogglePassword,
                      )
                    : null,
              ),
              onChanged: (_) {
                setState(() {
                  // Clear errors when user starts typing (better UX)
                  if (isPassword) {
                    _passwordFormatError = null;
                  } else {
                    _emailFormatError = null;
                  }
                  // Also clear auth error when user types
                  _authError = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}