import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  void _onFormFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    usernameController.addListener(_onFormFieldChanged);
    emailController.addListener(_onFormFieldChanged);
    passwordController.addListener(_onFormFieldChanged);
    phoneController.addListener(_onFormFieldChanged);
  }

  @override
  void dispose() {
    usernameController.removeListener(_onFormFieldChanged);
    emailController.removeListener(_onFormFieldChanged);
    passwordController.removeListener(_onFormFieldChanged);
    phoneController.removeListener(_onFormFieldChanged);
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool validateUsername(String name) => name.trim().length >= 3;

  bool validateEmail(String email) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return regex.hasMatch(email);
  }

  bool validatePhone(String phone) => RegExp(r'^[0-9]{10}$').hasMatch(phone);

  bool validatePassword(String password) {
    return RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%\^&\*\-_]).{8,}$',
    ).hasMatch(password);
  }

  int _passwordStrengthScore(String p) {
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[!@#$%^&*\-_]').hasMatch(p)) s++;
    return s;
  }

  bool get _isFormValid =>
      validateUsername(usernameController.text) &&
      validateEmail(emailController.text) &&
      validatePhone(phoneController.text) &&
      validatePassword(passwordController.text);

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString();
    String actualMessage = errorString;

    try {
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(errorString);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0);
        if (jsonString != null) {
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          if (jsonData.containsKey('message')) {
            actualMessage = jsonData['message'] as String;
          }
        }
      }
    } catch (_) {}

    final errorLower = actualMessage.toLowerCase();
    final l10n = AppLocalizations.of(context)!;

    if (errorLower.contains('phone number already exists') ||
        errorLower.contains('phone already exists') ||
        errorLower.contains('phone number is already registered')) {
      return l10n.signupErrorPhoneRegistered;
    }

    if (errorLower.contains('email already exists') ||
        errorLower.contains('email is already registered') ||
        errorLower.contains('email already in use')) {
      return l10n.signupErrorEmailRegistered;
    }

    if (errorLower.contains('username already exists') ||
        errorLower.contains('username is already taken')) {
      return l10n.signupErrorUsernameTaken;
    }

    if (errorLower.contains('invalid') || errorLower.contains('validation')) {
      return l10n.signupErrorCheckInfo;
    }

    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return l10n.signupErrorNetwork;
    }

    return actualMessage
        .replaceFirst('Exception: ', '')
        .replaceFirst('Network Error: ', '')
        .replaceFirst('Error: ', '')
        .replaceFirst('error: ', '');
  }

  Future<void> validateForm() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await HttpService.post(
        'auth/register',
        {
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'phoneNumber': phoneController.text.trim(),
          'password': passwordController.text.trim(),
          'role': 'FARMER',
        },
      );

      await StorageService.saveAuthDetails(
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
      );

      await StorageService.savePersonalDetails(
        firstName: usernameController.text.trim(),
        lastName: '',
        dob: '',
        gender: '',
        profilePicPath: null,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushNamed(context, AppRoutes.otp, arguments: false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final errorMessage = _getUserFriendlyErrorMessage(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.ok,
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final isCompactHeight = media.size.height < 700;
    final horizontalPadding = media.size.width >= 600 ? 24.0 : 16.0;
    final titleSize = media.size.width >= 600 ? 26.0 : 22.0;
    final pw = passwordController.text;
    final strength = _passwordStrengthScore(pw);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.signupTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
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
                  AppColors.brandGreen.withOpacity(0.85),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth >= 700 ? 520.0 : double.infinity;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isCompactHeight ? 12 : 16,
                  horizontalPadding,
                  20 + media.viewInsets.bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.signupHey,
                              style: GoogleFonts.poppins(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.signupTitle,
                              style: GoogleFonts.poppins(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandGreen,
                                height: 1.15,
                              ),
                            ),
                            SizedBox(height: isCompactHeight ? 16 : 20),
                            _fieldLabel(l10n.signupUsernameLabel),
                            const SizedBox(height: 6),
                            _textField(
                              l10n: l10n,
                              controller: usernameController,
                              focusNode: _usernameFocus,
                              nextFocusNode: _emailFocus,
                              hint: l10n.signupUsernameHint,
                              icon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (!validateUsername(v)) {
                                  return l10n.signupErrorUsername;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _fieldLabel(l10n.signupEmailLabel),
                            const SizedBox(height: 6),
                            _textField(
                              l10n: l10n,
                              controller: emailController,
                              focusNode: _emailFocus,
                              nextFocusNode: _passwordFocus,
                              hint: l10n.signupEmailHint,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (!validateEmail(v)) {
                                  return l10n.signupErrorEmail;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _fieldLabel(l10n.signupPasswordLabel),
                            const SizedBox(height: 6),
                            _textField(
                              l10n: l10n,
                              controller: passwordController,
                              focusNode: _passwordFocus,
                              nextFocusNode: _phoneFocus,
                              hint: l10n.signupPasswordHint,
                              icon: Icons.lock_outline,
                              isPassword: true,
                              obscureText: _obscurePassword,
                              onTogglePassword: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (!validatePassword(v)) {
                                  return l10n.signupErrorPassword;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.signupPasswordHelper,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade800,
                                height: 1.35,
                              ),
                            ),
                            if (pw.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _strengthDot(strength >= 1, strength),
                                  _strengthDot(strength >= 2, strength),
                                  _strengthDot(strength >= 3, strength),
                                  _strengthDot(strength >= 4, strength),
                                  _strengthDot(strength >= 5, strength),
                                  const SizedBox(width: 8),
                                  Text(
                                    _strengthLabel(l10n, strength),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _strengthColor(strength),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),
                            _fieldLabel(l10n.signupPhoneLabel),
                            const SizedBox(height: 6),
                            _textField(
                              l10n: l10n,
                              controller: phoneController,
                              focusNode: _phoneFocus,
                              hint: l10n.signupPhoneHint,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              autofillHints: const [
                                AutofillHints.telephoneNumber
                              ],
                              onFieldSubmitted: (_) => validateForm(),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (!validatePhone(v)) {
                                  return l10n.signupErrorPhone;
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: isCompactHeight ? 18 : 22),
                            AppPrimaryButton(
                              label: l10n.signupGetCode,
                              icon: Icons.send_rounded,
                              isLoading: _isLoading,
                              onPressed: (_isLoading || !_isFormValid)
                                  ? null
                                  : validateForm,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _strengthDot(bool filled, int strength) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? _strengthColor(strength) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Color _strengthColor(int s) {
    if (s >= 4) return Colors.green.shade700;
    if (s >= 2) return Colors.orange.shade800;
    return Colors.red.shade700;
  }

  String _strengthLabel(AppLocalizations l10n, int s) {
    if (s >= 4) return l10n.signupPasswordStrong;
    if (s >= 2) return l10n.signupPasswordFair;
    return l10n.signupPasswordWeak;
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _textField({
    required AppLocalizations l10n,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onTogglePassword,
    ValueChanged<String>? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final borderRadius = BorderRadius.circular(12);
    final baseBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofillHints: autofillHints,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.brandGreen),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.4),
        ),
        errorBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
        ),
        focusedErrorBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: Colors.red.shade500, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: isPassword && onTogglePassword != null
            ? IconButton(
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                tooltip: obscureText
                    ? l10n.signupShowPassword
                    : l10n.signupHidePassword,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.brandGreen,
                  size: 22,
                ),
                onPressed: onTogglePassword,
              )
            : null,
      ),
      validator: validator,
      onFieldSubmitted: (value) {
        onFieldSubmitted?.call(value);
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        }
      },
    );
  }
}
