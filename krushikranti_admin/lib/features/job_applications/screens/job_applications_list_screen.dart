import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../models/job_application_models.dart';
import '../services/job_application_service.dart';
import 'job_application_detail_screen.dart';

class JobApplicationsListScreen extends StatefulWidget {
  const JobApplicationsListScreen({Key? key}) : super(key: key);

  @override
  State<JobApplicationsListScreen> createState() =>
      _JobApplicationsListScreenState();
}

class _JobApplicationsListScreenState extends State<JobApplicationsListScreen> {
  final JobApplicationService _service = JobApplicationService();

  List<JobApplication> _applications = [];
  List<JobApplication> _filteredApplications = [];
  JobApplicationStats? _stats;
  bool _isLoading = true;

  // Filter controllers
  String _selectedStatus = 'ALL';
  String _selectedRoleType = 'ALL';

  // Column search controllers
  final TextEditingController _nameSearchController = TextEditingController();
  final TextEditingController _emailSearchController = TextEditingController();
  final TextEditingController _mobileSearchController = TextEditingController();

  // Dropdown overlay states
  OverlayEntry? _statusFilterOverlay;
  OverlayEntry? _roleTypeFilterOverlay;
  final LayerLink _statusFilterLayerLink = LayerLink();
  final LayerLink _roleTypeFilterLayerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _loadData();

    // Add listeners
    _nameSearchController.addListener(_applyFilters);
    _emailSearchController.addListener(_applyFilters);
    _mobileSearchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _nameSearchController.dispose();
    _emailSearchController.dispose();
    _mobileSearchController.dispose();
    _statusFilterOverlay?.remove();
    _roleTypeFilterOverlay?.remove();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final applications = await _service.getAllApplications();
      final stats = await _service.getStats();

