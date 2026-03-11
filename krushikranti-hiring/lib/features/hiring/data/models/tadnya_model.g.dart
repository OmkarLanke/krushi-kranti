// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tadnya_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TadnyaModel _$TadnyaModelFromJson(Map<String, dynamic> json) => TadnyaModel(
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  phoneNumber: json['phoneNumber'] as String,
  email: json['email'] as String,
  specialty: json['specialty'] as String,
  experienceYears: (json['experienceYears'] as num).toInt(),
  profilePhotoUrl: json['profilePhotoUrl'] as String?,
);

Map<String, dynamic> _$TadnyaModelToJson(TadnyaModel instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'specialty': instance.specialty,
      'experienceYears': instance.experienceYears,
      'profilePhotoUrl': instance.profilePhotoUrl,
    };
