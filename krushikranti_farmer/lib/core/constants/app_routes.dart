import 'package:flutter/material.dart';

// --- PARTNER'S SCREENS (Auth) ---
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/language_selection_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/forgot_password_phone_screen.dart';
import '../../features/auth/screens/forgot_password_otp_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/signup_screen.dart'; // Ensure Signup is here
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/onboarding_personal_screen.dart';
import '../../features/auth/screens/onboarding_address_screen.dart';
import '../../features/auth/screens/onboarding_contact_screen.dart';
import '../../features/auth/screens/email_login_screen.dart';

// --- YOUR SCREENS (Dashboard) ---
import '../../features/dashboard/screens/main_layout_screen.dart';
import '../../features/dashboard/screens/profile_screen.dart'; // ✅ This import is now used below
import '../../features/dashboard/screens/my_details_screen.dart';
import '../../features/farm_management/screens/farm_list_screen.dart';
import '../../features/farm_management/screens/add_farm_screen.dart';
import '../../features/crop_management/screens/crop_list_screen.dart';
import '../../features/crop_management/screens/add_crop_screen.dart';
import '../../features/funds/screens/request_funds_screen.dart';
import '../../features/sell/screens/sell_screen.dart';

// Subscription Screens
import '../../features/subscription/screens/welcome_screen.dart';
import '../../features/subscription/screens/subscription_screen.dart';

// KYC Screens
import '../../features/kyc/screens/kyc_status_screen.dart';
import '../../features/kyc/screens/aadhaar_verification_screen.dart';
import '../../features/kyc/screens/pan_verification_screen.dart';
import '../../features/kyc/screens/bank_verification_screen.dart';

// Field Officer Screens
import '../../features/field_officer/screens/field_officer_dashboard_screen.dart';

// Import
// Though this is mostly used in MainLayout
import '../../features/orders/screens/order_detail_screen.dart';

class AppRoutes {
  // --- Route Names ---
  static const String splash = '/';
  static const String languageSelection = '/language';
  static const String login = '/login';
  static const String emailLogin = '/email_login';
  static const String forgotPasswordPhone = '/forgot_password_phone';
  static const String forgotPasswordOtp = '/forgot_password_otp';
  static const String resetPassword = '/reset_password';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String onboardingPersonal = '/onboarding_personal';
  static const String onboardingContact = '/onboarding_contact';
  static const String onboardingAddress = '/onboarding_address';
  static const String bankVerification = '/bank_verification';

  static const String dashboard = '/dashboard';
  static const String profile = '/profile'; // ✅ ADDED PROFILE ROUTE NAME
  static const String myDetails = '/my_details';
  static const String farmList = '/farm_list';
  static const String addFarm = '/add_farm';
  static const String cropList = '/crop_list';
  static const String addCrop = '/add_crop';
  static const String requestFunds = '/request_funds';
  static const String sell = '/sell';
  static const String orderDetail = '/order_detail';
  
  // Subscription routes
  static const String welcome = '/welcome';
  static const String subscription = '/subscription';
  
  // KYC routes
  static const String kycStatus = '/kyc-status';
  static const String aadhaarVerification = '/aadhaar-verification';
  static const String panVerification = '/pan-verification';
  static const String kycBankVerification = '/kyc-bank-verification';

  // Field Officer routes
  static const String fieldOfficerDashboard = '/field-officer-dashboard';

  // --- Route Map ---
  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    languageSelection: (context) => const LanguageSelectionScreen(),
    login: (context) => const LoginScreen(),
    emailLogin: (context) => const EmailLoginScreen(),
    forgotPasswordPhone: (context) => const ForgotPasswordPhoneScreen(),
    forgotPasswordOtp: (context) => const ForgotPasswordOtpScreen(),
    resetPassword: (context) => const ResetPasswordScreen(),
    signup: (context) => const SignUpScreen(),
    otp: (context) => const OtpScreen(),
    onboardingPersonal: (context) => const OnboardingPersonalScreen(),
    onboardingContact: (context) => const OnboardingContactScreen(),
    onboardingAddress: (context) => const OnboardingAddressScreen(),

    dashboard: (context) => const MainLayoutScreen(),
    profile: (context) => const ProfileScreen(), // ✅ ADDED PROFILE WIDGET
    myDetails: (context) => const MyDetailsScreen(),
    farmList: (context) => const FarmListScreen(),
    addFarm: (context) => const AddFarmScreen(),
    cropList: (context) => const CropListScreen(),
    addCrop: (context) => const AddCropScreen(),
    requestFunds: (context) => const RequestFundsScreen(),
    sell: (context) => const SellScreen(),
    orderDetail: (context) => const OrderDetailScreen(),
    
    // Subscription routes
    welcome: (context) => const WelcomeScreen(),
    subscription: (context) => const SubscriptionScreen(),
    
    // KYC routes
    kycStatus: (context) => const KycStatusScreen(),
    aadhaarVerification: (context) => const AadhaarVerificationScreen(),
    panVerification: (context) => const PanVerificationScreen(),
    kycBankVerification: (context) => const BankVerificationScreen(),

    // Field Officer routes
    fieldOfficerDashboard: (context) => const FieldOfficerDashboardScreen(),
  };
}