import 'dart:async';
import '../models/sales_model.dart';

class SalesService {
  // MOCK DATABASE
  static final List<SalesModel> _mockSales = [
    SalesModel(
      id: 'S001',
      date: DateTime.now().subtract(const Duration(days: 1)),
      cropName: 'Tomato',
      quantityKg: 100,
      ratePerKg: 15,
      totalAmount: 1500,
      buyerName: 'KrushiKranti VCP', // Village Collection Point [cite: 87]
    ),
    SalesModel(
      id: 'S002',
      date: DateTime.now().subtract(const Duration(days: 5)),
      cropName: 'Onion',
      quantityKg: 50,
      ratePerKg: 20,
      totalAmount: 1000,
      buyerName: 'Local Market',
    ),
  ];

  // 1. GET SALES HISTORY
  static Future<List<SalesModel>> getSalesHistory() async {
    await Future.delayed(const Duration(seconds: 1)); // Fake delay
    // Sort by newest date first
    _mockSales.sort((a, b) => b.date.compareTo(a.date));
    return _mockSales;
  }

  // 2. RECORD NEW SALE
  static Future<void> recordSale(SalesModel sale) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockSales.add(sale);
  }

  // 3. GET TOTAL EARNINGS (For Dashboard Widget)
  static Future<double> getTotalEarnings() async {
    await Future.delayed(const Duration(milliseconds: 500));
    double total = 0;
    for (var sale in _mockSales) {
      total += sale.totalAmount;
    }
    return total;
  }
}