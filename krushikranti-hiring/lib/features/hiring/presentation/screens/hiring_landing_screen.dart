import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'application_form.dart';
import '../../../../core/app_localizations.dart';

class HiringLandingScreen extends StatelessWidget {
  const HiringLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: LayoutBuilder(
            builder: (context, constraints) {
              // Check if screen width is greater than 800px (Desktop/Tablet)
              bool isDesktop = constraints.maxWidth > 800;

              if (isDesktop) {
                // 🖥️ DESKTOP LAYOUT (Side-by-Side)
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
                          // Dark overlay for style
                          Container(color: Colors.black.withValues(alpha: 0.1)),
                        ],
                      ),
                    ),
                    
                    // Right Side: Content
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Padding(
                            padding: const EdgeInsets.all(48.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Language Switcher (Top Right of Content Area)
                                Align(
                                  alignment: Alignment.topRight,
                                  child: _buildLanguageDropdown(lang),
                                ),
                                const Spacer(),
                                
                                _buildTitle(),
                                const SizedBox(height: 24),
                                _buildSubtitle(),
                                const SizedBox(height: 48),
                                _buildNextButton(context),
                                
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // 📱 MOBILE LAYOUT (Vertical Stack)
                return Column(
                  children: [
                    // Top Image Section
                    Expanded(
                      flex: 5, 
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/hiring_intro.jpg'),
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                          ),
                          // Language Switcher Positioned
                          Positioned(
                            top: 40,
                            right: 20,
                            child: _buildLanguageDropdown(lang),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Content Section
                    Expanded(
                      flex: 4, 
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            _buildTitle(),
                            const SizedBox(height: 16),
                            _buildSubtitle(),
                            const SizedBox(height: 40), 
                            _buildNextButton(context),
                            const SizedBox(height: 20), 
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        );
      }
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _buildLanguageDropdown(String currentLang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLang,
          icon: const Icon(Icons.language, size: 20, color: Color(0xFF1B5E20)),
          isDense: true,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
          items: const [
            DropdownMenuItem(value: 'mr', child: Text("मराठी")),
            DropdownMenuItem(value: 'hi', child: Text("हिंदी")),
            DropdownMenuItem(value: 'en', child: Text("English")),
          ],
          onChanged: (val) {
            if (val != null) currentLanguage.value = val;
          },
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      AppStrings.tr('apply_title'), 
      style: GoogleFonts.poppins(
        fontSize: 32, // Slightly larger for better impact
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1B5E20), // Darker Green for better readability
        height: 1.2,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      AppStrings.tr('apply_subtitle'), 
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.grey[700],
        height: 1.6,
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56, 
              child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ApplicationFormScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700), // Brand Yellow
          foregroundColor: Colors.black, 
          elevation: 4, // Subtle shadow
          shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          AppStrings.tr('next'), 
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}