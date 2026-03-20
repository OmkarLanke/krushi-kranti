import 'dart:convert';
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

  final _formKey = GlobalKey<FormState>();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneFocus = FocusNode();

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

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
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

  // Helper method to generate user-friendly error messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString();
    String actualMessage = errorString;
    
    // Try to extract JSON message from error string
    try {
      // Look for JSON in the error string (format: {...})
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(errorString);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0);
        if (jsonString != null) {
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          if (jsonData.containsKey('message')) {
            actualMessage = jsonData['message'] as String;
          }
        }
      }
    } catch (e) {
      // If JSON parsing fails, use the original error string
    }
    
    final errorLower = actualMessage.toLowerCase();
    
    // Map common error messages to user-friendly text
    if (errorLower.contains('phone number already exists') || 
        errorLower.contains('phone already exists') ||
        errorLower.contains('phone number is already registered')) {
      return _getLocalizedError('phoneExists');
    }
    
    if (errorLower.contains('email already exists') || 
        errorLower.contains('email is already registered') ||
        errorLower.contains('email already in use')) {
      return _getLocalizedError('emailExists');
    }
    
    if (errorLower.contains('username already exists') || 
        errorLower.contains('username is already taken')) {
      return _getLocalizedError('usernameExists');
    }
    
    if (errorLower.contains('invalid') || errorLower.contains('validation')) {
      return _getLocalizedError('invalidData');
    }
    
    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return _getLocalizedError('networkError');
    }
    
    // Return the actual message (cleaned up)
    return actualMessage
        .replaceFirst("Exception: ", "")
        .replaceFirst("Network Error: ", "")
        .replaceFirst("Error: ", "")
        .replaceFirst("error: ", "");
  }
  
  String _getLocalizedError(String key) {
    final errorMessages = {
      "en": {
        "phoneExists": "This phone number is already registered. Please use a different number or try logging in.",
        "emailExists": "This email address is already registered. Please use a different email or try logging in.",
        "usernameExists": "This username is already taken. Please choose a different username.",
        "invalidData": "Please check your information and try again.",
        "networkError": "Network connection error. Please check your internet and try again.",
      },
      "hi": {
        "phoneExists": "यह फोन नंबर पहले से पंजीकृत है। कृपया कोई अन्य नंबर उपयोग करें या लॉग इन करने का प्रयास करें।",
        "emailExists": "यह ई-मेल पता पहले से पंजीकृत है। कृपया कोई अन्य ई-मेल उपयोग करें या लॉग इन करने का प्रयास करें।",
        "usernameExists": "यह उपयोगकर्ता नाम पहले से लिया गया है। कृपया कोई अन्य नाम चुनें।",
        "invalidData": "कृपया अपनी जानकारी जांचें और पुनः प्रयास करें।",
        "networkError": "नेटवर्क कनेक्शन त्रुटि। कृपया अपना इंटरनेट जांचें और पुनः प्रयास करें।",
      },
      "mr": {
        "phoneExists": "हा फोन नंबर आधीच नोंदणीकृत आहे. कृपया वेगळा नंबर वापरा किंवा लॉग इन करण्याचा प्रयत्न करा.",
        "emailExists": "हा ई-मेल पत्ता आधीच नोंदणीकृत आहे. कृपया वेगळा ई-मेल वापरा किंवा लॉग इन करण्याचा प्रयत्न करा.",
        "usernameExists": "हे वापरकर्तानाव आधीच घेतले आहे. कृपया वेगळे नाव निवडा.",
        "invalidData": "कृपया आपली माहिती तपासा आणि पुन्हा प्रयत्न करा.",
        "networkError": "नेटवर्क कनेक्शन त्रुटी. कृपया आपले इंटरनेट तपासा आणि पुन्हा प्रयत्न करा.",
      },
    };
    
    return errorMessages[appLang]?[key] ?? errorMessages["en"]![key]!;
  }

  // ✅ UPDATED: Async function to save data
  Future<void> validateForm() async {
    FocusManager.instance.primaryFocus?.unfocus();

    // Keep existing per-field error strings (used by translations), but drive UX via Form.
    setState(() {
      usernameError = null;
      emailError = null;
      passwordError = null;
      phoneError = null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await HttpService.post(
        "auth/register",
        {
          "username": usernameController.text.trim(),
          "email": emailController.text.trim(),
          "phoneNumber": phoneController.text.trim(),
          "password": passwordController.text.trim(),
          "role": "FARMER",
        },
      );

      await StorageService.saveAuthDetails(
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
      );

      await StorageService.savePersonalDetails(
        firstName: usernameController.text.trim(),
        lastName: "",
        dob: "",
        gender: "",
        profilePicPath: null,
      );

      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.otp, arguments: false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final errorMessage = _getUserFriendlyErrorMessage(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = translations[appLang] ?? translations["en"]!;
    final tErr = translationsErr[appLang] ?? translationsErr["en"]!;

    final media = MediaQuery.of(context);
    final isCompactHeight = media.size.height < 700;
    final horizontalPadding = media.size.width >= 600 ? 24.0 : 16.0;
    final titleSize = media.size.width >= 600 ? 32.0 : 28.0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            t["signupNow"] ?? "Sign Up",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
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
                  AppColors.brandGreen.withOpacity(0.85),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth >= 700 ? 520.0 : double.infinity;

              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isCompactHeight ? 12 : 20,
                  horizontalPadding,
                  20 + media.viewInsets.bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t["hey"] ?? "Hey,",
                              style: GoogleFonts.poppins(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t["signupNow"] ?? "Sign Up",
                              style: GoogleFonts.poppins(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandGreen,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: isCompactHeight ? 20 : 28),

                            _fieldLabel(t["username"] ?? "Username"),
                            const SizedBox(height: 8),
                            _textField(
                              controller: usernameController,
                              focusNode: _usernameFocus,
                              nextFocusNode: _emailFocus,
                              hint: t["usernameHint"] ?? "Enter username",
                              icon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              validator: (value) {
                                final v = value?.trim() ?? "";
                                if (!validateUsername(v)) return tErr["usernameErr"];
                                return null;
                              },
                            ),

                            SizedBox(height: isCompactHeight ? 14 : 18),

                            _fieldLabel(t["email"] ?? "E-Mail"),
                            const SizedBox(height: 8),
                            _textField(
                              controller: emailController,
                              focusNode: _emailFocus,
                              nextFocusNode: _passwordFocus,
                              hint: t["emailHint"] ?? "Enter e-mail address",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: (value) {
                                final v = value?.trim() ?? "";
                                if (!validateEmail(v)) return tErr["emailErr"];
                                return null;
                              },
                            ),

                            SizedBox(height: isCompactHeight ? 14 : 18),

                            _fieldLabel(t["password"] ?? "Password"),
                            const SizedBox(height: 8),
                            _textField(
                              controller: passwordController,
                              focusNode: _passwordFocus,
                              nextFocusNode: _phoneFocus,
                              hint: t["passwordHint"] ?? "Enter password",
                              icon: Icons.lock_outline,
                              isPassword: true,
                              obscureText: _obscurePassword,
                              onTogglePassword: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (value) {
                                final v = value?.trim() ?? "";
                                if (!validatePassword(v)) return tErr["passErr"];
                                return null;
                              },
                            ),

                            SizedBox(height: isCompactHeight ? 14 : 18),

                            _fieldLabel(t["phone"] ?? "Phone Number"),
                            const SizedBox(height: 8),
                            _textField(
                              controller: phoneController,
                              focusNode: _phoneFocus,
                              hint: t["phoneHint"] ?? "Enter phone number",
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              autofillHints: const [AutofillHints.telephoneNumber],
                              onFieldSubmitted: (_) => validateForm(),
                              validator: (value) {
                                final v = value?.trim() ?? "";
                                if (!validatePhone(v)) return tErr["phoneErr"];
                                return null;
                              },
                            ),

                            SizedBox(height: isCompactHeight ? 20 : 28),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.brandGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: _isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded, size: 20),
                                label: Text(
                                  t["getOtp"] ?? "Get OTP",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: _isLoading ? null : validateForm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
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

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onTogglePassword,
    ValueChanged<String>? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final borderRadius = BorderRadius.circular(14);
    final baseBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofillHints: autofillHints,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.brandGreen),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: AppColors.brandGreen, width: 1.4),
        ),
        errorBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
        ),
        focusedErrorBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: Colors.red.shade500, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: isPassword && onTogglePassword != null
            ? IconButton(
                tooltip: obscureText ? 'Show password' : 'Hide password',
                icon: Icon(
                  obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.brandGreen,
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
      ),
      validator: validator,
      onFieldSubmitted: (value) {
        onFieldSubmitted?.call(value);
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
    );
  }
}