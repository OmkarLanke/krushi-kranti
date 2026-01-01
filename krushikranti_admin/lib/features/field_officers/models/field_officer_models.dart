class FieldOfficerSummary {
  final int fieldOfficerId;
  final int userId;
  final String fullName;
  final String username;
  final String phoneNumber;
  final String email;
  final String? pincode;
  final String? village;
  final String? district;
  final String? state;
  final bool isActive;
  final int? assignedFarmsCount;
  final DateTime? createdAt;
  final DateTime? lastUpdatedAt;

  FieldOfficerSummary({
    required this.fieldOfficerId,
    required this.userId,
    required this.fullName,
    required this.username,
    required this.phoneNumber,
    required this.email,
    this.pincode,
    this.village,
    this.district,
    this.state,
    required this.isActive,
    this.assignedFarmsCount,
    this.createdAt,
    this.lastUpdatedAt,
  });

  factory FieldOfficerSummary.fromJson(Map<String, dynamic> json) {
    return FieldOfficerSummary(
      fieldOfficerId: json['fieldOfficerId'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      username: json['username'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      pincode: json['pincode'],
      village: json['village'],
      district: json['district'],
      state: json['state'],
      isActive: json['isActive'] ?? true,
      assignedFarmsCount: json['assignedFarmsCount'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.tryParse(json['lastUpdatedAt'])
          : null,
    );
  }
}

class FieldOfficerListResponse {
  final List<FieldOfficerSummary> fieldOfficers;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;

  FieldOfficerListResponse({
    required this.fieldOfficers,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory FieldOfficerListResponse.fromJson(Map<String, dynamic> json) {
    return FieldOfficerListResponse(
      fieldOfficers: (json['fieldOfficers'] as List?)
              ?.map((e) => FieldOfficerSummary.fromJson(e))
              .toList() ??
          [],
      currentPage: json['currentPage'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      pageSize: json['pageSize'] ?? 20,
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
    );
  }
}

class CreateFieldOfficerRequest {
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final String gender;
  final String phoneNumber;
  final String? alternatePhone;
  final String email;
  final String pincode;
  final String village;
  final String? district;
  final String? taluka;
  final String? state;
  final String username;
  final String password;
  final bool isActive;

  CreateFieldOfficerRequest({
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    required this.gender,
    required this.phoneNumber,
    this.alternatePhone,
    required this.email,
    required this.pincode,
    required this.village,
    this.district,
    this.taluka,
    this.state,
    required this.username,
    required this.password,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      'gender': gender,
      'phoneNumber': phoneNumber,
      if (alternatePhone != null) 'alternatePhone': alternatePhone,
      'email': email,
      'pincode': pincode,
      'village': village,
      if (district != null) 'district': district,
      if (taluka != null) 'taluka': taluka,
      if (state != null) 'state': state,
      'username': username,
      'password': password,
      'isActive': isActive,
    };
  }
}
