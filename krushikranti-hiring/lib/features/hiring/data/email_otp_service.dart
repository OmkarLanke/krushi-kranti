import 'package:dio/dio.dart';
import '../../../core/api_config.dart';

class EmailOtpService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static Future<bool> sendOtp(String email) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/api/otp/send',
      queryParameters: {'email': email},
    );
    if (response.statusCode == 200 && response.data is Map) {
      return response.data['sent'] == true;
    }
    return false;
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/api/otp/verify',
      data: {'email': email, 'otp': otp},
    );
    if (response.statusCode == 200 && response.data is Map) {
      return response.data['verified'] == true;
    }
    return false;
  }
}
