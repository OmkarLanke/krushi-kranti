import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import 'field_officer_home_screen.dart';
import 'field_officer_farmer_screen.dart';
import 'field_officer_assessment_screen.dart';
import 'field_officer_profile_screen.dart';

class FieldOfficerDashboardScreen extends StatefulWidget {
  const FieldOfficerDashboardScreen({super.key});

  @override
  State<FieldOfficerDashboardScreen> createState() =>
      _FieldOfficerDashboardScreenState();
}

class _FieldOfficerDashboardScreenState
    extends State<FieldOfficerDashboardScreen> {
  int _currentIndex = 0;
  bool _isNavigating = false;

  // Cache screen instances to avoid rebuilding
  final Map<int, Widget> _screenCache = {};

  // --- GET SCREEN WITH LAZY LOADING ---
  Widget _getScreen(int index) {
    if (_screenCache.containsKey(index)) {
      return _screenCache[index]!;
    }

    Widget screen;
    switch (index) {
      case 0:
        screen = const FieldOfficerHomeScreen();
        break;
      case 1:
        screen = const FieldOfficerFarmerScreen();
        break;
      case 2:
        screen = const FieldOfficerAssessmentScreen();
        break;
      case 3:
        screen = const FieldOfficerProfileScreen();
        break;
      default:
        screen = const FieldOfficerHomeScreen();
    }

    _screenCache[index] = screen;
    return screen;
  }

  void _onItemTapped(int index) async {
    if (index == _currentIndex) return; // Already on this screen

    // Preload the screen first if not cached (happens in background)
    if (!_screenCache.containsKey(index)) {
      _getScreen(index);
    }

    // Show loading animation only if screen is not ready yet
    if (!_screenCache.containsKey(index)) {
      setState(() {
        _isNavigating = true;
      });
      // Minimal delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 10));
    }

    if (mounted) {
      setState(() {
        _currentIndex = index;
        _isNavigating = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Preload the first screen immediately
    _getScreen(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          AnimatedSwitcher(
            duration: const Duration(
                milliseconds: 200), // Faster navigation transition
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<int>(_currentIndex),
              child: _getScreen(_currentIndex),
            ),
          ),
          // Loading overlay during navigation (only show if actually navigating)
          if (_isNavigating)
            IgnorePointer(
              ignoring: false,
              child: Container(
                color: Colors.white.withOpacity(0.85),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: AppColors.brandGreen,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.loading,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: l10n.fieldOfficerNavHome,
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people_rounded,
                  label: l10n.fieldOfficerNavFarmer,
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
                  label: l10n.fieldOfficerNavAssessment,
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: l10n.fieldOfficerNavProfile,
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 150), // Faster nav button animation
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandGreen.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected
                        ? AppColors.brandGreen
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.brandGreen
                          : Colors.grey.shade600,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
