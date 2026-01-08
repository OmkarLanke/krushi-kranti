import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/http_service.dart';
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
      final response = await HttpService.get("farmer/profile/farms");
      final data = response['data'] ?? [];
      
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.farmDetails,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.brandGreen),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, AppRoutes.addFarm);
              if (result == true) {
                _loadFarms(); // Refresh list after adding
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorOrProfileRequired(l10n)
              : _farms.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.agriculture_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noFarmsAdded,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.addYourFirstFarm,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.pushNamed(context, AppRoutes.addFarm);
                                if (result == true) {
                                  _loadFarms();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                              child: Text(l10n.addFarm, style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFarms,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farm Name and Verified Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    farm.farmName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (farm.isVerified == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 14, color: AppColors.brandGreen),
                        const SizedBox(width: 4),
                        Text(
                          l10n.verified,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.brandGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Main Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9), // Light green background
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.main,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on, "${farm.village}${farm.district != null ? ', ${farm.district}' : ''}", Colors.grey.shade700),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.square_foot, "${farm.totalAreaAcres} ${l10n.acres}", Colors.grey.shade700),
                  if (farm.farmType != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.eco, _getLocalizedFarmType(farm.farmType!, l10n), Colors.grey.shade700),
                  ],
                  if (farm.landOwnership.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.home, "${l10n.ownership}: ${_getLocalizedOwnership(farm.landOwnership, l10n)}", Colors.grey.shade700),
                  ],
                ],
              ),
            ),
            
            // Land Details Section (if available)
            if (farm.soilType != null || farm.irrigationType != null || farm.pincode.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.landDetailsSection,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (farm.pincode.isNotEmpty)
                _buildInfoRow(Icons.pin, "${l10n.pincode}: ${farm.pincode}", Colors.grey.shade600),
              if (farm.taluka != null && farm.taluka!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildInfoRow(Icons.location_city, "${l10n.taluka}: ${farm.taluka}", Colors.grey.shade600),
              ],
              if (farm.state != null && farm.state!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildInfoRow(Icons.public, "${l10n.state}: ${farm.state}", Colors.grey.shade600),
              ],
              if (farm.soilType != null) ...[
                const SizedBox(height: 6),
                _buildInfoRow(Icons.terrain, "${l10n.soilType}: ${_getLocalizedSoilType(farm.soilType!, l10n)}", Colors.grey.shade600),
              ],
              if (farm.irrigationType != null) ...[
                const SizedBox(height: 6),
                _buildInfoRow(Icons.water_drop, "${l10n.irrigationType}: ${_getLocalizedIrrigationType(farm.irrigationType!, l10n)}", Colors.grey.shade600),
              ],
            ],
            
            // Collateral Information Section (if available)
            if (farm.surveyNumber != null || 
                farm.landRegistrationNumber != null || 
                farm.pattaNumber != null || 
                farm.estimatedLandValue != null ||
                farm.encumbranceStatus != null) ...[
              const SizedBox(height: 16),
              Text(
                l10n.collateralSection,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (farm.surveyNumber != null && farm.surveyNumber!.isNotEmpty) ...[
                _buildInfoRow(Icons.description, "${l10n.surveyNo}: ${farm.surveyNumber}", Colors.grey.shade600),
                const SizedBox(height: 6),
              ],
              if (farm.landRegistrationNumber != null && farm.landRegistrationNumber!.isNotEmpty) ...[
                _buildInfoRow(Icons.assignment, "${l10n.landRegNo}: ${farm.landRegistrationNumber}", Colors.grey.shade600),
                const SizedBox(height: 6),
              ],
              if (farm.pattaNumber != null && farm.pattaNumber!.isNotEmpty) ...[
                _buildInfoRow(Icons.receipt, "${l10n.pattaNo}: ${farm.pattaNumber}", Colors.grey.shade600),
                const SizedBox(height: 6),
              ],
              if (farm.estimatedLandValue != null) ...[
                _buildInfoRow(Icons.currency_rupee, "${l10n.estimatedValue}: ₹${farm.estimatedLandValue!.toStringAsFixed(2)}", Colors.grey.shade600),
                const SizedBox(height: 6),
              ],
              if (farm.encumbranceStatus != null) ...[
                _buildInfoRow(Icons.info_outline, "${l10n.encumbrance}: ${_getLocalizedEncumbrance(farm.encumbranceStatus!, l10n)}", Colors.grey.shade600),
              ],
              if (farm.encumbranceRemarks != null && farm.encumbranceRemarks!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildInfoRow(Icons.note, "${l10n.remarks}: ${farm.encumbranceRemarks}", Colors.grey.shade600),
              ],
            ],
            
            // GPS Location Section (if available)
            if (farm.farmLatitude != null && farm.farmLongitude != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.brandGreen.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.my_location, size: 18, color: AppColors.brandGreen),
                        const SizedBox(width: 8),
                        Text(
                          l10n.farmLocationGPS,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.location_on,
                      "${l10n.latitude}: ${farm.farmLatitude!.toStringAsFixed(6)}°",
                      AppColors.brandGreen,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      Icons.location_on,
                      "${l10n.longitude}: ${farm.farmLongitude!.toStringAsFixed(6)}°",
                      AppColors.brandGreen,
                    ),
                    if (farm.farmLocationAccuracy != null) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        Icons.gps_fixed,
                        "${l10n.accuracy}: ${farm.farmLocationAccuracy!.toStringAsFixed(1)} ${l10n.meters}",
                        AppColors.brandGreen,
                      ),
                    ],
                    if (farm.farmLocationCapturedAt != null) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        Icons.calendar_today,
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
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 14, color: color),
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.creamBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                size: 64,
                color: AppColors.brandGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.profileRequired,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.completeProfileBeforeFarms,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.onboardingPersonal);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.completeProfile,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

