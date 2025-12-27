import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // --- SYSTEM KEYS ---
  static const String _tokenKey = 'auth_token';
  static const String _languageKey = 'app_language';
  
  // --- USER DATA KEYS ---
  static const String _emailKey = 'user_email';
  static const String _phoneKey = 'user_phone';
  static const String _firstNameKey = 'user_first_name';
  static const String _lastNameKey = 'user_last_name';
  static const String _profilePicKey = 'user_profile_pic';
  static const String _dobKey = 'user_dob';
  static const String _genderKey = 'user_gender';
  
  // ✅ NEW KEY: Alternate Phone
  static const String _altPhoneKey = 'user_alt_phone';
  
  // --- SUBSCRIPTION KEYS ---
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _subscriptionEndDateKey = 'subscription_end_date';
  
  // --- USER ROLE KEY ---
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id'; 

  // ===========================================================================
  // 1. SAVE AUTH DATA (From Signup Screen)
  // ===========================================================================
  static Future<void> saveAuthDetails({required String email, required String phone}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_phoneKey, phone);
  }

  // ===========================================================================
  // 2. SAVE PERSONAL DATA (From Onboarding Personal Screen)
  // ===========================================================================
  static Future<void> savePersonalDetails({
    required String firstName, 
    required String lastName,
    required String dob,     
    required String gender,  
    String? profilePicPath
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_firstNameKey, firstName);
    await prefs.setString(_lastNameKey, lastName);
    await prefs.setString(_dobKey, dob);
    await prefs.setString(_genderKey, gender);
    
    if (profilePicPath != null) {
      await prefs.setString(_profilePicKey, profilePicPath);
    }
  }

  // ===========================================================================
  // 3. SAVE CONTACT DATA (From Onboarding Contact Screen)
  // ===========================================================================
  static Future<void> saveContactDetails({required String altPhone}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_altPhoneKey, altPhone);
  }

  // ===========================================================================
  // 4. GET ALL USER DATA (For Profile & Contact Screen)
  // ===========================================================================
  static Future<Map<String, String>> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "firstName": prefs.getString(_firstNameKey) ?? "Guest",
      "lastName": prefs.getString(_lastNameKey) ?? "Farmer",
      "email": prefs.getString(_emailKey) ?? "No Email",
      "phone": prefs.getString(_phoneKey) ?? "",
      "pic": prefs.getString(_profilePicKey) ?? "",
      "dob": prefs.getString(_dobKey) ?? "",
      "gender": prefs.getString(_genderKey) ?? "",
      // ✅ Return Alt Phone
      "altPhone": prefs.getString(_altPhoneKey) ?? "", 
    };
  }

  // ===========================================================================
  // 5. AUTH TOKEN MANAGEMENT
  // ===========================================================================
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ✅ CLEARS USER DATA BUT KEEPS LANGUAGE
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_firstNameKey);
    await prefs.remove(_lastNameKey);
    await prefs.remove(_profilePicKey);
    await prefs.remove(_dobKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_altPhoneKey); // ✅ Remove Alt Phone on logout
    await prefs.remove(_subscriptionStatusKey); // ✅ Remove subscription status on logout
    await prefs.remove(_subscriptionEndDateKey);
    await prefs.remove(_userRoleKey); // ✅ Remove user role on logout
    await prefs.remove(_userIdKey); // ✅ Remove user ID on logout
  }

  // ===========================================================================
  // 6. LANGUAGE PREFERENCE
  // ===========================================================================
  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  // ===========================================================================
  // 7. SUBSCRIPTION STATUS
  // ===========================================================================
  static Future<void> saveSubscriptionStatus(bool isSubscribed, {String? endDate}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subscriptionStatusKey, isSubscribed);
    if (endDate != null) {
      await prefs.setString(_subscriptionEndDateKey, endDate);
    }
  }

  static Future<bool> isSubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_subscriptionStatusKey) ?? false;
  }

  static Future<String?> getSubscriptionEndDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subscriptionEndDateKey);
  }

  static Future<void> clearSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscriptionStatusKey);
    await prefs.remove(_subscriptionEndDateKey);
  }

  // ===========================================================================
  // 8. USER ROLE MANAGEMENT
  // ===========================================================================
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<bool> isFieldOfficer() async {
    final role = await getRole();
    return role == 'FIELD_OFFICER';
  }

  static Future<bool> isFarmer() async {
    final role = await getRole();
    return role == 'FARMER';
  }
}