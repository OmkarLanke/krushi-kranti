import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'application_form.dart';
import '../../../../core/app_localizations.dart';

enum _HiringRole {
  fieldOfficer,
  tadnya,
  shopkeeper,
}

class HiringLandingScreen extends StatefulWidget {
  const HiringLandingScreen({super.key});

  @override
  State<HiringLandingScreen> createState() => _HiringLandingScreenState();
}

class _HiringLandingScreenState extends State<HiringLandingScreen> {
  _HiringRole? _selectedRole;

  void _handleContinue(BuildContext context, _HiringRole role) {
    // Currently only FIELD_OFFICER has a complete flow.
    if (role == _HiringRole.fieldOfficer) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const ApplicationFormScreen(roleType: 'FIELD_OFFICER'),
        ),
      );
      return;
    }

    _showComingSoon(context);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bool isDesktop = constraints.maxWidth > 800;

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
                                image:
                                    AssetImage('assets/images/hiring_intro.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Dark overlay for style
                          Container(
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
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
                                const SizedBox(height: 32),
                                _buildRoleCards(context, isDesktop: true),
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
                // 📱 MOBILE LAYOUT (Scroll + Card)
                return SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image card
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: Image.asset(
                                      'assets/images/hiring_intro.jpg',
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: _buildLanguageDropdown(lang),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Content card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTitle(),
                                  const SizedBox(height: 12),
                                  _buildSubtitle(),
                                  const SizedBox(height: 24),
                                  _buildRoleCards(context, isDesktop: false),
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
            },
          ),
        );
      },
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

  Widget _buildRoleCards(BuildContext context, {required bool isDesktop}) {
    return Column(
      children: [
        _buildRoleCard(
          context,
          title: AppStrings.tr('role_field_officer'),
          subtitle: AppStrings.tr('role_officer_desc'),
          avatarColor: Colors.purple.shade100,
          icon: Icons.nature_people, // 🌿 Nature/Field
          iconColor: Colors.deepPurple,
          role: _HiringRole.fieldOfficer,
          isSelected: _selectedRole == _HiringRole.fieldOfficer,
          onTap: () {
            setState(() {
              _selectedRole = _HiringRole.fieldOfficer;
            });
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
          role: _HiringRole.tadnya,
          isSelected: _selectedRole == _HiringRole.tadnya,
          onTap: () {
            setState(() {
              _selectedRole = _HiringRole.tadnya;
            });
          },
        ),
        const SizedBox(height: 20),
        _buildRoleCard(
          context,
          title: AppStrings.tr('role_shopkeeper'),
          subtitle: AppStrings.tr('role_shopkeeper_desc'),
          avatarColor: Colors.blue.shade100,
          icon: Icons.storefront, // 🏪 Shop
          iconColor: Colors.blue[800]!,
          role: _HiringRole.shopkeeper,
          isSelected: _selectedRole == _HiringRole.shopkeeper,
          onTap: () {
            setState(() {
              _selectedRole = _HiringRole.shopkeeper;
            });
          },
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.tr('coming_soon')),
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
    required _HiringRole role,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color selectedBorderColor = const Color(0xFF1B5E20);
    final Color baseBorderColor = Colors.grey.withValues(alpha: 0.2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? selectedBorderColor : baseBorderColor,
          width: isSelected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 12,
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
                  height: 60,
                  width: 60,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: Color(0xFF1B5E20),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'निवडलेले',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                        ],
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
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () {
                            onTap();
                            _handleContinue(context, role);
                          },
                          child: Text(
                            AppStrings.tr('apply'),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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