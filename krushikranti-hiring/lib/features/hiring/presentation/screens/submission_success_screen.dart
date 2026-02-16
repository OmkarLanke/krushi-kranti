import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_localizations.dart'; // Import Localization

class SubmissionSuccessScreen extends StatelessWidget {
  const SubmissionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 800;

              if (isDesktop) {
                // 🖥️ DESKTOP LAYOUT
                return Row(
                  children: [
                    // Left Side: Image
                    Expanded(
                      flex: 1,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/hiring_intro.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(color: Colors.black.withValues(alpha: 0.1)),
                        ],
                      ),
                    ),
                    // Right Side: Success Content
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: _buildSuccessContent(context),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // 📱 MOBILE LAYOUT
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildSuccessContent(context),
                    ),
                  ),
                );
              }
            },
          ),
        );
      }
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated-style Icon
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                height: 120, width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                ),
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4CAF50),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 50),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        // Title
        Text(
          AppStrings.tr('success'),
          style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        
        const SizedBox(height: 16),
        
        // Success Message
        Text(
          AppStrings.tr('success_msg'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600], height: 1.5),
        ),

        const SizedBox(height: 24),

        // 📧 Email Update Notification (Newly Added)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9C4), // Light Yellow bg for attention
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.email_outlined, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.tr('email_update_msg'),
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
        
        // OK Button
        SizedBox(
          width: 200, height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(AppStrings.tr('ok'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}