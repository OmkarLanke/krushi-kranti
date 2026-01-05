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

  /// No description provided for @fieldOfficerAssignMsg.
  ///
  /// In en, this message translates to:
  /// **'We\'ll assign'**
  String get fieldOfficerAssignMsg;

  /// No description provided for @fieldOfficerSoonMsg.
  ///
  /// In en, this message translates to:
  /// **'Field Officer for verification soon'**
  String get fieldOfficerSoonMsg;

  /// No description provided for @fieldOfficerAssignedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your assigned Field Officer'**
  String get fieldOfficerAssignedMsg;

  /// No description provided for @viewFieldOfficerDetails.
  ///
  /// In en, this message translates to:
  /// **'View Field Officer Details'**
  String get viewFieldOfficerDetails;

  /// No description provided for @fieldOfficerDetails.
  ///
  /// In en, this message translates to:
  /// **'Field Officer Details'**
  String get fieldOfficerDetails;

  /// No description provided for @fieldOfficerName.
  ///
  /// In en, this message translates to:
  /// **'Field Officer Name'**
  String get fieldOfficerName;

  /// No description provided for @fieldOfficerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get fieldOfficerPhone;

  /// No description provided for @fieldOfficerLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get fieldOfficerLocation;

  /// No description provided for @assignedOn.
  ///
  /// In en, this message translates to:
  /// **'Assigned On'**
  String get assignedOn;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @noFieldOfficerAssigned.
  ///
  /// In en, this message translates to:
  /// **'No field officer assigned yet'**
  String get noFieldOfficerAssigned;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

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

  /// No description provided for @cropDetail.
  ///
  /// In en, this message translates to:
  /// **'Crop Detail'**
  String get cropDetail;

  /// No description provided for @cropDetails.
  ///
  /// In en, this message translates to:
  /// **'Crop Details'**
  String get cropDetails;

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

  /// No description provided for @noCropsYet.
  ///
  /// In en, this message translates to:
  /// **'No crops added yet'**
  String get noCropsYet;

  /// No description provided for @addFirstCrop.
  ///
  /// In en, this message translates to:
  /// **'Add your first crop to get started'**
  String get addFirstCrop;

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

  /// No description provided for @sowingDate.
  ///
  /// In en, this message translates to:
  /// **'Sowing Date'**
  String get sowingDate;

  /// No description provided for @selectSowingDate.
  ///
  /// In en, this message translates to:
  /// **'Select sowing date'**
  String get selectSowingDate;

  /// No description provided for @harvestingDate.
  ///
  /// In en, this message translates to:
  /// **'Expected Harvesting Date'**
  String get harvestingDate;

  /// No description provided for @selectHarvestingDate.
  ///
  /// In en, this message translates to:
  /// **'Select expected harvesting date'**
  String get selectHarvestingDate;

  /// No description provided for @cropStatus.
  ///
  /// In en, this message translates to:
  /// **'Crop Status'**
  String get cropStatus;

  /// No description provided for @selectCropStatus.
  ///
  /// In en, this message translates to:
  /// **'Select crop status'**
  String get selectCropStatus;

  /// No description provided for @selectFarm.
  ///
  /// In en, this message translates to:
  /// **'Select Farm'**
  String get selectFarm;

  /// No description provided for @farmLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farmLabel;

  /// No description provided for @noFarmsFound.
  ///
  /// In en, this message translates to:
  /// **'No farms found. Please add a farm first.'**
  String get noFarmsFound;

  /// No description provided for @pleaseSelectFarm.
  ///
  /// In en, this message translates to:
  /// **'Please select a farm'**
  String get pleaseSelectFarm;

  /// No description provided for @validAcres.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid area in acres'**
  String get validAcres;

  /// No description provided for @profileRequired.
  ///
  /// In en, this message translates to:
  /// **'Profile Required'**
  String get profileRequired;

  /// No description provided for @completeProfileFirst.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile first before adding crops.'**
  String get completeProfileFirst;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @statusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get statusPlanned;

  /// No description provided for @statusSown.
  ///
  /// In en, this message translates to:
  /// **'Sown'**
  String get statusSown;

  /// No description provided for @statusGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get statusGrowing;

  /// No description provided for @statusHarvested.
  ///
  /// In en, this message translates to:
  /// **'Harvested'**
  String get statusHarvested;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

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

  /// No description provided for @catGrainsCereals.
  ///
  /// In en, this message translates to:
  /// **'Grains & Cereals'**
  String get catGrainsCereals;

  /// No description provided for @catPulsesLegumes.
  ///
  /// In en, this message translates to:
  /// **'Pulses & Legumes'**
  String get catPulsesLegumes;

  /// No description provided for @catSpices.
  ///
  /// In en, this message translates to:
  /// **'Spices'**
  String get catSpices;

  /// No description provided for @catOilseeds.
  ///
  /// In en, this message translates to:
  /// **'Oilseeds'**
  String get catOilseeds;

  /// No description provided for @catCashCrops.
  ///
  /// In en, this message translates to:
  /// **'Cash Crops'**
  String get catCashCrops;

  /// No description provided for @catDairyMilk.
  ///
  /// In en, this message translates to:
  /// **'Dairy & Milk Products'**
  String get catDairyMilk;

  /// No description provided for @catFlowers.
  ///
  /// In en, this message translates to:
  /// **'Flowers'**
  String get catFlowers;

  /// No description provided for @catMedicinalHerbs.
  ///
  /// In en, this message translates to:
  /// **'Medicinal & Herbs'**
  String get catMedicinalHerbs;

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

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @alternatePhone.
  ///
  /// In en, this message translates to:
  /// **'Alternate Phone'**
  String get alternatePhone;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @addressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get addressDetails;

  /// No description provided for @pincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get pincode;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @taluka.
  ///
  /// In en, this message translates to:
  /// **'Taluka'**
  String get taluka;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @profileIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Profile Incomplete'**
  String get profileIncomplete;

  /// No description provided for @completeProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile details.'**
  String get completeProfileDetails;

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

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failedToLoadProfile;

  /// No description provided for @failedToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoadData;

  /// No description provided for @failedToLoadCrops.
  ///
  /// In en, this message translates to:
  /// **'Failed to load crops'**
  String get failedToLoadCrops;

  /// No description provided for @failedToLoadCropNames.
  ///
  /// In en, this message translates to:
  /// **'Failed to load crop names'**
  String get failedToLoadCropNames;

  /// No description provided for @addFarm.
  ///
  /// In en, this message translates to:
  /// **'Add Farm'**
  String get addFarm;

  /// No description provided for @farmName.
  ///
  /// In en, this message translates to:
  /// **'Farm Name'**
  String get farmName;

  /// No description provided for @enterFarmName.
  ///
  /// In en, this message translates to:
  /// **'Enter farm name'**
  String get enterFarmName;

  /// No description provided for @farmNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Farm name is required'**
  String get farmNameRequired;

  /// No description provided for @farmType.
  ///
  /// In en, this message translates to:
  /// **'Farm Type'**
  String get farmType;

  /// No description provided for @selectFarmType.
  ///
  /// In en, this message translates to:
  /// **'Select farm type'**
  String get selectFarmType;

  /// No description provided for @totalAreaAcres.
  ///
  /// In en, this message translates to:
  /// **'Total Area (Acres)'**
  String get totalAreaAcres;

  /// No description provided for @enterAreaAcres.
  ///
  /// In en, this message translates to:
  /// **'Enter area in acres'**
  String get enterAreaAcres;

  /// No description provided for @areaRequired.
  ///
  /// In en, this message translates to:
  /// **'Total area is required'**
  String get areaRequired;

  /// No description provided for @validArea.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid area'**
  String get validArea;

  /// No description provided for @enter6DigitPincode.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit pincode'**
  String get enter6DigitPincode;

  /// No description provided for @pincodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Pincode is required'**
  String get pincodeRequired;

  /// No description provided for @pincodeMust6Digits.
  ///
  /// In en, this message translates to:
  /// **'Pincode must be 6 digits'**
  String get pincodeMust6Digits;

  /// No description provided for @validPincode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit pincode'**
  String get validPincode;

  /// No description provided for @lookup.
  ///
  /// In en, this message translates to:
  /// **'Lookup'**
  String get lookup;

  /// No description provided for @selectVillage.
  ///
  /// In en, this message translates to:
  /// **'Select village'**
  String get selectVillage;

  /// No description provided for @enterPincodeToLoadVillages.
  ///
  /// In en, this message translates to:
  /// **'Enter pincode to load villages'**
  String get enterPincodeToLoadVillages;

  /// No description provided for @pleaseSelectVillage.
  ///
  /// In en, this message translates to:
  /// **'Please select a village'**
  String get pleaseSelectVillage;

  /// No description provided for @soilType.
  ///
  /// In en, this message translates to:
  /// **'Soil Type'**
  String get soilType;

  /// No description provided for @selectSoilType.
  ///
  /// In en, this message translates to:
  /// **'Select soil type'**
  String get selectSoilType;

  /// No description provided for @irrigationType.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Type'**
  String get irrigationType;

  /// No description provided for @selectIrrigationType.
  ///
  /// In en, this message translates to:
  /// **'Select irrigation type'**
  String get selectIrrigationType;

  /// No description provided for @landOwnership.
  ///
  /// In en, this message translates to:
  /// **'Land Ownership'**
  String get landOwnership;

  /// No description provided for @selectLandOwnership.
  ///
  /// In en, this message translates to:
  /// **'Select land ownership'**
  String get selectLandOwnership;

  /// No description provided for @pleaseSelectOwnership.
  ///
  /// In en, this message translates to:
  /// **'Please select land ownership'**
  String get pleaseSelectOwnership;

  /// No description provided for @collateralInfo.
  ///
  /// In en, this message translates to:
  /// **'Collateral Information (Optional)'**
  String get collateralInfo;

  /// No description provided for @surveyNumber.
  ///
  /// In en, this message translates to:
  /// **'Survey Number'**
  String get surveyNumber;

  /// No description provided for @enterSurveyNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter survey number'**
  String get enterSurveyNumber;

  /// No description provided for @landRegNumber.
  ///
  /// In en, this message translates to:
  /// **'Land Registration Number'**
  String get landRegNumber;

  /// No description provided for @enterLandRegNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter land registration number'**
  String get enterLandRegNumber;

  /// No description provided for @pattaNumber.
  ///
  /// In en, this message translates to:
  /// **'Patta Number'**
  String get pattaNumber;

  /// No description provided for @enterPattaNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter patta number'**
  String get enterPattaNumber;

  /// No description provided for @estimatedLandValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated Land Value (INR)'**
  String get estimatedLandValue;

  /// No description provided for @enterEstimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Enter estimated value'**
  String get enterEstimatedValue;

  /// No description provided for @encumbranceStatus.
  ///
  /// In en, this message translates to:
  /// **'Encumbrance Status'**
  String get encumbranceStatus;

  /// No description provided for @selectEncumbranceStatus.
  ///
  /// In en, this message translates to:
  /// **'Select encumbrance status'**
  String get selectEncumbranceStatus;

  /// No description provided for @encumbranceRemarks.
  ///
  /// In en, this message translates to:
  /// **'Encumbrance Remarks'**
  String get encumbranceRemarks;

  /// No description provided for @enterRemarks.
  ///
  /// In en, this message translates to:
  /// **'Enter remarks (if any)'**
  String get enterRemarks;

  /// No description provided for @saveFarm.
  ///
  /// In en, this message translates to:
  /// **'Save Farm'**
  String get saveFarm;

  /// No description provided for @farmAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Farm added successfully'**
  String get farmAddedSuccess;

  /// No description provided for @noFarmsAdded.
  ///
  /// In en, this message translates to:
  /// **'No farms added yet'**
  String get noFarmsAdded;

  /// No description provided for @addYourFirstFarm.
  ///
  /// In en, this message translates to:
  /// **'Add your first farm to get started'**
  String get addYourFirstFarm;

  /// No description provided for @main.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get main;

  /// No description provided for @landDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Land Details'**
  String get landDetailsSection;

  /// No description provided for @collateralSection.
  ///
  /// In en, this message translates to:
  /// **'Collateral Information'**
  String get collateralSection;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @completeProfileBeforeFarms.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile first before adding farms.'**
  String get completeProfileBeforeFarms;

  /// No description provided for @farmTypeOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get farmTypeOrganic;

  /// No description provided for @farmTypeConventional.
  ///
  /// In en, this message translates to:
  /// **'Conventional'**
  String get farmTypeConventional;

  /// No description provided for @farmTypeMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get farmTypeMixed;

  /// No description provided for @farmTypeVermiCompost.
  ///
  /// In en, this message translates to:
  /// **'Vermi Compost'**
  String get farmTypeVermiCompost;

  /// No description provided for @soilBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get soilBlack;

  /// No description provided for @soilRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get soilRed;

  /// No description provided for @soilSandy.
  ///
  /// In en, this message translates to:
  /// **'Sandy'**
  String get soilSandy;

  /// No description provided for @soilLoamy.
  ///
  /// In en, this message translates to:
  /// **'Loamy'**
  String get soilLoamy;

  /// No description provided for @soilClay.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get soilClay;

  /// No description provided for @soilMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get soilMixed;

  /// No description provided for @irrigDrip.
  ///
  /// In en, this message translates to:
  /// **'Drip'**
  String get irrigDrip;

  /// No description provided for @irrigSprinkler.
  ///
  /// In en, this message translates to:
  /// **'Sprinkler'**
  String get irrigSprinkler;

  /// No description provided for @irrigRainfed.
  ///
  /// In en, this message translates to:
  /// **'Rainfed'**
  String get irrigRainfed;

  /// No description provided for @irrigCanal.
  ///
  /// In en, this message translates to:
  /// **'Canal'**
  String get irrigCanal;

  /// No description provided for @irrigBoreWell.
  ///
  /// In en, this message translates to:
  /// **'Bore Well'**
  String get irrigBoreWell;

  /// No description provided for @irrigOpenWell.
  ///
  /// In en, this message translates to:
  /// **'Open Well'**
  String get irrigOpenWell;

  /// No description provided for @irrigMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get irrigMixed;

  /// No description provided for @ownershipOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get ownershipOwned;

  /// No description provided for @ownershipLeased.
  ///
  /// In en, this message translates to:
  /// **'Leased'**
  String get ownershipLeased;

  /// No description provided for @ownershipShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get ownershipShared;

  /// No description provided for @ownershipGovtAllotted.
  ///
  /// In en, this message translates to:
  /// **'Government Allotted'**
  String get ownershipGovtAllotted;

  /// No description provided for @encumNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get encumNotVerified;

  /// No description provided for @encumFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get encumFree;

  /// No description provided for @encumEncumbered.
  ///
  /// In en, this message translates to:
  /// **'Encumbered'**
  String get encumEncumbered;

  /// No description provided for @encumPartially.
  ///
  /// In en, this message translates to:
  /// **'Partially Encumbered'**
  String get encumPartially;

  /// No description provided for @surveyNo.
  ///
  /// In en, this message translates to:
  /// **'Survey No'**
  String get surveyNo;

  /// No description provided for @landRegNo.
  ///
  /// In en, this message translates to:
  /// **'Land Reg No'**
  String get landRegNo;

  /// No description provided for @pattaNo.
  ///
  /// In en, this message translates to:
  /// **'Patta No'**
  String get pattaNo;

  /// No description provided for @estimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated Value'**
  String get estimatedValue;

  /// No description provided for @encumbrance.
  ///
  /// In en, this message translates to:
  /// **'Encumbrance'**
  String get encumbrance;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @ownership.
  ///
  /// In en, this message translates to:
  /// **'Ownership'**
  String get ownership;

  /// No description provided for @acres.
  ///
  /// In en, this message translates to:
  /// **'acres'**
  String get acres;

  /// No description provided for @noAddressFound.
  ///
  /// In en, this message translates to:
  /// **'No address found for this pincode'**
  String get noAddressFound;

  /// No description provided for @subscriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Required'**
  String get subscriptionRequired;

  /// No description provided for @toAccessFeature.
  ///
  /// In en, this message translates to:
  /// **'To access {feature}, please subscribe to Krushi Kranti.'**
  String toAccessFeature(String feature);

  /// No description provided for @only999Year.
  ///
  /// In en, this message translates to:
  /// **'Only ₹999/year'**
  String get only999Year;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @benefitsInclude.
  ///
  /// In en, this message translates to:
  /// **'Benefits include:'**
  String get benefitsInclude;

  /// No description provided for @weatherUpdates.
  ///
  /// In en, this message translates to:
  /// **'Weather Updates'**
  String get weatherUpdates;

  /// No description provided for @expertAdvice.
  ///
  /// In en, this message translates to:
  /// **'Expert Advice'**
  String get expertAdvice;

  /// No description provided for @marketAccess.
  ///
  /// In en, this message translates to:
  /// **'Market Access'**
  String get marketAccess;

  /// No description provided for @zeroPercentLoan.
  ///
  /// In en, this message translates to:
  /// **'0% Loan'**
  String get zeroPercentLoan;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @annualSubscription.
  ///
  /// In en, this message translates to:
  /// **'Annual subscription:'**
  String get annualSubscription;

  /// No description provided for @thisFeature.
  ///
  /// In en, this message translates to:
  /// **'this feature'**
  String get thisFeature;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @imageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get imageNotFound;

  /// No description provided for @welcomePage1Title.
  ///
  /// In en, this message translates to:
  /// **'Manage all crops and\nfree guidance'**
  String get welcomePage1Title;

  /// No description provided for @welcomePage1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Krushi Kranti, fulfill your dreams!'**
  String get welcomePage1Subtitle;

  /// No description provided for @welcomePage1Feature1.
  ///
  /// In en, this message translates to:
  /// **'Weather Reports'**
  String get welcomePage1Feature1;

  /// No description provided for @welcomePage1Feature2.
  ///
  /// In en, this message translates to:
  /// **'Crop Advice'**
  String get welcomePage1Feature2;

  /// No description provided for @welcomePage1Feature3.
  ///
  /// In en, this message translates to:
  /// **'Personal Expert'**
  String get welcomePage1Feature3;

  /// No description provided for @welcomePage2Title.
  ///
  /// In en, this message translates to:
  /// **'Buy and sell in premium\nmarket under Krushi Kranti\nFarmer Market'**
  String get welcomePage2Title;

  /// No description provided for @welcomePage2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Right time, right information'**
  String get welcomePage2Subtitle;

  /// No description provided for @welcomePage2Feature1.
  ///
  /// In en, this message translates to:
  /// **'Zero % Interest'**
  String get welcomePage2Feature1;

  /// No description provided for @welcomePage2Feature2.
  ///
  /// In en, this message translates to:
  /// **'High Information'**
  String get welcomePage2Feature2;

  /// No description provided for @welcomePage2Feature3.
  ///
  /// In en, this message translates to:
  /// **'Quick Investment'**
  String get welcomePage2Feature3;

  /// No description provided for @welcomePage3Title.
  ///
  /// In en, this message translates to:
  /// **'Land-seed selection and\nproper sowing management.'**
  String get welcomePage3Title;

  /// No description provided for @welcomePage3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Basic steps of crop management:'**
  String get welcomePage3Subtitle;

  /// No description provided for @welcomePage3Feature1.
  ///
  /// In en, this message translates to:
  /// **'Crop Health'**
  String get welcomePage3Feature1;

  /// No description provided for @welcomePage3Feature2.
  ///
  /// In en, this message translates to:
  /// **'Pesticide and Fertilizer\nInformation'**
  String get welcomePage3Feature2;

  /// No description provided for @welcomePage3Feature3.
  ///
  /// In en, this message translates to:
  /// **'Personal Advice'**
  String get welcomePage3Feature3;

  /// No description provided for @welcomePage3Footer.
  ///
  /// In en, this message translates to:
  /// **'Land selection, land cultivation'**
  String get welcomePage3Footer;

  /// No description provided for @welcomePage4Title.
  ///
  /// In en, this message translates to:
  /// **'No middleman, direct profit\nYour benefit, in your hands'**
  String get welcomePage4Title;

  /// No description provided for @welcomePage4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct and right rates for produce'**
  String get welcomePage4Subtitle;

  /// No description provided for @welcomePage4Feature1.
  ///
  /// In en, this message translates to:
  /// **'Modern Technology\nand Methods'**
  String get welcomePage4Feature1;

  /// No description provided for @welcomePage4Feature2.
  ///
  /// In en, this message translates to:
  /// **'Good Price'**
  String get welcomePage4Feature2;

  /// No description provided for @welcomePage4Feature3.
  ///
  /// In en, this message translates to:
  /// **'Higher Price'**
  String get welcomePage4Feature3;

  /// No description provided for @welcomePage4Footer.
  ///
  /// In en, this message translates to:
  /// **'Kisan Credit Card registration only ₹999/year'**
  String get welcomePage4Footer;

  /// No description provided for @welcomePage5Title.
  ///
  /// In en, this message translates to:
  /// **'End financial worries! Farm\nprofitably for just ₹999\na year!'**
  String get welcomePage5Title;

  /// No description provided for @welcomePage5Subtitle.
  ///
  /// In en, this message translates to:
  /// **''**
  String get welcomePage5Subtitle;

  /// No description provided for @welcomePage5Benefit1.
  ///
  /// In en, this message translates to:
  /// **'Get zero percent interest loan:'**
  String get welcomePage5Benefit1;

  /// No description provided for @welcomePage5Benefit2.
  ///
  /// In en, this message translates to:
  /// **'Timely weather and crop advice'**
  String get welcomePage5Benefit2;

  /// No description provided for @welcomePage5Benefit3.
  ///
  /// In en, this message translates to:
  /// **'Direct and right rates for produce'**
  String get welcomePage5Benefit3;

  /// No description provided for @welcomePage5Benefit4.
  ///
  /// In en, this message translates to:
  /// **'Weather Reports'**
  String get welcomePage5Benefit4;

  /// No description provided for @welcomePage5KycText.
  ///
  /// In en, this message translates to:
  /// **'Complete your (KYC) immediately for\nfinancial assistance and all benefits!'**
  String get welcomePage5KycText;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @subscribeNowWelcome.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNowWelcome;

  /// No description provided for @notSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Not Subscribed'**
  String get notSubscribed;

  /// No description provided for @activeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Active Subscription'**
  String get activeSubscription;

  /// No description provided for @subscribeToAccessAll.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to access all features'**
  String get subscribeToAccessAll;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days remaining'**
  String daysRemaining(int count);

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires On'**
  String get expiresOn;

  /// No description provided for @subscriptionId.
  ///
  /// In en, this message translates to:
  /// **'Subscription ID'**
  String get subscriptionId;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @subscriptionBenefits.
  ///
  /// In en, this message translates to:
  /// **'Subscription Benefits'**
  String get subscriptionBenefits;

  /// No description provided for @benefitZeroInterest.
  ///
  /// In en, this message translates to:
  /// **'Get zero percent interest loan'**
  String get benefitZeroInterest;

  /// No description provided for @benefitTimelyWeather.
  ///
  /// In en, this message translates to:
  /// **'Timely weather and crop advice'**
  String get benefitTimelyWeather;

  /// No description provided for @benefitDirectRates.
  ///
  /// In en, this message translates to:
  /// **'Direct and fair prices for produce'**
  String get benefitDirectRates;

  /// No description provided for @benefitWeatherUpdates.
  ///
  /// In en, this message translates to:
  /// **'Weather updates'**
  String get benefitWeatherUpdates;

  /// No description provided for @benefitPremiumMarket.
  ///
  /// In en, this message translates to:
  /// **'Premium Market Access'**
  String get benefitPremiumMarket;

  /// No description provided for @benefitExpertAdvice.
  ///
  /// In en, this message translates to:
  /// **'Expert advice'**
  String get benefitExpertAdvice;

  /// No description provided for @kycVerification.
  ///
  /// In en, this message translates to:
  /// **'KYC Verification'**
  String get kycVerification;

  /// No description provided for @kycStatus.
  ///
  /// In en, this message translates to:
  /// **'KYC Status'**
  String get kycStatus;

  /// No description provided for @kycPending.
  ///
  /// In en, this message translates to:
  /// **'KYC Pending'**
  String get kycPending;

  /// No description provided for @kycComplete.
  ///
  /// In en, this message translates to:
  /// **'KYC Complete'**
  String get kycComplete;

  /// No description provided for @kycCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Your KYC verification is complete!'**
  String get kycCompleteMessage;

  /// No description provided for @kycInProgress.
  ///
  /// In en, this message translates to:
  /// **'KYC In Progress'**
  String get kycInProgress;

  /// No description provided for @verificationSteps.
  ///
  /// In en, this message translates to:
  /// **'Verification Steps'**
  String get verificationSteps;

  /// No description provided for @of3StepsCompleted.
  ///
  /// In en, this message translates to:
  /// **'of 3 steps completed'**
  String get of3StepsCompleted;

  /// No description provided for @startVerification.
  ///
  /// In en, this message translates to:
  /// **'Start Verification'**
  String get startVerification;

  /// No description provided for @continueVerification.
  ///
  /// In en, this message translates to:
  /// **'Continue Verification'**
  String get continueVerification;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @aadhaarVerification.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Verification'**
  String get aadhaarVerification;

  /// No description provided for @verifyYourAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Aadhaar'**
  String get verifyYourAadhaar;

  /// No description provided for @aadhaarOtpDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your 12-digit Aadhaar number. OTP will be sent to registered mobile.'**
  String get aadhaarOtpDescription;

  /// No description provided for @aadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get aadhaarNumber;

  /// No description provided for @enterAadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter 12-digit Aadhaar number'**
  String get enterAadhaarNumber;

  /// No description provided for @pleaseEnterAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Please enter Aadhaar number'**
  String get pleaseEnterAadhaar;

  /// No description provided for @aadhaarMustBe12Digits.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number must be 12 digits'**
  String get aadhaarMustBe12Digits;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @otpSentToMobile.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to your Aadhaar registered mobile number'**
  String get otpSentToMobile;

  /// No description provided for @enter6DigitOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP'**
  String get enter6DigitOtp;

  /// No description provided for @didntReceiveOtp.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive OTP?'**
  String get didntReceiveOtp;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in'**
  String get resendIn;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @changeAadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Aadhaar Number'**
  String get changeAadhaarNumber;

  /// No description provided for @aadhaarVerified.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Verified!'**
  String get aadhaarVerified;

  /// No description provided for @continueToPan.
  ///
  /// In en, this message translates to:
  /// **'Continue to PAN'**
  String get continueToPan;

  /// No description provided for @verifyAadhaarDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify with Aadhaar OTP'**
  String get verifyAadhaarDesc;

  /// No description provided for @panVerification.
  ///
  /// In en, this message translates to:
  /// **'PAN Verification'**
  String get panVerification;

  /// No description provided for @verifyYourPan.
  ///
  /// In en, this message translates to:
  /// **'Verify Your PAN'**
  String get verifyYourPan;

  /// No description provided for @panVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your 10-character PAN number for verification'**
  String get panVerificationDesc;

  /// No description provided for @panNumber.
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get panNumber;

  /// No description provided for @enterPanNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter PAN number (e.g., ABCDE1234F)'**
  String get enterPanNumber;

  /// No description provided for @pleaseEnterPan.
  ///
  /// In en, this message translates to:
  /// **'Please enter PAN number'**
  String get pleaseEnterPan;

  /// No description provided for @invalidPanFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid PAN format. Use XXXXX1234X'**
  String get invalidPanFormat;

  /// No description provided for @panFormatHint.
  ///
  /// In en, this message translates to:
  /// **'PAN Format: 5 letters + 4 digits + 1 letter (e.g., ABCDE1234F)'**
  String get panFormatHint;

  /// No description provided for @verifyPan.
  ///
  /// In en, this message translates to:
  /// **'Verify PAN'**
  String get verifyPan;

  /// No description provided for @panVerified.
  ///
  /// In en, this message translates to:
  /// **'PAN Verified!'**
  String get panVerified;

  /// No description provided for @continueToBank.
  ///
  /// In en, this message translates to:
  /// **'Continue to Bank'**
  String get continueToBank;

  /// No description provided for @verifyPanDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify your PAN card'**
  String get verifyPanDesc;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @of3.
  ///
  /// In en, this message translates to:
  /// **'of 3'**
  String get of3;

  /// No description provided for @bankVerification.
  ///
  /// In en, this message translates to:
  /// **'Bank Verification'**
  String get bankVerification;

  /// No description provided for @verifyYourBank.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Bank Account'**
  String get verifyYourBank;

  /// No description provided for @bankVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your bank account details for verification'**
  String get bankVerificationDesc;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @enterAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter account number'**
  String get enterAccountNumber;

  /// No description provided for @pleaseEnterAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter account number'**
  String get pleaseEnterAccountNumber;

  /// No description provided for @accountNumberLength.
  ///
  /// In en, this message translates to:
  /// **'Account number must be 9-18 digits'**
  String get accountNumberLength;

  /// No description provided for @confirmAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Confirm Account Number'**
  String get confirmAccountNumber;

  /// No description provided for @reEnterAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Re-enter account number'**
  String get reEnterAccountNumber;

  /// No description provided for @pleaseConfirmAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Please confirm account number'**
  String get pleaseConfirmAccountNumber;

  /// No description provided for @accountNumbersDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Account numbers do not match'**
  String get accountNumbersDoNotMatch;

  /// No description provided for @ifscCode.
  ///
  /// In en, this message translates to:
  /// **'IFSC Code'**
  String get ifscCode;

  /// No description provided for @enterIfscCode.
  ///
  /// In en, this message translates to:
  /// **'Enter IFSC code'**
  String get enterIfscCode;

  /// No description provided for @pleaseEnterIfsc.
  ///
  /// In en, this message translates to:
  /// **'Please enter IFSC code'**
  String get pleaseEnterIfsc;

  /// No description provided for @invalidIfscFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid IFSC format. Use XXXX0XXXXXX'**
  String get invalidIfscFormat;

  /// No description provided for @ifscFormatHint.
  ///
  /// In en, this message translates to:
  /// **'IFSC Format: 4 letters + 0 + 6 alphanumeric (e.g., SBIN0001234)'**
  String get ifscFormatHint;

  /// No description provided for @verifyBank.
  ///
  /// In en, this message translates to:
  /// **'Verify Bank Account'**
  String get verifyBank;

  /// No description provided for @bankVerified.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Verified!'**
  String get bankVerified;

  /// No description provided for @verifyBankDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify your bank account'**
  String get verifyBankDesc;

  /// No description provided for @finalStep.
  ///
  /// In en, this message translates to:
  /// **'Final Step'**
  String get finalStep;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yourKycDetails.
  ///
  /// In en, this message translates to:
  /// **'Your KYC Details'**
  String get yourKycDetails;

  /// No description provided for @aadhaarDetails.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Details'**
  String get aadhaarDetails;

  /// No description provided for @panDetails.
  ///
  /// In en, this message translates to:
  /// **'PAN Details'**
  String get panDetails;

  /// No description provided for @bankDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank Details'**
  String get bankDetails;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @aadhaarMasked.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar (masked)'**
  String get aadhaarMasked;

  /// No description provided for @panMasked.
  ///
  /// In en, this message translates to:
  /// **'PAN (masked)'**
  String get panMasked;

  /// No description provided for @accountMasked.
  ///
  /// In en, this message translates to:
  /// **'Account (masked)'**
  String get accountMasked;

  /// No description provided for @accountHolder.
  ///
  /// In en, this message translates to:
  /// **'Account Holder'**
  String get accountHolder;

  /// No description provided for @bankNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankNameLabel;

  /// No description provided for @verifiedOn.
  ///
  /// In en, this message translates to:
  /// **'Verified on'**
  String get verifiedOn;

  /// No description provided for @aadhaarAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar already verified'**
  String get aadhaarAlreadyVerified;

  /// No description provided for @aadhaarAlreadyVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Aadhaar is already verified. You cannot verify it again.'**
  String get aadhaarAlreadyVerifiedMessage;

  /// No description provided for @panAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'PAN already verified'**
  String get panAlreadyVerified;

  /// No description provided for @panAlreadyVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your PAN is already verified. You cannot verify it again.'**
  String get panAlreadyVerifiedMessage;

  /// No description provided for @bankAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'Bank already verified'**
  String get bankAlreadyVerified;

  /// No description provided for @bankAlreadyVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your bank account is already verified. You cannot verify it again.'**
  String get bankAlreadyVerifiedMessage;
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
