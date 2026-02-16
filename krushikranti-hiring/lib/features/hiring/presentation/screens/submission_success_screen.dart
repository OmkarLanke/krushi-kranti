import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_localizations.dart'; // Import Localization

class SubmissionSuccessScreen extends StatelessWidget {
  const SubmissionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Listen to Language Changes
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center( 
            child: SingleChildScrollView( 
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                width: double.infinity, 
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center, 
                  children: [
                    Container(
                      height: 100, width: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF4CAF50), width: 8)),
                      child: const Icon(Icons.check, color: Color(0xFF4CAF50), size: 60),
                    ),
                    const SizedBox(height: 30),
                    Text(AppStrings.tr('success'), style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Text(AppStrings.tr('success_msg'), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600], height: 1.5)),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 150, height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: Text(AppStrings.tr('ok'), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}