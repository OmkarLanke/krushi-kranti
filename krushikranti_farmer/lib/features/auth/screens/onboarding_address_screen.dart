import 'package:flutter/material.dart';
import 'package:krushikranti_farmer/core/constants/app_colors.dart';
import 'package:krushikranti_farmer/core/constants/app_routes.dart';
import 'package:krushikranti_farmer/core/services/storage_service.dart';
import '../../../core/services/http_service.dart';

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
      "subtitle":
          "आपल्या परिसरात काय चालले आहे हे समजण्यासाठी लोकेशन ऑन ठेवा",
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
            dateOfBirth = "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
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
      final response = await HttpService.put(
        "farmer/profile/my-details",
        requestBody,
      );

      if (!mounted) return;

      // Check subscription status - if not subscribed, go to welcome pages
      final isSubscribed = await StorageService.isSubscribed();
      
      if (!mounted) return;

      if (isSubscribed) {
        // Already subscribed - go to dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (route) => false,
        );
      } else {
        // Not subscribed - show welcome pages
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcome,
          (route) => false,
        );
      }
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
      final response = await HttpService.get("farmer/profile/address/lookup?pincode=$pincode");
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.pop(context),
              ),

              const SizedBox(height: 10),

              // Title
              Center(
                child: Text(
                  t[appLang]!["title"]!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Center(
                child: Text(
                  t[appLang]!["subtitle"]!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- UPDATED STEPPER INDICATOR ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Step 1 (Done)
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.brandGreen,
                    child: Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                  Container(height: 2, width: 40, color: AppColors.brandGreen),

                  // Step 2 (Done)
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.brandGreen,
                    child: Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                  Container(height: 2, width: 40, color: AppColors.brandGreen),

                  // Step 3 (Active)
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.brandGreen,
                    child: Text(
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

              const SizedBox(height: 20),

              Center(
                child: Image.asset(
                  "assets/images/auth/location.png",
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 20),

              _label(t[appLang]!["pincode"]!),
              Row(
                children: [
                  Expanded(
                    child: _textField(pincodeController, t[appLang]!["pincode"]!),
                  ),
                  const SizedBox(width: 10),
                  _isLookingUp
                      ? const SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _lookupAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Lookup"),
                        ),
                ],
              ),

              const SizedBox(height: 16),

              _label(t[appLang]!["village"]!),
              _villageDropdown(),

              const SizedBox(height: 16),

              _label(t[appLang]!["taluka"]!),
              _textField(talukaController, t[appLang]!["taluka"]!, enabled: false),

              const SizedBox(height: 16),

              _label(t[appLang]!["district"]!),
              _textField(districtController, t[appLang]!["district"]!, enabled: false),

              const SizedBox(height: 16),

              _label(t[appLang]!["state"]!),
              _textField(stateController, t[appLang]!["state"]!, enabled: false),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveAndContinue,
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
                          t[appLang]!["done"]!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: hint.toLowerCase().contains("pincode") ? TextInputType.number : TextInputType.text,
        maxLength: hint.toLowerCase().contains("pincode") ? 6 : null,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          counterText: "",
        ),
        onChanged: hint.toLowerCase().contains("pincode") && enabled
            ? (value) {
                if (value.length == 6) {
                  _lookupAddress();
                }
              }
            : null,
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _villageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: villageList.isEmpty ? Colors.grey.shade200 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            villageList.isEmpty 
                ? "Enter pincode to load villages" 
                : t[appLang]!["village"]!,
          ),
          value: selectedVillage,
          isExpanded: true,
          items: villageList.map((v) {
            return DropdownMenuItem(
              value: v,
              child: Text(v),
            );
          }).toList(),
          onChanged: villageList.isEmpty ? null : (v) {
            setState(() => selectedVillage = v);
          },
        ),
      ),
    );
  }
}