// KYC Status Response
class KycStatusResponse {
  final int? userId;
  final String? kycStatus;
  final bool aadhaarVerified;
  final String? aadhaarNumberMasked;
  final String? aadhaarName;
  final DateTime? aadhaarVerifiedAt;
  final bool panVerified;
  final String? panNumberMasked;
  final String? panName;
  final DateTime? panVerifiedAt;
  final bool bankVerified;
  final String? bankAccountMasked;
  final String? bankIfsc;
  final String? bankName;
  final String? bankAccountHolderName;
  final DateTime? bankVerifiedAt;

  KycStatusResponse({
    this.userId,
    this.kycStatus,
    this.aadhaarVerified = false,
    this.aadhaarNumberMasked,
    this.aadhaarName,
    this.aadhaarVerifiedAt,
    this.panVerified = false,
    this.panNumberMasked,
    this.panName,
    this.panVerifiedAt,
    this.bankVerified = false,
    this.bankAccountMasked,
    this.bankIfsc,
    this.bankName,
    this.bankAccountHolderName,
    this.bankVerifiedAt,
  });

  factory KycStatusResponse.fromJson(Map<String, dynamic> json) {
    return KycStatusResponse(
      userId: json['userId'],
      kycStatus: json['kycStatus'],
      aadhaarVerified: json['aadhaarVerified'] ?? false,
      aadhaarNumberMasked: json['aadhaarNumberMasked'],
      aadhaarName: json['aadhaarName'],
      aadhaarVerifiedAt: json['aadhaarVerifiedAt'] != null 
          ? DateTime.tryParse(json['aadhaarVerifiedAt']) 
          : null,
      panVerified: json['panVerified'] ?? false,
      panNumberMasked: json['panNumberMasked'],
      panName: json['panName'],
      panVerifiedAt: json['panVerifiedAt'] != null 
          ? DateTime.tryParse(json['panVerifiedAt']) 
          : null,
      bankVerified: json['bankVerified'] ?? false,
      bankAccountMasked: json['bankAccountMasked'],
      bankIfsc: json['bankIfsc'],
      bankName: json['bankName'],
      bankAccountHolderName: json['bankAccountHolderName'],
      bankVerifiedAt: json['bankVerifiedAt'] != null 
          ? DateTime.tryParse(json['bankVerifiedAt']) 
          : null,
    );
  }

  bool get isComplete => aadhaarVerified && panVerified && bankVerified;
  
  int get completedSteps {
    int count = 0;
    if (aadhaarVerified) count++;
    if (panVerified) count++;
    if (bankVerified) count++;
    return count;
  }
}

// Aadhaar OTP Generation Response
class AadhaarOtpResponse {
  final bool otpSent;
  final String? requestId;
  final String? message;

  AadhaarOtpResponse({
    this.otpSent = false,
    this.requestId,
    this.message,
  });

  factory AadhaarOtpResponse.fromJson(Map<String, dynamic> json) {
    return AadhaarOtpResponse(
      otpSent: json['otpSent'] ?? false,
      requestId: json['requestId'],
      message: json['message'],
    );
  }
}

// Aadhaar Verify Response
class AadhaarVerifyResponse {
  final bool verified;
  final String? aadhaarNumberMasked;
  final String? name;
  final String? dob;
  final String? gender;
  final String? address;
  final String? message;

  AadhaarVerifyResponse({
    this.verified = false,
    this.aadhaarNumberMasked,
    this.name,
    this.dob,
    this.gender,
    this.address,
    this.message,
  });

  factory AadhaarVerifyResponse.fromJson(Map<String, dynamic> json) {
    return AadhaarVerifyResponse(
      verified: json['verified'] ?? false,
      aadhaarNumberMasked: json['aadhaarNumberMasked'],
      name: json['name'],
      dob: json['dob'],
      gender: json['gender'],
      address: json['address'],
      message: json['message'],
    );
  }
}

// PAN Verify Response
class PanVerifyResponse {
  final bool verified;
  final String? panNumberMasked;
  final String? name;
  final String? message;

  PanVerifyResponse({
    this.verified = false,
    this.panNumberMasked,
    this.name,
    this.message,
  });

  factory PanVerifyResponse.fromJson(Map<String, dynamic> json) {
    return PanVerifyResponse(
      verified: json['verified'] ?? false,
      panNumberMasked: json['panNumberMasked'],
      name: json['name'],
      message: json['message'],
    );
  }
}

// Bank Verify Response
class BankVerifyResponse {
  final bool verified;
  final String? accountNumberMasked;
  final String? ifscCode;
  final String? accountHolderName;
  final String? bankName;
  final String? message;

  BankVerifyResponse({
    this.verified = false,
    this.accountNumberMasked,
    this.ifscCode,
    this.accountHolderName,
    this.bankName,
    this.message,
  });

  factory BankVerifyResponse.fromJson(Map<String, dynamic> json) {
    return BankVerifyResponse(
      verified: json['verified'] ?? false,
      accountNumberMasked: json['accountNumberMasked'],
      ifscCode: json['ifscCode'],
      accountHolderName: json['accountHolderName'],
      bankName: json['bankName'],
      message: json['message'],
    );
  }
}

