import 'dart:async';
import '../models/fund_request_model.dart';

class FundsService {
  // MOCK DATABASE
  static final List<FundRequestModel> _mockRequests = [
    FundRequestModel(
      requestId: 'REQ001',
      requestType: 'Fertilizer',
      amountNeeded: 5000,
      description: 'Need Urea for wheat crop',
      status: 'Approved',
    ),
    FundRequestModel(
      requestId: 'REQ002',
      requestType: 'Drip Irrigation',
      amountNeeded: 25000,
      description: 'Installing new pipes for 2 acres',
      status: 'Pending',
    ),
  ];

  // 1. GET REQUEST HISTORY
  static Future<List<FundRequestModel>> getRequests() async {
    await Future.delayed(const Duration(seconds: 1)); 
    return _mockRequests;
  }

  // 2. SUBMIT NEW REQUEST
  static Future<bool> submitRequest(FundRequestModel request) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Simple logic: If amount is huge, reject it (Just for testing)
    if (request.amountNeeded > 100000) {
      return false; // Request failed
    }
    
    _mockRequests.add(request);
    return true; // Success
  }
}