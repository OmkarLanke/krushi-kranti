import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart'; 
import 'submission_success_screen.dart';
import '../../../../core/app_localizations.dart';
import '../../data/job_application_service.dart';
import '../widgets/hiring_screen_wrapper.dart';
import '../widgets/hiring_form_widgets.dart';
import '../widgets/hiring_side_panel.dart';

class FieldOfficerQualificationScreen extends StatefulWidget {
  final String fullName;
  final String mobile;
  final String email;
  final String dob;
  final String location;

  const FieldOfficerQualificationScreen({
    super.key,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.dob,
    required this.location,
  });

  @override
  State<FieldOfficerQualificationScreen> createState() => _FieldOfficerQualificationScreenState();
}

class _FieldOfficerQualificationScreenState extends State<FieldOfficerQualificationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _institutionController = TextEditingController();
  final _yearOfCompletionController = TextEditingController();
  final _experienceController = TextEditingController();
  final _relevantExperienceController = TextEditingController(); // Text Area
  final _lastEmployerRoleController = TextEditingController();

  // Dropdown Values
  String? _highestQualificationValue;
  String? _vehicleValue;
  String? _willingToVisitValue;

  String? _resumeFileName;
  PlatformFile? _resumeFile;
  bool _consent = false;
  bool _isSubmitting = false;

  final List<String> _qualifications = [
    '10th',
    '12th',
    'Diploma (Agri)',
    'B.Sc Agri',
    'M.Sc Agri',
    'MBA (Agri)',
    'Other'
  ];

  // --- 📂 FILE PICKING LOGIC ---
  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);
    if (result != null) {
      setState(() {
        _resumeFile = result.files.single;
        _resumeFileName = _resumeFile!.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return HiringScreenWrapper(
          title: AppStrings.tr('enter_qualification'),
          currentStep: 2,
          totalSteps: 2,
          sidePanel: HiringSidePanel(
            icon: Icons.workspace_premium, 
            title: AppStrings.tr('showcase_skills'), 
            description: AppStrings.tr('showcase_desc'), 
            features: [
              AppStrings.tr('feat_earn'),
              AppStrings.tr('feat_growth'),
              AppStrings.tr('feat_smart'),
            ],
          ),
          child: _buildFormContent(),
        );
      }
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Highest Qualification (Dropdown)
            HiringLabel(AppStrings.tr('highest_qual'), required: true),
             HiringDropdown(
              hint: AppStrings.tr('highest_qual'),
              value: _highestQualificationValue,
              items: _qualifications,
              onChanged: (val) => setState(() => _highestQualificationValue = val),
              icon: Icons.school_outlined,
            ),

            // 2. Institution / University
            HiringLabel(AppStrings.tr('institution'), required: true),
            HiringTextField(
              controller: _institutionController,
              hint: "Agriculture College, Pune",
              prefixIcon: Icons.account_balance_outlined,
            ),

            // 3. Year of Completion
            HiringLabel(AppStrings.tr('year_of_completion'), required: true),
            HiringTextField(
              controller: _yearOfCompletionController,
              hint: "2020",
              isNumber: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              prefixIcon: Icons.calendar_today_outlined,
            ),

            // 4. Years of Experience
            HiringLabel(AppStrings.tr('years_exp'), required: true),
            HiringTextField(
              controller: _experienceController,
              hint: "2",
              isNumber: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: Icons.work_history_outlined,
            ),

            // 5. Relevant Experience (Text Area)
            HiringLabel(AppStrings.tr('relevant_experience'), required: false),
            HiringTextField(
              controller: _relevantExperienceController,
              hint: "Worked as sales executive...",
              maxLines: 3,
              required: false,
            ),

            // 6. Last Employer Role
            HiringLabel(AppStrings.tr('last_employer_role'), required: false),
            HiringTextField(
              controller: _lastEmployerRoleController,
              hint: "Sales Manager",
              required: false,
              prefixIcon: Icons.badge_outlined,
            ),

            // 7. Vehicle Available (Dropdown)
            HiringLabel(AppStrings.tr('vehicle_avail'), required: true),
            HiringDropdown(
              hint: "${AppStrings.tr('yes')} / ${AppStrings.tr('no')}",
              value: _vehicleValue,
              items: ["Yes", "No"],
              onChanged: (val) => setState(() => _vehicleValue = val),
              icon: Icons.directions_bike_outlined,
            ),
            
            // 8. Willingness for Field Visit (Dropdown)
            HiringLabel(AppStrings.tr('willing_field_visit'), required: true),
            HiringDropdown(
              hint: "${AppStrings.tr('yes')} / ${AppStrings.tr('no')}",
              value: _willingToVisitValue,
              items: ["Yes", "No"],
              onChanged: (val) => setState(() => _willingToVisitValue = val),
              icon: Icons.directions_walk_outlined,
            ),

            const SizedBox(height: 30),

            // Resume Upload
            HiringLabel(AppStrings.tr('resume'), required: true),
            InkWell(
              onTap: _pickDocument,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: HiringStyles.fieldDecoration.copyWith(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(
                      _resumeFileName ?? AppStrings.tr('upload_resume'), 
                      style: GoogleFonts.poppins(
                        color: _resumeFileName != null ? Colors.black : Colors.grey[600],
                        fontWeight: _resumeFileName != null ? FontWeight.w500 : FontWeight.normal,
                        fontSize: 15
                      ),
                    )),
                    Icon(
                      _resumeFileName != null ? Icons.check_circle : Icons.cloud_upload_outlined, 
                      color: _resumeFileName != null ? Colors.green : Colors.grey,
                      size: 24
                    )
                  ],
                ),
              ),
            ),
            if (_resumeFileName == null) Padding(
              padding: const EdgeInsets.only(top:8.0, left: 4),
              child: Text(AppStrings.tr('resume_required_hint'), style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),

            const SizedBox(height: 24),
            // Consent
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // Light Green
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24, 
                    height: 24, 
                    child: Checkbox(
                      value: _consent, 
                      activeColor: Colors.green, 
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (v) => setState(() => _consent = v ?? false)
                    )
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.tr('consent_text'), 
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.green[900], height: 1.5)
                    )
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            // Submit Button
            HiringPrimaryButton(
              text: AppStrings.tr('submit_form'),
              isLoading: _isSubmitting,
              onPressed: _submitForm,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
       if (_highestQualificationValue == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tr('required'))));
          return;
       }
       if (_vehicleValue == null || _willingToVisitValue == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tr('required'))));
          return;
       }
       if (_resumeFileName == null) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tr('resume_required'))));
         return;
       }
       if (!_consent) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tr('consent_required'))));
         return;
       }

       setState(() => _isSubmitting = true);

       try {
         await JobApplicationApiService.submitApplication(
            roleType: 'FIELD_OFFICER',
            fullName: widget.fullName,
            mobile: widget.mobile,
            email: widget.email,
            dob: widget.dob,
            locationText: widget.location,
            highestQualification: _highestQualificationValue, // Dropdown Value
            institution: _institutionController.text.trim(),
            yearOfCompletion: int.tryParse(_yearOfCompletionController.text.trim()),
            yearsExperience: int.tryParse(_experienceController.text.trim()),
            relevantExperience: _relevantExperienceController.text.trim(),
            lastEmployerRole: _lastEmployerRoleController.text.trim(),
            vehicleAvailable: _vehicleValue == 'Yes', // Map to boolean
            willingForFieldVisit: _willingToVisitValue == 'Yes', // Map to boolean
            resumeFile: _resumeFile,
          );

          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SubmissionSuccessScreen()));

       } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
       } finally {
         if (mounted) setState(() => _isSubmitting = false);
       }
    }
  }
}