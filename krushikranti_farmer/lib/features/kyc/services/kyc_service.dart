import '../../../core/services/http_service.dart';
import '../models/kyc_models.dart';

class KycService {
  // Get KYC Status
  static Future<KycStatusResponse> getKycStatus() async {
    try {
      final response = await HttpService.get('kyc/status');
      return KycStatusResponse.fromJson(response['data'] ?? response);
    } catch (e) {
      throw Exception('Failed to get KYC status: $e');
    }
  }

  // Check if KYC is complete
  static Future<bool> isKycComplete() async {
    try {
      final response = await HttpService.get('kyc/check');
      return response['data'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Generate Aadhaar OTP
  static Future<AadhaarOtpResponse> generateAadhaarOtp(String aadhaarNumber) async {
    try {
      final response = await HttpService.post('kyc/aadhaar/generate-otp', {
        'aadhaarNumber': aadhaarNumber,
      });
      return AadhaarOtpResponse.fromJson(response['data'] ?? response);
    } catch (e) {
      throw Exception('Failed to generate OTP: $e');
    }
  }

  // Verify Aadhaar OTP
  static Future<AadhaarVerifyResponse> verifyAadhaarOtp(String requestId, String otp) async {
    try {
      final response = await HttpService.post('kyc/aadhaar/verify-otp', {
        'requestId': requestId,
        'otp': otp,
      });
      return AadhaarVerifyResponse.fromJson(response['data'] ?? response);
    } catch (e) {
      throw Exception('Failed to verify Aadhaar: $e');
    }
  }

  // Verify PAN
  static Future<PanVerifyResponse> verifyPan(String panNumber) async {
    try {
      final response = await HttpService.post('kyc/pan/verify', {
        'panNumber': panNumber,
      });
      return PanVerifyResponse.fromJson(response['data'] ?? response);
    } catch (e) {
      throw Exception('Failed to verify PAN: $e');
    }
  }

  // Verify Bank Account
  static Future<BankVerifyResponse> verifyBank(String accountNumber, String ifscCode) async {
    try {
      final response = await HttpService.post('kyc/bank/verify', {
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
      });
      return BankVerifyResponse.fromJson(response['data'] ?? response);
    } catch (e) {
      throw Exception('Failed to verify bank account: $e');
    }
  }

  // Test endpoint to bypass all KYC verifications (for testing purposes only)
  static Future<KycStatusResponse> testVerifyAll() async {
    try {
      final response = await HttpService.post('kyc/test/verify-all', {});
      return KycStatusResponse.fromJson(response['data'] ?? response);
    } catch (e) {
      throw Exception('Failed to test verify all KYC: $e');
    }
  }
}

