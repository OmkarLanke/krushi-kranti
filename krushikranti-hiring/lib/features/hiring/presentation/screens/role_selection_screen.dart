import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'personal_detail_screen.dart'; 
// Import the localization helper
import '../../../../core/app_localizations.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap screen in ValueListenableBuilder to listen for language changes
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          // APP BAR FOR LANGUAGE SELECTION
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: lang,
                  icon: const Icon(Icons.language, color: Color(0xFF1B5E20)),
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
              const SizedBox(width: 20),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. BRAND HEADER
                      Center(
                        child: Text(
                          AppStrings.tr('brand_name'), // ✅ Localized
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),

                      // 2. SUB-HEADER
                      Text(
                        AppStrings.tr('continue_as'), // ✅ Localized
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppStrings.tr('role_desc'), // ✅ Localized
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 3. ROLE CARDS
                      _buildRoleCard(
                        context,
                        title: AppStrings.tr('role_field_officer'),
                        subtitle: AppStrings.tr('role_officer_desc'),
                        iconData: Icons.agriculture,
                        color: Colors.green,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalDetailScreen(roleType: 'officer'))),
                      ),

                      const SizedBox(height: 20),

                      _buildRoleCard(
                        context,
                        title: AppStrings.tr('role_tadnya'),
                        subtitle: AppStrings.tr('role_tadnya_desc'),
                        iconData: Icons.school,
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalDetailScreen(roleType: 'tadnya'))),
                      ),

                      const SizedBox(height: 20),

                      _buildRoleCard(
                        context,
                        title: AppStrings.tr('role_shopkeeper'),
                        subtitle: AppStrings.tr('role_shopkeeper_desc'),
                        iconData: Icons.store,
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalDetailScreen(roleType: 'shopkeeper'))),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleCard(BuildContext context, {required String title, required String subtitle, required IconData iconData, required Color color, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), spreadRadius: 2, blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  height: 56, width: 56,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(iconData, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], height: 1.4)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}