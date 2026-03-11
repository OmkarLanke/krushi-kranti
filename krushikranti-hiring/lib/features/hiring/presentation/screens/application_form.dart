import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_localizations.dart';
import '../widgets/hiring_screen_wrapper.dart';
import '../widgets/hiring_form_widgets.dart';
import '../widgets/hiring_side_panel.dart';
import 'field_officer_qualification_screen.dart';

class ApplicationFormScreen extends StatefulWidget {
  final String roleType;
  const ApplicationFormScreen({super.key, required this.roleType});

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

  @override
  void dispose() {
    _fullName.dispose();
    _mobile.dispose();
    _email.dispose();
    _dob.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HiringScreenWrapper(
      title: AppStrings.tr('personal_details'),
      currentStep: 1,
      totalSteps: 2,
      sidePanel: HiringSidePanel(
        icon: Icons.person_pin, 
        title: AppStrings.tr('join_kranti'), 
        description: AppStrings.tr('join_desc'), 
        features: [
          AppStrings.tr('feat_verified'),
          AppStrings.tr('feat_secure'),
          AppStrings.tr('feat_fast'),
        ],
      ),
      child: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HiringLabel(AppStrings.tr('full_name'), required: true),
            HiringTextField(
              controller: _fullName, 
              hint: AppStrings.tr('enter_full_name'), 
              required: true, 
              prefixIcon: Icons.person_outline
            ),

            HiringLabel(AppStrings.tr('mobile_no'), required: true),
            HiringTextField(
              controller: _mobile,
              hint: AppStrings.tr('enter_mobile'),
              isNumber: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              prefixIcon: Icons.phone_android_outlined,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return AppStrings.tr('required');
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) return AppStrings.tr('invalid_phone');
                return null;
              },
            ),

            HiringLabel(AppStrings.tr('email'), required: true),
            HiringTextField(
              controller: _email,
              hint: AppStrings.tr('enter_email'),
              prefixIcon: Icons.email_outlined,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return AppStrings.tr('required');
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(val.trim())) return AppStrings.tr('invalid_email');
                return null;
              },
            ),

            HiringLabel(AppStrings.tr('dob'), required: true),
            HiringTextField(
              controller: _dob,
              hint: 'DD/MM/YYYY',
              readOnly: true,
              prefixIcon: Icons.calendar_today_outlined,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFFFFD700),
                          onPrimary: Colors.black,
                          onSurface: Colors.black,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  _dob.text = '${picked.day}/${picked.month}/${picked.year}';
                }
              },
              validator: (val) {
                if (val == null || val.trim().isEmpty) return AppStrings.tr('required');
                return null;
              },
            ),

            HiringLabel(AppStrings.tr('location'), required: true),
            HiringTextField(
              controller: _location, 
              hint: AppStrings.tr('village_taluka_district'), 
              required: true, 
              prefixIcon: Icons.location_on_outlined
            ),

            const SizedBox(height: 32),
            HiringPrimaryButton(
              text: AppStrings.tr('next'),
              onPressed: _onNext,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      // Proceed to Qualification Screen based on Role
      if (widget.roleType == 'FIELD_OFFICER') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FieldOfficerQualificationScreen(
              fullName: _fullName.text.trim(),
              mobile: _mobile.text.trim(),
              email: _email.text.trim(),
              dob: _dob.text.trim(),
              location: _location.text.trim(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Qualification screen for ${widget.roleType} coming soon.")));
      }
    }
  }
}
