class SalesModel {
  final String id;
  final DateTime date;
  final String cropName;    // e.g., "Tomato"
  final double quantityKg;  // e.g., 50.0 kg
  final double ratePerKg;   // e.g., ₹20 per kg
  final double totalAmount; // e.g., ₹1000
  final String buyerName;   // "VCP Center" or "Private Merchant"

  SalesModel({
    required this.id,
    required this.date,
    required this.cropName,
    required this.quantityKg,
    required this.ratePerKg,
    required this.totalAmount,
    required this.buyerName,
  });

  // Calculate total automatically if needed
  double get calculatedTotal => quantityKg * ratePerKg;

  factory SalesModel.fromJson(Map<String, dynamic> json) {
    return SalesModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      cropName: json['cropName'],
      quantityKg: json['quantityKg'].toDouble(),
      ratePerKg: json['ratePerKg'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      buyerName: json['buyerName'],
    );
  }
}