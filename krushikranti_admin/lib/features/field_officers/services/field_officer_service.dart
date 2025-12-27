import '../../../core/services/http_service.dart';
import '../models/field_officer_models.dart';

class FieldOfficerService {
  static Future<FieldOfficerListResponse> getFieldOfficers({
    int page = 0,
    int size = 20,
    String? search,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await HttpService.get('admin/field-officers?$queryString');
      
      final data = response['data'] as Map<String, dynamic>;
      return FieldOfficerListResponse.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch field officers: ${e.toString()}');
    }
  }

  static Future<FieldOfficerSummary> createFieldOfficer(CreateFieldOfficerRequest request) async {
    try {
      final response = await HttpService.post(
        'admin/field-officers',
        request.toJson(),
      );
      
      final data = response['data'] as Map<String, dynamic>;
      return FieldOfficerSummary.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create field officer: ${e.toString()}');
    }
  }
}

