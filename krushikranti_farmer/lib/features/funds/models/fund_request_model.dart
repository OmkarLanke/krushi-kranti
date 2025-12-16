class FundRequestModel {
  final String requestId;
  final String requestType; // "Seeds", "Fertilizer", "Equipment", "Drip Irrigation" [cite: 24-27]
  final double amountNeeded;
  final String description;
  final String status;      // "Pending", "Approved", "Rejected"

  FundRequestModel({
    required this.requestId,
    required this.requestType,
    required this.amountNeeded,
    required this.description,
    required this.status,
  });
}