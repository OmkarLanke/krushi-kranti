import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/http_service.dart';
import '../../dashboard/services/field_officer_assignment_service.dart';
import '../models/farm_model.dart';

class FarmListScreen extends StatefulWidget {
  const FarmListScreen({super.key});

  @override
  State<FarmListScreen> createState() => _FarmListScreenState();
}

class _FarmListScreenState extends State<FarmListScreen> {
  bool _isLoading = true;
  List<Farm> _farms = [];
  String? _errorMessage;
  Map<int?, Map<String, dynamic>> _fieldOfficerAssignments = {}; // Map of farmId -> assignment

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load farms and field officer assignments in parallel
      final farmsFuture = HttpService.get("farmer/profile/farms");
      final assignmentsFuture = _loadFieldOfficerAssignments();

      final response = await farmsFuture;
      final data = response['data'] ?? [];
      
      // Wait for assignments to load
      await assignmentsFuture;
      
      if (mounted) {
        setState(() {
          _farms = (data as List)
              .map((item) => Farm.fromJson(item as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    }
  }

  Future<void> _loadFieldOfficerAssignments() async {
    try {
      final assignments = await FieldOfficerAssignmentService.getAssignments();
      
      // Filter active assignments
      final activeAssignments = assignments.where((assignment) {
        final status = assignment['status']?.toString().toUpperCase() ?? '';
        return status == 'ASSIGNED' || status == 'ACTIVE';
      }).toList();

      // Create a map of farmId -> assignment
      final Map<int?, Map<String, dynamic>> assignmentsMap = {};
      Map<String, dynamic>? allFarmsAssignment;
      
      for (var assignment in activeAssignments) {
        final farmIdObj = assignment['farmId'];
        // If farmId is null, it means assignment is for all farms
        if (farmIdObj == null) {
          allFarmsAssignment = assignment;
        } else {
          // Convert farmId to int
          int? farmId;
          if (farmIdObj is int) {
            farmId = farmIdObj;
          } else if (farmIdObj is String) {
            farmId = int.tryParse(farmIdObj);
          } else if (farmIdObj is num) {
            farmId = farmIdObj.toInt();
          }
          
          if (farmId != null) {
            assignmentsMap[farmId] = assignment;
          }
        }
      }
      
      // Store "all farms" assignment with key -1
      if (allFarmsAssignment != null) {
        assignmentsMap[-1] = allFarmsAssignment;
      }

      if (mounted) {
        setState(() {
          _fieldOfficerAssignments = assignmentsMap;
        });
      }
    } catch (e) {
      // Silently fail - field officer assignments are optional
      print('Error loading field officer assignments: $e');
    }
  }

  Map<String, dynamic>? _getFieldOfficerAssignmentForFarm(Farm farm) {
    // First check for specific farm assignment
    if (farm.id != null && _fieldOfficerAssignments.containsKey(farm.id)) {
      return _fieldOfficerAssignments[farm.id];
    }
    // If no specific assignment, check for "all farms" assignment
    if (_fieldOfficerAssignments.containsKey(-1)) {
      return _fieldOfficerAssignments[-1];
    }
    return null;
  }

  String _getLocalizedFarmType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'ORGANIC': return l10n.farmTypeOrganic;
      case 'CONVENTIONAL': return l10n.farmTypeConventional;
      case 'MIXED': return l10n.farmTypeMixed;
      case 'VERMI_COMPOST': return l10n.farmTypeVermiCompost;
      default: return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedSoilType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'BLACK': return l10n.soilBlack;
      case 'RED': return l10n.soilRed;
      case 'SANDY': return l10n.soilSandy;
      case 'LOAMY': return l10n.soilLoamy;
      case 'CLAY': return l10n.soilClay;
      case 'MIXED': return l10n.soilMixed;
      default: return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedIrrigationType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'DRIP': return l10n.irrigDrip;
      case 'SPRINKLER': return l10n.irrigSprinkler;
      case 'RAINFED': return l10n.irrigRainfed;
      case 'CANAL': return l10n.irrigCanal;
      case 'BORE_WELL': return l10n.irrigBoreWell;
      case 'OPEN_WELL': return l10n.irrigOpenWell;
      case 'MIXED': return l10n.irrigMixed;
      default: return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedOwnership(String type, AppLocalizations l10n) {
    switch (type) {
      case 'OWNED': return l10n.ownershipOwned;
      case 'LEASED': return l10n.ownershipLeased;
      case 'SHARED': return l10n.ownershipShared;
      case 'GOVERNMENT_ALLOTTED': return l10n.ownershipGovtAllotted;
      default: return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedEncumbrance(String status, AppLocalizations l10n) {
    switch (status) {
      case 'NOT_VERIFIED': return l10n.encumNotVerified;
      case 'FREE': return l10n.encumFree;
      case 'ENCUMBERED': return l10n.encumEncumbered;
      case 'PARTIALLY_ENCUMBERED': return l10n.encumPartially;
      default: return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.farmDetails,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final result = await Navigator.pushNamed(context, AppRoutes.addFarm);
                if (result == true) {
                  _loadFarms(); // Refresh list after adding
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandGreen,
                AppColors.brandGreen.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandGreen))
          : _errorMessage != null
              ? _buildErrorOrProfileRequired(l10n)
              : _farms.isEmpty
                  ? _buildEmptyState(l10n)
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadFarms();
                      },
                      color: AppColors.brandGreen,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        itemCount: _farms.length,
                        itemBuilder: (context, index) {
                          final farm = _farms[index];
                          return _buildFarmCard(farm, l10n);
                        },
                      ),
                    ),
    );
  }

  Widget _buildFarmCard(Farm farm, AppLocalizations l10n) {
    final fieldOfficerAssignment = _getFieldOfficerAssignmentForFarm(farm);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farm Name and Verified Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brandGreen,
                        AppColors.brandGreen.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.agriculture_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.farmName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (farm.isVerified == true) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 12, color: AppColors.brandGreen),
                              const SizedBox(width: 4),
                              Text(
                                l10n.verified,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.brandGreen,
                                  fontWeight: FontWeight.w600,
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
            const SizedBox(height: 16),
            // Field Officer Assignment Section
            if (fieldOfficerAssignment != null)
              _buildFieldOfficerAssignmentCard(fieldOfficerAssignment, l10n)
            else
              _buildNoFieldOfficerCard(l10n),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 16),
            
            // Main Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandGreen.withOpacity(0.06),
                    AppColors.brandGreen.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.brandGreen.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.brandGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.brandGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.main,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandGreen,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(Icons.location_on_rounded, "${farm.village}${farm.district != null ? ', ${farm.district}' : ''}", AppColors.brandGreen),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.square_foot_rounded, "${farm.totalAreaAcres} ${l10n.acres}", AppColors.brandGreen),
                  if (farm.farmType != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.eco_rounded, _getLocalizedFarmType(farm.farmType!, l10n), AppColors.brandGreen),
                  ],
                  if (farm.landOwnership.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.home_rounded, "${l10n.ownership}: ${_getLocalizedOwnership(farm.landOwnership, l10n)}", AppColors.brandGreen),
                  ],
                ],
              ),
            ),
            
            // Land Details Section (if available)
            if (farm.soilType != null || farm.irrigationType != null || farm.pincode.isNotEmpty) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.landDetailsSection,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (farm.pincode.isNotEmpty)
                _buildInfoRow(Icons.pin_rounded, "${l10n.pincode}: ${farm.pincode}", Colors.grey.shade600),
              if (farm.taluka != null && farm.taluka!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_city_rounded, "${l10n.taluka}: ${farm.taluka}", Colors.grey.shade600),
              ],
              if (farm.state != null && farm.state!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.public_rounded, "${l10n.state}: ${farm.state}", Colors.grey.shade600),
              ],
              if (farm.soilType != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.terrain_rounded, "${l10n.soilType}: ${_getLocalizedSoilType(farm.soilType!, l10n)}", Colors.grey.shade600),
              ],
              if (farm.irrigationType != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.water_drop_rounded, "${l10n.irrigationType}: ${_getLocalizedIrrigationType(farm.irrigationType!, l10n)}", Colors.grey.shade600),
              ],
            ],
            
            // Collateral Information Section (if available)
            if (farm.surveyNumber != null || 
                farm.landRegistrationNumber != null || 
                farm.pattaNumber != null || 
                farm.estimatedLandValue != null ||
                farm.encumbranceStatus != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.collateralSection,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (farm.surveyNumber != null && farm.surveyNumber!.isNotEmpty) ...[
                _buildInfoRow(Icons.description_rounded, "${l10n.surveyNo}: ${farm.surveyNumber}", Colors.grey.shade600),
                const SizedBox(height: 12),
              ],
              if (farm.landRegistrationNumber != null && farm.landRegistrationNumber!.isNotEmpty) ...[
                _buildInfoRow(Icons.assignment_rounded, "${l10n.landRegNo}: ${farm.landRegistrationNumber}", Colors.grey.shade600),
                const SizedBox(height: 12),
              ],
              if (farm.pattaNumber != null && farm.pattaNumber!.isNotEmpty) ...[
                _buildInfoRow(Icons.receipt_rounded, "${l10n.pattaNo}: ${farm.pattaNumber}", Colors.grey.shade600),
                const SizedBox(height: 12),
              ],
              if (farm.estimatedLandValue != null) ...[
                _buildInfoRow(Icons.currency_rupee_rounded, "${l10n.estimatedValue}: ₹${farm.estimatedLandValue!.toStringAsFixed(2)}", Colors.grey.shade600),
                const SizedBox(height: 12),
              ],
              if (farm.encumbranceStatus != null) ...[
                _buildInfoRow(Icons.info_outline_rounded, "${l10n.encumbrance}: ${_getLocalizedEncumbrance(farm.encumbranceStatus!, l10n)}", Colors.grey.shade600),
              ],
              if (farm.encumbranceRemarks != null && farm.encumbranceRemarks!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.note_rounded, "${l10n.remarks}: ${farm.encumbranceRemarks}", Colors.grey.shade600),
              ],
            ],
            
            // GPS Location Section (if available)
            if (farm.farmLatitude != null && farm.farmLongitude != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.brandGreen.withOpacity(0.06),
                      AppColors.brandGreen.withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.brandGreen.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.my_location_rounded, size: 14, color: AppColors.brandGreen),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.farmLocationGPS,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandGreen,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildInfoRow(
                      Icons.location_on_rounded,
                      "${l10n.latitude}: ${farm.farmLatitude!.toStringAsFixed(6)}°",
                      AppColors.brandGreen,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.location_on_rounded,
                      "${l10n.longitude}: ${farm.farmLongitude!.toStringAsFixed(6)}°",
                      AppColors.brandGreen,
                    ),
                    if (farm.farmLocationAccuracy != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.gps_fixed_rounded,
                        "${l10n.accuracy}: ${farm.farmLocationAccuracy!.toStringAsFixed(1)} ${l10n.meters}",
                        AppColors.brandGreen,
                      ),
                    ],
                    if (farm.farmLocationCapturedAt != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.calendar_today_rounded,
                        "${l10n.capturedOn}: ${DateFormat('dd MMM yyyy, hh:mm a').format(farm.farmLocationCapturedAt!)}",
                        AppColors.brandGreen,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldOfficerAssignmentCard(Map<String, dynamic> assignment, AppLocalizations l10n) {
    final fieldOfficerName = assignment['fieldOfficerName']?.toString() ?? 'Field Officer';
    final fieldOfficerPhone = assignment['fieldOfficerPhone']?.toString() ?? '';
    final fieldOfficerPincode = assignment['fieldOfficerPincode']?.toString() ?? '';
    final assignedAt = assignment['assignedAt'];
    
    // Format assigned date
    String assignedDateStr = '';
    if (assignedAt != null) {
      try {
        final dateTime = DateTime.parse(assignedAt.toString());
        assignedDateStr = DateFormat('M/d/yyyy').format(dateTime);
      } catch (e) {
        assignedDateStr = assignedAt.toString();
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.brandGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_rounded, size: 14, color: AppColors.brandGreen),
              ),
              const SizedBox(width: 8),
              Text(
                'Field Officer Assign',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandGreen,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  fieldOfficerName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ASSIGNED',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          if (fieldOfficerPhone.isNotEmpty || fieldOfficerPincode.isNotEmpty || assignedDateStr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (fieldOfficerPhone.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_rounded, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        fieldOfficerPhone,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                if (fieldOfficerPincode.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        fieldOfficerPincode,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                if (assignedDateStr.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        assignedDateStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoFieldOfficerCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.brandGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person_rounded, size: 14, color: AppColors.brandGreen),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Field Officer Assign',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandGreen,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Not Assigned',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandGreen.withOpacity(0.1),
                    AppColors.brandGreen.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.agriculture_rounded,
                size: 64,
                color: AppColors.brandGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noFarmsAdded,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addYourFirstFarm,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, AppRoutes.addFarm);
                if (result == true) {
                  _loadFarms();
                }
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                l10n.addFarm,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show either generic error UI or a "Profile Required" state when
  /// backend indicates that farmer profile is not yet created.
  Widget _buildErrorOrProfileRequired(AppLocalizations l10n) {
    final message = _errorMessage ?? '';

    final isProfileMissing = message.contains("Farmer profile not found") ||
        message.toLowerCase().contains("complete your profile");

    if (isProfileMissing) {
      return _buildProfileRequiredState(l10n);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFarms,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
              ),
              child: Text(l10n.retry, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Same style as Crop Details when My Details are not completed.
  Widget _buildProfileRequiredState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.shade400,
                    Colors.orange.shade600,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.profileRequired,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.completeProfileBeforeFarms,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.onboardingPersonal);
              },
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: Text(
                l10n.completeProfile,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

