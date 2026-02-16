import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/app_localizations.dart';
import '../../data/job_application_service.dart';
import 'submission_success_screen.dart';

class ApplicationFormScreen extends StatefulWidget {
  const ApplicationFormScreen({super.key});

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _location = TextEditingController();
  String? _resumeFileName;
  PlatformFile? _resumeFile;
  bool _isSubmitting = false;

  // Education
  String? _highestQualification;
  final TextEditingController _institution = TextEditingController();
  final TextEditingController _yearOfCompletion = TextEditingController();

  // Experience
  final TextEditingController _yearsExperience = TextEditingController();
  final TextEditingController _relevantExperience = TextEditingController();
  final TextEditingController _lastEmployerRole = TextEditingController();

  // Extras
  String? _willingForFieldVisit;
  String? _vehicleAvailable;
  bool _consent = false;
  int _step = 0; // 0 = Personal, 1 = Education/Experience

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        _resumeFile = result.files.single;
        _resumeFileName = _resumeFile!.name;
      });
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _mobile.dispose();
    _email.dispose();
    _dob.dispose();
    _location.dispose();
    _institution.dispose();
    _yearOfCompletion.dispose();
    _yearsExperience.dispose();
    _relevantExperience.dispose();
    _lastEmployerRole.dispose();
    super.dispose();
  }

  Widget _label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
        child: Row(
          children: [
            Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            if (required) const SizedBox(width: 4),
            if (required) const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _textField(TextEditingController controller, String hint, {bool required = true, List<TextInputFormatter>? inputFormatters, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
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
      validator: (val) {
        if (!required) return null;
        return (val == null || val.trim().isEmpty) ? AppStrings.tr('required') : null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr('apply_title'), style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal
                  _label(AppStrings.tr('personal_details')),
                  if (_step == 0) ...[
                    _label(AppStrings.tr('full_name'), required: true),
                    _textField(_fullName, AppStrings.tr('enter_full_name'), required: true),
                    _label(AppStrings.tr('mobile_no'), required: true),
                    // Mobile with +91 prefix and 10 digit limit
                    TextFormField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: InputDecoration(
                        hintText: AppStrings.tr('enter_mobile'),
                        prefixText: '+91 ',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return AppStrings.tr('required');
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) return AppStrings.tr('invalid_phone');
                        return null;
                      },
                    ),
                    _label(AppStrings.tr('email'), required: true),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: AppStrings.tr('enter_email'),
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return AppStrings.tr('required');
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(val.trim())) return AppStrings.tr('invalid_email');
                      return null;
                    },
                  ),
                  _label(AppStrings.tr('dob'), required: true),
                  // Date picker field
                  TextFormField(
                    controller: _dob,
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        _dob.text = '${picked.day}/${picked.month}/${picked.year}';
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'DD/MM/YYYY',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return AppStrings.tr('required');
                      // basic date format check
                      final parts = val.split('/');
                      if (parts.length != 3) return AppStrings.tr('invalid_date');
                      final year = int.tryParse(parts[2]);
                      if (year == null || year < 1900 || year > DateTime.now().year) return AppStrings.tr('invalid_date');
                      return null;
                    },
                  ),
                    _label(AppStrings.tr('location'), required: true),
                    _textField(_location, AppStrings.tr('village_taluka_district'), required: true),
                    _label(AppStrings.tr('resume'), required: true),
                  InkWell(
                    onTap: _pickResume,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(_resumeFileName ?? AppStrings.tr('upload_resume'), style: GoogleFonts.poppins(color: Colors.grey[700]))),
                          const Icon(Icons.upload_file)
                        ],
                      ),
                    ),
                  ),
                  // Show small validation hint for resume
                  if (_resumeFileName == null) Padding(
                    padding: const EdgeInsets.only(top:8.0),
                    child: Text(AppStrings.tr('resume_required_hint'), style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                  // Immediate Next button for step 0 (keeps it visible near personal fields)
                  if (_step == 0) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!_validatePersonalPart()) return;
                          setState(() => _step = 1);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text(AppStrings.tr('next'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  ],

                  if (_step == 1) ...[
                    // Education
                    _label(AppStrings.tr('education_details')),
                    _label(AppStrings.tr('highest_qualification'), required: true),
                  DropdownButtonFormField<String>(
                    value: _highestQualification,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(value: 'High School', child: Text('High School')),
                      DropdownMenuItem(value: 'Diploma', child: Text('Diploma')),
                      DropdownMenuItem(value: 'B.Sc (Agri)', child: Text('B.Sc (Agri)')),
                      DropdownMenuItem(value: 'M.Sc', child: Text('M.Sc')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _highestQualification = v),
                    validator: (v) => v == null ? AppStrings.tr('required') : null,
                  ),
                  const SizedBox(height: 12),
                  _textField(_institution, AppStrings.tr('institution_optional'), required: false),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _yearOfCompletion,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(hintText: AppStrings.tr('year_of_completion'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return null; // optional
                      final year = int.tryParse(val);
                      if (year == null) return AppStrings.tr('invalid_number');
                      final cy = DateTime.now().year;
                      if (year < 1900 || year > cy) return AppStrings.tr('invalid_year');
                      return null;
                    },
                  ),

                    const SizedBox(height: 12),
                    // Experience
                    _label(AppStrings.tr('experience'), required: true),
                  TextFormField(
                    controller: _yearsExperience,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(hintText: AppStrings.tr('total_years_experience'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return AppStrings.tr('required');
                      final num = int.tryParse(val);
                      if (num == null || num < 0 || num > 80) return AppStrings.tr('invalid_number');
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _relevantExperience,
                    maxLines: 3,
                    decoration: InputDecoration(hintText: AppStrings.tr('relevant_agri_experience'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.tr('required') : null,
                  ),
                  const SizedBox(height: 8),
                  _textField(_lastEmployerRole, AppStrings.tr('last_employer_role_optional'), required: false),

                    // Extras
                    const SizedBox(height: 12),
                    _label(AppStrings.tr('willing_for_field_visit'), required: true),
                    DropdownButtonFormField<String>(
                      value: _willingForFieldVisit,
                      items: const [
                        DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                        DropdownMenuItem(value: 'No', child: Text('No')),
                      ],
                      onChanged: (v) => setState(() => _willingForFieldVisit = v),
                      validator: (v) => v == null ? AppStrings.tr('required') : null,
                    ),
                  const SizedBox(height: 12),
                  _label(AppStrings.tr('vehicle_available')),
                  DropdownButtonFormField<String>(
                    value: _vehicleAvailable,
                    items: const [
                      DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                      DropdownMenuItem(value: 'No', child: Text('No')),
                    ],
                    onChanged: (v) => setState(() => _vehicleAvailable = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(value: _consent, onChanged: (v) => setState(() => _consent = v ?? false)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(AppStrings.tr('consent_text'), style: GoogleFonts.poppins(fontSize: 14))),
                    ],
                  ),
                  // Action row (Next / Back / Submit)
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (_step == 1)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _step = 0),
                            child: Text(AppStrings.tr('back')),
                          ),
                        ),
                      if (_step == 1) const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : () async {
                              if (_step == 0) {
                                // validate personal fields
                                if (!_validatePersonalPart()) return;
                                setState(() => _step = 1);
                                return;
                              }
                              // final submit
                              if (!_consent) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tr('consent_required'))));
                                return;
                              }
                              if (_resumeFileName == null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tr('resume_required'))));
                                return;
                              }
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isSubmitting = true);
                                try {
                                  await JobApplicationApiService.submitApplication(
                                    roleType: 'FIELD_OFFICER',
                                    fullName: _fullName.text.trim(),
                                    mobile: _mobile.text.trim(),
                                    email: _email.text.trim(),
                                    dob: _dob.text.trim(),
                                    locationText: _location.text.trim(),
                                    highestQualification: _highestQualification,
                                    institution: _institution.text.trim(),
                                    yearOfCompletion: _yearOfCompletion.text.trim().isNotEmpty
                                        ? int.tryParse(_yearOfCompletion.text.trim())
                                        : null,
                                    yearsExperience: _yearsExperience.text.trim().isNotEmpty
                                        ? int.tryParse(_yearsExperience.text.trim())
                                        : null,
                                    relevantExperience: _relevantExperience.text.trim(),
                                    lastEmployerRole: _lastEmployerRole.text.trim(),
                                    vehicleAvailable: _vehicleAvailable == 'Yes',
                                    willingForFieldVisit: _willingForFieldVisit == 'Yes',
                                    resumeFile: _resumeFile,
                                  );
                                  if (!mounted) return;
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SubmissionSuccessScreen()));
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() => _isSubmitting = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Submission failed: ${e.toString()}'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: _isSubmitting
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                                : Text(_step == 0 ? AppStrings.tr('next') : AppStrings.tr('submit_form'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _validatePersonalPart() {
    String? error;
    if (_fullName.text.trim().isEmpty) {
      error = AppStrings.tr('full_name') + ' ' + AppStrings.tr('required');
    } else if (_mobile.text.trim().isEmpty) {
      error = AppStrings.tr('mobile_no') + ' ' + AppStrings.tr('required');
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_mobile.text.trim())) {
      error = AppStrings.tr('invalid_phone');
    } else if (_email.text.trim().isEmpty) {
      error = AppStrings.tr('email') + ' ' + AppStrings.tr('required');
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      error = AppStrings.tr('invalid_email');
    } else if (_dob.text.trim().isEmpty) {
      error = AppStrings.tr('dob') + ' ' + AppStrings.tr('required');
    } else if (_location.text.trim().isEmpty) {
      error = AppStrings.tr('location') + ' ' + AppStrings.tr('required');
    } else if (_resumeFileName == null) {
      error = AppStrings.tr('resume_required');
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return false;
    }
    return true;
  }
}

