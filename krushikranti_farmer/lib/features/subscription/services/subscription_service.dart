import 'dart:convert';
import '../../../core/services/http_service.dart';
import '../../../core/constants/api_endpoints.dart';

/// Service for subscription-related API calls.
class SubscriptionService {
  
  /// Get subscription status for the current user.
  static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final response = await HttpService.get(ApiEndpoints.subscriptionStatus);
      
      if (response['data'] != null) {
        return response['data'];
      }
      
      return {
        'isSubscribed': false,
        'subscriptionStatus': 'NONE',
        'message': response['message'] ?? 'No subscription found',
      };
    } catch (e) {
      print('Error getting subscription status: $e');
      return {
        'isSubscribed': false,
        'subscriptionStatus': 'ERROR',
        'message': e.toString(),
      };
    }
  }

  /// Check if user is subscribed (simple boolean check).
  static Future<bool> isSubscribed() async {
    try {
      final response = await HttpService.get(ApiEndpoints.subscriptionCheck);
      return response['data'] == true;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  /// Check profile completion status for subscription eligibility.
  static Future<Map<String, dynamic>> checkProfileCompletion({
    required bool hasMyDetails,
    required bool hasFarmDetails,
    required bool hasCropDetails,
  }) async {
    try {
      final url = "${ApiEndpoints.subscriptionProfileCheck}"
          "?hasMyDetails=$hasMyDetails"
          "&hasFarmDetails=$hasFarmDetails"
          "&hasCropDetails=$hasCropDetails";
      
      final response = await HttpService.get(url);
      
      if (response['data'] != null) {
        return response['data'];
      }
      
      return {
        'profileCompleted': false,
        'canSubscribe': false,
        'message': response['message'] ?? 'Unable to check profile completion',
      };
    } catch (e) {
      print('Error checking profile completion: $e');
      return {
        'profileCompleted': false,
        'canSubscribe': false,
        'message': e.toString(),
      };
    }
  }

  /// Initiate subscription payment.
  static Future<Map<String, dynamic>> initiatePayment({
    String? paymentMethod,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (paymentMethod != null) {
        body['paymentMethod'] = paymentMethod;
      }
      
      final response = await HttpService.post(
        ApiEndpoints.subscriptionPaymentInitiate,
        body,
      );
      
      if (response['data'] != null) {
        return response['data'];
      }
      
      throw Exception(response['error'] ?? response['message'] ?? 'Failed to initiate payment');
    } catch (e) {
      print('Error initiating payment: $e');
      rethrow;
    }
  }

  /// Complete subscription payment (mock or real).
  static Future<Map<String, dynamic>> completePayment({
    required int transactionId,
    bool mockPayment = true,
    String mockPaymentStatus = 'SUCCESS',
  }) async {
    try {
      final body = {
        'transactionId': transactionId,
        'mockPayment': mockPayment,
        'mockPaymentStatus': mockPaymentStatus,
      };
      
      final response = await HttpService.post(
        ApiEndpoints.subscriptionPaymentComplete,
        body,
      );
      
      if (response['data'] != null) {
        return response['data'];
      }
      
      throw Exception(response['error'] ?? response['message'] ?? 'Failed to complete payment');
    } catch (e) {
      print('Error completing payment: $e');
      rethrow;
    }
  }
}

