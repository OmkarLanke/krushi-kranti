import '../services/http_service.dart';

class ApiEndpoints {
  // Base URL now uses platform detection from HttpService
  // - Web/Desktop: uses 'http://localhost:4004'
  // - Android/iOS: uses your local IP address (192.168.1.42)
  static String get baseUrl => HttpService.baseUrl;

  // Auth Endpoints
  static String get login => "$baseUrl/auth/login";
  static String get register => "$baseUrl/auth/register";
  static String get verifyOtp => "$baseUrl/auth/verify-otp";
  static String get requestLoginOtp => "$baseUrl/auth/request-login-otp";
  static String get resendOtp => "$baseUrl/auth/resend-otp";
  
  // Farmer Profile Endpoints
  static String get myDetails => "$baseUrl/farmer/profile/my-details";
  static String get addressLookup => "$baseUrl/farmer/profile/address/lookup";
  
  // Farm Endpoints
  static String get farms => "$baseUrl/farmer/profile/farms";
  static String farmById(String farmId) => "$baseUrl/farmer/profile/farms/$farmId";
  static String get farmsCount => "$baseUrl/farmer/profile/farms/count";
  static String get farmsCollateral => "$baseUrl/farmer/profile/farms/collateral";
  
  // Crop Endpoints
  static String get cropTypes => "$baseUrl/farmer/profile/crop-types";
  static String get cropNames => "$baseUrl/farmer/profile/crop-names";
  static String get crops => "$baseUrl/farmer/profile/crops";
  static String cropById(String cropId) => "$baseUrl/farmer/profile/crops/$cropId";
  static String cropsByFarm(String farmId) => "$baseUrl/farmer/profile/crops/farm/$farmId";
  
  // Subscription Endpoints
  static String get subscriptionStatus => "$baseUrl/subscription/status";
  static String get subscriptionCheck => "$baseUrl/subscription/check";
  static String get subscriptionProfileCheck => "$baseUrl/subscription/profile-check";
  static String get subscriptionPaymentInitiate => "$baseUrl/subscription/payment/initiate";
  static String get subscriptionPaymentComplete => "$baseUrl/subscription/payment/complete";
  
  // Add other endpoints here as needed
}