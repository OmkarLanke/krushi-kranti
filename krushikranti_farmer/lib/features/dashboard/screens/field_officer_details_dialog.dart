import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';

class FieldOfficerDetailsDialog extends StatelessWidget {
  final List<Map<String, dynamic>> assignments;

  const FieldOfficerDetailsDialog({
    super.key,
    required this.assignments,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.fieldOfficerDetails,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            if (assignments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noFieldOfficerAssigned,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return _buildFieldOfficerCard(context, assignment, l10n);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldOfficerCard(
    BuildContext context,
    Map<String, dynamic> assignment,
    AppLocalizations l10n,
  ) {
    final fieldOfficerName = assignment['fieldOfficerName']?.toString() ?? 'Unknown';
    final fieldOfficerPhone = assignment['fieldOfficerPhone']?.toString() ?? 'Not provided';
    final fieldOfficerPincode = assignment['fieldOfficerPincode']?.toString() ?? 'Not provided';
    final status = assignment['status']?.toString() ?? 'UNKNOWN';
    final assignedAt = assignment['assignedAt'];
    final notes = assignment['notes']?.toString();

    // Format assigned date
    String assignedDateStr = 'Not available';
    if (assignedAt != null) {
      try {
        final dateTime = DateTime.parse(assignedAt.toString());
        assignedDateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
      } catch (e) {
        assignedDateStr = assignedAt.toString();
      }
    }

    // Get status color
    Color statusColor = Colors.grey;
    String statusText = status;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        statusColor = AppColors.brandGreen;
        statusText = l10n.active;
        break;
      case 'PENDING':
        statusColor = AppColors.pendingStatus;
        statusText = l10n.pending;
        break;
      case 'COMPLETED':
        statusColor = Colors.blue;
        statusText = l10n.completed;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = l10n.cancelled;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.creamBackground,
                      child: const Icon(Icons.person, color: Colors.brown, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fieldOfficerName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Details
          _buildDetailRow(
            Icons.phone,
            l10n.fieldOfficerPhone,
            fieldOfficerPhone,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.location_on,
            l10n.fieldOfficerLocation,
            'Pincode: $fieldOfficerPincode',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_today,
            l10n.assignedOn,
            assignedDateStr,
            Colors.grey,
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.note,
              'Notes',
              notes,
              Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
