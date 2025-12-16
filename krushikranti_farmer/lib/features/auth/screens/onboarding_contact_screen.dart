import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';

class OnboardingContactScreen extends StatefulWidget {
  const OnboardingContactScreen({super.key});

  @override
  State<OnboardingContactScreen> createState() => _OnboardingContactScreenState();
}

class _OnboardingContactScreenState extends State<OnboardingContactScreen> {
  // Controllers
  final TextEditingController _altPhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // Read Only
  final TextEditingController _phoneController = TextEditingController(); // Read Only

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.contactDetails, 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // --- STEPPER (Step 2 of 3) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Step 1: Done
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.brandGreen,
                  child: Icon(Icons.check, color: Colors.white, size: 16),
                ),
                Container(width: 30, height: 2, color: AppColors.brandGreen),
                
                // Step 2: Active (Contact)
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.brandGreen,
                  child: Text("2", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                Container(width: 30, height: 2, color: Colors.grey.shade300),

                // Step 3: Inactive (Address)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey.shade300,
                  child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // --- 1. EMAIL (Read Only) - First ---
            Text(l10n.emailLabel, style: _labelStyle()),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _emailController,
              hint: "",
              icon: Icons.email,
              enabled: false, // 🔒 LOCKED
              fillColor: Colors.grey.shade100,
            ),
            const SizedBox(height: 20),

            // --- 2. PHONE (Read Only) - Second ---
            Text(l10n.phoneLabel, style: _labelStyle()),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _phoneController,
              hint: "",
              icon: Icons.phone_android,
              enabled: false, // 🔒 LOCKED
              fillColor: Colors.grey.shade100,
            ),
            
            const SizedBox(height: 20),

            // --- 3. ALTERNATE MOBILE (Editable) - Third ---
            Text(l10n.altPhone, style: _labelStyle()),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _altPhoneController,
              hint: l10n.altPhoneHint,
              icon: Icons.phone_in_talk,
              enabled: true, // User can type
            ),

            const SizedBox(height: 40),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _saveAndContinue(l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  l10n.continueBtn, 
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() => const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

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
          // Grey border if disabled, Green if enabled
          color: enabled ? AppColors.brandGreen : Colors.grey.shade400, 
          width: 1
        ),
        borderRadius: BorderRadius.circular(12), 
      ),
      child: TextField(
        controller: controller,
        readOnly: !enabled, // Prevents typing if false
        keyboardType: TextInputType.phone,
        style: TextStyle(color: enabled ? Colors.black : Colors.grey.shade700),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          suffixIcon: icon != null 
            ? Icon(icon, color: enabled ? AppColors.brandGreen : Colors.grey) 
            : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}