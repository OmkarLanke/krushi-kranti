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
      backgroundColor: AppColors.background,
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Crop Details",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.brandGreen),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addCrop).then((_) {
                _loadCrops();
              });
            },
          ),
        ],
      ),

      // --- BODY ---
      body: RefreshIndicator(
        onRefresh: () async => _loadCrops(),
        color: AppColors.brandGreen,
        child: FutureBuilder<List<CropModel>>(
          future: _cropsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final errorMsg = snapshot.error.toString();
              // Check if it's a profile not found error
              if (errorMsg.contains("Farmer profile not found") || errorMsg.contains("complete your profile")) {
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
                        "Error: ${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadCrops,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandGreen,
                        ),
                        child: const Text("Retry", style: TextStyle(color: Colors.white)),
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
              padding: const EdgeInsets.all(16),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop Name and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getCropDisplay(crop, l10n),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
                    "Main",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.category, "Type: ${_getCategoryDisplay(crop, l10n)}", Colors.grey.shade700),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.square_foot, "Area: ${crop.acres.toStringAsFixed(2)} acres", Colors.grey.shade700),
                  if (crop.farmName != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.agriculture, "Farm: ${crop.farmName}", Colors.grey.shade700),
                  ],
                  if (crop.plantingDate != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.calendar_today, "Sowing Date: ${_formatDate(crop.plantingDate!)}", Colors.grey.shade700),
                  ],
                  if (crop.harvestingDate != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.event, "Harvesting Date: ${_formatDate(crop.harvestingDate!)}", Colors.grey.shade700),
                  ],
                  if (crop.cropStatus != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.info_outline, "Status: ${crop.cropStatus!.replaceAll('_', ' ')}", Colors.grey.shade700),
                  ],
                ],
              ),
            ),
            
            // Additional Details Section (if available)
            if (crop.cropLocalName != null || crop.cropName != null) ...[
              const SizedBox(height: 16),
              Text(
                "Additional Details",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (crop.cropLocalName != null) ...[
                _buildInfoRow(Icons.translate, "Local Name: ${crop.cropLocalName}", Colors.grey.shade600),
                const SizedBox(height: 6),
              ],
              if (crop.cropName != null) ...[
                _buildInfoRow(Icons.label, "Crop Code: ${crop.cropName}", Colors.grey.shade600),
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grass, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No crops added yet",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add your first crop to get started",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addCrop).then((_) {
                  _loadCrops();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text("Add Crop", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

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
              child: const Icon(Icons.person_add, size: 64, color: AppColors.brandGreen),
            ),
            const SizedBox(height: 24),
            Text(
              "Profile Required",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Please complete your profile first before adding crops.",
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
                "Complete Profile",
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