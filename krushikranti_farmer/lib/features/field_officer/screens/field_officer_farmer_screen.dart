import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../services/field_officer_service.dart';
import 'farm_verification_screen.dart';

class FieldOfficerFarmerScreen extends StatefulWidget {
  const FieldOfficerFarmerScreen({super.key});

  @override
  State<FieldOfficerFarmerScreen> createState() => _FieldOfficerFarmerScreenState();
}

class _FieldOfficerFarmerScreenState extends State<FieldOfficerFarmerScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _assignments = [];
  List<dynamic> _filteredAssignments = [];
  
  // Filter states
  String? _selectedVerificationStatus; // null = All, 'PENDING', 'VERIFIED', 'REJECTED'
  String? _selectedDistrict;
  String _searchQuery = '';
  List<String> _availableDistricts = [];
  String? _selectedDateFilter; // null = All, 'TODAY', 'THIS_WEEK', 'THIS_MONTH', 'LAST_MONTH', 'CUSTOM'
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _filterChipController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _filterChipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadData();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _filterChipController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final assignments = await FieldOfficerService.getAssignedFarms();
      setState(() {
        _assignments = assignments;
        _extractDistricts();
        _applyFilters();
        _isLoading = false;
      });
      // Start animations after data loads
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      print('Error loading assignments: $e');
      setState(() {
        _assignments = [];
        _filteredAssignments = [];
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  void _extractDistricts() {
    final districts = <String>{};
    for (var assignment in _assignments) {
      if (assignment is Map<String, dynamic>) {
        final farms = assignment['farms'] as List? ?? [];
        for (var farm in farms) {
          if (farm is Map<String, dynamic>) {
            final district = farm['district'] as String?;
            if (district != null && district.isNotEmpty) {
              districts.add(district);
            }
          }
        }
      }
    }
    _availableDistricts = districts.toList()..sort();
  }

  void _applyFilters() {
    List<dynamic> filtered = List.from(_assignments);

    // Filter by search query (farmer name)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((assignment) {
        if (assignment is! Map<String, dynamic>) return false;
        final farmerName = (assignment['farmerName'] ?? '').toString().toLowerCase();
        return farmerName.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by district
    if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
      filtered = filtered.where((assignment) {
        if (assignment is! Map<String, dynamic>) return false;
        final farms = assignment['farms'] as List? ?? [];
        return farms.any((farm) {
          if (farm is Map<String, dynamic>) {
            return (farm['district'] ?? '').toString() == _selectedDistrict;
          }
          return false;
        });
      }).toList();
    }

    // Filter by verification status
    if (_selectedVerificationStatus != null && _selectedVerificationStatus!.isNotEmpty) {
      filtered = filtered.where((assignment) {
        if (assignment is! Map<String, dynamic>) return false;
        final farms = assignment['farms'] as List? ?? [];
        
        if (_selectedVerificationStatus == 'PENDING') {
          // Show if at least one farm is pending (not verified and not rejected)
          return farms.any((farm) {
            if (farm is Map<String, dynamic>) {
              final isVerified = farm['isVerified'] ?? false;
              final status = (farm['status'] ?? '').toString().toUpperCase();
              return !isVerified && status != 'VERIFIED' && status != 'REJECTED';
            }
            return false;
          });
        } else if (_selectedVerificationStatus == 'VERIFIED') {
          // Show if all farms are verified
          if (farms.isEmpty) return false;
          return farms.every((farm) {
            if (farm is Map<String, dynamic>) {
              final isVerified = farm['isVerified'] ?? false;
              final status = (farm['status'] ?? '').toString().toUpperCase();
              return isVerified || status == 'VERIFIED';
            }
            return false;
          });
        } else if (_selectedVerificationStatus == 'REJECTED') {
          // Show if at least one farm is rejected
          return farms.any((farm) {
            if (farm is Map<String, dynamic>) {
              final status = (farm['status'] ?? '').toString().toUpperCase();
              return status == 'REJECTED';
            }
            return false;
          });
        }
        return true;
      }).toList();
    }

    // Filter by date
    if (_selectedDateFilter != null && _selectedDateFilter!.isNotEmpty) {
      DateTime? startDate;
      DateTime? endDate;
      final now = DateTime.now();
      
      if (_selectedDateFilter == 'TODAY') {
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (_selectedDateFilter == 'THIS_WEEK') {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        endDate = now;
      } else if (_selectedDateFilter == 'THIS_MONTH') {
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
      } else if (_selectedDateFilter == 'LAST_MONTH') {
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = DateTime(lastMonth.year, lastMonth.month, 1);
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
      } else if (_selectedDateFilter == 'CUSTOM' && _customStartDate != null && _customEndDate != null) {
        startDate = _customStartDate;
        endDate = _customEndDate;
      }
      
      if (startDate != null && endDate != null) {
        filtered = filtered.where((assignment) {
          if (assignment is! Map<String, dynamic>) return false;
          final assignedAt = assignment['assignedAt'];
          if (assignedAt == null) return false;
          
          try {
            final assignedDate = DateTime.parse(assignedAt);
            final assignedDateOnly = DateTime(assignedDate.year, assignedDate.month, assignedDate.day);
            final startDateOnly = DateTime(startDate!.year, startDate!.month, startDate!.day);
            final endDateOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
            
            return (assignedDateOnly.isAtSameMomentAs(startDateOnly) || assignedDateOnly.isAfter(startDateOnly)) &&
                   (assignedDateOnly.isAtSameMomentAs(endDateOnly) || assignedDateOnly.isBefore(endDateOnly));
          } catch (e) {
            return false;
          }
        }).toList();
      }
    }

    setState(() {
      _filteredAssignments = filtered;
    });
    // Animate filter chips when filters change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasActiveFilters()) {
        _filterChipController.forward();
      } else {
        _filterChipController.reverse();
      }
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')} ${date.year}';
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
          'Farmers',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.brandGreen,
              child: _assignments.isEmpty
                  ? _buildEmptyState()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          children: [
                            // Search Bar and Filter Button in one row
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Search Bar
                                      Expanded(
                                        child: _buildAnimatedSearchBar(),
                                      ),
                                      const SizedBox(width: 12),
                                      // Filter Button
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: _hasActiveFilters() ? 1.0 : 0.0),
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: 1.0 + (value * 0.1),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: _hasActiveFilters()
                                                    ? AppColors.brandGreen
                                                    : Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _hasActiveFilters()
                                                      ? AppColors.brandGreen
                                                      : Colors.grey.shade300,
                                                  width: _hasActiveFilters() ? 2 : 1.5,
                                                ),
                                                boxShadow: _hasActiveFilters()
                                                    ? [
                                                        BoxShadow(
                                                          color: AppColors.brandGreen.withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: _showFilterBottomSheet,
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(12),
                                                    child: Icon(
                                                      Icons.filter_list,
                                                      color: _hasActiveFilters()
                                                          ? Colors.white
                                                          : AppColors.textSecondary,
                                                      size: 24,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        // Active Filters Chips
                        AnimatedBuilder(
                          animation: _filterChipController,
                          builder: (context, child) {
                            return SizeTransition(
                              sizeFactor: _filterChipController,
                              axisAlignment: -1.0,
                              child: _hasActiveFilters()
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      child: SizedBox(
                                        height: 50,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          physics: const BouncingScrollPhysics(),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_selectedVerificationStatus != null)
                                                _buildAnimatedFilterChip(
                                                  'Status: ${_getStatusLabel(_selectedVerificationStatus!)}',
                                                  () {
                                                    setState(() {
                                                      _selectedVerificationStatus = null;
                                                    });
                                                    _applyFilters();
                                                  },
                                                ),
                                              if (_selectedDistrict != null)
                                                _buildAnimatedFilterChip(
                                                  'District: $_selectedDistrict',
                                                  () {
                                                    setState(() {
                                                      _selectedDistrict = null;
                                                    });
                                                    _applyFilters();
                                                  },
                                                ),
                                              if (_selectedDateFilter != null)
                                                _buildAnimatedFilterChip(
                                                  'Date: ${_getDateFilterLabel(_selectedDateFilter!)}',
                                                  () {
                                                    setState(() {
                                                      _selectedDateFilter = null;
                                                      _customStartDate = null;
                                                      _customEndDate = null;
                                                    });
                                                    _applyFilters();
                                                  },
                                                ),
                                              if (_searchQuery.isNotEmpty)
                                                _buildAnimatedFilterChip(
                                                  'Search: ${_searchQuery.length > 15 ? "${_searchQuery.substring(0, 15)}..." : _searchQuery}',
                                                  () {
                                                    setState(() {
                                                      _searchQuery = '';
                                                    });
                                                    _applyFilters();
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            );
                          },
                        ),
                        // Farmers List
                        Expanded(
                          child: _filteredAssignments.isEmpty
                              ? _buildEmptyFilterState()
                              : FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                                        FadeTransition(
                                          opacity: _fadeAnimation,
                                          child: Text(
                                            'Assigned Farmers (${_filteredAssignments.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                                            ),
                            ),
                          ),
                          const SizedBox(height: 16),
                                        ..._filteredAssignments.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final assignment = entry.value;
                                          return _buildAnimatedFarmerCard(assignment, index);
                                        }).toList(),
                        ],
                      ),
                    ),
            ),
                        ),
                      ],
                    );
                      },
                    ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandGreen,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeIn,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  'Loading farmers...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSearchBar() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                                _applyFilters();
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by farmer name...',
                                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                          _applyFilters();
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.brandGreen, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedFilterChip(String label, VoidCallback onRemove) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              constraints: const BoxConstraints(
                maxWidth: 200,
                maxHeight: 40,
              ),
              child: Chip(
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                label: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                onDeleted: onRemove,
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: AppColors.brandGreen.withOpacity(0.1),
                labelStyle: const TextStyle(color: AppColors.brandGreen),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedFarmerCard(dynamic assignment, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: _buildFarmerCard(assignment),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
              Icons.assignment_outlined,
              size: 80,
                      color: AppColors.brandGreen.withOpacity(value),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: AlwaysStoppedAnimation(value),
                  child: Text(
              'No Farmers Assigned',
              style: GoogleFonts.poppins(
                      fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: AlwaysStoppedAnimation(value * 0.8),
                  child: Text(
              'You will see assigned farmers here once the admin assigns them to you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
        );
      },
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
    String initials = _getInitials(farmerName);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.98 + (0.02 * value),
          child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC), // Beige background like reference
              borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
                  color: Colors.black.withOpacity(0.08 * value),
                  blurRadius: 15,
                  offset: Offset(0, 4 * value),
                  spreadRadius: 0,
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
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => FarmVerificationScreen(
                  assignment: latestAssignment,
                ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOutCubic,
                          )),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
              ),
            ).then((result) {
              // Always reload data when returning from verification screen
              // to get updated verification status from database
              _loadData();
            });
          },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                      // Profile Picture (Circular Avatar) with animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.brandGreen.withOpacity(0.2),
                                    AppColors.brandGreen.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.transparent,
                  child: Text(
                    initials,
                    style: GoogleFonts.poppins(
                                    fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 18),
                // Farmer Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farmer Name
                      Text(
                        farmerName,
                        style: GoogleFonts.poppins(
                                fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                                letterSpacing: 0.2,
                        ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                      ),
                            const SizedBox(height: 6),
                      // Location
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                        locationStr,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                      ),
                      const SizedBox(height: 4),
                      // Assigned Date
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                      Text(
                        assignedDateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                                ),
                              ],
                      ),
                      // Farm Details (if multiple farms, show count)
                      if (farms.length > 1) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.brandGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                          '${farms.length} farms assigned',
                          style: GoogleFonts.poppins(
                                    fontSize: 11,
                            color: AppColors.brandGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                      // Arrow Icon with animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(-10 * (1 - value), 0),
                            child: Opacity(
                              opacity: value,
                              child: Icon(
                  Icons.arrow_forward_ios,
                                size: 18,
                                color: AppColors.brandGreen,
                              ),
                            ),
                          );
                        },
                      ),
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

  bool _hasActiveFilters() {
    return _selectedVerificationStatus != null ||
        _selectedDistrict != null ||
        _selectedDateFilter != null ||
        _searchQuery.isNotEmpty;
  }


  void _showFilterBottomSheet() {
    // Store temporary filter values
    String? tempVerificationStatus = _selectedVerificationStatus;
    String? tempDistrict = _selectedDistrict;
    String? tempDateFilter = _selectedDateFilter;
    DateTime? tempStartDate = _customStartDate;
    DateTime? tempEndDate = _customEndDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 100 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                  // Header with icon and animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, -20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.brandGreen.withOpacity(0.12),
                                            AppColors.brandGreen.withOpacity(0.06),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.tune,
                                        color: AppColors.brandGreen.withOpacity(0.9),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Filter Farmers',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF424242),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        tempVerificationStatus = null;
                                        tempDistrict = null;
                                        tempDateFilter = null;
                                        tempStartDate = null;
                                        tempEndDate = null;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.refresh,
                                            size: 14,
                                            color: AppColors.error,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Clear All',
                                            style: GoogleFonts.poppins(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey.shade100,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Verification Status Filter with animation
                          _buildAnimatedFilterSection(
                            delay: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user,
                                      size: 18,
                                      color: AppColors.brandGreen.withOpacity(0.85),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Verification Status',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF424242),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _buildEnhancedFilterOption(
                                      'All',
                                      Icons.apps,
                                      tempVerificationStatus == null,
                                      () {
                                        setModalState(() {
                                          tempVerificationStatus = null;
                                        });
                                      },
                                    ),
                                    _buildEnhancedFilterOption(
                                      'Pending',
                                      Icons.pending,
                                      tempVerificationStatus == 'PENDING',
                                      () {
                                        setModalState(() {
                                          tempVerificationStatus = 'PENDING';
                                        });
                                      },
                                    ),
                                    _buildEnhancedFilterOption(
                                      'Verified',
                                      Icons.check_circle,
                                      tempVerificationStatus == 'VERIFIED',
                                      () {
                                        setModalState(() {
                                          tempVerificationStatus = 'VERIFIED';
                                        });
                                      },
                                    ),
                                    _buildEnhancedFilterOption(
                                      'Rejected',
                                      Icons.cancel,
                                      tempVerificationStatus == 'REJECTED',
                                      () {
                                        setModalState(() {
                                          tempVerificationStatus = 'REJECTED';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // District Filter with animation
                          _buildAnimatedFilterSection(
                            delay: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: AppColors.brandGreen.withOpacity(0.85),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'District',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF424242),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE8E8E8),
                                      width: 1,
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: tempDistrict,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.brandGreen, width: 2),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.map,
                                        color: AppColors.brandGreen.withOpacity(0.85),
                                        size: 20,
                                      ),
                                    ),
                                    hint: Text(
                                      'Select District',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                  color: AppColors.textSecondary,
                ),
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          'All Districts',
                                          style: GoogleFonts.poppins(fontSize: 15),
                                        ),
                                      ),
                                      ..._availableDistricts.map((district) => DropdownMenuItem<String>(
                                            value: district,
                                            child: Text(
                                              district,
                                              style: GoogleFonts.poppins(fontSize: 15),
                                            ),
                                          )),
                                    ],
                                    onChanged: (value) {
                                      setModalState(() {
                                        tempDistrict = value;
                                      });
                                    },
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    dropdownColor: Colors.white,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: AppColors.brandGreen.withOpacity(0.85),
                                      size: 28,
                                    ),
        ),
      ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Date Filter with animation
                          _buildAnimatedFilterSection(
                            delay: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: AppColors.brandGreen.withOpacity(0.85),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Date Assigned',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF424242),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _buildEnhancedFilterOption(
                                      'All',
                                      Icons.all_inclusive,
                                      tempDateFilter == null,
                                      () {
                                        setModalState(() {
                                          tempDateFilter = null;
                                          tempStartDate = null;
                                          tempEndDate = null;
                                        });
                                      },
                                    ),
                                    _buildEnhancedFilterOption(
                                      'Today',
                                      Icons.today,
                                      tempDateFilter == 'TODAY',
                                      () {
                                        setModalState(() {
                                          tempDateFilter = 'TODAY';
                                          tempStartDate = null;
                                          tempEndDate = null;
                                        });
                                      },
                                    ),
                                    _buildEnhancedFilterOption(
                                      'This Week',
                                      Icons.view_week,
                                      tempDateFilter == 'THIS_WEEK',
                                      () {
                                        setModalState(() {
                                          tempDateFilter = 'THIS_WEEK';
                                          tempStartDate = null;
                                          tempEndDate = null;
                                        });
                                      },
                                    ),
                                    _buildEnhancedFilterOption(
                                      'This Month',
                                      Icons.calendar_month,
                                      tempDateFilter == 'THIS_MONTH',
                                      () {
                                        setModalState(() {
                                          tempDateFilter = 'THIS_MONTH';
                                          tempStartDate = null;
                                          tempEndDate = null;
                                        });
                                      },
                                    ),
                                    _buildEnhancedFilterOption(
                                      'Last Month',
                                      Icons.history,
                                      tempDateFilter == 'LAST_MONTH',
                                      () {
                                        setModalState(() {
                                          tempDateFilter = 'LAST_MONTH';
                                          tempStartDate = null;
                                          tempEndDate = null;
                                        });
                                      },
                                    ),
                                    _buildEnhancedFilterOption(
                                      'Custom',
                                      Icons.date_range,
                                      tempDateFilter == 'CUSTOM',
                                      () {
                                        setModalState(() {
                                          tempDateFilter = 'CUSTOM';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                // Custom Date Range Picker with animation
                                if (tempDateFilter == 'CUSTOM')
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: 0.95 + (0.05 * value),
                                        child: Opacity(
                                          opacity: value,
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _buildAnimatedDatePicker(
                                                    'Start Date',
                                                    tempStartDate,
                                                    Icons.calendar_today,
                                                    () async {
                                                      final date = await showDatePicker(
                                                        context: context,
                                                        initialDate: tempStartDate ?? DateTime.now(),
                                                        firstDate: DateTime(2020),
                                                        lastDate: DateTime.now(),
                                                      );
                                                      if (date != null) {
                                                        setModalState(() {
                                                          tempStartDate = date;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: _buildAnimatedDatePicker(
                                                    'End Date',
                                                    tempEndDate,
                                                    Icons.event,
                                                    () async {
                                                      final date = await showDatePicker(
                                                        context: context,
                                                        initialDate: tempEndDate ?? DateTime.now(),
                                                        firstDate: tempStartDate ?? DateTime(2020),
                                                        lastDate: DateTime.now(),
                                                      );
                                                      if (date != null) {
                                                        setModalState(() {
                                                          tempEndDate = date;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Apply Button with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedVerificationStatus = tempVerificationStatus;
                                    _selectedDistrict = tempDistrict;
                                    _selectedDateFilter = tempDateFilter;
                                    _customStartDate = tempStartDate;
                                    _customEndDate = tempEndDate;
                                  });
                                  _applyFilters();
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.brandGreen,
                                        AppColors.brandGreen.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.brandGreen.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Apply Filters',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
        },
      ),
    );
  }

  Widget _buildAnimatedFilterSection({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildEnhancedFilterOption(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: isSelected ? 1.0 : 0.95 + (0.05 * value),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.brandGreen 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.brandGreen 
                        : const Color(0xFFE8E8E8),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.brandGreen.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                            spreadRadius: 0,
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected 
                          ? Colors.white 
                          : AppColors.brandGreen.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected 
                              ? Colors.white 
                              : const Color(0xFF616161),
                          letterSpacing: 0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDatePicker(
    String label,
    DateTime? date,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: date != null
                ? AppColors.brandGreen.withOpacity(0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: date != null
                  ? AppColors.brandGreen
                  : const Color(0xFFE8E8E8),
              width: date != null ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: date != null
                      ? AppColors.brandGreen
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: date != null 
                      ? Colors.white 
                      : const Color(0xFFBDBDBD),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date != null ? _formatDate(date!) : 'Select',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: date != null ? Colors.black : AppColors.textSecondary,
                        fontWeight: date != null ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, bool isSelected, VoidCallback onTap) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: isSelected ? 1.0 : 0.95 + (0.05 * value),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandGreen : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.brandGreen : Colors.grey.shade300,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.brandGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'VERIFIED':
        return 'Verified';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }

  String _getDateFilterLabel(String filter) {
    switch (filter) {
      case 'TODAY':
        return 'Today';
      case 'THIS_WEEK':
        return 'This Week';
      case 'THIS_MONTH':
        return 'This Month';
      case 'LAST_MONTH':
        return 'Last Month';
      case 'CUSTOM':
        if (_customStartDate != null && _customEndDate != null) {
          return '${_formatDate(_customStartDate!)} - ${_formatDate(_customEndDate!)}';
        }
        return 'Custom Range';
      default:
        return filter;
    }
  }

  Widget _buildEmptyFilterState() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.filter_alt_outlined,
                      size: 80,
                      color: AppColors.textSecondary.withOpacity(value),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: AlwaysStoppedAnimation(value),
                  child: Text(
                    'No Farmers Found',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: AlwaysStoppedAnimation(value * 0.8),
                  child: Text(
                    'Try adjusting your filters to see more results.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
