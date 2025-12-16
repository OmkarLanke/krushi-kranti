import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SalesOrderModel {
  final String id;
  final String date;
  final int items;
  final String weight;
  final String status;
  
  // Specific financial details for the Detail Screen
  final double? pricePerKg; 
  final double? totalPrice;

  SalesOrderModel({
    required this.id,
    required this.date,
    required this.items,
    required this.weight,
    required this.status,
    this.pricePerKg,
    this.totalPrice,
  });

  // --- HELPER: Get Color based on Status ---
  Color get statusColor {
    // You can add more status logic here (e.g., 'Cancelled', 'Processing')
    if (status.toLowerCase().contains('received') || status.toLowerCase().contains('verified')) {
      return AppColors.brandGreen;
    } else if (status.toLowerCase().contains('pending')) {
      return AppColors.pendingStatus;
    } else {
      return Colors.grey;
    }
  }

  // --- FACTORY: For API Integration later ---
  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderModel(
      id: json['order_id'],
      date: json['created_at'],
      items: json['item_count'],
      weight: json['total_weight'],
      status: json['status'],
    );
  }
}