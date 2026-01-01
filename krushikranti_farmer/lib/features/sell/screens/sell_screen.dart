import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart'; 
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../orders/models/sales_order_model.dart';
import '../../orders/services/order_service.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  late Future<List<SalesOrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
      setState(() {
      _ordersFuture = OrderService.getOrders();
      });
    }

  // ✅ HELPER: Convert "English Backend Status" to "Localized UI Status"
  String _getLocalStatus(String backendStatus, AppLocalizations l10n) {
    if (backendStatus == "Received") return l10n.statusReceived;
    if (backendStatus == "Pending") return l10n.pending;
    return backendStatus; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.yourSales, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: FutureBuilder<List<SalesOrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brandGreen));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading orders"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No sales found"));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, orders[index], l10n);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to add order screen
          await Navigator.pushNamed(context, AppRoutes.addOrder);
          // Reload orders after returning from add order screen
          _loadOrders();
        },
        backgroundColor: AppColors.brandGreen,
        child: const Icon(Icons.add, color: Colors.white),
                    ),
    );
  }

  Widget _buildOrderCard(BuildContext context, SalesOrderModel order, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.orderDetail, arguments: order.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: AppColors.brandGreen),
              ),
            const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Text(
                    "${l10n.orderId} ${order.id}",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    "${l10n.placedOn} ${order.date}",
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  Row(
                      children: [
                      _buildMiniTag("${l10n.items}: ${order.items.toString().padLeft(2, '0')}"),
                      const SizedBox(width: 8),
                      _buildMiniTag("${l10n.weight}: ${order.weight}"),
                      const SizedBox(width: 8),
                      Text(
                        "${l10n.status} : ", 
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                      Text(
                        _getLocalStatus(order.status, l10n),
                        style: GoogleFonts.poppins(
                          fontSize: 10, 
                          color: order.statusColor,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
        ),
      ),
    );
  }

  Widget _buildMiniTag(String text) {
    return Text(
        text,
      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
    );
  }
}
