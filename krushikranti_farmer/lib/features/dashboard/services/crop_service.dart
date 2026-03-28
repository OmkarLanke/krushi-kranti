import 'dart:async';
import '../models/crop_model.dart';
import '../../../core/services/http_service.dart';

class CropService {
  static const Duration _cacheTtl = Duration(seconds: 45);

  static List<CropModel>? _cachedCrops;
  static DateTime? _cachedCropsAt;
  static Future<List<CropModel>>? _inFlightCrops;

  static List<Map<String, dynamic>>? _cachedCropTypes;
  static DateTime? _cachedCropTypesAt;

  static final Map<int, List<Map<String, dynamic>>> _cachedCropNamesByType = {};
  static final Map<int, DateTime> _cachedCropNamesAt = {};

  static List<Map<String, dynamic>>? _cachedFarms;
  static DateTime? _cachedFarmsAt;

  // 1. GET ALL CROPS
  static Future<List<CropModel>> getCrops({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedCrops != null &&
        _cachedCropsAt != null &&
        now.difference(_cachedCropsAt!) < _cacheTtl) {
      return _cachedCrops!;
    }

    if (!forceRefresh && _inFlightCrops != null) {
      return _inFlightCrops!;
    }

    final request = _fetchCrops();
    _inFlightCrops = request;
    try {
      final result = await request;
      _cachedCrops = result;
      _cachedCropsAt = DateTime.now();
      return result;
    } finally {
      if (identical(_inFlightCrops, request)) {
        _inFlightCrops = null;
      }
    }
  }

  static Future<List<CropModel>> _fetchCrops() async {
    try {
      final response = await HttpService.get("farmer/profile/crops");
      final List<dynamic> cropsData = response['data'] ?? [];

      return cropsData.map((json) => CropModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch crops: $e');
    }
  }

  // 2. GET CROP TYPES
  static Future<List<Map<String, dynamic>>> getCropTypes(
      {bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedCropTypes != null &&
        _cachedCropTypesAt != null &&
        now.difference(_cachedCropTypesAt!) < _cacheTtl) {
      return _cachedCropTypes!;
    }

    try {
      final response = await HttpService.get("farmer/profile/crop-types");
      final List<dynamic> typesData = response['data'] ?? [];

      final result = typesData
          .map((json) => {
                'id': json['id'],
                'typeName': json['typeName'],
                'displayName': json['displayName'] ?? json['typeName'],
              })
          .toList();

      _cachedCropTypes = result;
      _cachedCropTypesAt = DateTime.now();
      return result;
    } catch (e) {
      throw Exception('Failed to fetch crop types: $e');
    }
  }

  // 3. GET CROP NAMES BY TYPE
  static Future<List<Map<String, dynamic>>> getCropNamesByType(
    int typeId, {
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final cachedAt = _cachedCropNamesAt[typeId];
    final cached = _cachedCropNamesByType[typeId];
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        now.difference(cachedAt) < _cacheTtl) {
      return cached;
    }

    try {
      final response =
          await HttpService.get("farmer/profile/crop-names?typeId=$typeId");
      final List<dynamic> namesData = response['data'] ?? [];

      final result = namesData
          .map((json) => {
                'id': json['id'],
                'name': json['name'],
                'displayName': json['displayName'] ?? json['name'],
                'localName': json['localName'],
                'cropTypeId': json['cropTypeId'],
              })
          .toList();

      _cachedCropNamesByType[typeId] = result;
      _cachedCropNamesAt[typeId] = DateTime.now();
      return result;
    } catch (e) {
      throw Exception('Failed to fetch crop names: $e');
    }
  }

  // 4. GET FARMS (needed for adding crops)
  static Future<List<Map<String, dynamic>>> getFarms(
      {bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedFarms != null &&
        _cachedFarmsAt != null &&
        now.difference(_cachedFarmsAt!) < _cacheTtl) {
      return _cachedFarms!;
    }

    try {
      final response = await HttpService.get("farmer/profile/farms");
      final List<dynamic> farmsData = response['data'] ?? [];

      final result = farmsData
          .map((json) => {
                'id': json['id'],
                'name': json['farmName'] ?? 'Farm ${json['id']}',
              })
          .toList();

      _cachedFarms = result;
      _cachedFarmsAt = DateTime.now();
      return result;
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
      _cachedCrops = null;
      _cachedCropsAt = null;
    } catch (e) {
      throw Exception('Failed to add crop: $e');
    }
  }

  static void clearCache() {
    _cachedCrops = null;
    _cachedCropsAt = null;
    _inFlightCrops = null;
    _cachedCropTypes = null;
    _cachedCropTypesAt = null;
    _cachedCropNamesByType.clear();
    _cachedCropNamesAt.clear();
    _cachedFarms = null;
    _cachedFarmsAt = null;
  }
}
