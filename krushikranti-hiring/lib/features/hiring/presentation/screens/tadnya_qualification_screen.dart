import 'dart:ui';
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Text(
              AppStrings.tr('enter_qualification'), 
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
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
                      _buildLabel(AppStrings.tr('highest_qual')),
                      _buildTextField(_qualificationController, "A.sc"),

                      _buildLabel(AppStrings.tr('agri_spec')),
                      _buildTextField(_specializationController, "Crop"),

                      _buildLabel(AppStrings.tr('years_exp')),
                      _buildTextField(
                        _experienceController, 
                        "5", 
                        isNumber: true,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),

                      _buildLabel(AppStrings.tr('pref_area')),
                      _buildTextField(_workAreaController, "District / Taluka"),
                      
                      _buildLabel(AppStrings.tr('field_visit')),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
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

                      _buildUploadButton(
                        label: _resumeFileName ?? AppStrings.tr('upload_resume'), 
                        icon: Icons.upload_file,
                        onTap: _pickDocument,
                        isSelected: _resumeFileName != null,
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
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

  // --- Helper Widgets ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, {
    bool isNumber = false, 
    List<TextInputFormatter>? inputFormatters, 
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: inputFormatters, 
      style: GoogleFonts.poppins(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
      ),
      validator: (val) => val!.isEmpty ? AppStrings.tr('required') : null, 
    );
  }

  Widget _buildUploadButton({required String label, required IconData icon, required VoidCallback onTap, required bool isSelected}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: DashedBorderPainter(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: isSelected ? Colors.green : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Icon(isSelected ? Icons.check_circle : icon, color: isSelected ? Colors.green : Colors.indigo),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.grey[400]!..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final Path path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));
    final Path dashPath = Path();
    double dashWidth = 6.0; double dashSpace = 4.0; double distance = 0.0;
    for (final PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(pathMetric.extractPath(distance, distance + dashWidth), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}