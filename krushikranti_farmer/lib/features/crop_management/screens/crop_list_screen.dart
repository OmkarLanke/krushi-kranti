import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart'; // ✅ Import Localization
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../dashboard/models/crop_model.dart';
import '../../dashboard/services/crop_service.dart';

class CropListScreen extends StatefulWidget {
  const CropListScreen({super.key});

  @override
  State<CropListScreen> createState() => _CropListScreenState();
}

class _CropListScreenState extends State<CropListScreen> {
  late Future<List<CropModel>> _cropsFuture;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  void _loadCrops() {
    setState(() {
      _cropsFuture = CropService.getCrops();
    });
  }

  // Helper to get display name (use displayName from API, fallback to name)
  String _getCropDisplay(CropModel crop, AppLocalizations l10n) {
    return crop.cropDisplayName ?? crop.name;
  }

  // Helper to get category display name
  String _getCategoryDisplay(CropModel crop, AppLocalizations l10n) {
    return crop.cropTypeName ?? crop.category;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Shortcut for translations
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.cropDetails,
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
              onTap: () {
              Navigator.pushNamed(context, AppRoutes.addCrop).then((_) {
                _loadCrops();
              });
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

      // --- BODY ---
      body: RefreshIndicator(
        onRefresh: () async => _loadCrops(),
        color: AppColors.brandGreen,
        child: FutureBuilder<List<CropModel>>(
          future: _cropsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.brandGreen,
                ),
              );
            }
            if (snapshot.hasError) {
              final errorMsg = snapshot.error.toString();
              // Check if it's a profile not found error
              if (errorMsg.contains("Farmer profile not found") || errorMsg.contains("complete your profile")) {
                return _buildProfileRequiredState(l10n);
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Error Loading Crops",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString().replaceFirst("Exception: ", ""),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _loadCrops,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text("Retry"),
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

            final crops = snapshot.data ?? [];
            if (crops.isEmpty) {
              return _buildEmptyState(l10n);
            }

            // --- LIST ---
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: crops.length,
              itemBuilder: (context, index) {
                final crop = crops[index];
                return _buildCropCard(crop, l10n);
              },
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET: Crop Card (Localized) ---
  Widget _buildCropCard(CropModel crop, AppLocalizations l10n) {
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
            // Crop Name and Status Badge
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
                    Icons.grass_rounded,
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
                    _getCropDisplay(crop, l10n),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                          fontWeight: FontWeight.w600,
                      color: Colors.black87,
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                    ),
                      if (crop.cropStatus != null) ...[
                        const SizedBox(height: 6),
                        _buildCropStatusBadge(crop.cropStatus!, l10n),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
                    l10n.cropDetail,
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
                  _buildInfoRow(Icons.category_rounded, "${l10n.cropTypeLabel}: ${_getCategoryDisplay(crop, l10n)}", AppColors.brandGreen),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.square_foot_rounded, "${l10n.landArea}: ${crop.acres.toStringAsFixed(2)} ${l10n.acresSuffix}", AppColors.brandGreen),
                  if (crop.farmName != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.agriculture_rounded, "${l10n.farmLabel}: ${crop.farmName}", AppColors.brandGreen),
                  ],
                  if (crop.plantingDate != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.calendar_today_rounded, "${l10n.sowingDate}: ${_formatDate(crop.plantingDate!)}", AppColors.brandGreen),
                  ],
                  if (crop.harvestingDate != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.event_rounded, "${l10n.harvestingDate}: ${_formatDate(crop.harvestingDate!)}", AppColors.brandGreen),
                  ],
                ],
              ),
            ),
            
            // Additional Details Section (if available)
            if (crop.cropLocalName != null || crop.cropName != null) ...[
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
                "Additional Details",
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
              if (crop.cropLocalName != null) ...[
                _buildInfoRow(Icons.translate_rounded, "Local Name: ${crop.cropLocalName}", Colors.grey.shade600),
                const SizedBox(height: 12),
              ],
              if (crop.cropName != null) ...[
                _buildInfoRow(Icons.label_rounded, "Crop Code: ${crop.cropName}", Colors.grey.shade600),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  // Helper to get localized crop status
  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status.toUpperCase()) {
      case 'PLANNED':
        return l10n.statusPlanned;
      case 'SOWN':
        return l10n.statusSown;
      case 'GROWING':
        return l10n.statusGrowing;
      case 'HARVESTED':
        return l10n.statusHarvested;
      case 'FAILED':
        return l10n.statusFailed;
      default:
        return status.replaceAll('_', ' ');
    }
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

  // Helper to get status color
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLANNED':
        return const Color(0xFF9E9E9E); // Gray
      case 'SOWN':
        return const Color(0xFF2196F3); // Blue
      case 'GROWING':
        return AppColors.brandGreen; // Green
      case 'HARVESTED':
        return const Color(0xFF4CAF50); // Dark Green
      case 'FAILED':
        return const Color(0xFFF44336); // Red
      default:
        return Colors.grey;
    }
  }

  // Build crop status badge with shadow and border
  Widget _buildCropStatusBadge(String status, AppLocalizations l10n) {
    final statusText = _getLocalizedStatus(status, l10n).toUpperCase();
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: statusColor,
          letterSpacing: 0.3,
        ),
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
                Icons.grass_rounded,
                size: 64,
                color: AppColors.brandGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noCropsYet,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addFirstCrop,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addCrop).then((_) {
                  _loadCrops();
                });
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                l10n.addCropBtn,
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
              l10n.completeProfileFirst,
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