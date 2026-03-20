import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_dropdown_field.dart';
import '../../../core/widgets/form_stepper.dart';
import '../../../core/onboarding/onboarding_controller.dart';
import 'package:provider/provider.dart';

class OnboardingPersonalScreen extends StatefulWidget {
  const OnboardingPersonalScreen({super.key});

  @override
  State<OnboardingPersonalScreen> createState() =>
      _OnboardingPersonalScreenState();
}

class _OnboardingPersonalScreenState extends State<OnboardingPersonalScreen> {
  File? selectedImageFile; // For mobile
  Uint8List? selectedImageBytes; // For web
  final ImagePicker picker = ImagePicker();

  String appLang = "en";

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dobController = TextEditingController();
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    loadLang();
  }

  Future<void> loadLang() async {
    String? lang = await StorageService.getLanguage();
    setState(() => appLang = lang ?? "en");
  }

  // ------------ LANGUAGE TEXT -------------
  final Map<String, Map<String, String>> text = {
    "en": {
      "title": "Personal Details",
      "firstName": "First Name",
      "lastName": "Last Name",
      "firstNameHint": "Enter First Name",
      "lastNameHint": "Enter Last Name",
      "dob": "Date of Birth",
      "dobHint": "DD/MM/YYYY",
      "gender": "Gender",
      "genderHint": "Select Gender",
      "male": "Male",
      "female": "Female",
      "other": "Other",
      "continue": "Save & Continue",
      "error": "Please fill all details",
    },
    "hi": {
      "title": "व्यक्तिगत विवरण",
      "firstName": "पहला नाम",
      "lastName": "अंतिम नाम",
      "firstNameHint": "पहला नाम दर्ज करें",
      "lastNameHint": "अंतिम नाम दर्ज करें",
      "dob": "जन्म तिथि",
      "dobHint": "DD/MM/YYYY",
      "gender": "लिंग",
      "genderHint": "लिंग चुनें",
      "male": "पुरुष",
      "female": "महिला",
      "other": "अन्य",
      "continue": "सेव करें और आगे बढ़ें",
      "error": "कृपया सभी विवरण भरें",
    },
    "mr": {
      "title": "वैयक्तिक तपशील",
      "firstName": "पहिले नाव",
      "lastName": "आडनाव",
      "firstNameHint": "पहिले नाव टाका",
      "lastNameHint": "आडनाव टाका",
      "dob": "जन्म तारीख",
      "dobHint": "DD/MM/YYYY",
      "gender": "लिंग",
      "genderHint": "लिंग निवडा",
      "male": "पुरुष",
      "female": "स्त्री",
      "other": "इतर",
      "continue": "जतन करा आणि पुढे चला",
      "error": "कृपया सर्व माहिती भरा",
    }
  };

  // ---------- CAMERA PICKER ----------
  Future<void> pickImage() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        setState(() => selectedImageBytes = bytes);
      } else {
        setState(() => selectedImageFile = File(file.path));
      }
    }
  }

  // ✅ DATE PICKER LOGIC
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // ✅ SAVE DATA FUNCTION
  Future<void> _saveAndContinue() async {
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        dobController.text.isEmpty ||
        selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text[appLang]!["error"]!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save to Storage
    await StorageService.savePersonalDetails(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      dob: dobController.text.trim(),
      gender: selectedGender!,
      profilePicPath: selectedImageFile?.path,
    );

    if (!mounted) return;
    // Personal step spans multiple sub-screens (Contact -> Address).
    // The actual backend update is done in Address screen, which then
    // completes Step 1 and navigates to Farm.
    Navigator.pushNamed(context, AppRoutes.onboardingContact);
  }

  @override
  Widget build(BuildContext context) {
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
          text[appLang]!["title"]!,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await context
                  .read<OnboardingController>()
                  .skipPersonalAndEndOnboarding(context);
            },
            child: Text(
              'Skip',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
                const SizedBox(height: 10),

                // ✅ GLOBAL ONBOARDING STEPPER (Steps 1–5)
                  FormStepper(
                    stepStatuses:
                        context.watch<OnboardingController>().stepStatuses,
                  ),

                const SizedBox(height: 30),

                // PROFILE IMAGE
                Center(
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.brandGreen,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: selectedImageBytes != null
                            ? Image.memory(
                                selectedImageBytes!,
                                fit: BoxFit.cover,
                              )
                            : selectedImageFile != null
                                ? Image.file(
                                    selectedImageFile!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: AppColors.brandGreen,
                                    size: 40,
                                  ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 1. FIRST NAME
                CustomTextField(
                  controller: firstNameController,
                  label: text[appLang]!["firstName"]!,
                  hint: text[appLang]!["firstNameHint"]!,
                  prefixIcon: Icons.person_outline_rounded,
                ),

                const SizedBox(height: 20),

                // 2. LAST NAME
                CustomTextField(
                  controller: lastNameController,
                  label: text[appLang]!["lastName"]!,
                  hint: text[appLang]!["lastNameHint"]!,
                  prefixIcon: Icons.person_outline_rounded,
                ),

                const SizedBox(height: 20),

                // 3. DATE OF BIRTH (Clickable)
                GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: dobController,
                      label: text[appLang]!["dob"]!,
                      hint: text[appLang]!["dobHint"]!,
                      prefixIcon: Icons.calendar_month_rounded,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. GENDER (Dropdown)
                CustomDropdownField<String>(
                  items: const ["Male", "Female", "Other"],
                  value: selectedGender,
                  onChanged: (val) => setState(() => selectedGender = val),
                  hint: text[appLang]!["genderHint"]!,
                  label: text[appLang]!["gender"]!,
                  prefixIcon: Icons.wc_rounded,
                  itemLabelBuilder: (val) {
                    if (val == "Male") return text[appLang]!["male"]!;
                    if (val == "Female") return text[appLang]!["female"]!;
                    return text[appLang]!["other"]!;
                  },
                ),

                const SizedBox(height: 40),

                // SAVE BUTTON
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
                    icon: const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                    label: Text(
                      text[appLang]!["continue"]!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    onPressed: _saveAndContinue,
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
}
