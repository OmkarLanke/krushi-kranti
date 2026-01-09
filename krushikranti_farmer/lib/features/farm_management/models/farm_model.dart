class Farm {
  final int? id;
  final int? farmerId;
  final String farmName;
  final String? farmType;
  final double totalAreaAcres;
  final String pincode;
  final String village;
  final String? district;
  final String? taluka;
  final String? state;
  final String? soilType;
  final String? irrigationType;
  final String landOwnership;
  final String? surveyNumber;
  final String? landRegistrationNumber;
  final String? pattaNumber;
  final double? estimatedLandValue;
  final String? encumbranceStatus;
  final String? encumbranceRemarks;
  final bool? isVerified;
  final bool? isActive;
  // GPS coordinates for farm location
  final double? farmLatitude;
  final double? farmLongitude;
  final double? farmLocationAccuracy;
  final DateTime? farmLocationCapturedAt;

  Farm({
    this.id,
    this.farmerId,
    required this.farmName,
    this.farmType,
    required this.totalAreaAcres,
    required this.pincode,
    required this.village,
    this.district,
    this.taluka,
    this.state,
    this.soilType,
    this.irrigationType,
    required this.landOwnership,
    this.surveyNumber,
    this.landRegistrationNumber,
    this.pattaNumber,
    this.estimatedLandValue,
    this.encumbranceStatus,
    this.encumbranceRemarks,
    this.isVerified,
    this.isActive,
    this.farmLatitude,
    this.farmLongitude,
    this.farmLocationAccuracy,
    this.farmLocationCapturedAt,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'],
      farmerId: json['farmerId'],
      farmName: json['farmName'] ?? '',
      farmType: json['farmType'],
      totalAreaAcres: (json['totalAreaAcres'] ?? 0).toDouble(),
      pincode: json['pincode'] ?? '',
      village: json['village'] ?? '',
      district: json['district'],
      taluka: json['taluka'],
      state: json['state'],
      soilType: json['soilType'],
      irrigationType: json['irrigationType'],
      landOwnership: json['landOwnership'] ?? '',
      surveyNumber: json['surveyNumber'],
      landRegistrationNumber: json['landRegistrationNumber'],
      pattaNumber: json['pattaNumber'],
      estimatedLandValue: json['estimatedLandValue']?.toDouble(),
      encumbranceStatus: json['encumbranceStatus'],
      encumbranceRemarks: json['encumbranceRemarks'],
      isVerified: json['isVerified'],
      isActive: json['isActive'],
      farmLatitude: json['farmLatitude']?.toDouble(),
      farmLongitude: json['farmLongitude']?.toDouble(),
      farmLocationAccuracy: json['farmLocationAccuracy']?.toDouble(),
      farmLocationCapturedAt: json['farmLocationCapturedAt'] != null
          ? DateTime.parse(json['farmLocationCapturedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (farmerId != null) 'farmerId': farmerId,
      'farmName': farmName,
      if (farmType != null) 'farmType': farmType,
      'totalAreaAcres': totalAreaAcres,
      'pincode': pincode,
      'village': village,
      if (district != null) 'district': district,
      if (taluka != null) 'taluka': taluka,
      if (state != null) 'state': state,
      if (soilType != null) 'soilType': soilType,
      if (irrigationType != null) 'irrigationType': irrigationType,
      'landOwnership': landOwnership,
      if (surveyNumber != null) 'surveyNumber': surveyNumber,
      if (landRegistrationNumber != null) 'landRegistrationNumber': landRegistrationNumber,
      if (pattaNumber != null) 'pattaNumber': pattaNumber,
      if (estimatedLandValue != null) 'estimatedLandValue': estimatedLandValue,
      if (encumbranceStatus != null) 'encumbranceStatus': encumbranceStatus,
      if (encumbranceRemarks != null) 'encumbranceRemarks': encumbranceRemarks,
      if (farmLatitude != null) 'farmLatitude': farmLatitude,
      if (farmLongitude != null) 'farmLongitude': farmLongitude,
      if (farmLocationAccuracy != null) 'farmLocationAccuracy': farmLocationAccuracy,
      if (farmLocationCapturedAt != null) 'farmLocationCapturedAt': farmLocationCapturedAt!.toIso8601String(),
    };
  }
}


