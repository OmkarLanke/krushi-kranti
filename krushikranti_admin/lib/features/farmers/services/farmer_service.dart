import '../../../core/services/http_service.dart';
import '../models/farmer_models.dart';

class AdminFarmerService {
  static const String _basePath = 'admin/farmers';

  /// Fetch paginated list of farmers
  static Future<FarmerListResponse> getFarmers({
    int page = 0,
    int size = 20,
    String? search,
    String? kycStatus,
    String? subscriptionStatus,
    String? pincode,
  }) async {
    String endpoint = '$_basePath?page=$page&size=$size';
    
    if (search != null && search.isNotEmpty) {
      endpoint += '&search=${Uri.encodeComponent(search)}';
    }
    if (kycStatus != null && kycStatus.isNotEmpty) {
      endpoint += '&kycStatus=$kycStatus';
    }
    if (subscriptionStatus != null && subscriptionStatus.isNotEmpty) {
      endpoint += '&subscriptionStatus=$subscriptionStatus';
    }
    if (pincode != null && pincode.isNotEmpty) {
      endpoint += '&pincode=${Uri.encodeComponent(pincode)}';
    }
    
    final response = await HttpService.get(endpoint);
    
    if (response is Map && response.containsKey('data')) {
      return FarmerListResponse.fromJson(response['data']);
    }
    
    throw Exception('Invalid response format');
  }

  /// Fetch detailed information for a single farmer
  static Future<FarmerDetail> getFarmerDetail(int farmerId) async {
    final response = await HttpService.get('$_basePath/$farmerId');
    
    if (response is Map && response.containsKey('data')) {
      return FarmerDetail.fromJson(response['data']);
    }
    
    throw Exception('Invalid response format');
  }

  /// Fetch dashboard statistics
  static Future<DashboardStats> getDashboardStats() async {
    final response = await HttpService.get('$_basePath/stats');
    
    if (response is Map && response.containsKey('data')) {
      return DashboardStats.fromJson(response['data']);
    }
    
    throw Exception('Invalid response format');
  }
}

