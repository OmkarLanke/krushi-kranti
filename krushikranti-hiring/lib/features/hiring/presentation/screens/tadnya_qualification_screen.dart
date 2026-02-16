import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart'; 
import 'submission_success_screen.dart';
import '../../../../core/app_localizations.dart';

class TadnyaQualificationScreen extends StatefulWidget {
  const TadnyaQualificationScreen({super.key});

  @override
  State<TadnyaQualificationScreen> createState() => _TadnyaQualificationScreenState();
}

class _TadnyaQualificationScreenState extends State<TadnyaQualificationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _qualificationController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _workAreaController = TextEditingController();

  String? _fieldVisitValue;
  String? _resumeFileName;

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _resumeFileName = result.files.single.name;
      });
    }
  }

  // --- HELPER WIDGETS ---
  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0, top: 20.0),
    child: Row(
      children: [
        Text(text, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blueGrey[900])),
        if (required) const SizedBox(width: 4),
        if (required) const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _textField(TextEditingController controller, String hint, {bool required = true, bool isNumber = false, List<TextInputFormatter>? inputFormatters, IconData? prefixIcon}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50], // Light background
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[600], size: 22) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
      validator: (val) {
        if (!required) return null;
        return (val == null || val.trim().isEmpty) ? AppStrings.tr('required') : null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Text(
              AppStrings.tr('enter_qualification'), 
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(AppStrings.tr('highest_qual'), required: true),
                      _textField(_qualificationController, "M.Sc Agri", prefixIcon: Icons.school_outlined),

                      _label(AppStrings.tr('agri_spec'), required: true),
                      _textField(_specializationController, "Crop Science", prefixIcon: Icons.grass_outlined),

                      _label(AppStrings.tr('years_exp'), required: true),
                      _textField(
                        _experienceController, 
                        "5", 
                        isNumber: true,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        prefixIcon: Icons.work_history_outlined
                      ),

                      _label(AppStrings.tr('pref_area'), required: true),
                      _textField(_workAreaController, "District / Taluka", prefixIcon: Icons.map_outlined),
                      
                      _label(AppStrings.tr('field_visit'), required: true),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          prefixIcon: const Icon(Icons.nature_people_outlined, color: Colors.grey, size: 22),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5)),
                        ),
                        // ✅ FIXED: String Interpolation
                        hint: Text("${AppStrings.tr('yes')} / ${AppStrings.tr('no')}", style: GoogleFonts.poppins(color: Colors.grey[400])),
                        
                        // Use current value
                        value: _fieldVisitValue, 
                        
                        items: [
                          DropdownMenuItem(value: "Yes", child: Text(AppStrings.tr('yes'))),
                          DropdownMenuItem(value: "No", child: Text(AppStrings.tr('no'))),
                        ],
                        onChanged: (val) => setState(() => _fieldVisitValue = val),
                        validator: (val) => val == null ? AppStrings.tr('required') : null,
                      ),

                      const SizedBox(height: 30),

                      _label(AppStrings.tr('resume'), required: true),
                      InkWell(
                        onTap: _pickDocument,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _resumeFileName ?? AppStrings.tr('upload_resume'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: _resumeFileName != null ? Colors.black : Colors.grey[600],
                                    fontWeight: _resumeFileName != null ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Icon(_resumeFileName != null ? Icons.check_circle : Icons.upload_file, color: _resumeFileName != null ? Colors.green : Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      if (_resumeFileName == null) Padding(
                        padding: const EdgeInsets.only(top:8.0, left: 4),
                        child: Text(AppStrings.tr('resume_required_hint'), style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              if (_fieldVisitValue == null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tr('required'))));
                                return;
                              }
                              if (_resumeFileName == null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tr('resume_required'))));
                                return;
                              }
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const SubmissionSuccessScreen()),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            AppStrings.tr('submit_form'), 
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
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
}