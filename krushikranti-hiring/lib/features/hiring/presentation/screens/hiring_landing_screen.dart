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
                                _buildRoleCards(context),
                                
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
                            _buildRoleCards(context),
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
      AppStrings.tr('brand_name'), // "Krushi Kranti"
      style: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1B5E20),
        height: 1.2,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.tr('continue_as'), // "Continue as"
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.tr('role_desc'), // "Choose form to work as..."
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCards(BuildContext context) {
    return Column(
      children: [
        _buildRoleCard(
          context,
          title: AppStrings.tr('role_field_officer'),
          subtitle: AppStrings.tr('role_officer_desc'),
          avatarColor: Colors.purple.shade100,
          icon: Icons.nature_people, // 🌿 Nature/Field
          iconColor: Colors.deepPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ApplicationFormScreen(roleType: 'FIELD_OFFICER')),
            );
          },
        ),
        const SizedBox(height: 20),
        _buildRoleCard(
          context,
          title: AppStrings.tr('role_tadnya'),
          subtitle: AppStrings.tr('role_tadnya_desc'),
          avatarColor: Colors.orange.shade100,
          icon: Icons.psychology, // 🧠 Knowledge/Expert
          iconColor: Colors.deepOrange,
          onTap: () => _showComingSoon(context),
        ),
        const SizedBox(height: 20),
        _buildRoleCard(
          context,
          title: AppStrings.tr('role_shopkeeper'),
          subtitle: AppStrings.tr('role_shopkeeper_desc'),
          avatarColor: Colors.blue.shade100,
          icon: Icons.storefront, // 🏪 Shop
          iconColor: Colors.blue[800]!,
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.tr('coming_soon') ?? "Coming Soon"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color avatarColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  height: 60, width: 60,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}