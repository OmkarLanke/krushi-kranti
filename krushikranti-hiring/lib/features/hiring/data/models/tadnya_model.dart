import 'package:json_annotation/json_annotation.dart';

part 'tadnya_model.g.dart'; // This will be generated later

@JsonSerializable()
class TadnyaModel {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  
  // CRITICAL: This field is required for the "Auto-Assignment" feature [cite: 46]
  // Values: "Grapes", "Tomato", "Pomegranate", "Vegetables", etc.
  final String specialty; 
  
  final int experienceYears;
  final String? profilePhotoUrl; // Optional [cite: 20]

  TadnyaModel({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.specialty,
    required this.experienceYears,
    this.profilePhotoUrl,
  });

  // Connects to the backend JSON
  factory TadnyaModel.fromJson(Map<String, dynamic> json) => _$TadnyaModelFromJson(json);
  Map<String, dynamic> toJson() => _$TadnyaModelToJson(this);
}