import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  String countryCode = "+91";
  String appLang = "en";
  bool _isLoading = false;

  String? phoneErrorText;

  final Map<String, Map<String, String>> translations = {
    "en": {
      "tagline": "Reconnect With Goodness",
      "start": "Let’s get you started",
      "phoneHint": "your phone number",
      "otpInfo": "OTP will be sent on this number",
      "otpBtn": "Get OTP",
      "emailLogin": "Log in with Email & Password",
      "terms": "By continuing you agree to our Terms & Conditions and Privacy & Legal Policy",
      "signUp": "Sign Up",
      "phoneError": "Please enter a valid 10-digit phone number"
    },
    "hi": {
      "tagline": "भलाई से फिर जुड़ें",
      "start": "चलें शुरू करते हैं",
      "phoneHint": "अपना मोबाइल नंबर",
      "otpInfo": "OTP इस नंबर पर भेजा जाएगा",
      "otpBtn": "OTP प्राप्त करें",
      "emailLogin": "ईमेल और पासवर्ड से लॉग इन करें",
      "terms": "आगे बढ़ते हुए आप हमारी शर्तों और गोपनीयता नीति से सहमत हैं",
      "signUp": "साइन अप करें",
      "phoneError": "कृपया 10 अंकों का मान्य मोबाइल नंबर दर्ज करें"
    },
    "mr": {
      "tagline": "चांगुलपणाशी पुन्हा जोडले जा",
      "start": "चला सुरुवात करूया",
      "phoneHint": "आपला मोबाईल नंबर",
      "otpInfo": "OTP या नंबरवर पाठविला जाईल",
      "otpBtn": "OTP मिळवा",
      "emailLogin": "ईमेल आणि पासवर्डसह लॉग इन करा",
      "terms": "पुढे जाताना आपण आमच्या अटी आणि गोपनीयता धोरणास सहमती देता",
      "signUp": "साइन अप",
      "phoneError": "कृपया वैध 10 अंकी मोबाईल नंबर प्रविष्ट करा"
    }
  };

  @override
  void initState() {
    super.initState();
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    String? lang = await StorageService.getLanguage();
    if (mounted) {
      setState(() {
        appLang = lang ?? "en";
      });
    }
  }

  bool validatePhoneNumber(String phone) {
    final regex = RegExp(r"^[0-9]{10}$");
    return regex.hasMatch(phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BACK BUTTON ---
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 10),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.languageSelection,
                    (route) => false,
                  );
                },
              ),
            ),
            
            // --- HEADER IMAGE & TAGLINE ---
            Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        "assets/images/auth/farmer_logo.jpg",
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Container(height: 240, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 50, color: Colors.grey)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    translations[appLang]!["tagline"]!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.brandGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- SCROLLABLE FORM ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translations[appLang]!["start"]!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- PHONE INPUT ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: phoneErrorText == null
                                ? AppColors.border
                                : Colors.red,
                          ),
                        ),
                        child: Row(
                          children: [
                            DropdownButton<String>(
                              value: countryCode,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: "+91", child: Text("+91")),
                                DropdownMenuItem(value: "+92", child: Text("+92")),
                                DropdownMenuItem(value: "+1", child: Text("+1")),
                              ],
                              onChanged: (value) {
                                setState(() => countryCode = value!);
                              },
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  counterText: "",
                                  hintText: translations[appLang]!["phoneHint"]!,
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  if (value.length == 10) {
                                    setState(() => phoneErrorText = null);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (phoneErrorText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5, left: 10),
                          child: Text(
                            phoneErrorText!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),

                      const SizedBox(height: 8),

                      Text(
                        translations[appLang]!["otpInfo"]!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),

                      const SizedBox(height: 20),

                      // --- GET OTP BUTTON ---
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
                          onPressed: _isLoading ? null : () async {
                            final phone = phoneController.text.trim();

                            if (!validatePhoneNumber(phone)) {
                              setState(() {
                                phoneErrorText = translations[appLang]!["phoneError"];
                              });
                              return;
                            }

                            setState(() {
                              _isLoading = true;
                              phoneErrorText = null;
                            });

                            try {
                              // 1. Save language preference
                              await StorageService.saveLanguage(appLang);

                              // 2. Save phone number for OTP screen
                              await StorageService.saveAuthDetails(
                                email: "",
                                phone: phone,
                              );

                              // 3. Request OTP from backend
                              final response = await HttpService.post(
                                "auth/request-login-otp",
                                {"phoneNumber": phone},
                              );

                              if (!mounted) return;

                              // 4. Navigate to OTP screen (pass true for login flow)
                              Navigator.pushNamed(context, AppRoutes.otp, arguments: true);
                            } catch (e) {
                              if (!mounted) return;
                              
                              setState(() {
                                _isLoading = false;
                                phoneErrorText = e.toString().replaceFirst("Exception: ", "");
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceFirst("Exception: ", "")),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          },
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
                                  translations[appLang]!["otpBtn"]!,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // --- EMAIL LOGIN LINK ---
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.emailLogin);
                          },
                          child: Text(
                            translations[appLang]!["emailLogin"]!,
                            style: const TextStyle(
                              color: AppColors.brandGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        translations[appLang]!["terms"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),

                      const SizedBox(height: 15),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "or ",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.signup);
                              },
                              child: Text(
                                translations[appLang]!["signUp"]!,
                                style: const TextStyle(
                                  color: AppColors.brandGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}