class UserModel {
  final String mobileNumber; // From Login [cite: 5]
  final String firstName;    // From Step 1 [cite: 8]
  final String lastName;     // From Step 1 [cite: 8]
  final String village;      // From Step 2 [cite: 9]
  final String district;     // From Step 2 [cite: 9]
  final String? profilePicUrl;

  UserModel({
    required this.mobileNumber,
    required this.firstName,
    required this.lastName,
    required this.village,
    required this.district,
    this.profilePicUrl,
  });

  // Factory constructor to create a User from JSON (Backend response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      mobileNumber: json['mobileNumber'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      village: json['village'] ?? '',
      district: json['district'] ?? '',
      profilePicUrl: json['profilePicUrl'],
    );
  }

  // To send data back to server
  Map<String, dynamic> toJson() {
    return {
      'mobileNumber': mobileNumber,
      'firstName': firstName,
      'lastName': lastName,
      'village': village,
      'district': district,
    };
  }
}