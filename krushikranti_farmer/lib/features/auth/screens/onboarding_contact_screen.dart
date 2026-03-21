import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/form_stepper.dart';

class OnboardingContactScreen extends StatefulWidget {
  const OnboardingContactScreen({super.key});

  @override
  State<OnboardingContactScreen> createState() =>
      _OnboardingContactScreenState();
}

class _OnboardingContactScreenState extends State<OnboardingContactScreen> {
  // Controllers
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(); // Read Only
  final TextEditingController _phoneController =
      TextEditingController(); // Read Only

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // LOAD DATA FROM STORAGE
  Future<void> _loadSavedData() async {
    final data = await StorageService.getUserDetails();
    if (mounted) {
      setState(() {
        _emailController.text = data['email'] ?? "";
        _phoneController.text = data['phone'] ?? "";
      });
    }
  }

  Future<void> _saveAndContinue(AppLocalizations l10n) async {
    // 1. Save Alternate Phone
    await StorageService.saveContactDetails(
      altPhone: _altPhoneController.text.trim(),
    );

    // 2. Navigate to Address Screen
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.onboardingAddress);
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
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.contactDetails,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // --- GLOBAL ONBOARDING STEPPER (Steps 1–5) ---
            const OnboardingStepProgressBarConnected(),
            const SizedBox(height: 32),

            // --- 1. EMAIL (Read Only) - First ---
            Text(l10n.emailLabel, style: _labelStyle()),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _emailController,
              hint: "",
              icon: Icons.email_outlined,
              enabled: false, // 🔒 LOCKED
              fillColor: Colors.grey.shade100,
            ),
            const SizedBox(height: 20),

            // --- 2. PHONE (Read Only) - Second ---
            Text(l10n.phoneLabel, style: _labelStyle()),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _phoneController,
              hint: "",
              icon: Icons.phone_android_outlined,
              enabled: false, // 🔒 LOCKED
              fillColor: Colors.grey.shade100,
            ),

            const SizedBox(height: 20),

            // --- 3. ALTERNATE MOBILE (Editable) - Third ---
            Text(l10n.altPhone, style: _labelStyle()),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _altPhoneController,
              hint: l10n.altPhoneHint,
              icon: Icons.phone_in_talk_outlined,
              enabled: true, // User can type
            ),

            const SizedBox(height: 32),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _saveAndContinue(l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
                label: Text(
                  l10n.continueBtn,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        letterSpacing: 0.2,
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool enabled = true,
    Color? fillColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white,
        border: Border.all(
          color: enabled ? Colors.grey.shade300 : Colors.grey.shade400,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.brandGreen.withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: enabled ? AppColors.brandGreen : Colors.grey.shade600,
              ),
            ),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: !enabled,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: enabled ? Colors.black87 : Colors.grey.shade700,
              ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
