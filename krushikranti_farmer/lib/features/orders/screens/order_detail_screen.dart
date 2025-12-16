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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.brandGreen, size: 20),
                const SizedBox(width: 8),
                Text(l10n.verifiedVcp, style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Text(
              "Order $displayId • 02 Dec 2025",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
            )
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Entry Verified at VCP weighbridge Quality and final price is confirmed",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              title: l10n.produceSaleEntry,
              child: Column(
                children: [
                  _buildRow("Crop", l10n.acceptedWeight, isHeader: true),
                  const Divider(),
                  _buildRow("Tomato", "50 Kg"),
                  _buildRow("Potato", "40 Kg"),
                  _buildRow("Wheat", "60 Kg"),
                  const SizedBox(height: 10),
                  Text(
                    l10n.weighNote,
                    style: GoogleFonts.poppins(color: AppColors.brandGreen, fontSize: 11),
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
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
                  const Divider(),
                  _buildSettlementRow("Tomato", "50 Kg", "12/Kg", "₹ 600"),
                  _buildSettlementRow("Potato", "40 Kg", "20/Kg", "₹ 800"),
                  _buildSettlementRow("Wheat", "60 Kg", "80/Kg", "₹ 4800"),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Final Breakdown", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text("₹ 6200", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: l10n.finalBreakment,
              child: Column(
                children: [
                   _buildRow("Produce Total", "₹ 6200", isBoldValue: true),
                   _buildRow(l10n.loanDeduction, "₹ 4000", isBoldValue: true),
                   const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                   _buildRow(l10n.balance, "₹ 1200", isBoldValue: true),
                   // ✅ FIXED: Used l10n.pending instead of "Pending"
                   _buildRow(l10n.settlementStatus, l10n.pending, isBoldValue: true),
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

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHeader = false, bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isHeader ? _headerStyle() : GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: isHeader ? _headerStyle() : GoogleFonts.poppins(fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSettlementRow(String p, String w, String pr, String t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(p, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700))),
          Expanded(flex: 1, child: Text(w, style: GoogleFonts.poppins(fontSize: 13))),
          Expanded(flex: 1, child: Text(pr, style: GoogleFonts.poppins(fontSize: 13))),
          Expanded(flex: 1, child: Text(t, textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87);
}