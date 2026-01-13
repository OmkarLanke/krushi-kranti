import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/assignment_models.dart';
import '../services/assignment_service.dart';

class FieldOfficerAssignmentsDialog extends StatefulWidget {
  final int fieldOfficerId;
  final String fieldOfficerName;

  const FieldOfficerAssignmentsDialog({
    super.key,
    required this.fieldOfficerId,
    required this.fieldOfficerName,
  });

  @override
  State<FieldOfficerAssignmentsDialog> createState() =>
      _FieldOfficerAssignmentsDialogState();
}

class _FieldOfficerAssignmentsDialogState
    extends State<FieldOfficerAssignmentsDialog> {
  List<AssignmentResponse> _assignments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assignments =
          await FieldOfficerAssignmentService.getAssignmentsForFieldOfficer(
              widget.fieldOfficerId);
      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = _parseErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.all(
        MediaQuery.of(context).size.width > 600 ? 40 : 20,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width > 1200
            ? 900
            : MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height > 700
            ? 700
            : MediaQuery.of(context).size.height * 0.9,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 1200 ? 900 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height > 700 ? 700 : double.infinity,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farm Assignments',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Field Officer: ${widget.fieldOfficerName}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
                      ),
                    )
                  : _error != null
                      ? _buildErrorView()
                      : _assignments.isEmpty
                          ? _buildEmptyState()
                          : _buildAssignmentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: AppColors.error.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.poppins(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAssignments,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.agriculture_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Farm Assignments',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This field officer has not been assigned to any farms yet.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList() {
    return ListView.builder(
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        return _buildAssignmentCard(assignment);
      },
    );
  }

  Widget _buildAssignmentCard(AssignmentResponse assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.agriculture,
                          color: AppColors.brandGreen, size: 20),
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
              _buildStatusChip(assignment.status),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Farmer Details
          _buildInfoRow(
            Icons.person,
            'Farmer',
            assignment.farmerName ?? 'Unknown Farmer',
          ),
          if (assignment.farmerPhone != null && assignment.farmerPhone!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.phone,
              'Phone',
              assignment.farmerPhone!,
            ),
          ],
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.calendar_today,
            'Assigned On',
            assignment.assignedAt != null
                ? DateFormat('MMM dd, yyyy').format(assignment.assignedAt!)
                : 'N/A',
          ),
          if (assignment.notes != null && assignment.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      assignment.notes!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
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
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Parse and return user-friendly error messages
  String _parseErrorMessage(String error) {
    // Remove "Exception: " prefix if present
    String message = error.replaceFirst('Exception: ', '').trim();
    String lowerMessage = message.toLowerCase();
    
    // Handle network errors
    if (lowerMessage.contains('network error') || 
        lowerMessage.contains('socketexception') ||
        lowerMessage.contains('failed host lookup') ||
        lowerMessage.contains('connection refused') ||
        lowerMessage.contains('connection reset')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }
    
    // Handle server errors
    if (lowerMessage.contains('server error') ||
        lowerMessage.contains('500') ||
        lowerMessage.contains('internal server error')) {
      return 'Server error. Please try again later.';
    }
    
    // Handle service not found
    if (lowerMessage.contains('not found') ||
        lowerMessage.contains('404')) {
      return 'Service unavailable. Please try again later.';
    }
    
    // Handle timeout errors
    if (lowerMessage.contains('timeout') ||
        lowerMessage.contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    
    // Return the original message if it's already user-friendly
    // Otherwise, return a generic error message
    if (message.isNotEmpty && message.length < 100) {
      return message;
    }
    
    return 'Failed to load assignments. Please try again.';
  }

  Widget _buildStatusChip(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
