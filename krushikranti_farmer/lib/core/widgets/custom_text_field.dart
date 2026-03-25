import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int maxLines;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: prefixIcon == null ? 16 : 0),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade100,
            border: Border.all(
              color: enabled ? Colors.grey.shade300 : Colors.grey.shade300,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Container(
                  margin: const EdgeInsets.only(left: 16, right: 10, top: 8, bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppColors.brandGreen.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    prefixIcon,
                    size: 18,
                    color: enabled ? AppColors.brandGreen : Colors.grey.shade500,
                  ),
                ),
              ],
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  maxLength: maxLength,
                  maxLines: maxLines,
                  validator: validator,
                  onChanged: onChanged,
                  inputFormatters: inputFormatters,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: enabled ? Colors.black87 : Colors.grey.shade600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    counterText: "",
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: prefixIcon == null ? 0 : 6,
                    ),
                    isDense: true,
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (suffixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: suffixIcon!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
