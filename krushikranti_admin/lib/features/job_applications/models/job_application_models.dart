class JobApplication {
  final String id;
  final String fullName;
  final String? email;
  final String? mobileNumber;
  final String? whatsappNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? highestQualification;
  final String? fieldOfStudy;
  final int? yearOfPassing;
  final String? previousExperience;
  final String? yearsOfExperience;
  final String? relevantSkills;
  final String roleType;
  final String? resumeUrl;
  final String currentStatus;
  final DateTime appliedAt;
  final DateTime? lastUpdated;

  JobApplication({
    required this.id,
    required this.fullName,
    this.email,
    this.mobileNumber,
    this.whatsappNumber,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.highestQualification,
    this.fieldOfStudy,
    this.yearOfPassing,
    this.previousExperience,
    this.yearsOfExperience,
    this.relevantSkills,
    required this.roleType,
    this.resumeUrl,
    required this.currentStatus,
    required this.appliedAt,
    this.lastUpdated,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['applicantId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Unknown',
      email: json['email']?.toString(),
      mobileNumber: json['mobile']?.toString(),
      whatsappNumber: null, // Not in backend
      dateOfBirth: json['dob'] != null
          ? DateTime.tryParse(json['dob'] as String)
          : null,
      gender: null, // Not in backend
      address: json['locationText']?.toString(),
      city: null, // Part of locationText
      state: null, // Part of locationText
      pincode: null, // Part of locationText
      highestQualification: json['highestQualification']?.toString(),
      fieldOfStudy: null, // Not in backend
      yearOfPassing: json['yearOfCompletion'] as int?,
      previousExperience: json['yearsExperience'] != null ? 'Yes' : null,
      yearsOfExperience: json['yearsExperience']?.toString(),
      relevantSkills: json['relevantExperience']?.toString(),
      roleType: json['roleType']?.toString() ?? 'UNKNOWN',
      resumeUrl: json['resumeUrl']?.toString(),
      currentStatus: json['currentStatus']?.toString() ?? 'SCREENING',
      appliedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : DateTime.now(),
      lastUpdated: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicantId': id,
      'fullName': fullName,
      'email': email,
      'mobile': mobileNumber,
      'dob': dateOfBirth?.toIso8601String(),
      'locationText': address,
      'highestQualification': highestQualification,
      'yearOfCompletion': yearOfPassing,
      'yearsExperience': yearsOfExperience != null
          ? int.tryParse(yearsOfExperience!)
          : null,
      'relevantExperience': relevantSkills,
      'roleType': roleType,
      'resumeUrl': resumeUrl,
      'currentStatus': currentStatus,
      'submittedAt': appliedAt.toIso8601String(),
      'updatedAt': lastUpdated?.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (currentStatus) {
      case 'SCREENING':
        return 'Screening';
      case 'SELECTED_FOR_HR':
        return 'Selected for HR';
      case 'SELECTED':
        return 'Selected';
      case 'REJECTED':
        return 'Rejected';
      default:
        return currentStatus;
    }
  }

  String get roleTypeDisplay {
    switch (roleType) {
      case 'FIELD_OFFICER':
        return 'Field Officer';
      case 'KRUSHI_TADNYA':
        return 'Krushi Tadnya';
      case 'VENDOR':
        return 'Vendor';
      default:
        return roleType;
    }
  }
}

class JobApplicationStats {
  final int total;
  final int screening;
  final int selectedForHR;
  final int selected;
  final int rejected;

  JobApplicationStats({
    required this.total,
    required this.screening,
    required this.selectedForHR,
    required this.selected,
    required this.rejected,
  });

  factory JobApplicationStats.fromJson(Map<String, dynamic> json) {
    return JobApplicationStats(
      total: json['total'] as int,
      screening: json['screening'] as int,
      selectedForHR: json['selectedForHR'] as int,
      selected: json['selected'] as int,
      rejected: json['rejected'] as int,
    );
  }

  factory JobApplicationStats.fromApplications(
    List<JobApplication> applications,
  ) {
    return JobApplicationStats(
      total: applications.length,
      screening: applications
          .where((a) => a.currentStatus == 'SCREENING')
          .length,
      selectedForHR: applications
          .where((a) => a.currentStatus == 'SELECTED_FOR_HR')
          .length,
      selected: applications.where((a) => a.currentStatus == 'SELECTED').length,
      rejected: applications.where((a) => a.currentStatus == 'REJECTED').length,
    );
  }
}
