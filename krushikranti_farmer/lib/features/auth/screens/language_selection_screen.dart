import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/storage_service.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String selectedLang = "en"; // default

  @override
  void initState() {
    super.initState();
    // Load saved language preference
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    // Load saved language from storage
    final String? savedLang = await StorageService.getLanguage();
    if (savedLang != null && mounted) {
      setState(() {
        selectedLang = savedLang;
      });
    }
  }

  final Map<String, Map<String, String>> translations = {
    "en": {
      "title": "Choose Your Preferred Language",
      "subtitle": "Please Select Your Language",
      "btn": "Save & Continue",
    },
    "hi": {
      "title": "अपनी पसंदीदा भाषा चुनें",
      "subtitle": "कृपया अपनी भाषा चुनें",
      "btn": "सेव करें और आगे बढ़ें",
    },
    "mr": {
      "title": "आपली आवडती भाषा निवडा",
      "subtitle": "कृपया आपली भाषा निवडा",
      "btn": "जतन करा आणि पुढे चला",
    }
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Select Language",
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // App Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.brandGreen.withOpacity(0.1),
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
                    child: Image.asset(
                      "assets/images/logo/krushi_logo.png",
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.language_rounded, size: 80, color: AppColors.brandGreen),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  translations[selectedLang]!["title"]!,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  translations[selectedLang]!["subtitle"]!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 28),

                // Language Options
                _langTile("mr", "मराठी"),
                const SizedBox(height: 12),
                _langTile("hi", "हिंदी"),
                const SizedBox(height: 12),
                _langTile("en", "English"),

                const SizedBox(height: 32),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // ✅ UPDATED LOGIC:
                      // 1. Tell Provider to change language globally
                      // (This also saves it to StorageService automatically)
                      context.read<LocaleProvider>().setLocale(Locale(selectedLang));

                      // 2. Navigate to Login
                      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                    },
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    label: Text(
                      translations[selectedLang]!["btn"]!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
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

  // Modern Radio Button
  Widget _langTile(String code, String title) {
    final isSelected = selectedLang == code;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedLang = code;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.brandGreen : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.brandGreen.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.brandGreen : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.brandGreen : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.black87 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}