import 'dart:async';
import '../models/crop_model.dart';
import '../../../core/services/http_service.dart';

class CropService {
  // 1. GET ALL CROPS
  static Future<List<CropModel>> getCrops() async {
    try {
      final response = await HttpService.get("farmer/profile/crops");
      final List<dynamic> cropsData = response['data'] ?? [];
      
      return cropsData.map((json) => CropModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch crops: $e');
    }
  }

  // 2. GET CROP TYPES
  static Future<List<Map<String, dynamic>>> getCropTypes() async {
    try {
      final response = await HttpService.get("farmer/profile/crop-types");
      final List<dynamic> typesData = response['data'] ?? [];
      
      return typesData.map((json) => {
        'id': json['id'],
        'typeName': json['typeName'],
        'displayName': json['displayName'] ?? json['typeName'],
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch crop types: $e');
    }
  }

  // 3. GET CROP NAMES BY TYPE
  static Future<List<Map<String, dynamic>>> getCropNamesByType(int typeId) async {
    try {
      final response = await HttpService.get("farmer/profile/crop-names?typeId=$typeId");
      final List<dynamic> namesData = response['data'] ?? [];
      
      return namesData.map((json) => {
        'id': json['id'],
        'name': json['name'],
        'displayName': json['displayName'] ?? json['name'],
        'localName': json['localName'],
        'cropTypeId': json['cropTypeId'],
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch crop names: $e');
    }
  }

  // 4. GET FARMS (needed for adding crops)
  static Future<List<Map<String, dynamic>>> getFarms() async {
    try {
      final response = await HttpService.get("farmer/profile/farms");
      final List<dynamic> farmsData = response['data'] ?? [];
      
      return farmsData.map((json) => {
        'id': json['id'],
        'name': json['farmName'] ?? 'Farm ${json['id']}',
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch farms: $e');
    }
  }

  // 5. ADD NEW CROP
  static Future<void> addCrop({
    required int farmId,
    required int cropNameId,
    required double areaAcres,
    String? sowingDate,
    String? harvestingDate,
    String? cropStatus,
  }) async {
    try {
      final requestBody = {
        'farmId': farmId,
        'cropNameId': cropNameId,
        'areaAcres': areaAcres,
        if (sowingDate != null) 'sowingDate': sowingDate,
        if (harvestingDate != null) 'harvestingDate': harvestingDate,
        if (cropStatus != null) 'cropStatus': cropStatus,
      };
      
      await HttpService.post("farmer/profile/crops", requestBody);
    } catch (e) {
      throw Exception('Failed to add crop: $e');
    }
  }
}