      setState(() {
        _applications = applications;
        _filteredApplications = applications;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredApplications = _applications.where((app) {
        // Status filter
        if (_selectedStatus != 'ALL' && app.currentStatus != _selectedStatus) {
          return false;
        }

        // Role type filter
        if (_selectedRoleType != 'ALL' && app.roleType != _selectedRoleType) {
          return false;
        }

        // Name search
        if (_nameSearchController.text.isNotEmpty &&
            !app.fullName.toLowerCase().contains(
              _nameSearchController.text.toLowerCase(),
            )) {
          return false;
        }

        // Email search
        if (_emailSearchController.text.isNotEmpty &&
            (app.email == null ||
                !app.email!.toLowerCase().contains(
                  _emailSearchController.text.toLowerCase(),
                ))) {
          return false;
        }

        // Mobile search
        if (_mobileSearchController.text.isNotEmpty &&
            (app.mobileNumber == null ||
                !app.mobileNumber!.contains(_mobileSearchController.text))) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _showStatusFilter(BuildContext context) {
    _statusFilterOverlay?.remove();
    _statusFilterOverlay = _createFilterOverlay(
      context,
      _statusFilterLayerLink,
      [
        {'value': 'ALL', 'label': 'All Status'},
        {'value': 'SCREENING', 'label': 'Screening'},
        {'value': 'SELECTED_FOR_HR', 'label': 'Selected for HR'},
        {'value': 'SELECTED', 'label': 'Selected'},
        {'value': 'REJECTED', 'label': 'Rejected'},
      ],
      _selectedStatus,
      (value) {
        setState(() => _selectedStatus = value);
        _applyFilters();
        _statusFilterOverlay?.remove();
        _statusFilterOverlay = null;
      },
    );
    Overlay.of(context).insert(_statusFilterOverlay!);
  }

  void _showRoleTypeFilter(BuildContext context) {
    _roleTypeFilterOverlay?.remove();
    _roleTypeFilterOverlay = _createFilterOverlay(
      context,
      _roleTypeFilterLayerLink,
      [
        {'value': 'ALL', 'label': 'All Roles'},
        {'value': 'FIELD_OFFICER', 'label': 'Field Officer'},
        {'value': 'KRUSHI_TADNYA', 'label': 'Krushi Tadnya'},
        {'value': 'VENDOR', 'label': 'Vendor'},
      ],
      _selectedRoleType,
      (value) {
        setState(() => _selectedRoleType = value);
        _applyFilters();
        _roleTypeFilterOverlay?.remove();
        _roleTypeFilterOverlay = null;
      },
    );
    Overlay.of(context).insert(_roleTypeFilterOverlay!);
  }

  OverlayEntry _createFilterOverlay(
    BuildContext context,
    LayerLink layerLink,
    List<Map<String, String>> options,
    String selectedValue,
    Function(String) onSelect,
  ) {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 220,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option['value'] == selectedValue;

                  return InkWell(
                    onTap: () => onSelect(option['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandGreen.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          if (isSelected)
                            Icon(
                              Icons.check,
                              size: 18,
                              color: AppColors.brandGreen,
                            ),
                          if (isSelected) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              option['label']!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.brandGreen
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job Applications',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage and review job applications',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Cards
                if (_stats != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Total Applications',
                            value: _stats!.total.toString(),
                            icon: Icons.people_outline,
                            color: AppColors.brandGreen,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Screening',
                            value: _stats!.screening.toString(),
                            icon: Icons.schedule,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Selected for HR',
                            value: _stats!.selectedForHR.toString(),
                            icon: Icons.event,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Selected',
                            value: _stats!.selected.toString(),
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Data Table
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Table Header with Search
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildSearchField(
                                    'Search name...',
                                    _nameSearchController,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _buildSearchField(
                                    'Search email...',
                                    _emailSearchController,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: _buildSearchField(
                                    'Search mobile...',
                                    _mobileSearchController,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: CompositedTransformTarget(
                                    link: _roleTypeFilterLayerLink,
                                    child: _buildFilterButton(
                                      'Role Type',
                                      _selectedRoleType == 'ALL'
                                          ? 'All Roles'
                                          : _service.getRoleTypeDisplay(
                                              _selectedRoleType,
                                            ),
                                      () => _showRoleTypeFilter(context),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: CompositedTransformTarget(
                                    link: _statusFilterLayerLink,
                                    child: _buildFilterButton(
                                      'Status',
                                      _selectedStatus == 'ALL'
                                          ? 'All Status'
                                          : _service.getStatusDisplay(
                                              _selectedStatus,
                                            ),
                                      () => _showStatusFilter(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Table Content
                          Expanded(
                            child: _filteredApplications.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No applications found',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView(
                                    children: [
                                      // Table Header Row
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Full Name',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Email',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'Mobile',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'Role Type',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'Status',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                'Applied Date',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 100),
                                          ],
                                        ),
                                      ),

                                      // Table Rows
                                      ..._filteredApplications.map((app) {
                                        return _buildApplicationRow(app);
                                      }).toList(),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSearchField(String hint, TextEditingController controller) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationRow(JobApplication app) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                JobApplicationDetailScreen(applicationId: app.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                app.fullName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                app.email ?? 'N/A',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                app.mobileNumber ?? 'N/A',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                app.roleTypeDisplay,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(flex: 1, child: _buildStatusBadge(app.currentStatus)),
            Expanded(
              flex: 1,
              child: Text(
                DateFormat('dd MMM yyyy').format(app.appliedAt),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          JobApplicationDetailScreen(applicationId: app.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'SCREENING':
        bgColor = AppColors.warningBg;
        textColor = AppColors.warning;
        break;
      case 'SELECTED_FOR_HR':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case 'SELECTED':
        bgColor = AppColors.successBg;
        textColor = AppColors.success;
        break;
      case 'REJECTED':
        bgColor = AppColors.errorBg;
        textColor = AppColors.error;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _service.getStatusDisplay(status),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
