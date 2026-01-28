import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/http_service.dart';
import '../services/auth_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isPhoneLogin = false; // Toggle between email and phone login
  String? _errorMessage;
  String? _phoneFormatError;
  String? _phoneAuthError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validatePhoneNumber(String phone) {
    final regex = RegExp(r"^[0-9]{10}$");
    return regex.hasMatch(phone);
  }

  Future<void> _handlePhoneLogin() async {
    final phone = _phoneController.text.trim();

    // Clear previous errors
    setState(() {
      _phoneFormatError = null;
      _phoneAuthError = null;
    });

    // Validate phone format
    if (!_validatePhoneNumber(phone)) {
      setState(() {
        _phoneFormatError = "Please enter a valid 10-digit phone number";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Request OTP for login
      await HttpService.post(
        "auth/request-login-otp",
        {"phoneNumber": phone},
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OTP sent to +91 $phone"),
          backgroundColor: AppColors.brandGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // TODO: Navigate to OTP screen when implemented
      // For now, just show success message
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
      } else if (lowerError.contains('timeout') && 
                 (lowerError.contains('connection') || 
                  lowerError.contains('socket'))) {
        isRealNetworkError = true;
      }
      
      if (isRealNetworkError) {
        setState(() {
          _phoneAuthError = "Network error. Please check your connection and try again.";
        });
      } else {
        setState(() {
          _phoneAuthError = "Incorrect phone number. Please try again.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _parseErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Parse and return user-friendly error messages
  String _parseErrorMessage(String error) {
    // Remove "Exception: " prefix if present
    String message = error.replaceFirst('Exception: ', '').trim();
    String lowerMessage = message.toLowerCase();
    
    // IMPORTANT: Check authentication errors FIRST before network errors
    // This ensures 401 errors show "Invalid credentials" not "Network error"
    
    // Handle authentication errors (check first!)
    // This ensures 401 errors show "Invalid credentials" not "Network error"
    if (lowerMessage.contains('invalid email or password') ||
        lowerMessage.contains('invalid email') ||
        lowerMessage.contains('invalid password') ||
        lowerMessage.contains('unauthorized') ||
        lowerMessage.contains('invalid credentials') ||
        lowerMessage.contains('authentication failed') ||
        lowerMessage.contains('login failed') ||
        lowerMessage.contains('credentials') ||
        // Check if it's a 401 error that got wrapped
        (lowerMessage.contains('network error') && 
         (lowerMessage.contains('invalid') || lowerMessage.contains('unauthorized') || lowerMessage.contains('401')))) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    
    // Handle network errors (only if not an auth error)
    if (lowerMessage.contains('network error') || 
        lowerMessage.contains('socketexception') ||
        lowerMessage.contains('failed host lookup') ||
        lowerMessage.contains('connection refused') ||
        lowerMessage.contains('connection reset')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }
    
    // Handle access denied errors
    if (message.toLowerCase().contains('access denied') ||
        message.toLowerCase().contains('admin role required') ||
        message.toLowerCase().contains('forbidden')) {
      return 'Access denied. Admin role is required to access this panel.';
    }
    
    // Handle server errors
    if (message.toLowerCase().contains('server error') ||
        message.toLowerCase().contains('500') ||
        message.toLowerCase().contains('internal server error')) {
      return 'Server error. Please try again later.';
    }
    
    // Handle service not found
    if (message.toLowerCase().contains('not found') ||
        message.toLowerCase().contains('404')) {
      return 'The requested service is temporarily unavailable. Please try again later.';
    }
    
    // Handle timeout errors
    if (message.toLowerCase().contains('timeout') ||
        message.toLowerCase().contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    
    // Return the original message if it's already user-friendly
    // Otherwise, return a generic error message
    if (message.isNotEmpty && message.length < 100) {
      return message;
    }
    
    return 'Login failed. Please check your credentials and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _isPhoneLogin
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Log in with Phone',
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
            )
          : null,
      body: isWideScreen
          ? Row(
              children: [
                // ---------------------------------------------
                // LEFT SIDE: Hero Image & Branding (Desktop)
                // ---------------------------------------------
                Expanded(
                  flex: 3,
                  child: _buildHeroSection(size),
                ),
                // ---------------------------------------------
                // RIGHT SIDE: Login Form
                // ---------------------------------------------
                Expanded(
                  flex: 2,
                  child: _buildLoginForm(),
                ),
              ],
            )
          : _buildMobileLayout(),
    );
  }

  Widget _buildHeroSection(Size size) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandGreen,
        image: DecorationImage(
          // NEW WORKING URL: A high-res field/farmer image
          image: const NetworkImage(
            'https://images.unsplash.com/photo-1495107334309-fcf20504a5ab?q=80&w=2070&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3), // Slightly darker for better text contrast
            BlendMode.darken,
          ),
          onError: (exception, stackTrace) {
            // Fail gracefully if image fails to load
            debugPrint('Background image failed to load: $exception');
          },
        ),
      ),
      child: Container(
        // Gradient Overlay
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        padding: EdgeInsets.all(size.width > 1200 ? 60 : 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Empowering\nAgriculture.',
              style: GoogleFonts.poppins(
                fontSize: size.width > 1200 ? 48 : 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Text(
              'Manage your market, track farmers, and revolutionize the supply chain with KrushiKranti.',
              style: GoogleFonts.poppins(
                fontSize: size.width > 1200 ? 18 : 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Mobile Hero Section (Compact)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              image: DecorationImage(
                image: const NetworkImage(
                  'https://images.unsplash.com/photo-1495107334309-fcf20504a5ab?q=80&w=2070&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
                onError: (exception, stackTrace) {
                  debugPrint('Background image failed to load: $exception');
                },
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Empowering Agriculture.',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Mobile Login Form
          _buildLoginForm(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Section
                Center(
                  child: Container(
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.agriculture,
                            size: 60,
                            color: AppColors.brandGreen,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enter your details to access the admin panel.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Toggle between Email and Phone Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildToggleButton('Email', !_isPhoneLogin, () {
                      setState(() => _isPhoneLogin = false);
                    }),
                    const SizedBox(width: 12),
                    _buildToggleButton('Phone', _isPhoneLogin, () {
                      setState(() => _isPhoneLogin = true);
                    }),
                  ],
                ),
                const SizedBox(height: 32),

                // Form
                _isPhoneLogin ? _buildPhoneLoginForm() : _buildEmailLoginForm(),
                
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    '© 2026 KrushiKranti Systems',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade400,
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

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brandGreen : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.brandGreen : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error Banner
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
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
                    child: Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
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

          // Email Field
          _buildLabel('Email Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            style: GoogleFonts.poppins(fontSize: 15),
            decoration: _inputDecoration(
              hint: 'admin@krushikranti.com',
              icon: Icons.email_outlined,
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Email is required';
              }
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              );
              if (!emailRegex.hasMatch(val.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),

          // Password Field
          _buildLabel('Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.poppins(fontSize: 15),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outlined,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (val) => val!.isEmpty ? 'Password required' : null,
            onFieldSubmitted: (_) => _handleLogin(),
          ),

          const SizedBox(height: 32),

          // Login Button
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLogin,
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.login_rounded, color: Colors.white, size: 20),
              label: Text(
                'Sign In',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Format Error
        if (_phoneFormatError != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
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
                  child: Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _phoneFormatError!,
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

        // Phone Auth Error
        if (_phoneAuthError != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
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
                  child: Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _phoneAuthError!,
                    style: GoogleFonts.poppins(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

        // Phone Field
        _buildLabel('Phone Number'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _phoneFormatError != null ? Colors.red.shade300 : Colors.grey.shade300,
              width: _phoneFormatError != null ? 1.5 : 1,
            ),
            boxShadow: _phoneFormatError != null
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "+91",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.brandGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  style: GoogleFonts.poppins(fontSize: 15),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: "",
                    hintText: "Enter phone number",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _phoneFormatError = null;
                      _phoneAuthError = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Text(
          "OTP will be sent on this number",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 32),

        // Get OTP Button
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handlePhoneLogin,
            icon: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            label: Text(
              'Get OTP',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for input labels
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }

  // Helper for consistent input decoration
  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade200),
      ),
    );
  }
}