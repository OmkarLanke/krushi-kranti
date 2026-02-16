import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// --- STYLES ---
class HiringStyles {
  static final TextStyle labelStyle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.blueGrey[800],
  );

  static final TextStyle inputStyle = GoogleFonts.poppins(
    fontSize: 15,
    color: Colors.black87,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle hintStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.grey[400],
  );

  static final BoxDecoration fieldDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// --- LABEL ---
class HiringLabel extends StatelessWidget {
  final String text;
  final bool required;

  const HiringLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 20.0),
      child: Row(
        children: [
          Text(text, style: HiringStyles.labelStyle),
          if (required) ...[
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}

// --- TEXT FIELD ---
class HiringTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final bool required;
  final bool isNumber;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  const HiringTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.required = true,
    this.isNumber = false,
    this.maxLines = 1,
    this.inputFormatters,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: HiringStyles.fieldDecoration,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        style: HiringStyles.inputStyle,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: HiringStyles.hintStyle,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: prefixIcon != null 
              ? Icon(prefixIcon, color: Colors.grey[400], size: 20) 
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
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
        validator: validator ?? (val) {
          if (!required) return null;
          if (val == null || val.trim().isEmpty) return 'Required';
          return null; 
        },
      ),
    );
  }
}

// --- DROPDOWN ---
class HiringDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? icon;
  final bool required;

  const HiringDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: HiringStyles.fieldDecoration,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: icon != null 
              ? Icon(icon, color: Colors.grey[400], size: 20) 
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
           enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
          ),
        ),
        hint: Text(hint, style: HiringStyles.hintStyle),
        value: value,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
        items: items.map((e) => DropdownMenuItem(
          value: e, 
          child: Text(e, style: HiringStyles.inputStyle),
        )).toList(),
        onChanged: onChanged,
        validator: (val) => (required && val == null) ? 'Required' : null,
      ),
    );
  }
}

// --- PRIMARY BUTTON ---
class HiringPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const HiringPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          elevation: 0, // Flat design with slight shadow on container if needed
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: const Color(0xFFFFD700).withOpacity(0.4),
        ).copyWith(
          elevation: MaterialStateProperty.all(4), // Subtle lift
        ),
        child: isLoading 
          ? const SizedBox(
              height: 24, 
              width: 24, 
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
            )
          : Text(
              text, 
              style: GoogleFonts.poppins(
                fontSize: 16, 
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
      ),
    );
  }
}
