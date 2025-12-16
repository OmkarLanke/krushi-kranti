import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';

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
    Navigator.pushNamed(context, AppRoutes.onboardingContact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BACK BUTTON
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.pop(context),
                ),

                // TITLE
                Center(
                  child: Text(
                    text[appLang]!["title"]!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ UPDATED STEPPER (1 Active, 2 & 3 Inactive)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Step 1: Active (Green "1")
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.brandGreen,
                      child: Text(
                        "1",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 2,
                      color: Colors.grey.shade300,
                    ), // Grey Line

                    // Step 2: Inactive (Grey "2")
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade300,
                      child: const Text(
                        "2",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 2,
                      color: Colors.grey.shade300,
                    ), // Grey Line

                    // Step 3: Inactive (Grey "3")
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade300,
                      child: const Text(
                        "3",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
                Text(text[appLang]!["firstName"]!, style: _labelStyle()),
                const SizedBox(height: 5),
                _inputField(
                  controller: firstNameController,
                  hint: text[appLang]!["firstNameHint"]!,
                ),

                const SizedBox(height: 20),

                // 2. LAST NAME
                Text(text[appLang]!["lastName"]!, style: _labelStyle()),
                const SizedBox(height: 5),
                _inputField(
                  controller: lastNameController,
                  hint: text[appLang]!["lastNameHint"]!,
                ),

                const SizedBox(height: 20),

                // 3. DATE OF BIRTH (Clickable)
                Text(text[appLang]!["dob"]!, style: _labelStyle()),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: _inputField(
                      controller: dobController,
                      hint: text[appLang]!["dobHint"]!,
                      icon: Icons.calendar_month,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 4. GENDER (Dropdown)
                Text(text[appLang]!["gender"]!, style: _labelStyle()),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.brandGreen, width: 1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedGender,
                      hint: Text(
                        text[appLang]!["genderHint"]!,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.brandGreen,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: "Male",
                          child: Text(text[appLang]!["male"]!),
                        ),
                        DropdownMenuItem(
                          value: "Female",
                          child: Text(text[appLang]!["female"]!),
                        ),
                        DropdownMenuItem(
                          value: "Other",
                          child: Text(text[appLang]!["other"]!),
                        ),
                      ],
                      onChanged: (val) => setState(() => selectedGender = val),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saveAndContinue,
                    child: Text(
                      text[appLang]!["continue"]!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

  TextStyle _labelStyle() =>
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.brandGreen, width: 1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          suffixIcon:
              icon != null ? Icon(icon, color: AppColors.brandGreen) : null,
        ),
      ),
    );
  }
}