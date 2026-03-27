import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../models/field_officer_models.dart';
import '../models/assignment_models.dart';
import '../services/assignment_service.dart';
import '../../shared/widgets/photo_viewer_dialog.dart';
import 'field_officer_assignments_dialog.dart';

class FieldOfficerDetailDialog extends StatefulWidget {
  final FieldOfficerSummary fieldOfficer;

  const FieldOfficerDetailDialog({
    super.key,
    required this.fieldOfficer,
  });

  @override
  State<FieldOfficerDetailDialog> createState() => _FieldOfficerDetailDialogState();
}

class _FieldOfficerDetailDialogState extends State<FieldOfficerDetailDialog> {
  List<AssignmentResponse> _assignments = [];
  bool _isLoadingAssignments = false;
  String? _assignmentsError;
  static const int _previewPageSize = 20;
  int _totalAssignmentsCount = 0;

  @override
  void initState() {
    super.initState();
    _totalAssignmentsCount = widget.fieldOfficer.assignedFarmsCount ?? 0;

    final cached = FieldOfficerAssignmentService.getCachedAssignmentsForFieldOfficer(
      widget.fieldOfficer.fieldOfficerId,
      page: 0,
      size: _previewPageSize,
    );
    if (cached != null) {
      _assignments = cached.assignments;
      if (cached.totalElements > 0) {
        _totalAssignmentsCount = cached.totalElements;
      }
      _isLoadingAssignments = false;
      _loadAssignments(showLoader: false, useCache: false);
    } else {
      _loadAssignments();
    }
  }

