import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // ✅ ADDED: Username Controller
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String appLang = "en"; // default
  bool _isLoading = false;
  bool _obscurePassword = true; // ✅ ADDED: Password visibility toggle

  String? usernameError; // ✅ ADDED: Username Error
  String? emailError;
  String? passwordError;
  String? phoneError;

  // 🌍 UI TRANSLATIONS
  final Map<String, Map<String, String>> translations = {
    "en": {
      "hey": "Hey,",
      "signupNow": "Sign Up Now !",
      "username": "Username",           // ✅ New
      "usernameHint": "Enter username", // ✅ New
      "email": "E-Mail",
      "emailHint": "Enter e-mail address",
      "password": "Password",
      "passwordHint": "Enter password",
      "phone": "Phone Number",
      "phoneHint": "Enter phone number",
      "getOtp": "Get OTP",
    },
    "hi": {
      "hey": "नमस्ते,",
      "signupNow": "अभी साइन अप करें !",
      "username": "उपयोगकर्ता नाम",           // ✅ New
      "usernameHint": "उपयोगकर्ता नाम दर्ज करें", // ✅ New
      "email": "ई-मेल",
      "emailHint": "ई-मेल दर्ज करें",
      "password": "पासवर्ड",
      "passwordHint": "पासवर्ड दर्ज करें",
      "phone": "फोन नंबर",
      "phoneHint": "फोन नंबर दर्ज करें",
      "getOtp": "OTP प्राप्त करें",
    },
    "mr": {
      "hey": "नमस्कार,",
      "signupNow": "आता साइन अप करा !",
      "username": "वापरकर्तानाव",           // ✅ New
      "usernameHint": "वापरकर्तानाव टाका",   // ✅ New
      "email": "ई-मेल",
      "emailHint": "ई-मेल टाका",
      "password": "पासवर्ड",
      "passwordHint": "पासवर्ड टाका",
      "phone": "फोन नंबर",
      "phoneHint": "फोन नंबर टाका",
      "getOtp": "OTP मिळवा",
    }
  };

  // 🌍 ERROR TRANSLATIONS
  final Map<String, Map<String, String>> translationsErr = {
    "en": {
      "usernameErr": "Please enter a username", // ✅ New
      "emailErr": "Enter a valid email address",
      "passErr": "Password must contain 8+ chars, A-Z, a-z, number & special character",
      "phoneErr": "Enter a valid 10-digit phone number",
    },
    "hi": {
      "usernameErr": "कृपया उपयोगकर्ता नाम दर्ज करें", // ✅ New
      "emailErr": "कृपया मान्य ई-मेल दर्ज करें",
      "passErr": "पासवर्ड में 8+ अक्षर, A-Z, a-z, संख्या और विशेष वर्ण शामिल होने चाहिए",
      "phoneErr": "कृपया 10 अंकों का मान्य फ़ोन नंबर दर्ज करें",
    },
    "mr": {
      "usernameErr": "कृपया वापरकर्तानाव प्रविष्ट करा", // ✅ New
      "emailErr": "कृपया वैध ई-मेल पत्ता प्रविष्ट करा",
      "passErr": "पासवर्डमध्ये 8+ अक्षरे, A-Z, a-z, संख्या व विशेष चिन्ह असणे आवश्यक आहे",
      "phoneErr": "कृपया वैध 10 अंकी मोबाईल नंबर टाका",
    }
  };

  @override
  void initState() {
    super.initState();
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    String? lang = await StorageService.getLanguage();
    setState(() => appLang = lang ?? "en");
  }

  // VALIDATIONS
  bool validateUsername(String name) {
    return name.trim().length >= 3; // Simple check
  }

  bool validateEmail(String email) {
    final regex = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$");
    return regex.hasMatch(email);
  }

  bool validatePhone(String phone) {
    final regex = RegExp(r"^[0-9]{10}$");
    return regex.hasMatch(phone);
  }

  bool validatePassword(String password) {
    final regex = RegExp(r"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%\^&\*\-_]).{8,}$");
    return regex.hasMatch(password);
  }

  // ✅ UPDATED: Async function to save data
  Future<void> validateForm() async {
    setState(() {
      usernameError = validateUsername(usernameController.text)
          ? null
          : translationsErr[appLang]!["usernameErr"];

      emailError = validateEmail(emailController.text.trim())
          ? null
          : translationsErr[appLang]!["emailErr"];

      passwordError = validatePassword(passwordController.text.trim())
          ? null
          : translationsErr[appLang]!["passErr"];

      phoneError = validatePhone(phoneController.text.trim())
          ? null
          : translationsErr[appLang]!["phoneErr"];
    });

    if (usernameError == null && 
        emailError == null && 
        passwordError == null && 
        phoneError == null) {
      
      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Call /auth/register endpoint
        final response = await HttpService.post(
          "auth/register",
          {
            "username": usernameController.text.trim(),
            "email": emailController.text.trim(),
            "phoneNumber": phoneController.text.trim(),
            "password": passwordController.text.trim(),
            "role": "FARMER",
          },
        );

        // 2. Save Auth Details (Email/Phone) for OTP screen
        await StorageService.saveAuthDetails(
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
        );

        // 3. Save Username as First Name initially (so Profile isn't empty)
        await StorageService.savePersonalDetails(
          firstName: usernameController.text.trim(),
          lastName: "",
          dob: "",
          gender: "",
          profilePicPath: null,
        );

        if (!mounted) return;

        // 4. Navigate to OTP (Pass 'false' because this is Signup)
        Navigator.pushNamed(context, AppRoutes.otp, arguments: false);
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
  }

  @override
  Widget build(BuildContext context) {
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
          translations[appLang]!["signupNow"]!,
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

                Text(
                  translations[appLang]!["hey"]!,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translations[appLang]!["signupNow"]!,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandGreen,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 32),

                // --- 1. USERNAME FIELD (ADDED BACK) ---
                _label(translations[appLang]!["username"]!),
                _inputField(
                  controller: usernameController,
                  hint: translations[appLang]!["usernameHint"]!,
                  icon: Icons.person_outline,
                ),
                if (usernameError != null) _errorText(usernameError!),

                const SizedBox(height: 20),

                // --- 2. EMAIL FIELD ---
                _label(translations[appLang]!["email"]!),
                _inputField(
                  controller: emailController,
                  hint: translations[appLang]!["emailHint"]!,
                  icon: Icons.email_outlined,
                ),
                if (emailError != null) _errorText(emailError!),

                const SizedBox(height: 20),

                // --- 3. PASSWORD FIELD ---
                _label(translations[appLang]!["password"]!),
                _inputField(
                  controller: passwordController,
                  hint: translations[appLang]!["passwordHint"]!,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onTogglePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                if (passwordError != null) _errorText(passwordError!),

                const SizedBox(height: 20),

                // --- 4. PHONE FIELD ---
                _label(translations[appLang]!["phone"]!),
                _inputField(
                  controller: phoneController,
                  hint: translations[appLang]!["phoneHint"]!,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                if (phoneError != null) _errorText(phoneError!),

                const SizedBox(height: 40),

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
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    label: Text(
                      translations[appLang]!["getOtp"]!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    onPressed: _isLoading ? null : validateForm,
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _errorText(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200, width: 1),
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
                msg,
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

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.brandGreen),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword ? obscureText : false,
              keyboardType: keyboardType,
              maxLength: maxLength,
              style: GoogleFonts.poppins(fontSize: 14),
              inputFormatters: maxLength != null
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(maxLength),
                    ]
                  : null,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                counterText: '',
                suffixIcon: isPassword && onTogglePassword != null
                    ? IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: AppColors.brandGreen,
                          size: 20,
                        ),
                        onPressed: onTogglePassword,
                      )
                    : null,
              ),
              onChanged: (_) {
                setState(() {
                  usernameError = null;
                  emailError = null;
                  passwordError = null;
                  phoneError = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}