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
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, l10n),

            // Content
              Expanded(
              child: assignments.isEmpty
                  ? _buildEmptyState(l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
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

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandGreen,
            AppColors.brandGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.fieldOfficerDetails,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${assignments.length} ${assignments.length == 1 ? "Assignment" : "Assignments"}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noFieldOfficerAssigned,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A field officer will be assigned to you soon.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandGreen,
                      AppColors.brandGreen.withOpacity(0.6),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 28,
                      backgroundColor: AppColors.creamBackground,
                  child: Icon(Icons.person_rounded, color: Colors.brown, size: 30),
                ),
                    ),
              const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fieldOfficerName,
                            style: GoogleFonts.poppins(
                        fontSize: 18,
                              fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 0.2,
                            ),
                          ),
                    const SizedBox(height: 6),
                          Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                            ),
                            child: Text(
                              statusText,
                              style: GoogleFonts.poppins(
                          fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                          letterSpacing: 0.2,
                          ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 16),

          // Details
          _buildDetailRow(
            Icons.phone_rounded,
            l10n.fieldOfficerPhone,
            fieldOfficerPhone,
            Colors.blue,
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            Icons.location_on_rounded,
            l10n.fieldOfficerLocation,
            'Pincode: $fieldOfficerPincode',
            Colors.orange,
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            Icons.calendar_today_rounded,
            l10n.assignedOn,
            assignedDateStr,
            Colors.grey,
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildDetailRow(
              Icons.note_rounded,
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
