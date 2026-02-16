import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tadnya_qualification_screen.dart';
import 'field_officer_qualification_screen.dart';
import 'shopkeeper_qualification_screen.dart';
// Import localization
import '../../../../core/app_localizations.dart';

class PersonalDetailScreen extends StatefulWidget {
  final String roleType;
  const PersonalDetailScreen({super.key, required this.roleType});

  @override
  State<PersonalDetailScreen> createState() => _PersonalDetailScreenState();
}

class _PersonalDetailScreenState extends State<PersonalDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _aadhaarController = TextEditingController();
  bool _isAadhaarVisible = false;
  bool _isTermsAccepted = false;

  @override
  Widget build(BuildContext context) {
    // Listen to language changes
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
            centerTitle: true,
            title: Text(AppStrings.tr('personal_detail_title'), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      
                      _buildLabel(AppStrings.tr('enter_full_name')),
                      _buildTextField(
                        controller: _nameController, 
                        hint: "Ramesh kakade",
                        validator: (val) {
                          if (val == null || val.isEmpty) return AppStrings.tr('required');
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(val)) return AppStrings.tr('alphabets_only');
                          return null;
                        },
                      ),

                      _buildLabel(AppStrings.tr('enter_mobile')),
                      _buildTextField(
                        controller: _mobileController, 
                        hint: "7748548548",
                        inputType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                        validator: (val) {
                          if (val == null || val.isEmpty) return AppStrings.tr('required');
                          if (val.length != 10) return AppStrings.tr('invalid_mobile');
                          return null;
                        },
                      ),

                      _buildLabel(AppStrings.tr('dob')),
                      _buildTextField(
                        controller: _dobController,
                        hint: "DD/MM/YYYY",
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime(1990),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _dobController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                            });
                          }
                        },
                      ),

                      _buildLabel(AppStrings.tr('enter_aadhaar')),
                      _buildTextField(
                        controller: _aadhaarController,
                        hint: "1234 5678 9012",
                        inputType: TextInputType.number,
                        obscureText: !_isAadhaarVisible,
                        maxLength: 12,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        suffixIcon: IconButton(
                          icon: Icon(_isAadhaarVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          onPressed: () => setState(() => _isAadhaarVisible = !_isAadhaarVisible),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return AppStrings.tr('required');
                          if (val.length != 12) return AppStrings.tr('invalid_aadhaar');
                          return null;
                        },
                      ),

                      const SizedBox(height: 25),

                      Row(
                        children: [
                          SizedBox(height: 24, width: 24, child: Checkbox(value: _isTermsAccepted, activeColor: const Color(0xFFFFD700), checkColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), onChanged: (val) => setState(() => _isTermsAccepted = val ?? false))),
                          const SizedBox(width: 12),
                          Expanded(child: Text(AppStrings.tr('terms_agree'), style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]))),
                        ],
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(AppStrings.tr('next'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0, top: 16.0), child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)));
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType inputType = TextInputType.text, bool obscureText = false, Widget? suffixIcon, VoidCallback? onTap, bool readOnly = false, String? Function(String?)? validator, int? maxLength, List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: controller, keyboardType: inputType, obscureText: obscureText, readOnly: readOnly, onTap: onTap, maxLength: maxLength, inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 16),
      decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.poppins(color: Colors.grey[400]), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), suffixIcon: suffixIcon, counterText: "", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 1.5))),
      validator: validator ?? (val) => (val == null || val.isEmpty) ? AppStrings.tr('required') : null,
    );
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      if (!_isTermsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tr('required'))));
        return;
      }
      if (widget.roleType == 'tadnya') { Navigator.push(context, MaterialPageRoute(builder: (context) => const TadnyaQualificationScreen())); } 
      else if (widget.roleType == 'officer') { Navigator.push(context, MaterialPageRoute(builder: (context) => const FieldOfficerQualificationScreen())); } 
      else if (widget.roleType == 'shopkeeper') { Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopkeeperQualificationScreen())); }
    }
  }
}