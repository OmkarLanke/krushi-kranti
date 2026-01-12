import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
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
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      return 'Service unavailable. Please try again later.';
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
      backgroundColor: Colors.white,
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
      color: Colors.white,
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
                    height: 120, // Reduced height for better proportion
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
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
                const SizedBox(height: 40),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error Banner
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red.shade900,
                                    fontSize: 13,
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

                      const SizedBox(height: 40),

                      // Login Button
                      SizedBox(
                        height: 56, // Taller button for modern feel
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: AppColors.brandGreen.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                
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

  // Helper widget for input labels
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
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
      fillColor: Colors.grey.shade50, // Very subtle grey background
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none, // Clean look without borders by default
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200), // Subtle border when inactive
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade200),
      ),
    );
  }
}