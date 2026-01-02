import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../services/field_officer_service.dart';
import 'farm_verification_screen.dart';

class FieldOfficerHomeScreen extends StatefulWidget {
  const FieldOfficerHomeScreen({super.key});

  @override
  State<FieldOfficerHomeScreen> createState() => _FieldOfficerHomeScreenState();
}

class _FieldOfficerHomeScreenState extends State<FieldOfficerHomeScreen> {
  bool _isLoading = true;
  List<dynamic> _assignments = [];
  String _userName = 'Field Officer';
  String _userId = '';
  String _region = '';
  Map<String, dynamic> _profileData = {};

  // Statistics
  int _totalAssignedFarmers = 0;
  int _approvedFarms = 0;
  int _pendingFarms = 0;
  List<String> _assignedVillages = [];
  List<dynamic> _pendingVerifications = [];
  List<dynamic> _priorityFarms = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load user profile data
      final userData = await StorageService.getUserDetails();
      setState(() {
        _userName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
        if (_userName.isEmpty) {
          _userName = 'Field Officer';
        }
        _userId = userData['userId']?.toString() ?? '';
        _region = userData['district']?.toString() ?? 'Region';
      });

      // Try to get profile data for region
      try {
        final profile = await FieldOfficerService.getProfile();
        if (profile.isNotEmpty) {
          setState(() {
            _profileData = profile;
            _region = profile['district']?.toString() ?? profile['state']?.toString() ?? 'Region';
            _userId = profile['fieldOfficerId']?.toString() ?? _userId;
          });
        }
      } catch (e) {
        print('Error loading profile: $e');
      }

      // Load assignments
      final assignments = await FieldOfficerService.getAssignedFarms();
      
