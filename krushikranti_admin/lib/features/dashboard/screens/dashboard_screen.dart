import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/sidebar.dart';
import '../../farmers/screens/farmer_list_screen.dart';
import '../../field_officers/screens/field_officer_list_screen.dart';
import '../../job_applications/screens/job_applications_list_screen.dart';
import '../../job_applications/screens/job_application_detail_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentRoute = 'farmers'; // Default to farmers page
  final Map<String, int> _routeIndex = const {
    'dashboard': 0,
    'farmers': 1,
    'field-officers': 2,
    'job-applications': 3,
  };

  Widget _buildCurrentPage() {
    if (_routeIndex.containsKey(_currentRoute)) {
      return IndexedStack(
        index: _routeIndex[_currentRoute]!,
        children: const [
          _DashboardOverview(),
          FarmerListScreen(),
          FieldOfficerListScreen(),
          JobApplicationsListScreen(),
        ],
      );
    }

    switch (_currentRoute) {
      case 'products':
      case 'inventory':
      case 'orders':
      case 'payments':
      case 'users':
      case 'support':
      case 'settings':
        return _buildComingSoon(_currentRoute);
      default:
        return const FarmerListScreen();
    }
  }

  Widget _buildComingSoon(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: AppColors.brandGreen.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            '${title[0].toUpperCase()}${title.substring(1)} Module',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(String route) async {
    if (route == 'logout') {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      setState(() {
        _currentRoute = route;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            currentRoute: _currentRoute,
            onItemSelected: _handleNavigation,
          ),

          // Main Content
          Expanded(
            child: Container(
              color: AppColors.background,
              child: _buildCurrentPage(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard,
            size: 80,
            color: AppColors.brandGreen.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Dashboard Overview',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Charts and analytics coming soon',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
