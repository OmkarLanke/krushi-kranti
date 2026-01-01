import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/http_service.dart';
import '../services/field_officer_service.dart';
import 'farm_verification_screen.dart';

class FieldOfficerHomeScreen extends StatefulWidget {
  const FieldOfficerHomeScreen({super.key});

  @override
  State<FieldOfficerHomeScreen> createState() => _FieldOfficerHomeScreenState();
}

class _FieldOfficerHomeScreenState extends State<FieldOfficerHomeScreen> {
  bool _isLoading = true;
  List<dynamic> _assignments = []; // Changed to assignments instead of flattened farms
  String _userName = 'Field Officer';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load user name
      final userData = await StorageService.getUserDetails();
      setState(() {
        _userName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
        if (_userName.isEmpty) {
          _userName = 'Field Officer';
        }
      });

      // Load assignments from field-officer-service
      try {
        final assignments = await FieldOfficerService.getAssignedFarms();
        print('DEBUG: Received ${assignments.length} assignments');
        print('DEBUG: Assignments data: $assignments');
        
        setState(() {
          _assignments = assignments;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading assignments: $e');
        print('Error stack trace: ${StackTrace.current}');
        setState(() {
          _assignments = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: Text(
          'KrushiKranti',
          style: GoogleFonts.poppins(
            color: AppColors.brandGreen,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          _buildCircleIcon(Icons.notifications_none),
          const SizedBox(width: 24),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Text(
                    'Welcome, $_userName',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Assigned Farmers',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Assigned Farmers List
                  if (_assignments.isEmpty)
                    _buildEmptyState()
                  else
                    ..._assignments.map((assignment) => _buildFarmerCard(assignment)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.brandGreen, size: 20),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Farmers Assigned',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will see assigned farmers here once the admin assigns them to you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerCard(dynamic assignment) {
    if (assignment is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    // Create a copy of the assignment to ensure we're using fresh data
    final assignmentCopy = Map<String, dynamic>.from(assignment);
    
    final farmerName = assignmentCopy['farmerName'] ?? 'Unknown Farmer';
    final farmerPhone = assignmentCopy['farmerPhoneNumber'] ?? '';
    final assignedAt = assignmentCopy['assignedAt'];
    final farms = assignmentCopy['farms'] as List? ?? [];
    
    // Format assigned date
    String assignedDateStr = 'Date not available';
    if (assignedAt != null) {
      try {
        final date = DateTime.parse(assignedAt);
        assignedDateStr = 'Assigned On ${_formatDate(date)}';
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    // Get first farm's location for display (or combine all farms)
    String locationStr = 'Location not available';
    if (farms.isNotEmpty) {
      final firstFarm = farms[0] as Map<String, dynamic>?;
      if (firstFarm != null) {
        final village = firstFarm['village'] ?? '';
        final district = firstFarm['district'] ?? '';
        if (village.isNotEmpty || district.isNotEmpty) {
          locationStr = '$village, $district';
        }
      }
    }

    // Get initials for avatar
    String initials = farmerName.isNotEmpty ? farmerName[0].toUpperCase() : '?';
    if (farmerName.contains(' ')) {
      final parts = farmerName.split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC), // Beige background like reference
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to farm verification screen with all farms from assignment
            // Find the latest assignment data from the list to ensure fresh data
            final latestAssignment = _assignments.firstWhere(
              (a) => a is Map<String, dynamic> && 
                     (a['assignmentId'] ?? a['id']) == (assignment['assignmentId'] ?? assignment['id']),
              orElse: () => assignment,
            );
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FarmVerificationScreen(
                  assignment: latestAssignment,
                ),
              ),
            ).then((result) {
              // Always reload data when returning from verification screen
              // to get updated verification status from database
              _loadData();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Picture (Circular Avatar)
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.brandGreen.withOpacity(0.1),
                  child: Text(
                    initials,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Farmer Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farmer Name
                      Text(
                        farmerName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Location
                      Text(
                        locationStr,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Assigned Date
                      Text(
                        assignedDateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      // Farm Details (if multiple farms, show count)
                      if (farms.length > 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${farms.length} farms assigned',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.brandGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (farms.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          (farms[0] is Map<String, dynamic>)
                              ? ((farms[0] as Map<String, dynamic>)['farmName'] ?? 'Farm')
                              : 'Farm',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')} ${date.year}';
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'VERIFIED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
      default:
        return Colors.orange;
    }
  }
}