      // Calculate statistics
      _calculateStatistics(assignments);
      
      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics(List<dynamic> assignments) {
    Set<String> uniqueFarmers = {};
    Set<String> villages = {};
    int approved = 0;
    int pending = 0;
    List<dynamic> pendingVerifs = [];
    List<dynamic> priorityFarms = [];

    for (var assignment in assignments) {
      if (assignment is! Map<String, dynamic>) continue;
      
      final farmerUserId = assignment['farmerUserId']?.toString() ?? '';
      if (farmerUserId.isNotEmpty) {
        uniqueFarmers.add(farmerUserId);
      }

      final farms = assignment['farms'] as List? ?? [];
      final farmerName = assignment['farmerName'] ?? 'Unknown Farmer';
      final assignedAt = assignment['assignedAt'];

      for (var farm in farms) {
        if (farm is! Map<String, dynamic>) continue;
        
        final village = farm['village']?.toString() ?? '';
        if (village.isNotEmpty) {
          villages.add(village);
        }

        final status = farm['status']?.toString().toUpperCase() ?? 'PENDING';
        final isVerified = farm['isVerified'] ?? false;

        if (status == 'VERIFIED' || isVerified == true) {
          approved++;
        } else {
          pending++;
          // Add to pending verifications
          pendingVerifs.add({
            'farmerName': farmerName,
            'village': village,
            'farm': farm,
            'assignment': assignment,
            'assignedAt': assignedAt,
          });

          // Check if pending for more than 4 days
          if (assignedAt != null) {
            try {
              final assignedDate = DateTime.parse(assignedAt);
              final daysPending = DateTime.now().difference(assignedDate).inDays;
              if (daysPending > 4) {
                priorityFarms.add({
                  'farmerName': farmerName,
                  'village': village,
                  'farm': farm,
                  'assignment': assignment,
                  'daysPending': daysPending,
                });
              }
            } catch (e) {
              print('Error parsing date: $e');
            }
          }
        }
      }
    }

    setState(() {
      _totalAssignedFarmers = uniqueFarmers.length;
      _approvedFarms = approved;
      _pendingFarms = pending;
      _assignedVillages = villages.toList()..sort();
      _pendingVerifications = pendingVerifs;
      _priorityFarms = priorityFarms;
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              color: AppColors.brandGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandGreen),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.brandGreen,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Profile Card
                    _buildProfileCard(),
                    const SizedBox(height: 16),

                    // Assigned Villages
                    _buildAssignedVillages(),
                    const SizedBox(height: 24),

                    // Summary Statistics
                    _buildStatisticsCards(),
                    const SizedBox(height: 24),

                    // Pending Verification Section
                    _buildPendingVerificationSection(),
                    const SizedBox(height: 24),

                    // Priority Farm Section
                    _buildPriorityFarmSection(),
                    const SizedBox(height: 24),

                    // Additional Analytics Section
                    _buildAdditionalAnalyticsSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Image at Top
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/field_officer/farm.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF81C784),
                        const Color(0xFF66BB6A),
                        AppColors.brandGreen,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // User Info Overlay at Bottom (Left side, near profile picture)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 120, top: 7, bottom: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF0), // Very pale cream/off-white background
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _userName,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ID : ${_userId.isNotEmpty ? _userId : 'N/A'}',
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        _region,
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.brandGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Profile Picture on Right
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset(
                  'assets/images/field_officer/krushifarmer.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to initials if image fails to load
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: AppColors.brandGreen.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_userName),
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandGreen,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedVillages() {
    if (_assignedVillages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: AppColors.brandGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Assigned Villages: ${_assignedVillages.join(', ')}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Assigned Farmer',
            _totalAssignedFarmers.toString(),
            Icons.people,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Approved Farms',
            _approvedFarms.toString(),
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending Farms',
            _pendingFarms.toString(),
            Icons.pending,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.brandGreen,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pending Verification',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to first pending verification or show list
                if (_pendingVerifications.isNotEmpty) {
                  final firstPending = _pendingVerifications[0];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FarmVerificationScreen(
                        assignment: firstPending['assignment'],
                      ),
                    ),
                  ).then((_) => _loadData());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Visit Now',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_pendingVerifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No pending verifications',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...(_pendingVerifications.take(2).map((item) => _buildPendingVerificationItem(item))),
      ],
    );
  }

  Widget _buildPendingVerificationItem(dynamic item) {
    final farmerName = item['farmerName'] ?? 'Unknown';
    final village = item['village'] ?? '';
    final assignment = item['assignment'];
    final assignedAt = item['assignedAt'];

    String timeStr = 'Today';
    if (assignedAt != null) {
      try {
        final date = DateTime.parse(assignedAt);
        final now = DateTime.now();
        if (date.year == now.year && date.month == now.month && date.day == now.day) {
          timeStr = 'Today ${_formatTime(date)}';
        } else {
          timeStr = _formatDate(date);
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FarmVerificationScreen(
                assignment: assignment,
              ),
            ),
          ).then((_) => _loadData());
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.brandGreen.withOpacity(0.1),
              child: Text(
                _getInitials(farmerName),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandGreen,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmerName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    village,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.brandGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityFarmSection() {
    if (_priorityFarms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Priority Farm',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'High Priority',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF7043),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_priorityFarms.length} Farms pending for over 4 days',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        if (_priorityFarms.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                final firstPriority = _priorityFarms[0];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmVerificationScreen(
                      assignment: firstPriority['assignment'],
                    ),
                  ),
                ).then((_) => _loadData());
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.brandGreen.withOpacity(0.1),
                    child: Text(
                      _getInitials(_priorityFarms[0]['farmerName'] ?? ''),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _priorityFarms[0]['farmerName'] ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_priorityFarms[0]['village'] ?? ''}, ${_priorityFarms[0]['farm']?['cropName'] ?? 'Farm'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF7043),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pending for ${_priorityFarms[0]['daysPending']} days',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFFFF7043),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdditionalAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Analytics',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Analytics content will be shown here',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')} ${date.year}';
  }
}
