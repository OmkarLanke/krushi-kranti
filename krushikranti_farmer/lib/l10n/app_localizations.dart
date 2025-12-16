import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @krushiKranti.
  ///
  /// In en, this message translates to:
  /// **'KrushiKranti'**
  String get krushiKranti;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @assignMsg.
  ///
  /// In en, this message translates to:
  /// **'We\'ll assign'**
  String get assignMsg;

  /// No description provided for @soonMsg.
  ///
  /// In en, this message translates to:
  /// **'KrushiTadnya Soon !'**
  String get soonMsg;

  /// No description provided for @assignedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your assigned Krushi Tadnya'**
  String get assignedMsg;

  /// No description provided for @quickAction.
  ///
  /// In en, this message translates to:
  /// **'Quick Action'**
  String get quickAction;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @cropDetail.
  ///
  /// In en, this message translates to:
  /// **'Crop Detail'**
  String get cropDetail;

  /// No description provided for @dailySale.
  ///
  /// In en, this message translates to:
  /// **'Daily Produce Sale Entry'**
  String get dailySale;

  /// No description provided for @funding.
  ///
  /// In en, this message translates to:
  /// **'Funding Request'**
  String get funding;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account Balance & Settlement'**
  String get account;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @crops.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get crops;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myDetails.
  ///
  /// In en, this message translates to:
  /// **'My Details'**
  String get myDetails;

  /// No description provided for @farmDetails.
  ///
  /// In en, this message translates to:
  /// **'Farm Details'**
  String get farmDetails;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @myCropsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Crops'**
  String get myCropsTitle;

  /// No description provided for @addCropBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Crop'**
  String get addCropBtn;

  /// No description provided for @noCropsAdded.
  ///
  /// In en, this message translates to:
  /// **'No crops added yet'**
  String get noCropsAdded;

  /// No description provided for @addCropsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your vegetables or fruits\nto start selling.'**
  String get addCropsSubtitle;

  /// No description provided for @addNewCrop.
  ///
  /// In en, this message translates to:
  /// **'Add New Crop'**
  String get addNewCrop;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category (Veg/Fruit/Grain)'**
  String get categoryLabel;

  /// No description provided for @selectCropName.
  ///
  /// In en, this message translates to:
  /// **'Select Crop Name'**
  String get selectCropName;

  /// No description provided for @cropNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Crop Name'**
  String get cropNameLabel;

  /// No description provided for @landArea.
  ///
  /// In en, this message translates to:
  /// **'Land Area'**
  String get landArea;

  /// No description provided for @acresHint.
  ///
  /// In en, this message translates to:
  /// **'How many acres?'**
  String get acresHint;

  /// No description provided for @acresSuffix.
  ///
  /// In en, this message translates to:
  /// **'Acres'**
  String get acresSuffix;

  /// No description provided for @saveCropBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Crop Details'**
  String get saveCropBtn;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @cropAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success! Crop Added.'**
  String get cropAddedSuccess;

  /// No description provided for @catVeg.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get catVeg;

  /// No description provided for @catFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get catFruit;

  /// No description provided for @catGrain.
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get catGrain;

  /// No description provided for @cropTomato.
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get cropTomato;

  /// No description provided for @cropOnion.
  ///
  /// In en, this message translates to:
  /// **'Onion'**
  String get cropOnion;

  /// No description provided for @cropPotato.
  ///
  /// In en, this message translates to:
  /// **'Potato'**
  String get cropPotato;

  /// No description provided for @cropCauliflower.
  ///
  /// In en, this message translates to:
  /// **'Cauliflower'**
  String get cropCauliflower;

  /// No description provided for @cropBrinjal.
  ///
  /// In en, this message translates to:
  /// **'Brinjal'**
  String get cropBrinjal;

  /// No description provided for @cropOkra.
  ///
  /// In en, this message translates to:
  /// **'Okra'**
  String get cropOkra;

  /// No description provided for @cropBanana.
  ///
  /// In en, this message translates to:
  /// **'Banana'**
  String get cropBanana;

  /// No description provided for @cropMango.
  ///
  /// In en, this message translates to:
  /// **'Mango'**
  String get cropMango;

  /// No description provided for @cropPapaya.
  ///
  /// In en, this message translates to:
  /// **'Papaya'**
  String get cropPapaya;

  /// No description provided for @cropPomegranate.
  ///
  /// In en, this message translates to:
  /// **'Pomegranate'**
  String get cropPomegranate;

  /// No description provided for @cropGrapes.
  ///
  /// In en, this message translates to:
  /// **'Grapes'**
  String get cropGrapes;

  /// No description provided for @cropWheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get cropWheat;

  /// No description provided for @cropRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get cropRice;

  /// No description provided for @cropJowar.
  ///
  /// In en, this message translates to:
  /// **'Jowar'**
  String get cropJowar;

  /// No description provided for @cropBajra.
  ///
  /// In en, this message translates to:
  /// **'Bajra'**
  String get cropBajra;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter First Name'**
  String get firstNameHint;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Last Name'**
  String get lastNameHint;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dob;

  /// No description provided for @dobHint.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get dobHint;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderHint.
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get genderHint;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get continueBtn;

  /// No description provided for @errorFillAll.
  ///
  /// In en, this message translates to:
  /// **'Please fill all details'**
  String get errorFillAll;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @altPhone.
  ///
  /// In en, this message translates to:
  /// **'Alternate Mobile Number'**
  String get altPhone;

  /// No description provided for @altPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter alternate number'**
  String get altPhoneHint;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered Email'**
  String get emailLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered Mobile'**
  String get phoneLabel;

  /// No description provided for @emailLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Log in with Email & Password'**
  String get emailLoginLink;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @emailLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in with Email'**
  String get emailLoginTitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Email Address'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get passwordHint;

  /// No description provided for @loginBtn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginBtn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @passwordRecovery.
  ///
  /// In en, this message translates to:
  /// **'Password Recovery'**
  String get passwordRecovery;

  /// No description provided for @verifyNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get verifyNumber;

  /// No description provided for @verifyNumberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered mobile number to receive an OTP code.'**
  String get verifyNumberSubtitle;

  /// No description provided for @nextBtn.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextBtn;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Please Input OTP'**
  String get enterOtp;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4-digit code sent to your number'**
  String get otpSubtitle;

  /// No description provided for @submitOtp.
  ///
  /// In en, this message translates to:
  /// **'Submit OTP'**
  String get submitOtp;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmPassword;

  /// No description provided for @submitBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitBtn;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password Changed Successfully!'**
  String get passwordResetSuccess;

  /// No description provided for @sellTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Details'**
  String get sellTitle;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @cropTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Crop Type'**
  String get cropTypeLabel;

  /// No description provided for @selectCropLabel.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectCropLabel;

  /// No description provided for @selectCropHint.
  ///
  /// In en, this message translates to:
  /// **'Select your crop'**
  String get selectCropHint;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @submitVcpBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit For VCP Verification'**
  String get submitVcpBtn;

  /// No description provided for @successVcp.
  ///
  /// In en, this message translates to:
  /// **'Submitted for Verification!'**
  String get successVcp;

  /// No description provided for @catLegumes.
  ///
  /// In en, this message translates to:
  /// **'Legumes'**
  String get catLegumes;

  /// No description provided for @catMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get catMore;

  /// No description provided for @cropSpinach.
  ///
  /// In en, this message translates to:
  /// **'Spinach'**
  String get cropSpinach;

  /// No description provided for @cropLadyfinger.
  ///
  /// In en, this message translates to:
  /// **'Ladyfinger'**
  String get cropLadyfinger;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'Kg'**
  String get unitKg;

  /// No description provided for @unitTon.
  ///
  /// In en, this message translates to:
  /// **'Ton'**
  String get unitTon;

  /// No description provided for @unitQuintal.
  ///
  /// In en, this message translates to:
  /// **'Quintal'**
  String get unitQuintal;

  /// No description provided for @yourSales.
  ///
  /// In en, this message translates to:
  /// **'Your Sales'**
  String get yourSales;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @placedOn.
  ///
  /// In en, this message translates to:
  /// **'Placed on'**
  String get placedOn;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @statusReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get statusReceived;

  /// No description provided for @verifiedVcp.
  ///
  /// In en, this message translates to:
  /// **'Verified At VCP'**
  String get verifiedVcp;

  /// No description provided for @produceSaleEntry.
  ///
  /// In en, this message translates to:
  /// **'Produce Sale Entry'**
  String get produceSaleEntry;

  /// No description provided for @acceptedWeight.
  ///
  /// In en, this message translates to:
  /// **'Accepted Weight'**
  String get acceptedWeight;

  /// No description provided for @settlementStatement.
  ///
  /// In en, this message translates to:
  /// **'Settlement Statement'**
  String get settlementStatement;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @finalBreakment.
  ///
  /// In en, this message translates to:
  /// **'Final Breakment'**
  String get finalBreakment;

  /// No description provided for @loanDeduction.
  ///
  /// In en, this message translates to:
  /// **'Loan Deduction'**
  String get loanDeduction;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @settlementStatus.
  ///
  /// In en, this message translates to:
  /// **'Settlement Status'**
  String get settlementStatus;

  /// No description provided for @settlementCycle.
  ///
  /// In en, this message translates to:
  /// **'Settlement Cycle'**
  String get settlementCycle;

  /// No description provided for @weighNote.
  ///
  /// In en, this message translates to:
  /// **'Weigh may be different due to moisture & sorting'**
  String get weighNote;

  /// No description provided for @kyc.
  ///
  /// In en, this message translates to:
  /// **'KYC'**
  String get kyc;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccount;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
