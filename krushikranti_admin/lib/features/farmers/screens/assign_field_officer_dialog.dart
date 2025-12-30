import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../field_officers/models/assignment_models.dart';
import '../../field_officers/services/assignment_service.dart';
import '../models/farmer_models.dart';
import '../services/farmer_service.dart';

class AssignFieldOfficerDialog extends StatefulWidget {
  final int farmerUserId;
  final int farmerId;

  const AssignFieldOfficerDialog({
    super.key,
    required this.farmerUserId,
    required this.farmerId,
  });

  @override
  State<AssignFieldOfficerDialog> createState() =>
      _AssignFieldOfficerDialogState();
}

class _AssignFieldOfficerDialogState extends State<AssignFieldOfficerDialog> {
  List<SuggestedFieldOfficer> _suggestedFieldOfficers = [];
  List<FarmInfo> _farms = [];
  bool _isLoading = true;
  bool _isAssigning = false;
  String? _error;
  SuggestedFieldOfficer? _selectedFieldOfficer;
  FarmInfo? _selectedFarm;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load farmer detail to get farms
      final farmerDetail = await AdminFarmerService.getFarmerDetail(widget.farmerId);
      setState(() {
        _farms = farmerDetail.farms;
      });

      // Load suggested field officers
      final suggestions =
          await FieldOfficerAssignmentService.getSuggestedFieldOfficers(
              widget.farmerUserId);

      setState(() {
        _suggestedFieldOfficers = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _assignFieldOfficer() async {
    if (_selectedFieldOfficer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a field officer'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedFarm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a farm'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      final request = AssignFieldOfficerRequest(
        fieldOfficerId: _selectedFieldOfficer!.fieldOfficerId,
        farmerUserId: widget.farmerUserId,
        farmId: _selectedFarm!.farmId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await FieldOfficerAssignmentService.assignFieldOfficer(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Field officer assigned successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        // Extract error message - backend returns detailed messages
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        
        // Show error in a dialog if it contains assignment conflict details
        if (errorMessage.contains('already assigned') || 
            errorMessage.contains('already assigned to field officer')) {
          _showAssignmentConflictDialog(errorMessage);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  void _showAssignmentConflictDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Assignment Conflict',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          errorMessage,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
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
                  'Assign Field Officer',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _buildErrorView()
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farms Section
                      _buildFarmsSection(),
                      const SizedBox(height: 24),

                      // Suggested Field Officers Section
                      _buildSuggestedFieldOfficersSection(),
                      const SizedBox(height: 24),

                      // Notes Section
                      _buildNotesSection(),
                    ],
                  ),
                ),
              ),

            // Action Buttons
            if (!_isLoading && _error == null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isAssigning
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isAssigning ? null : _assignFieldOfficer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _isAssigning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Assign'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture, color: AppColors.brandGreen),
              const SizedBox(width: 8),
              Text(
                'Select Farm to Assign',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_farms.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No farms found for this farmer. Please add farms before assigning a field officer.',
                      style: GoogleFonts.poppins(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._farms.map((farm) => _buildFarmCard(farm)),
        ],
      ),
    );
  }

  Widget _buildFarmCard(FarmInfo farm) {
    final isSelected = _selectedFarm?.farmId == farm.farmId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.brandGreen.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.brandGreen
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFarm = farm;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Radio Button
              Radio<FarmInfo>(
                value: farm,
                groupValue: _selectedFarm,
                onChanged: (value) {
                  setState(() {
                    _selectedFarm = value;
                  });
                },
                activeColor: AppColors.brandGreen,
              ),
              const SizedBox(width: 12),
              // Farm Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.agriculture,
                  color: AppColors.brandGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Farm Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.farmName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (farm.farmType != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              farm.farmType!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (farm.totalAreaAcres != null) ...[
                          Icon(Icons.square_foot,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${farm.totalAreaAcres!.toStringAsFixed(2)} acres',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${farm.village ?? ""}, ${farm.district ?? ""}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (farm.pincode != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Pincode: ${farm.pincode}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.brandGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildSuggestedFieldOfficersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_search, color: AppColors.brandGreen),
            const SizedBox(width: 8),
            Text(
              'Suggested Field Officers',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_suggestedFieldOfficers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No field officers found with matching pincodes. You can still assign manually.',
                    style: GoogleFonts.poppins(
                      color: Colors.orange.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ..._suggestedFieldOfficers.map((fo) => _buildFieldOfficerCard(fo)),
      ],
    );
  }

  Widget _buildFieldOfficerCard(SuggestedFieldOfficer fo) {
    final isSelected = _selectedFieldOfficer?.fieldOfficerId == fo.fieldOfficerId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.brandGreen.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.brandGreen
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFieldOfficer = fo;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Radio Button
              Radio<SuggestedFieldOfficer>(
                value: fo,
                groupValue: _selectedFieldOfficer,
                onChanged: (value) {
                  setState(() {
                    _selectedFieldOfficer = value;
                  });
                },
                activeColor: AppColors.brandGreen,
              ),
              const SizedBox(width: 12),
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.brandGreen.withOpacity(0.1),
                child: Text(
                  fo.fullName.isNotEmpty ? fo.fullName[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fo.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${fo.phoneNumber} • ${fo.username}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${fo.village ?? ""}, ${fo.district ?? ""}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (fo.pincode != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Pincode: ${fo.pincode}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.brandGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (fo.matchingFarmCount > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'Matches ${fo.matchingFarmCount} farm(s)',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add any notes about this assignment...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.brandGreen),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}

