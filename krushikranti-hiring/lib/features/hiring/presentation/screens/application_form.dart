import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_localizations.dart';
import '../../data/email_otp_service.dart';
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

  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isEmailVerified = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _otpError;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _fullName.dispose();
    _mobile.dispose();
    _email.dispose();
    _dob.dispose();
    _location.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendOtp() async {
    final email = _email.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _otpError = AppStrings.tr('invalid_email'));
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _otpError = null;
    });

    try {
      final sent = await EmailOtpService.sendOtp(email);
      if (!mounted) return;
      if (sent) {
        setState(() {
          _isOtpSent = true;
          _isEmailVerified = false;
          _otpController.clear();
        });
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.tr('otp_sent_success')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _otpError = AppStrings.tr('otp_send_failed'));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _otpError = AppStrings.tr('otp_send_failed'));
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _otpError = AppStrings.tr('otp_invalid'));
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _otpError = null;
    });

    try {
      final verified = await EmailOtpService.verifyOtp(_email.text.trim(), otp);
      if (!mounted) return;
      if (verified) {
        setState(() {
          _isEmailVerified = true;
          _isOtpSent = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.tr('email_verified_success')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _otpError = AppStrings.tr('otp_invalid'));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _otpError = AppStrings.tr('otp_verify_failed'));
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
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
              prefixIcon: Icons.person_outline,
            ),

            HiringLabel(AppStrings.tr('mobile_no'), required: true),
            HiringTextField(
              controller: _mobile,
              hint: AppStrings.tr('enter_mobile'),
              isNumber: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              prefixIcon: Icons.phone_android_outlined,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return AppStrings.tr('required');
                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) return AppStrings.tr('invalid_phone');
                return null;
              },
            ),

            HiringLabel(AppStrings.tr('email'), required: true),
            _buildEmailFieldWithOtp(),

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
                          style: TextButton.styleFrom(foregroundColor: Colors.black),
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
              prefixIcon: Icons.location_on_outlined,
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

  Widget _buildEmailFieldWithOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email field + Send OTP / Verified badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: HiringStyles.fieldDecoration,
                child: TextFormField(
                  controller: _email,
                  enabled: !_isEmailVerified,
                  keyboardType: TextInputType.emailAddress,
                  style: HiringStyles.inputStyle,
                  decoration: InputDecoration(
                    hintText: AppStrings.tr('enter_email'),
                    hintStyle: HiringStyles.hintStyle,
                    filled: true,
                    fillColor: _isEmailVerified ? const Color(0xFFF0FDF4) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    prefixIcon: Icon(
                      _isEmailVerified ? Icons.verified : Icons.email_outlined,
                      color: _isEmailVerified ? Colors.green : Colors.grey[400],
                      size: 20,
                    ),
                    suffixIcon: _isEmailVerified
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isEmailVerified ? Colors.green.shade200 : Colors.grey.shade100,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green.shade200),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                  onChanged: (_) {
                    if (_isOtpSent || _isEmailVerified) {
                      setState(() {
                        _isOtpSent = false;
                        _isEmailVerified = false;
                        _otpController.clear();
                        _otpError = null;
                      });
                    }
                  },
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return AppStrings.tr('required');
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val.trim())) {
                      return AppStrings.tr('invalid_email');
                    }
                    if (!_isEmailVerified) return AppStrings.tr('email_not_verified');
                    return null;
                  },
                ),
              ),
            ),
            if (!_isEmailVerified) ...[
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isSendingOtp || _resendCooldown > 0) ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade200,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  child: _isSendingOtp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          _resendCooldown > 0
                              ? '${_resendCooldown}s'
                              : _isOtpSent
                                  ? AppStrings.tr('resend_otp')
                                  : AppStrings.tr('send_otp'),
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ],
        ),

        // Verified badge text
        if (_isEmailVerified)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  AppStrings.tr('email_verified_success'),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

        // OTP input row (visible after OTP is sent, hidden after verification)
        if (_isOtpSent && !_isEmailVerified) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: HiringStyles.fieldDecoration,
                  child: TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 8,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '• • • • • •',
                      hintStyle: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[300], letterSpacing: 8),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orange.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifyingOtp ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 0,
                  ),
                  child: _isVerifyingOtp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          AppStrings.tr('verify_otp'),
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
          if (_otpError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _otpError!,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              AppStrings.tr('otp_hint'),
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        ],
      ],
    );
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Qualification screen for ${widget.roleType} coming soon.")),
        );
      }
    }
  }
}
