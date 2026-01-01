class SuggestedFieldOfficer {
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
  final List<String> matchingPincodes;
  final int matchingFarmCount;

  SuggestedFieldOfficer({
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
    required this.matchingPincodes,
    required this.matchingFarmCount,
  });

  factory SuggestedFieldOfficer.fromJson(Map<String, dynamic> json) {
    return SuggestedFieldOfficer(
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
      matchingPincodes: (json['matchingPincodes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      matchingFarmCount: json['matchingFarmCount'] ?? 0,
    );
  }
}

class AssignmentResponse {
  final int assignmentId;
  final int fieldOfficerId;
  final int farmerUserId;
  final int? farmId; // Farm ID from farmer-service
  final String fieldOfficerName;
  final String fieldOfficerPhone;
  final String? fieldOfficerPincode;
  final String? farmerName;
  final String? farmerPhone;
  final String? farmName;
  final String? farmLocation;
  final String status;
  final int? assignedByUserId;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final String? notes;

  AssignmentResponse({
    required this.assignmentId,
    required this.fieldOfficerId,
    required this.farmerUserId,
    this.farmId,
    required this.fieldOfficerName,
    required this.fieldOfficerPhone,
    this.fieldOfficerPincode,
    this.farmerName,
    this.farmerPhone,
    this.farmName,
    this.farmLocation,
    required this.status,
    this.assignedByUserId,
    this.assignedAt,
    this.completedAt,
    this.notes,
  });

  factory AssignmentResponse.fromJson(Map<String, dynamic> json) {
    return AssignmentResponse(
      assignmentId: json['assignmentId'] ?? 0,
      fieldOfficerId: json['fieldOfficerId'] ?? 0,
      farmerUserId: json['farmerUserId'] ?? 0,
      farmId: json['farmId'],
      fieldOfficerName: json['fieldOfficerName'] ?? '',
      fieldOfficerPhone: json['fieldOfficerPhone'] ?? '',
      fieldOfficerPincode: json['fieldOfficerPincode'],
      farmerName: json['farmerName'],
      farmerPhone: json['farmerPhone'],
      farmName: json['farmName'],
      farmLocation: json['farmLocation'],
      status: json['status'] ?? 'ASSIGNED',
      assignedByUserId: json['assignedByUserId'],
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      notes: json['notes'],
    );
  }
}

class AssignFieldOfficerRequest {
  final int fieldOfficerId;
  final int farmerUserId;
  final int farmId; // Required: Farm ID from farmer-service
  final String? notes;

  AssignFieldOfficerRequest({
    required this.fieldOfficerId,
    required this.farmerUserId,
    required this.farmId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'fieldOfficerId': fieldOfficerId,
      'farmerUserId': farmerUserId,
      'farmId': farmId,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

