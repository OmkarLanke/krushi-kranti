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

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to:'**
  String get assignedTo;

  /// No description provided for @forFarm.
  ///
  /// In en, this message translates to:
  /// **'For:'**
  String get forFarm;

  /// No description provided for @moreAssignments.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more'**
  String moreAssignments(int count);

  /// No description provided for @pincodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pincode:'**
  String get pincodeLabel;

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

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

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

  /// No description provided for @accountTab.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTab;

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

  /// No description provided for @errorCropAreaFullyUsed.
  ///
  /// In en, this message translates to:
  /// **'You tried to add {acres} acres, but your farm area is only {farmArea} acres and it\'s already fully used. Please reduce the crop area or remove existing crops to add new ones.'**
  String errorCropAreaFullyUsed(String acres, String farmArea);

  /// No description provided for @errorCropAreaAvailable.
  ///
  /// In en, this message translates to:
  /// **'You tried to add {acres} acres, but your farm area is only {farmArea} acres. Only {availableArea} acres are available. Please reduce the crop area to {availableArea} acres or less.'**
  String errorCropAreaAvailable(
      String acres, String farmArea, String availableArea);

  /// No description provided for @errorCropAreaExceed.
  ///
  /// In en, this message translates to:
  /// **'You tried to add {acres} acres, but your farm area is only {farmArea} acres. The total crop area cannot exceed the farm area. Please reduce the crop area or remove existing crops.'**
  String errorCropAreaExceed(String acres, String farmArea);

  /// No description provided for @errorCropAreaLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You tried to add {acres} acres, but this area is already used. Your crop area limit has been reached. Please reduce the area or remove existing crops to add new ones.'**
  String errorCropAreaLimitReached(String acres);

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

  /// No description provided for @completePersonalDetailsToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Complete your personal details to unlock full features'**
  String get completePersonalDetailsToUnlock;

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

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Mobile Number'**
  String get phoneHint;

  /// No description provided for @phoneFormatError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit phone number'**
  String get phoneFormatError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection and try again.'**
  String get networkError;

  /// No description provided for @incorrectPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect phone number. Please try again.'**
  String get incorrectPhoneError;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @incorrectEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email format'**
  String get incorrectEmailFormat;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidEmailOrPassword;

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

  /// No description provided for @farmRequired.
  ///
  /// In en, this message translates to:
  /// **'Farm Required'**
  String get farmRequired;

  /// No description provided for @farmRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'To add crops, you need to add a farm first. A farm is required to track your crop details.'**
  String get farmRequiredMessage;

  /// No description provided for @farmRequiredInstruction.
  ///
  /// In en, this message translates to:
  /// **'Click \'Add Farm\' below to create your first farm.'**
  String get farmRequiredInstruction;

  /// No description provided for @farmAddedCanAddCrops.
  ///
  /// In en, this message translates to:
  /// **'Farm added! You can now add crops.'**
  String get farmAddedCanAddCrops;

  /// No description provided for @farmLocationGPS.
  ///
  /// In en, this message translates to:
  /// **'Farm Location (GPS)'**
  String get farmLocationGPS;

  /// No description provided for @captureFarmLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Capture your farm\'s GPS coordinates. This helps field officers verify your farm location.'**
  String get captureFarmLocationDesc;

  /// No description provided for @captureFarmLocation.
  ///
  /// In en, this message translates to:
  /// **'Capture Farm Location'**
  String get captureFarmLocation;

  /// No description provided for @retakeLocation.
  ///
  /// In en, this message translates to:
  /// **'Retake Location'**
  String get retakeLocation;

  /// No description provided for @locationCaptured.
  ///
  /// In en, this message translates to:
  /// **'Location Captured'**
  String get locationCaptured;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @meters.
  ///
  /// In en, this message translates to:
  /// **'meters'**
  String get meters;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services and grant location permission to capture farm GPS coordinates.'**
  String get locationPermissionMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @locationCapturedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Farm location captured successfully!'**
  String get locationCapturedSuccess;

  /// No description provided for @capturedOn.
  ///
  /// In en, this message translates to:
  /// **'Captured On'**
  String get capturedOn;

  /// No description provided for @gpsCoordinates.
  ///
  /// In en, this message translates to:
  /// **'GPS Coordinates'**
  String get gpsCoordinates;

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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Krushi Kranti'**
  String get appTitle;

  /// No description provided for @completeSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetupTitle;

  /// No description provided for @progressPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String progressPercent(int value);

  /// No description provided for @setupStepCompleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get setupStepCompleteProfileTitle;

  /// No description provided for @setupStepCompleteProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your basic personal details'**
  String get setupStepCompleteProfileSubtitle;

  /// No description provided for @setupStepAddFarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Your Farm'**
  String get setupStepAddFarmTitle;

  /// No description provided for @setupStepAddFarmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Setup your farm for insights'**
  String get setupStepAddFarmSubtitle;

  /// No description provided for @setupStepSubscribeTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to Premium'**
  String get setupStepSubscribeTitle;

  /// No description provided for @setupStepSubscribeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock all exclusive features'**
  String get setupStepSubscribeSubtitle;

  /// No description provided for @continueSetup.
  ///
  /// In en, this message translates to:
  /// **'Continue Setup'**
  String get continueSetup;

  /// No description provided for @unlockWeatherInsights.
  ///
  /// In en, this message translates to:
  /// **'Unlock Weather Insights'**
  String get unlockWeatherInsights;

  /// No description provided for @unlockWeatherInsightsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your farm with GPS location to get daily forecasting and actionable insights.'**
  String get unlockWeatherInsightsDescription;

  /// No description provided for @addFarmNow.
  ///
  /// In en, this message translates to:
  /// **'Add Farm Now'**
  String get addFarmNow;

  /// No description provided for @weatherUnableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load weather'**
  String get weatherUnableToLoad;

  /// No description provided for @weatherDataNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Weather data not available'**
  String get weatherDataNotAvailable;

  /// No description provided for @weatherAddGpsToFarm.
  ///
  /// In en, this message translates to:
  /// **'Add GPS coordinates to farm'**
  String get weatherAddGpsToFarm;

  /// No description provided for @weatherAddFarmForInsights.
  ///
  /// In en, this message translates to:
  /// **'Add your farm to see weather insights'**
  String get weatherAddFarmForInsights;

  /// No description provided for @weatherCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherCardTitle;

  /// No description provided for @weatherFeelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like {temp}°C'**
  String weatherFeelsLike(String temp);

  /// No description provided for @weatherHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weatherHumidity;

  /// No description provided for @weatherWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get weatherWind;

  /// No description provided for @weatherUvIndex.
  ///
  /// In en, this message translates to:
  /// **'UV Index'**
  String get weatherUvIndex;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @forecastComingSoon.
  ///
  /// In en, this message translates to:
  /// **'7-day forecast feature coming soon!'**
  String get forecastComingSoon;

  /// No description provided for @view7DayForecast.
  ///
  /// In en, this message translates to:
  /// **'View 7-Day Forecast'**
  String get view7DayForecast;

  /// No description provided for @taskScreenComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Task Screen Coming Soon'**
  String get taskScreenComingSoon;

  /// No description provided for @sellScreenComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Sell Screen Coming Soon'**
  String get sellScreenComingSoon;

  /// No description provided for @onboardingStepCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get onboardingStepCrop;

  /// No description provided for @dateInputFormatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get dateInputFormatPlaceholder;

  /// No description provided for @financeScreenComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Finance Screen Coming Soon'**
  String get financeScreenComingSoon;

  /// No description provided for @profileSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get profileSectionServices;

  /// No description provided for @profileSectionFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get profileSectionFinancial;

  /// No description provided for @profileSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get profileSectionSupport;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @guestFarmer.
  ///
  /// In en, this message translates to:
  /// **'Guest Farmer'**
  String get guestFarmer;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No Email'**
  String get noEmail;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get languageHindi;

  /// No description provided for @languageMarathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get languageMarathi;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveChanges;

  /// No description provided for @otpResentSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP resent successfully'**
  String get otpResentSuccess;

  /// No description provided for @pleaseEnterFull6DigitOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter full 6-digit OTP'**
  String get pleaseEnterFull6DigitOtp;

  /// No description provided for @otpCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'OTP copied to clipboard: {otp}'**
  String otpCopiedToClipboard(String otp);

  /// No description provided for @errorLoadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error loading orders'**
  String get errorLoadingOrders;

  /// No description provided for @noSalesFound.
  ///
  /// In en, this message translates to:
  /// **'No sales found'**
  String get noSalesFound;

  /// No description provided for @failedToLoadDataWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data: {message}'**
  String failedToLoadDataWithDetails(String message);

  /// No description provided for @productsHeader.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsHeader;

  /// No description provided for @cropInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Crop Information'**
  String get cropInformationSection;

  /// No description provided for @cultivationDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Cultivation Details'**
  String get cultivationDetailsSection;

  /// No description provided for @basicInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformationSection;

  /// No description provided for @locationDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get locationDetailsSection;

  /// No description provided for @soilAndWaterSection.
  ///
  /// In en, this message translates to:
  /// **'Soil & Water'**
  String get soilAndWaterSection;

  /// No description provided for @ownershipLegalInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Ownership & Legal Info'**
  String get ownershipLegalInfoSection;

  /// No description provided for @emailHintExample.
  ///
  /// In en, this message translates to:
  /// **'your.email@example.com'**
  String get emailHintExample;

  /// No description provided for @assessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get assessmentTitle;

  /// No description provided for @assessmentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Assessment details will be shown here'**
  String get assessmentPlaceholder;

  /// No description provided for @requestFundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Funds'**
  String get requestFundsTitle;

  /// No description provided for @fundRequestComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Fund Request Form Coming Soon'**
  String get fundRequestComingSoon;

  /// No description provided for @fieldOfficerNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get fieldOfficerNavHome;

  /// No description provided for @fieldOfficerNavFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get fieldOfficerNavFarmer;

  /// No description provided for @fieldOfficerNavAssessment.
  ///
  /// In en, this message translates to:
  /// **'Assessment'**
  String get fieldOfficerNavAssessment;

  /// No description provided for @fieldOfficerNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get fieldOfficerNavProfile;

  /// No description provided for @searchByFarmerName.
  ///
  /// In en, this message translates to:
  /// **'Search by farmer name...'**
  String get searchByFarmerName;

  /// No description provided for @otpHintSixDigits.
  ///
  /// In en, this message translates to:
  /// **'000000'**
  String get otpHintSixDigits;

  /// No description provided for @verificationPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Photos - {farmName}'**
  String verificationPhotosTitle(String farmName);

  /// No description provided for @viewGeoTaggedPhoto.
  ///
  /// In en, this message translates to:
  /// **'View Geo Tagged Photo'**
  String get viewGeoTaggedPhoto;

  /// No description provided for @photoCaptureTimeout.
  ///
  /// In en, this message translates to:
  /// **'Photo capture timed out. Please try again.'**
  String get photoCaptureTimeout;

  /// No description provided for @photoCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture photo: {error}'**
  String photoCaptureFailed(String error);

  /// No description provided for @otpSentToFarmer.
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully to farmer. Please ask the farmer for the OTP.'**
  String get otpSentToFarmer;

  /// No description provided for @otpValidatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP validated successfully! You can now submit verification.'**
  String get otpValidatedSuccess;

  /// No description provided for @selectVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Please select verification status (Verify or Reject)'**
  String get selectVerificationStatus;

  /// No description provided for @captureGpsBeforeVerify.
  ///
  /// In en, this message translates to:
  /// **'Please capture GPS location before verifying the farm'**
  String get captureGpsBeforeVerify;

  /// No description provided for @captureGeotaggedPhotoBeforeVerify.
  ///
  /// In en, this message translates to:
  /// **'Please capture a geotagged photo of the farm before verification'**
  String get captureGeotaggedPhotoBeforeVerify;

  /// No description provided for @requestValidateOtpBeforeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Please request and validate OTP before submitting verification.'**
  String get requestValidateOtpBeforeSubmit;

  /// No description provided for @uploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get uploadingPhoto;

  /// No description provided for @photoUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded successfully!'**
  String get photoUploadedSuccess;

  /// No description provided for @authFailedRelogin.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please login again and try verifying the farm.'**
  String get authFailedRelogin;

  /// No description provided for @photoUploadFailedProceeding.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed, but proceeding with verification: {error}'**
  String photoUploadFailedProceeding(String error);

  /// No description provided for @farmVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Farm verified successfully!'**
  String get farmVerifiedSuccess;

  /// No description provided for @loadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Loading photos...'**
  String get loadingPhotos;

  /// No description provided for @noVerificationPhotosForFarm.
  ///
  /// In en, this message translates to:
  /// **'No verification photos found for this farm.'**
  String get noVerificationPhotosForFarm;

  /// No description provided for @errorLoadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Error loading photos: {error}'**
  String errorLoadingPhotos(String error);

  /// No description provided for @verificationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Verification successful'**
  String get verificationSuccessful;

  /// No description provided for @allKycCompletedTestMode.
  ///
  /// In en, this message translates to:
  /// **'All KYC verifications completed (TEST MODE)'**
  String get allKycCompletedTestMode;

  /// No description provided for @genericErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String genericErrorWithMessage(String message);

  /// No description provided for @onboardingPincodeAndVillage.
  ///
  /// In en, this message translates to:
  /// **'Please enter pincode and select village'**
  String get onboardingPincodeAndVillage;

  /// No description provided for @failedToLoadProfileWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile: {message}'**
  String failedToLoadProfileWithDetails(String message);

  /// No description provided for @myDetailsStepAddFarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your farm (Step 2)'**
  String get myDetailsStepAddFarmTitle;

  /// No description provided for @myDetailsStepAddFarmBody.
  ///
  /// In en, this message translates to:
  /// **'Add at least one farm to unlock farm-specific insights and funding options.'**
  String get myDetailsStepAddFarmBody;

  /// No description provided for @myDetailsStepAddFarmCta.
  ///
  /// In en, this message translates to:
  /// **'Go to farms'**
  String get myDetailsStepAddFarmCta;

  /// No description provided for @myDetailsStepAddCropsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your crops (Step 3)'**
  String get myDetailsStepAddCropsTitle;

  /// No description provided for @myDetailsStepAddCropsBody.
  ///
  /// In en, this message translates to:
  /// **'Add crops for your farms to start tracking growth, sales, and alerts.'**
  String get myDetailsStepAddCropsBody;

  /// No description provided for @myDetailsStepAddCropsCta.
  ///
  /// In en, this message translates to:
  /// **'Go to crops'**
  String get myDetailsStepAddCropsCta;

  /// No description provided for @homeOnboardingCompleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get homeOnboardingCompleteProfileTitle;

  /// No description provided for @homeOnboardingCompleteProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'Before using this feature, please add your basic personal details.'**
  String get homeOnboardingCompleteProfileMessage;

  /// No description provided for @homeOnboardingCompleteProfileCta.
  ///
  /// In en, this message translates to:
  /// **'Complete now'**
  String get homeOnboardingCompleteProfileCta;

  /// No description provided for @homeOnboardingAddFarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first farm'**
  String get homeOnboardingAddFarmTitle;

  /// No description provided for @homeOnboardingAddFarmMessage.
  ///
  /// In en, this message translates to:
  /// **'Add at least one farm to start using this feature for your land.'**
  String get homeOnboardingAddFarmMessage;

  /// No description provided for @homeOnboardingAddFarmCta.
  ///
  /// In en, this message translates to:
  /// **'Add farm'**
  String get homeOnboardingAddFarmCta;

  /// No description provided for @homeOnboardingAddCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Your Crop'**
  String get homeOnboardingAddCropTitle;

  /// No description provided for @homeOnboardingAddCropMessage.
  ///
  /// In en, this message translates to:
  /// **'Add at least one crop on your farm to start tracking it here.'**
  String get homeOnboardingAddCropMessage;

  /// No description provided for @homeOnboardingAddCropCta.
  ///
  /// In en, this message translates to:
  /// **'Add crop'**
  String get homeOnboardingAddCropCta;

  /// No description provided for @otpCheckNotificationSnackbar.
  ///
  /// In en, this message translates to:
  /// **'You will get the OTP. Please check it at notification'**
  String get otpCheckNotificationSnackbar;

  /// No description provided for @allFarmsVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'All Farms Verified!'**
  String get allFarmsVerifiedTitle;

  /// No description provided for @allFarmsVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! All your {farmCount} {farmWord} ({verified}/{farmCount} verified) have been successfully verified by field officers.'**
  String allFarmsVerifiedBody(int farmCount, String farmWord, int verified);

  /// No description provided for @farmWordSingular.
  ///
  /// In en, this message translates to:
  /// **'farm'**
  String get farmWordSingular;

  /// No description provided for @farmWordPlural.
  ///
  /// In en, this message translates to:
  /// **'farms'**
  String get farmWordPlural;

  /// No description provided for @fieldOfficerDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Field Officer'**
  String get fieldOfficerDefaultName;

  /// No description provided for @farmFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Farm {id}'**
  String farmFallbackName(String id);

  /// No description provided for @statusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get statusLocked;

  /// No description provided for @farmVerificationOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm Verification OTP'**
  String get farmVerificationOtpTitle;

  /// No description provided for @fieldOfficerVerifyingFarm.
  ///
  /// In en, this message translates to:
  /// **'{officer} is verifying \"{farm}\"'**
  String fieldOfficerVerifyingFarm(String officer, String farm);

  /// No description provided for @yourOtpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Your OTP Code'**
  String get yourOtpCodeLabel;

  /// No description provided for @copyOtpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy OTP'**
  String get copyOtpTooltip;

  /// No description provided for @expiresInTimer.
  ///
  /// In en, this message translates to:
  /// **'Expires in: {time}'**
  String expiresInTimer(String time);

  /// No description provided for @shareOtpWithFieldOfficer.
  ///
  /// In en, this message translates to:
  /// **'Please share this OTP with the field officer to complete verification.'**
  String get shareOtpWithFieldOfficer;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMessage;

  /// No description provided for @fieldOfficerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get fieldOfficerEmailLabel;

  /// No description provided for @fieldOfficerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get fieldOfficerPhoneLabel;

  /// No description provided for @fieldOfficerAlternateLabel.
  ///
  /// In en, this message translates to:
  /// **'Alternate Number'**
  String get fieldOfficerAlternateLabel;

  /// No description provided for @fieldOfficerDobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get fieldOfficerDobLabel;

  /// No description provided for @fieldOfficerGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get fieldOfficerGenderLabel;

  /// No description provided for @loginWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Log in with Phone'**
  String get loginWithPhone;

  /// No description provided for @reconnectWithGoodness.
  ///
  /// In en, this message translates to:
  /// **'Reconnect With Goodness'**
  String get reconnectWithGoodness;

  /// No description provided for @letsGetYouStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you started'**
  String get letsGetYouStarted;

  /// No description provided for @phoneHintYourNumber.
  ///
  /// In en, this message translates to:
  /// **'your phone number'**
  String get phoneHintYourNumber;

  /// No description provided for @otpSentToThisNumber.
  ///
  /// In en, this message translates to:
  /// **'OTP will be sent on this number'**
  String get otpSentToThisNumber;

  /// No description provided for @getOtp.
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get getOtp;

  /// No description provided for @termsAgreementLogin.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms & Conditions and Privacy & Legal Policy'**
  String get termsAgreementLogin;

  /// No description provided for @orSeparator.
  ///
  /// In en, this message translates to:
  /// **'or '**
  String get orSeparator;

  /// No description provided for @signUpCta.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpCta;

  /// No description provided for @enterOtpShort.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtpShort;

  /// No description provided for @phoneNumberNotFound.
  ///
  /// In en, this message translates to:
  /// **'Phone number not found. Please try again.'**
  String get phoneNumberNotFound;

  /// No description provided for @failedToLoadCropNamesWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load crop names: {message}'**
  String failedToLoadCropNamesWithDetails(String message);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String minutesAgo(int minutes);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @expiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredLabel;

  /// No description provided for @noNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get noNotificationsTitle;

  /// No description provided for @noOtpNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'You will receive OTP notifications here'**
  String get noOtpNotificationsHint;

  /// No description provided for @loginFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailedRetry;

  /// No description provided for @otpVerificationFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'OTP verification failed. Please try again.'**
  String get otpVerificationFailedRetry;

  /// No description provided for @noPhotosAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Photos Available'**
  String get noPhotosAvailable;

  /// No description provided for @verificationPhotosHeader.
  ///
  /// In en, this message translates to:
  /// **'Verification Photos'**
  String get verificationPhotosHeader;

  /// No description provided for @contactInformationHeader.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformationHeader;

  /// No description provided for @locationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSectionTitle;

  /// No description provided for @farmersScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmers'**
  String get farmersScreenTitle;

  /// No description provided for @verifyFarmAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Farm'**
  String get verifyFarmAppBarTitle;

  /// No description provided for @farmerLabelDefault.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmerLabelDefault;

  /// No description provided for @farmsToVerifySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Farms to Verify'**
  String get farmsToVerifySectionTitle;

  /// No description provided for @noFarmsInAssignment.
  ///
  /// In en, this message translates to:
  /// **'No farms found in this assignment'**
  String get noFarmsInAssignment;

  /// No description provided for @locationNotAvailableShort.
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get locationNotAvailableShort;

  /// No description provided for @farmNameFallback.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farmNameFallback;

  /// No description provided for @verificationStatusVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verificationStatusVerifiedBadge;

  /// No description provided for @submitVerificationButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Verification'**
  String get submitVerificationButton;

  /// No description provided for @farmAlreadyVerifiedNotice.
  ///
  /// In en, this message translates to:
  /// **'This farm has already been verified.'**
  String get farmAlreadyVerifiedNotice;

  /// No description provided for @verificationStatusSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Status *'**
  String get verificationStatusSectionTitle;

  /// No description provided for @verifyFarmStatusOption.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyFarmStatusOption;

  /// No description provided for @feedbackNotesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback / Notes'**
  String get feedbackNotesSectionTitle;

  /// No description provided for @feedbackNotesHintVerified.
  ///
  /// In en, this message translates to:
  /// **'Add any notes or observations about the farm verification...'**
  String get feedbackNotesHintVerified;

  /// No description provided for @feedbackNotesHintRejected.
  ///
  /// In en, this message translates to:
  /// **'Add feedback about why the farm is being rejected...'**
  String get feedbackNotesHintRejected;

  /// No description provided for @locationPhotoVerificationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location & Photo Verification'**
  String get locationPhotoVerificationSectionTitle;

  /// No description provided for @gpsLocationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'GPS Location'**
  String get gpsLocationSectionTitle;

  /// No description provided for @latitudeDisplay.
  ///
  /// In en, this message translates to:
  /// **'Lat: {degrees}°'**
  String latitudeDisplay(String degrees);

  /// No description provided for @longitudeDisplay.
  ///
  /// In en, this message translates to:
  /// **'Lon: {degrees}°'**
  String longitudeDisplay(String degrees);

  /// No description provided for @accuracyDisplayMeters.
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {meters}m'**
  String accuracyDisplayMeters(String meters);

  /// No description provided for @farmPhotoGeotaggedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm Photo (Geotagged)'**
  String get farmPhotoGeotaggedSectionTitle;

  /// No description provided for @retakeFarmPhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakeFarmPhotoButton;

  /// No description provided for @captureFarmPhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Capture Farm Photo'**
  String get captureFarmPhotoButton;

  /// No description provided for @otpVerificationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerificationSectionTitle;

  /// No description provided for @requestingOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Requesting OTP...'**
  String get requestingOtpButton;

  /// No description provided for @gpsValidationRequiredButton.
  ///
  /// In en, this message translates to:
  /// **'GPS Validation Required'**
  String get gpsValidationRequiredButton;

  /// No description provided for @fieldOfficerRequestOtpCta.
  ///
  /// In en, this message translates to:
  /// **'Request OTP'**
  String get fieldOfficerRequestOtpCta;

  /// No description provided for @enterSixDigitOtpFromFarmer.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP received by the farmer:'**
  String get enterSixDigitOtpFromFarmer;

  /// No description provided for @otpExpiresInCountdown.
  ///
  /// In en, this message translates to:
  /// **'OTP expires in: {time}'**
  String otpExpiresInCountdown(String time);

  /// No description provided for @validatingOtpButton.
  ///
  /// In en, this message translates to:
  /// **'Validating...'**
  String get validatingOtpButton;

  /// No description provided for @validateOtpButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Validate OTP'**
  String get validateOtpButtonLabel;

  /// No description provided for @locationCapturedDistanceMeters.
  ///
  /// In en, this message translates to:
  /// **'Location captured! Distance from farm: {meters}m (within 100m threshold)'**
  String locationCapturedDistanceMeters(String meters);

  /// No description provided for @locationCapturedSuccessShort.
  ///
  /// In en, this message translates to:
  /// **'Location captured successfully!'**
  String get locationCapturedSuccessShort;

  /// No description provided for @geotaggedPhotoCapturedDistanceMeters.
  ///
  /// In en, this message translates to:
  /// **'Photo captured! Distance from farm: {meters}m (within 100m threshold)'**
  String geotaggedPhotoCapturedDistanceMeters(String meters);

  /// No description provided for @geotaggedPhotoCapturedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Geotagged photo captured successfully!'**
  String get geotaggedPhotoCapturedSuccess;

  /// No description provided for @gpsValidationFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'GPS validation failed'**
  String get gpsValidationFailedFallback;

  /// No description provided for @gpsValidationFailedOtpBlocked.
  ///
  /// In en, this message translates to:
  /// **'GPS validation failed. OTP request will be blocked.'**
  String get gpsValidationFailedOtpBlocked;

  /// No description provided for @photoFileNotSavedRetry.
  ///
  /// In en, this message translates to:
  /// **'Photo file was not saved properly. Please try again.'**
  String get photoFileNotSavedRetry;

  /// No description provided for @locationCaptureFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture location: {error}'**
  String locationCaptureFailedWithError(String error);

  /// No description provided for @captureGpsBeforeOtpRequest.
  ///
  /// In en, this message translates to:
  /// **'Please capture GPS location first before requesting OTP.'**
  String get captureGpsBeforeOtpRequest;

  /// No description provided for @farmMissingGpsCoordinatesAdmin.
  ///
  /// In en, this message translates to:
  /// **'This farm does not have GPS coordinates. Please contact admin to add farm location before verification.'**
  String get farmMissingGpsCoordinatesAdmin;

  /// No description provided for @invalidFarmGpsCoordinatesAdmin.
  ///
  /// In en, this message translates to:
  /// **'Invalid farm GPS coordinates. Please contact admin.'**
  String get invalidFarmGpsCoordinatesAdmin;

  /// No description provided for @tooFarFromFarmMeters.
  ///
  /// In en, this message translates to:
  /// **'You are too far from the farm location. Distance: {meters}m (required: within 100m). Please move closer to the farm location.'**
  String tooFarFromFarmMeters(String meters);

  /// No description provided for @invalidOtpPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please try again.'**
  String get invalidOtpPleaseTryAgain;

  /// No description provided for @pincodeRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Pincode: {code}'**
  String pincodeRowLabel(String code);

  /// No description provided for @pleaseEnterValidSixDigitOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit OTP'**
  String get pleaseEnterValidSixDigitOtp;

  /// No description provided for @verificationFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'{message}'**
  String verificationFailureMessage(String message);

  /// No description provided for @authOtpAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get authOtpAppBarTitle;

  /// No description provided for @authOtpHeadline.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get authOtpHeadline;

  /// No description provided for @authOtpDescription.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to your phone.'**
  String get authOtpDescription;

  /// No description provided for @authOtpSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit code'**
  String get authOtpSubmit;

  /// No description provided for @authOtpResendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String authOtpResendCountdown(int seconds);

  /// No description provided for @authOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authOtpResend;

  /// No description provided for @signupHey.
  ///
  /// In en, this message translates to:
  /// **'Hey,'**
  String get signupHey;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up now'**
  String get signupTitle;

  /// No description provided for @signupUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get signupUsernameLabel;

  /// No description provided for @signupUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get signupUsernameHint;

  /// No description provided for @signupEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signupEmailLabel;

  /// No description provided for @signupEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get signupEmailHint;

  /// No description provided for @signupPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signupPasswordLabel;

  /// No description provided for @signupPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get signupPasswordHint;

  /// No description provided for @signupPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters with upper & lower case, a number, and a symbol.'**
  String get signupPasswordHelper;

  /// No description provided for @signupPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get signupPhoneLabel;

  /// No description provided for @signupPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit mobile number'**
  String get signupPhoneHint;

  /// No description provided for @signupGetCode.
  ///
  /// In en, this message translates to:
  /// **'Get verification code'**
  String get signupGetCode;

  /// No description provided for @signupErrorUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters'**
  String get signupErrorUsername;

  /// No description provided for @signupErrorEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get signupErrorEmail;

  /// No description provided for @signupErrorPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get signupErrorPhone;

  /// No description provided for @signupErrorPassword.
  ///
  /// In en, this message translates to:
  /// **'Use 8+ characters with A–Z, a–z, 0–9 and a symbol'**
  String get signupErrorPassword;

  /// No description provided for @signupShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get signupShowPassword;

  /// No description provided for @signupHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get signupHidePassword;

  /// No description provided for @signupErrorPhoneRegistered.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered. Try another number or log in.'**
  String get signupErrorPhoneRegistered;

  /// No description provided for @signupErrorEmailRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try another email or log in.'**
  String get signupErrorEmailRegistered;

  /// No description provided for @signupErrorUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken. Please choose another.'**
  String get signupErrorUsernameTaken;

  /// No description provided for @signupErrorCheckInfo.
  ///
  /// In en, this message translates to:
  /// **'Please check your details and try again.'**
  String get signupErrorCheckInfo;

  /// No description provided for @signupErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your internet and try again.'**
  String get signupErrorNetwork;

  /// No description provided for @signupPasswordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get signupPasswordWeak;

  /// No description provided for @signupPasswordFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get signupPasswordFair;

  /// No description provided for @signupPasswordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get signupPasswordStrong;
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
