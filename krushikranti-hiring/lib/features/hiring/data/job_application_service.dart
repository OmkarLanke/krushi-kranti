import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class JobApplicationApiService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// Submits a job application with form fields and optional resume file.
  /// Returns the response map on success, throws on failure.
  static Future<Map<String, dynamic>> submitApplication({
    required String roleType,
    required String fullName,
    String? mobile,
    String? email,
    String? dob,
    String? locationText,
    String? highestQualification,
    String? institution,
    int? yearOfCompletion,
    int? yearsExperience,
    String? relevantExperience,
    String? lastEmployerRole,
    bool? vehicleAvailable,
    bool? willingForFieldVisit,
    PlatformFile? resumeFile,
  }) async {
    final formMap = <String, dynamic>{
      'roleType': roleType,
      'fullName': fullName,
    };

    if (mobile != null && mobile.isNotEmpty) formMap['mobile'] = mobile;
    if (email != null && email.isNotEmpty) formMap['email'] = email;
    if (locationText != null && locationText.isNotEmpty) formMap['locationText'] = locationText;
    if (highestQualification != null) formMap['highestQualification'] = highestQualification;
    if (institution != null && institution.isNotEmpty) formMap['institution'] = institution;
    if (yearOfCompletion != null) formMap['yearOfCompletion'] = yearOfCompletion;
    if (yearsExperience != null) formMap['yearsExperience'] = yearsExperience;
    if (relevantExperience != null && relevantExperience.isNotEmpty) {
      formMap['relevantExperience'] = relevantExperience;
    }
    if (lastEmployerRole != null && lastEmployerRole.isNotEmpty) {
      formMap['lastEmployerRole'] = lastEmployerRole;
    }
    if (vehicleAvailable != null) formMap['vehicleAvailable'] = vehicleAvailable;
    if (willingForFieldVisit != null) formMap['willingForFieldVisit'] = willingForFieldVisit;

    // Attach resume file if provided
    if (resumeFile != null) {
      if (kIsWeb && resumeFile.bytes != null) {
        formMap['resume'] = MultipartFile.fromBytes(
          resumeFile.bytes!,
          filename: resumeFile.name,
        );
      } else if (resumeFile.path != null) {
        formMap['resume'] = await MultipartFile.fromFile(
          resumeFile.path!,
          filename: resumeFile.name,
        );
      }
    }

    // Convert DOB from DD/MM/YYYY to ISO 8601 for the backend
    if (dob != null && dob.isNotEmpty) {
      try {
        final parts = dob.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final dateTime = DateTime(year, month, day);
          formMap['dob'] = dateTime.toIso8601String();
        }
      } catch (_) {
        // Skip DOB if parsing fails
      }
    }

    final formData = FormData.fromMap(formMap);

    final response = await _dio.post(
      ApiConfig.applicationsEndpoint,
      data: formData,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return response.data is Map<String, dynamic>
          ? response.data
          : <String, dynamic>{};
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Submission failed with status ${response.statusCode}',
      );
    }
  }
}
