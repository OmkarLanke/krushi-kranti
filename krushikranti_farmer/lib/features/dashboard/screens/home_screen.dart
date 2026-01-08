import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart'; 
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../dashboard/services/crop_service.dart';
import '../../dashboard/services/field_officer_assignment_service.dart';
import 'field_officer_details_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAgentAssigned = false; 
  List<Map<String, dynamic>> fieldOfficerAssignments = [];
  bool isLoadingAssignments = true;
  bool isNavigating = false;

  @override
  void initState() {
    super.initState();
    _checkFieldOfficerAssignments(); 
  }

  Future<void> _checkFieldOfficerAssignments() async {
    setState(() {
      isLoadingAssignments = true;
    });
    
    try {
      final assignments = await FieldOfficerAssignmentService.getAssignments();
      // Filter out CANCELLED assignments
      final activeAssignments = assignments.where((assignment) {
        final status = assignment['status']?.toString().toUpperCase();
        return status != 'CANCELLED';
      }).toList();
      
      if (mounted) {
        setState(() {
          fieldOfficerAssignments = activeAssignments;
          isAgentAssigned = activeAssignments.isNotEmpty;
          isLoadingAssignments = false;
        });
      }
    } catch (e) {
      // If error, assume no assignments
      if (mounted) {
        setState(() {
          fieldOfficerAssignments = [];
          isAgentAssigned = false;
          isLoadingAssignments = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      
      // --- 1. HEADER ---
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false, 
        titleSpacing: 24,
        title: Text(
          l10n.krushiKranti, 
          style: GoogleFonts.poppins(
            color: AppColors.brandGreen,
            fontSize: 32, 
            fontWeight: FontWeight.w700, 
            height: 1.0, 
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          _buildCircleIcon(Icons.search),
          const SizedBox(width: 12),
          _buildCircleIcon(Icons.notifications_none),
          const SizedBox(width: 24),
        ],
      ),

      // --- 2. BODY ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // A. Weather
            _buildWeatherHeader(l10n),
            const SizedBox(height: 24),

            // B. Banner
            if (isLoadingAssignments)
              _buildLoadingBanner(l10n)
            else if (isAgentAssigned) 
              _buildFieldOfficerAssignedCard(l10n)
            else 
              _buildFieldOfficerPendingBanner(l10n),
            
            const SizedBox(height: 28),

            // C. Quick Action Title
            Text(
              l10n.quickAction,
              style: GoogleFonts.poppins(
                fontSize: 20, 
                fontWeight: FontWeight.w700, 
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // D. Grid
            _buildQuickActionGrid(context, l10n),
            
            const SizedBox(height: 28),

            // E. Alerts
            Text(
              l10n.alerts,
              style: GoogleFonts.poppins(
                fontSize: 20, 
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _buildAlertCard(context),
            const SizedBox(height: 40), 
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS
  // ===========================================================================

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        // ✅ FIXED: Updated withValues
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)), 
      ),
      child: Icon(icon, color: Colors.black54, size: 26),
    );
  }

  Widget _buildWeatherHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.creamBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${l10n.hello} Ramesh,", 
                  style: GoogleFonts.poppins(
                    fontSize: 18, 
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandGreen,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.currentLocation, 
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary, 
                          fontWeight: FontWeight.w500, 
                          fontSize: 12
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on, size: 14, color: AppColors.textPrimary),
                  ],
                ),
              ],
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "28°", 
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700, 
                      color: AppColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "High: 30° / Low: 15°", 
                    style: GoogleFonts.poppins(
                      fontSize: 10, 
                      color: Colors.grey.shade700, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Icon(Icons.cloud, size: 48, color: Color(0xFF29B6F6)), 
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], 
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildFieldOfficerPendingBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)], 
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandGreen.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.fieldOfficerAssignMsg,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.fieldOfficerSoonMsg,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldOfficerAssignedCard(AppLocalizations l10n) {
    if (fieldOfficerAssignments.isEmpty) {
      return _buildFieldOfficerPendingBanner(l10n);
    }

    // Get the first active assignment
    final assignment = fieldOfficerAssignments.first;
    final fieldOfficerName = assignment['fieldOfficerName']?.toString() ?? 'Field Officer';
    final fieldOfficerPhone = assignment['fieldOfficerPhone']?.toString() ?? '';
    final fieldOfficerPincode = assignment['fieldOfficerPincode']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        _showFieldOfficerDetailsDialog(l10n);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.creamBackground,
              child: Icon(Icons.person, color: Colors.brown, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.fieldOfficerAssignedMsg,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fieldOfficerName,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  if (fieldOfficerPincode.isNotEmpty)
                    Text(
                      "Pincode: $fieldOfficerPincode",
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 4),
                  if (fieldOfficerPhone.isNotEmpty)
                    Text(
                      fieldOfficerPhone,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  if (fieldOfficerAssignments.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "+ ${fieldOfficerAssignments.length - 1} more",
                        style: GoogleFonts.poppins(fontSize: 10, color: AppColors.brandGreen, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandGreen, width: 2),
              ),
              child: const Icon(Icons.arrow_forward_ios, color: AppColors.brandGreen, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showFieldOfficerDetailsDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => FieldOfficerDetailsDialog(
        assignments: fieldOfficerAssignments,
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandGreen),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionGrid(BuildContext context, AppLocalizations l10n) {
    final String cropStatus = isAgentAssigned ? l10n.active : l10n.pending; 
    final Color cropStatusColor = isAgentAssigned ? AppColors.brandGreen : AppColors.pendingStatus;

    final items = [
      {
        "icon": Icons.grass, 
        "title": l10n.cropDetail,
        "route": AppRoutes.cropList,
        "status": cropStatus, 
        "statusColor": cropStatusColor 
      },
      {
        "icon": Icons.bar_chart, 
        "title": l10n.dailySale,
        "route": AppRoutes.sell, // ✅ Linked to Sell Screen
        "status": l10n.pending,
        "statusColor": AppColors.pendingStatus
      },
      {
        "icon": Icons.monetization_on_outlined, 
        "title": l10n.funding,
        "route": AppRoutes.requestFunds,
        "status": l10n.pending,
        "statusColor": AppColors.pendingStatus
      },
      {
        "icon": Icons.account_balance_wallet_outlined, 
        "title": l10n.account,
        "route": null,
        "status": l10n.pending,
        "statusColor": AppColors.pendingStatus
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95, 
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        return _buildActionCard(
          context,
          items[index]['icon'] as IconData,
          items[index]['title'] as String,
          items[index]['route'] as String?,
          items[index]['status'] as String,
          items[index]['statusColor'] as Color,
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, 
    IconData icon, 
    String title, 
    String? route, 
    String status, 
    Color statusColor
  ) {
    return GestureDetector(
      onTap: () async {
        if (route != null && !isNavigating) {
          setState(() {
            isNavigating = true;
          });
          
          // Show loading dialog
          _showLoadingDialog(context);
          
          // Small delay to show loading animation
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Hide loading dialog and navigate
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            await Navigator.pushNamed(context, route);
            _checkFieldOfficerAssignments();
            
            setState(() {
              isNavigating = false;
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            // ✅ FIXED: Updated withValues
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandGreen, 
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    status, 
                    style: GoogleFonts.poppins(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_circle_right_outlined, color: AppColors.brandGreen, size: 26),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                // ✅ FIXED: Updated withValues
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05), 
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "Lorem Ipsum is simply dummy text of the printing.",
                    style: GoogleFonts.poppins(
                      fontSize: 12, 
                      color: AppColors.alertText, 
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ), 
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        GestureDetector(
          onTap: () {
            // TODO: Navigate to ThynkChat
          },
          child: Container(
            width: 64, 
            height: 64,
            padding: const EdgeInsets.all(8), 
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              boxShadow: [
                // ✅ FIXED: Updated withValues
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05), 
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/ai_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (c, o, s) => const Icon(Icons.smart_toy, color: AppColors.brandGreen),
            ),
          ),
        ),
      ],
    );
  }
}