  Future<void> _loadAssignments({
    bool showLoader = true,
    bool useCache = true,
  }) async {
    if (showLoader) {
      setState(() {
        _isLoadingAssignments = true;
        _assignmentsError = null;
      });
    }

    try {
      final assignmentPage =
          await FieldOfficerAssignmentService.getAssignmentsForFieldOfficer(
        widget.fieldOfficer.fieldOfficerId,
        page: 0,
        size: _previewPageSize,
        useCache: useCache,
      );
      if (!mounted) return;
      setState(() {
        _assignments = assignmentPage.assignments;
        _totalAssignmentsCount = assignmentPage.totalElements;
        _isLoadingAssignments = false;
        _assignmentsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _assignmentsError = _parseErrorMessage(e.toString());
        _isLoadingAssignments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth > 1200 ? 20 : 16,
        vertical: screenHeight > 800 ? 40 : 20,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenWidth > 1200 ? 1000 : screenWidth - 32,
          maxHeight: screenHeight > 800 ? 900 : screenHeight - 40,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Field Officer Details',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.fieldOfficer.fullName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSection(
              'Profile Information',
              Icons.person_outline_rounded,
              AppColors.brandGreen,
              _buildProfileContent(),
            ),
            const SizedBox(height: 20),

            // Status Section
            _buildSection(
              'Status',
              Icons.toggle_on_outlined,
              widget.fieldOfficer.isActive ? AppColors.success : AppColors.textSecondary,
              _buildStatusContent(),
            ),
            const SizedBox(height: 20),

            // Assignments Section
            _buildSection(
              'Farm Assignments ($_totalAssignmentsCount)',
              Icons.agriculture_rounded,
              AppColors.info,
              _buildAssignmentsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color iconColor, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final fo = widget.fieldOfficer;
    return Column(
      children: [
        _buildInfoRow('Full Name', fo.fullName),
        _buildInfoRow('Username', fo.username),
        _buildInfoRow('Email', fo.email),
        _buildInfoRow('Phone Number', fo.phoneNumber),
        _buildInfoRow(
          'Address',
          '${fo.village ?? '-'}, ${fo.district ?? '-'}, ${fo.state ?? '-'}',
          maxLines: 2,
        ),
        if (fo.pincode != null && fo.pincode!.isNotEmpty)
          _buildInfoRow('Pincode', fo.pincode!),
        if (fo.createdAt != null)
          _buildInfoRow('Registered On', _formatDate(fo.createdAt)),
        if (fo.lastUpdatedAt != null)
          _buildInfoRow('Last Updated', _formatDate(fo.lastUpdatedAt)),
      ],
    );
  }

  Widget _buildStatusContent() {
    final isActive = widget.fieldOfficer.isActive;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.successBg,
                      AppColors.success.withOpacity(0.1),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.errorBg,
                      AppColors.error.withOpacity(0.1),
                    ],
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.error.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isActive ? AppColors.success : AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? 'This field officer is currently active'
                          : 'This field officer is currently inactive',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.fieldOfficer.assignedFarmsCount != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.agriculture_rounded,
                    color: AppColors.brandGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Farm Assignments',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.fieldOfficer.assignedFarmsCount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAssignmentsContent() {
    if (_isLoadingAssignments) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
          ),
        ),
      );
    }

    if (_assignmentsError != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Assignments',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _assignmentsError!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAssignments,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_assignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.agriculture_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No Farm Assignments',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This field officer has not been assigned to any farms yet.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Show first 3 assignments with option to view all
        ...(_assignments.take(3).map((assignment) => _buildAssignmentCard(assignment))),
        if (_totalAssignmentsCount > 3) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandGreen.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Close detail dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => FieldOfficerAssignmentsDialog(
                    fieldOfficerId: widget.fieldOfficer.fieldOfficerId,
                    fieldOfficerName: widget.fieldOfficer.fullName,
                    initialAssignments: _assignments,
                    initialTotalCount: _totalAssignmentsCount,
                  ),
                );
              },
              icon: const Icon(Icons.visibility, size: 18),
              label: Text(
                'View All $_totalAssignmentsCount Assignments',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAssignmentCard(AssignmentResponse assignment) {
    // Determine farm assignment status for color scheme
    // - Green  : COMPLETED (assigned and verified)
    // - Orange : ASSIGNED or IN_PROGRESS (assigned but not verified yet)
    // - Red    : CANCELLED (cancelled assignment)
    final String statusUpper = assignment.status.toUpperCase();
    final bool isCompleted = statusUpper == 'COMPLETED';
    final bool isAssignedOrInProgress = statusUpper == 'ASSIGNED' || statusUpper == 'IN_PROGRESS';
    final bool isCancelled = statusUpper == 'CANCELLED';
    
    late final String farmStatusLabel;
    late final Color farmStatusColor;
    late final List<Color> cardGradientColors;
    late final Color cardBorderColor;
    late final Color iconColor;
    
    if (isCompleted) {
      // Completed/Verified => GREEN
      farmStatusLabel = 'Verified farm';
      farmStatusColor = AppColors.success;
      cardGradientColors = [
        AppColors.successBg,
        AppColors.success.withOpacity(0.1),
      ];
      cardBorderColor = AppColors.success.withOpacity(0.3);
      iconColor = AppColors.success;
    } else if (isAssignedOrInProgress) {
      // Assigned but not verified => ORANGE
      farmStatusLabel = 'Assigned · not verified';
      farmStatusColor = AppColors.warning;
      cardGradientColors = [
        AppColors.warning.withOpacity(0.18),
        AppColors.warning.withOpacity(0.06),
      ];
      cardBorderColor = AppColors.warning.withOpacity(0.4);
      iconColor = AppColors.warning;
    } else {
      // Cancelled => RED
      farmStatusLabel = 'Cancelled';
      farmStatusColor = AppColors.error;
      cardGradientColors = [
        AppColors.errorBg,
        AppColors.error.withOpacity(0.1),
      ];
      cardBorderColor = AppColors.error.withOpacity(0.3);
      iconColor = AppColors.error;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradientColors,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardBorderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farm Name and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.agriculture_rounded,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.farmName ?? 'Farm ID: ${assignment.farmId ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (assignment.farmLocation != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              assignment.farmLocation!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip('Farm status', farmStatusLabel, farmStatusColor),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          
          // Assignment Details
          _buildInfoRow(
            'Farmer',
            assignment.farmerName ?? 'Unknown Farmer',
            icon: Icons.person_outline_rounded,
          ),
          if (assignment.farmerPhone != null && assignment.farmerPhone!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Phone',
              assignment.farmerPhone!,
              icon: Icons.phone_outlined,
            ),
          ],
          const SizedBox(height: 8),
          _buildInfoRow(
            'Assigned On',
            assignment.assignedAt != null
                ? _formatDate(assignment.assignedAt!)
                : 'N/A',
            icon: Icons.calendar_today_outlined,
          ),
          if (assignment.completedAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Completed On',
              _formatDate(assignment.completedAt!),
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
          // View Geo Tagged Photo button for completed assignments
          if (assignment.status.toUpperCase() == 'COMPLETED' && assignment.farmId != null) ...[
            const SizedBox(height: 16),
            _buildViewPhotoButton(assignment.farmId!, assignment.farmName ?? 'Farm'),
          ],
          if (assignment.notes != null && assignment.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cardBorderColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      assignment.notes!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignmentStatusChip(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'ASSIGNED':
        color = AppColors.info;
        break;
      case 'IN_PROGRESS':
        color = AppColors.warning;
        break;
      case 'COMPLETED':
        color = AppColors.success;
        break;
      case 'CANCELLED':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            SizedBox(
              width: 160,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 13,
              ),
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _parseErrorMessage(String error) {
    String message = error.replaceFirst('Exception: ', '').trim();
    String lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('network error') ||
        lowerMessage.contains('socketexception') ||
        lowerMessage.contains('failed host lookup') ||
        lowerMessage.contains('connection refused') ||
        lowerMessage.contains('connection reset')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }

    if (lowerMessage.contains('server error') ||
        lowerMessage.contains('500') ||
        lowerMessage.contains('internal server error')) {
      return 'Server error. Please try again later.';
    }

    if (lowerMessage.contains('not found') || lowerMessage.contains('404')) {
      return 'The requested service is temporarily unavailable. Please try again later.';
    }

    if (lowerMessage.contains('timeout') || lowerMessage.contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    if (message.isNotEmpty && message.length < 100) {
      return message;
    }

    return 'Failed to load assignments. Please try again.';
  }

  Widget _buildViewPhotoButton(int farmId, String farmName) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showVerificationPhotos(farmId, farmName),
        icon: const Icon(Icons.photo_camera_rounded, size: 18),
        label: const Text('View Geo Tagged Photo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _showVerificationPhotos(int farmId, String farmName) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading photos...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Fetch photos
      final photos = await FieldOfficerAssignmentService.getVerificationPhotos(farmId);
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Extract photo URLs
      final photoUrls = photos
          .map((photo) => photo['photoUrl'] as String?)
          .whereType<String>()
          .toList();

      // Show photo viewer
      if (mounted && photoUrls.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => PhotoViewerDialog(
            photoUrls: photoUrls,
            title: 'Verification Photos - $farmName',
          ),
        );
      } else if (mounted) {
        // Show error if no photos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No verification photos found for this farm.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading photos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
