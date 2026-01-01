class FarmerSummary {
  final int farmerId;
  final int userId;
  final String fullName;
  final String username;
  final String phoneNumber;
  final String email;
  final String? village;
  final String? district;
  final String? state;
  final bool isProfileComplete;
  final String kycStatus;
  final String subscriptionStatus;
  final int farmCount;
  final int verifiedFarmCount;
  final int? assignedFarmsCount;
  final int? totalFarmsCount;
  final bool? hasAllFarmsAssigned;
  final bool? hasPartialAssignment;
  final DateTime? registeredAt;
  final DateTime? lastUpdatedAt;

  FarmerSummary({
    required this.farmerId,
    required this.userId,
    required this.fullName,
    required this.username,
    required this.phoneNumber,
    required this.email,
    this.village,
    this.district,
    this.state,
    required this.isProfileComplete,
    required this.kycStatus,
    required this.subscriptionStatus,
    required this.farmCount,
    required this.verifiedFarmCount,
    this.assignedFarmsCount,
    this.totalFarmsCount,
    this.hasAllFarmsAssigned,
    this.hasPartialAssignment,
    this.registeredAt,
    this.lastUpdatedAt,
  });

  factory FarmerSummary.fromJson(Map<String, dynamic> json) {
    return FarmerSummary(
      farmerId: json['farmerId'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      username: json['username'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      village: json['village'],
      district: json['district'],
      state: json['state'],
      isProfileComplete: json['isProfileComplete'] ?? false,
      kycStatus: json['kycStatus'] ?? 'PENDING',
      subscriptionStatus: json['subscriptionStatus'] ?? 'PENDING',
      farmCount: json['farmCount'] ?? 0,
      verifiedFarmCount: json['verifiedFarmCount'] ?? 0,
      assignedFarmsCount: json['assignedFarmsCount'],
      totalFarmsCount: json['totalFarmsCount'],
      hasAllFarmsAssigned: json['hasAllFarmsAssigned'],
      hasPartialAssignment: json['hasPartialAssignment'],
      registeredAt: json['registeredAt'] != null
          ? DateTime.tryParse(json['registeredAt'])
          : null,
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.tryParse(json['lastUpdatedAt'])
          : null,
    );
  }
}

class DashboardStats {
  final int totalFarmers;
  final int pendingKyc;
  final int verifiedKyc;
  final int activeSubscriptions;
  final int pendingSubscriptions;
  final int totalFarms;
  final int verifiedFarms;

  DashboardStats({
    required this.totalFarmers,
    required this.pendingKyc,
    required this.verifiedKyc,
    required this.activeSubscriptions,
    required this.pendingSubscriptions,
    required this.totalFarms,
    required this.verifiedFarms,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalFarmers: json['totalFarmers'] ?? 0,
      pendingKyc: json['pendingKyc'] ?? 0,
      verifiedKyc: json['verifiedKyc'] ?? 0,
      activeSubscriptions: json['activeSubscriptions'] ?? 0,
      pendingSubscriptions: json['pendingSubscriptions'] ?? 0,
      totalFarms: json['totalFarms'] ?? 0,
      verifiedFarms: json['verifiedFarms'] ?? 0,
    );
  }
}

class FarmerListResponse {
  final List<FarmerSummary> farmers;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;
  final DashboardStats? stats;

  FarmerListResponse({
    required this.farmers,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
    this.stats,
  });

  factory FarmerListResponse.fromJson(Map<String, dynamic> json) {
    return FarmerListResponse(
      farmers: (json['farmers'] as List?)
              ?.map((e) => FarmerSummary.fromJson(e))
              .toList() ??
          [],
      currentPage: json['currentPage'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      pageSize: json['pageSize'] ?? 20,
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
      stats: json['stats'] != null
          ? DashboardStats.fromJson(json['stats'])
          : null,
    );
  }
}

// Detailed Farmer Model
class FarmerDetail {
  final int farmerId;
  final int userId;
  final ProfileInfo profile;
  final KycInfo? kyc;
  final SubscriptionInfo? subscription;
  final List<FarmInfo> farms;
  final List<CropInfo> crops;

  FarmerDetail({
    required this.farmerId,
    required this.userId,
    required this.profile,
    this.kyc,
    this.subscription,
    required this.farms,
    required this.crops,
  });

  factory FarmerDetail.fromJson(Map<String, dynamic> json) {
    return FarmerDetail(
      farmerId: json['farmerId'] ?? 0,
      userId: json['userId'] ?? 0,
      profile: ProfileInfo.fromJson(json['profile'] ?? {}),
      kyc: json['kyc'] != null ? KycInfo.fromJson(json['kyc']) : null,
      subscription: json['subscription'] != null
          ? SubscriptionInfo.fromJson(json['subscription'])
          : null,
      farms: (json['farms'] as List?)
              ?.map((e) => FarmInfo.fromJson(e))
              .toList() ??
          [],
      crops: (json['crops'] as List?)
              ?.map((e) => CropInfo.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ProfileInfo {
  final String? firstName;
  final String? lastName;
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final String? alternatePhone;
  final String? dateOfBirth;
  final String? gender;
  final String? pincode;
  final String? village;
  final String? taluka;
  final String? district;
  final String? state;
  final bool isProfileComplete;
  final DateTime? createdAt;

  ProfileInfo({
    this.firstName,
    this.lastName,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.alternatePhone,
    this.dateOfBirth,
    this.gender,
    this.pincode,
    this.village,
    this.taluka,
    this.district,
    this.state,
    required this.isProfileComplete,
    this.createdAt,
  });

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
      firstName: json['firstName'],
      lastName: json['lastName'],
      fullName: json['fullName'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      alternatePhone: json['alternatePhone'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      pincode: json['pincode'],
      village: json['village'],
      taluka: json['taluka'],
      district: json['district'],
      state: json['state'],
      isProfileComplete: json['isProfileComplete'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class KycInfo {
  final String status;
  final bool aadhaarVerified;
  final String? aadhaarName;
  final String? aadhaarNumberMasked;
  final DateTime? aadhaarVerifiedAt;
  final bool panVerified;
  final String? panName;
  final String? panNumberMasked;
  final DateTime? panVerifiedAt;
  final bool bankVerified;
  final String? bankName;
  final String? bankAccountHolderName;
  final String? bankAccountMasked;
  final String? bankIfsc;
  final DateTime? bankVerifiedAt;

  KycInfo({
    required this.status,
    required this.aadhaarVerified,
    this.aadhaarName,
    this.aadhaarNumberMasked,
    this.aadhaarVerifiedAt,
    required this.panVerified,
    this.panName,
    this.panNumberMasked,
    this.panVerifiedAt,
    required this.bankVerified,
    this.bankName,
    this.bankAccountHolderName,
    this.bankAccountMasked,
    this.bankIfsc,
    this.bankVerifiedAt,
  });

  factory KycInfo.fromJson(Map<String, dynamic> json) {
    return KycInfo(
      status: json['status'] ?? 'PENDING',
      aadhaarVerified: json['aadhaarVerified'] ?? false,
      aadhaarName: json['aadhaarName'],
      aadhaarNumberMasked: json['aadhaarNumberMasked'],
      aadhaarVerifiedAt: json['aadhaarVerifiedAt'] != null
          ? DateTime.tryParse(json['aadhaarVerifiedAt'])
          : null,
      panVerified: json['panVerified'] ?? false,
      panName: json['panName'],
      panNumberMasked: json['panNumberMasked'],
      panVerifiedAt: json['panVerifiedAt'] != null
          ? DateTime.tryParse(json['panVerifiedAt'])
          : null,
      bankVerified: json['bankVerified'] ?? false,
      bankName: json['bankName'],
      bankAccountHolderName: json['bankAccountHolderName'],
      bankAccountMasked: json['bankAccountMasked'],
      bankIfsc: json['bankIfsc'],
      bankVerifiedAt: json['bankVerifiedAt'] != null
          ? DateTime.tryParse(json['bankVerifiedAt'])
          : null,
    );
  }

  int get completedSteps {
    int count = 0;
    if (aadhaarVerified) count++;
    if (panVerified) count++;
    if (bankVerified) count++;
    return count;
  }
}

class SubscriptionInfo {
  final int? subscriptionId;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? amount;
  final String? paymentStatus;
  final String? paymentTransactionId;
  final DateTime? paymentDate;

  SubscriptionInfo({
    this.subscriptionId,
    required this.status,
    this.startDate,
    this.endDate,
    this.amount,
    this.paymentStatus,
    this.paymentTransactionId,
    this.paymentDate,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      subscriptionId: json['subscriptionId'],
      status: json['status'] ?? 'PENDING',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,
      amount: json['amount']?.toDouble(),
      paymentStatus: json['paymentStatus'],
      paymentTransactionId: json['paymentTransactionId'],
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'])
          : null,
    );
  }
}

class FarmInfo {
  final int farmId;
  final String farmName;
  final String? farmType;
  final double? totalAreaAcres;
  final String? pincode;
  final String? village;
  final String? district;
  final String? taluka;
  final String? state;
  final String? soilType;
  final String? irrigationType;
  final String? landOwnership;
  final String? surveyNumber;
  final String? landRegistrationNumber;
  final String? pattaNumber;
  final double? estimatedLandValue;
  final String? encumbranceStatus;
  final String? encumbranceRemarks;
  final String? landDocumentUrl;
  final String? surveyMapUrl;
  final String? registrationCertificateUrl;
  final bool isVerified;
  final int? verifiedByOfficerId;
  final String? verifiedByOfficerName;
  final DateTime? verifiedAt;
  final String? verificationRemarks;
  final DateTime? createdAt;

  FarmInfo({
    required this.farmId,
    required this.farmName,
    this.farmType,
    this.totalAreaAcres,
    this.pincode,
    this.village,
    this.district,
    this.taluka,
    this.state,
    this.soilType,
    this.irrigationType,
    this.landOwnership,
    this.surveyNumber,
    this.landRegistrationNumber,
    this.pattaNumber,
    this.estimatedLandValue,
    this.encumbranceStatus,
    this.encumbranceRemarks,
    this.landDocumentUrl,
    this.surveyMapUrl,
    this.registrationCertificateUrl,
    required this.isVerified,
    this.verifiedByOfficerId,
    this.verifiedByOfficerName,
    this.verifiedAt,
    this.verificationRemarks,
    this.createdAt,
  });

  factory FarmInfo.fromJson(Map<String, dynamic> json) {
    return FarmInfo(
      farmId: json['farmId'] ?? 0,
      farmName: json['farmName'] ?? '',
      farmType: json['farmType'],
      totalAreaAcres: json['totalAreaAcres']?.toDouble(),
      pincode: json['pincode'],
      village: json['village'],
      district: json['district'],
      taluka: json['taluka'],
      state: json['state'],
      soilType: json['soilType'],
      irrigationType: json['irrigationType'],
      landOwnership: json['landOwnership'],
      surveyNumber: json['surveyNumber'],
      landRegistrationNumber: json['landRegistrationNumber'],
      pattaNumber: json['pattaNumber'],
      estimatedLandValue: json['estimatedLandValue']?.toDouble(),
      encumbranceStatus: json['encumbranceStatus'],
      encumbranceRemarks: json['encumbranceRemarks'],
      landDocumentUrl: json['landDocumentUrl'],
      surveyMapUrl: json['surveyMapUrl'],
      registrationCertificateUrl: json['registrationCertificateUrl'],
      isVerified: json['isVerified'] ?? false,
      verifiedByOfficerId: json['verifiedByOfficerId'],
      verifiedByOfficerName: json['verifiedByOfficerName'],
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'])
          : null,
      verificationRemarks: json['verificationRemarks'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class CropInfo {
  final int cropId;
  final int? farmId;
  final String? farmName;
  final int? cropTypeId;
  final String? cropTypeName;
  final int? cropNameId;
  final String? cropName;
  final String? cropDisplayName;
  final double? areaAcres;
  final String? sowingDate;
  final String? harvestingDate;
  final String? cropStatus;
  final bool? isActive;
  final DateTime? createdAt;

  CropInfo({
    required this.cropId,
    this.farmId,
    this.farmName,
    this.cropTypeId,
    this.cropTypeName,
    this.cropNameId,
    this.cropName,
    this.cropDisplayName,
    this.areaAcres,
    this.sowingDate,
    this.harvestingDate,
    this.cropStatus,
    this.isActive,
    this.createdAt,
  });

  factory CropInfo.fromJson(Map<String, dynamic> json) {
    return CropInfo(
      cropId: json['cropId'] ?? 0,
      farmId: json['farmId'],
      farmName: json['farmName'],
      cropTypeId: json['cropTypeId'],
      cropTypeName: json['cropTypeName'],
      cropNameId: json['cropNameId'],
      cropName: json['cropName'],
      cropDisplayName: json['cropDisplayName'],
      areaAcres: json['areaAcres']?.toDouble(),
      sowingDate: json['sowingDate'],
      harvestingDate: json['harvestingDate'],
      cropStatus: json['cropStatus'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

