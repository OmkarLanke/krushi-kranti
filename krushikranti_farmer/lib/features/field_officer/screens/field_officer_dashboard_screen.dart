import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import 'field_officer_home_screen.dart';
import 'field_officer_farmer_screen.dart';
import 'field_officer_assessment_screen.dart';
import 'field_officer_profile_screen.dart';

class FieldOfficerDashboardScreen extends StatefulWidget {
  const FieldOfficerDashboardScreen({super.key});

  @override
  State<FieldOfficerDashboardScreen> createState() => _FieldOfficerDashboardScreenState();
}

class _FieldOfficerDashboardScreenState extends State<FieldOfficerDashboardScreen> {
  int _currentIndex = 0;

  // --- LIST OF SCREENS ---
  final List<Widget> _screens = [
    const FieldOfficerHomeScreen(),
    const FieldOfficerFarmerScreen(),
    const FieldOfficerAssessmentScreen(),
    const FieldOfficerProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.brandGreen,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          // 1. Home
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'Home',
          ),
          // 2. Farmer
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'Farmer',
          ),
          // 3. Assessment
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_outlined),
            activeIcon: const Icon(Icons.assignment),
            label: 'Assessment',
          ),
          // 4. Profile
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}

