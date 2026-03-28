import '../models/setup_state.dart';
import 'http_service.dart';
import 'storage_service.dart';
import '../../features/subscription/services/subscription_service.dart';
import '../../features/kyc/services/kyc_service.dart';

class SetupStateService {
  static Future<SetupState> load() async {
    final hasProfile = await _loadHasProfile();
    final hasFarm = await _loadHasFarm();
    final hasCrop = await _loadHasCrop();
    final hasSubscription = await _loadHasSubscription();
    final hasKyc = await _loadHasKyc();

    return SetupState(
      hasProfile: hasProfile,
      hasFarm: hasFarm,
      hasCrop: hasCrop,
      hasSubscription: hasSubscription,
      hasKyc: hasKyc,
    );
  }

  static Future<bool> _loadHasProfile() async {
    try {
      final response = await HttpService.get('farmer/profile/my-details');
      final data = response['data'] ?? response;
      if (data is! Map<String, dynamic>) return false;
      final firstName = (data['firstName'] ?? '').toString().trim();
      final lastName = (data['lastName'] ?? '').toString().trim();
      final dob = (data['dateOfBirth'] ?? '').toString().trim();
      final gender = (data['gender'] ?? '').toString().trim();
      return firstName.isNotEmpty &&
          lastName.isNotEmpty &&
          dob.isNotEmpty &&
          gender.isNotEmpty;
    } catch (_) {
      final userData = await StorageService.getUserDetails();
      final firstName = (userData['firstName'] ?? '').toString().trim();
      final lastName = (userData['lastName'] ?? '').toString().trim();
      final dob = (userData['dob'] ?? '').toString().trim();
      final gender = (userData['gender'] ?? '').toString().trim();
      return firstName.isNotEmpty &&
          lastName.isNotEmpty &&
          dob.isNotEmpty &&
          gender.isNotEmpty;
    }
  }

  static Future<bool> _loadHasFarm() async {
    try {
      final response = await HttpService.get('farmer/profile/farms');
      final list = response['data'];
      return list is List && list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _loadHasCrop() async {
    try {
      final response = await HttpService.get('farmer/profile/crops');
      final list = response['data'];
      return list is List && list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _loadHasSubscription() async {
    try {
      return await SubscriptionService.isSubscribed();
    } catch (_) {
      return StorageService.isSubscribed();
    }
  }

  static Future<bool> _loadHasKyc() async {
    try {
      final status = await KycService.getKycStatus();
      return status.isComplete;
    } catch (_) {
      return false;
    }
  }
}
