import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:krushikranti_farmer/core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_dropdown_field.dart';
import '../../../core/widgets/form_stepper.dart';
import '../../../core/onboarding/onboarding_controller.dart';
import 'package:provider/provider.dart';

class OnboardingAddressScreen extends StatefulWidget {
  const OnboardingAddressScreen({super.key});

  @override
  State<OnboardingAddressScreen> createState() =>
      _OnboardingAddressScreenState();
}

class _OnboardingAddressScreenState extends State<OnboardingAddressScreen> {
  String appLang = "en";
  bool _isLoading = false;
  bool _isLookingUp = false;

  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController talukaController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController stateController = TextEditingController();

  String? selectedVillage;
  List<String> villageList = [];

  final Map<String, Map<String, String>> t = {
    "en": {
      "title": "Select Your Location",
      "subtitle":
          "Switch on your location to stay in tune with what's happening in your area",
      "pincode": "Pincode",
      "village": "Village",
      "taluka": "Taluka",
      "district": "District",
      "state": "State",
      "done": "Done",
    },
    "hi": {
      "title": "अपना स्थान चुनें",
      "subtitle":
          "अपने क्षेत्र में क्या हो रहा है, इसके लिए अपना लोकेशन ऑन रखें",
      "pincode": "पिनकोड",
      "village": "गांव",
      "taluka": "तहसील",
      "district": "ज़िला",
      "state": "राज्य",
      "done": "हो गया",
    },
    "mr": {
      "title": "आपले स्थान निवडा",
      "subtitle": "आपल्या परिसरात काय चालले आहे हे समजण्यासाठी लोकेशन ऑन ठेवा",
      "pincode": "पिनकोड",
      "village": "गाव",
      "taluka": "तालुका",
      "district": "जिल्हा",
      "state": "राज्य",
      "done": "पूर्ण",
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

  Future<void> _saveAndContinue() async {
    // Validate required fields
    if (pincodeController.text.trim().isEmpty || selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter pincode and select village"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get personal details from storage
      final userData = await StorageService.getUserDetails();
      final firstName = userData['firstName'] ?? "";
      final lastName = userData['lastName'] ?? "";
      final dob = userData['dob'] ?? "";
      final gender = userData['gender'] ?? "";
      final altPhone = userData['altPhone'] ?? "";

      // Parse date from DD/MM/YYYY to YYYY-MM-DD
      String dateOfBirth = "";
      if (dob.isNotEmpty) {
        try {
          final parts = dob.split("/");
          if (parts.length == 3) {
            dateOfBirth =
                "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
          }
        } catch (e) {
          throw Exception("Invalid date format. Please use DD/MM/YYYY");
        }
      }

      // Map gender string to backend enum
      String genderValue = "MALE"; // Default
      if (gender.toUpperCase() == "FEMALE") {
        genderValue = "FEMALE";
      } else if (gender.toUpperCase() == "OTHER") {
        genderValue = "OTHER";
      }

      // Prepare request body
      final requestBody = {
        "firstName": firstName,
        "lastName": lastName,
        "dateOfBirth": dateOfBirth,
        "gender": genderValue,
        "alternatePhone": altPhone.isEmpty ? null : altPhone,
        "pincode": pincodeController.text.trim(),
        "village": selectedVillage!,
      };

      // Call PUT /farmer/profile/my-details
      await HttpService.put(
        "farmer/profile/my-details",
        requestBody,
      );

      if (!mounted) return;

      await context
          .read<OnboardingController>()
          .completePersonalAndGoToFarm(context);
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

  Future<void> _lookupAddress() async {
    final pincode = pincodeController.text.trim();

    if (pincode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 6-digit pincode"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLookingUp = true;
    });

    try {
      final response = await HttpService.get(
          "farmer/profile/address/lookup?pincode=$pincode");
      final data = response['data'] ?? {};

      if (mounted && data.isNotEmpty) {
        setState(() {
          districtController.text = data['district'] ?? "";
          talukaController.text = data['taluka'] ?? "";
          stateController.text = data['state'] ?? "";
          villageList = List<String>.from(data['villages'] ?? []);
          selectedVillage = null; // Reset selection
          _isLookingUp = false;
        });
      } else {
        throw Exception("No address found for this pincode");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLookingUp = false;
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
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t[appLang]!["title"]!,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(
                  t[appLang]!["subtitle"]!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FormStepper(
                stepStatuses: context.watch<OnboardingController>().stepStatuses,
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brandGreen.withOpacity(0.15),
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
                    "assets/images/auth/location.png",
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.location_on_rounded,
                        size: 60,
                        color: AppColors.brandGreen),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: pincodeController,
                      label: t[appLang]!["pincode"]!,
                      hint: t[appLang]!["pincode"]!,
                      prefixIcon: Icons.location_on_outlined,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      onChanged: (value) {
                        if (value.length == 6) {
                          _lookupAddress();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _isLookingUp
                      ? Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(
                              bottom: 2), // align with text field roughly
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.brandGreen),
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _lookupAddress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandGreen,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.search_rounded,
                                  color: Colors.white, size: 18),
                              label: Text(
                                "Lookup",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 16),
              CustomDropdownField<String>(
                items: villageList,
                value: selectedVillage,
                enabled: villageList.isNotEmpty,
                onChanged: villageList.isEmpty
                    ? null
                    : (v) => setState(() => selectedVillage = v),
                hint: villageList.isEmpty
                    ? "Enter pincode to load villages"
                    : t[appLang]!["village"]!,
                label: t[appLang]!["village"]!,
                prefixIcon: Icons.home_outlined,
                itemLabelBuilder: (v) => v,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: talukaController,
                label: t[appLang]!["taluka"]!,
                hint: t[appLang]!["taluka"]!,
                prefixIcon: Icons.business_outlined,
                enabled: false,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: districtController,
                label: t[appLang]!["district"]!,
                hint: t[appLang]!["district"]!,
                prefixIcon: Icons.map_outlined,
                enabled: false,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: stateController,
                label: t[appLang]!["state"]!,
                hint: t[appLang]!["state"]!,
                prefixIcon: Icons.public_outlined,
                enabled: false,
              ),
              const SizedBox(height: 32),
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                  label: Text(
                    t[appLang]!["done"]!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveAndContinue,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
