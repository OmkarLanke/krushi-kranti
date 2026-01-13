import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart'; 
import '../../../core/constants/app_colors.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String? orderId = ModalRoute.of(context)?.settings.arguments as String?;
    final displayId = orderId ?? "#0000";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.verifiedVcp,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Order $displayId • 02 Dec 2025",
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandGreen.withOpacity(0.1),
                    AppColors.brandGreen.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.brandGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: AppColors.brandGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Entry Verified at VCP weighbridge Quality and final price is confirmed",
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        letterSpacing: 0.2,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _buildSectionCard(
              icon: Icons.inventory_2_rounded,
              title: l10n.produceSaleEntry,
              child: Column(
                children: [
                  _buildRow("Crop", l10n.acceptedWeight, isHeader: true),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 12),
                  _buildRow("Tomato", "50 Kg"),
                  const SizedBox(height: 10),
                  _buildRow("Potato", "40 Kg"),
                  const SizedBox(height: 10),
                  _buildRow("Wheat", "60 Kg"),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: AppColors.brandGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.weighNote,
                            style: GoogleFonts.poppins(
                              color: AppColors.brandGreen,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.receipt_long_rounded,
              title: l10n.settlementStatement,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(flex: 2, child: Text("Products", style: _headerStyle())),
                      Expanded(flex: 1, child: Text(l10n.weight, style: _headerStyle())),
                      Expanded(flex: 1, child: Text(l10n.price, style: _headerStyle())),
                      Expanded(flex: 1, child: Text(l10n.total, textAlign: TextAlign.right, style: _headerStyle())),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 12),
                  _buildSettlementRow("Tomato", "50 Kg", "12/Kg", "₹ 600"),
                  const SizedBox(height: 10),
                  _buildSettlementRow("Potato", "40 Kg", "20/Kg", "₹ 800"),
                  const SizedBox(height: 10),
                  _buildSettlementRow("Wheat", "60 Kg", "80/Kg", "₹ 4800"),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Final Breakdown",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "₹ 6200",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.brandGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.account_balance_wallet_rounded,
              title: l10n.finalBreakment,
              child: Column(
                children: [
                  _buildRow("Produce Total", "₹ 6200", isBoldValue: true),
                  const SizedBox(height: 10),
                  _buildRow(l10n.loanDeduction, "₹ 4000", isBoldValue: true),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 12),
                  _buildRow(l10n.balance, "₹ 1200", isBoldValue: true),
                  const SizedBox(height: 10),
                  _buildRow(l10n.settlementStatus, l10n.pending, isBoldValue: true),
                  const SizedBox(height: 10),
                  _buildRow(l10n.settlementCycle, "T +2 days", isBoldValue: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.brandGreen),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHeader = false, bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: isHeader
                ? _headerStyle()
                : GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
          ),
        ),
        Text(
          value,
          style: isHeader
              ? _headerStyle()
              : GoogleFonts.poppins(
                  fontWeight: isBoldValue ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                  color: isBoldValue ? Colors.black87 : Colors.black87,
                  letterSpacing: 0.2,
                ),
        ),
      ],
    );
  }

  Widget _buildSettlementRow(String p, String w, String pr, String t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            p,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            w,
            style: GoogleFonts.poppins(
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            pr,
            style: GoogleFonts.poppins(
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            t,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.brandGreen,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _headerStyle() => GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Colors.black87,
        letterSpacing: 0.3,
      );
}