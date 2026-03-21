import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/http_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_dropdown_field.dart';
import '../../../core/widgets/form_stepper.dart';
import '../../../core/widgets/section_container.dart';
import '../../../core/onboarding/onboarding_controller.dart';

class AddFarmScreen extends StatefulWidget {
  const AddFarmScreen({super.key});

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLookingUp = false;
  bool _fromOnboarding = false;

  // Controllers
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _totalAreaController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _talukaController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _surveyNumberController = TextEditingController();
  final TextEditingController _landRegController = TextEditingController();
  final TextEditingController _pattaNumberController = TextEditingController();
  final TextEditingController _estimatedValueController =
      TextEditingController();
  final TextEditingController _encumbranceRemarksController =
      TextEditingController();

  // Dropdowns
  String? _selectedFarmType;
  String? _selectedSoilType;
  String? _selectedIrrigationType;
  String? _selectedLandOwnership;
  String? _selectedEncumbranceStatus;
  String? _selectedVillage;
  List<String> _villageList = [];

  // GPS Location
  double? _farmLatitude;
  double? _farmLongitude;
  double? _farmLocationAccuracy;
  bool _isCapturingLocation = false;
  String? _locationError;

  // Enum values
  final List<String> _farmTypes = [
    'ORGANIC',
    'CONVENTIONAL',
    'MIXED',
    'VERMI_COMPOST'
  ];
  final List<String> _soilTypes = [
    'BLACK',
    'RED',
    'SANDY',
    'LOAMY',
    'CLAY',
    'MIXED'
  ];
  final List<String> _irrigationTypes = [
    'DRIP',
    'SPRINKLER',
    'RAINFED',
    'CANAL',
    'BORE_WELL',
    'OPEN_WELL',
    'MIXED'
  ];
  final List<String> _landOwnershipTypes = [
    'OWNED',
    'LEASED',
    'SHARED',
    'GOVERNMENT_ALLOTTED'
  ];
  final List<String> _encumbranceStatuses = [
    'NOT_VERIFIED',
    'FREE',
    'ENCUMBERED',
    'PARTIALLY_ENCUMBERED'
  ];

  @override
  void dispose() {
    _farmNameController.dispose();
    _totalAreaController.dispose();
    _pincodeController.dispose();
    _talukaController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _surveyNumberController.dispose();
    _landRegController.dispose();
    _pattaNumberController.dispose();
    _estimatedValueController.dispose();
    _encumbranceRemarksController.dispose();
    super.dispose();
  }

  Future<void> _lookupAddress() async {
    final l10n = AppLocalizations.of(context)!;
    final pincode = _pincodeController.text.trim();

    if (pincode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validPincode),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLookingUp = true;
    });

    try {
      final response = await HttpService.get(
          "farmer/profile/address/lookup?pincode=$pincode");
      final data = response['data'] ?? {};

      if (mounted && data.isNotEmpty) {
        setState(() {
          _districtController.text = data['district'] ?? "";
          _talukaController.text = data['taluka'] ?? "";
          _stateController.text = data['state'] ?? "";
          _villageList = List<String>.from(data['villages'] ?? []);
          _selectedVillage = null;
          _isLookingUp = false;
        });
      } else {
        throw Exception(l10n.noAddressFound);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLookingUp = false;
        });

        // Show a more user‑friendly and attractive error message
        final rawError = e.toString().replaceFirst("Exception: ", "");
        String friendlyMessage;

        if (rawError.toLowerCase().contains('pincode not found')) {
          friendlyMessage =
              "We couldn't find this pincode. Please check the 6‑digit pincode and try again.";
        } else if (rawError.toLowerCase().contains('no address found')) {
          friendlyMessage = l10n.noAddressFound;
        } else {
          friendlyMessage =
              "Something went wrong while fetching address details. Please try again.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red.shade600,
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    friendlyMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveFarm() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Farm location is mandatory: ensure GPS coordinates are captured
    if (_farmLatitude == null || _farmLongitude == null) {
      setState(() {
        _locationError = "Please capture farm location before saving the farm.";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Farm location is required. Please tap '${l10n.captureFarmLocation}'."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectVillage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLandOwnership == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectOwnership),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final requestBody = {
        'farmName': _farmNameController.text.trim(),
        if (_selectedFarmType != null) 'farmType': _selectedFarmType,
        'totalAreaAcres': double.parse(_totalAreaController.text.trim()),
        'pincode': _pincodeController.text.trim(),
        'village': _selectedVillage!,
        if (_selectedSoilType != null) 'soilType': _selectedSoilType,
        if (_selectedIrrigationType != null)
          'irrigationType': _selectedIrrigationType,
        'landOwnership': _selectedLandOwnership!,
        if (_surveyNumberController.text.trim().isNotEmpty)
          'surveyNumber': _surveyNumberController.text.trim(),
        if (_landRegController.text.trim().isNotEmpty)
          'landRegistrationNumber': _landRegController.text.trim(),
        if (_pattaNumberController.text.trim().isNotEmpty)
          'pattaNumber': _pattaNumberController.text.trim(),
        if (_estimatedValueController.text.trim().isNotEmpty)
          'estimatedLandValue':
              double.parse(_estimatedValueController.text.trim()),
        if (_selectedEncumbranceStatus != null)
          'encumbranceStatus': _selectedEncumbranceStatus,
        if (_encumbranceRemarksController.text.trim().isNotEmpty)
          'encumbranceRemarks': _encumbranceRemarksController.text.trim(),
        // GPS coordinates (optional but recommended)
        // Round to 4 decimal places to match backend validation
        if (_farmLatitude != null)
          'farmLatitude': double.parse(_farmLatitude!.toStringAsFixed(8)),
        if (_farmLongitude != null)
          'farmLongitude': double.parse(_farmLongitude!.toStringAsFixed(8)),
        if (_farmLocationAccuracy != null)
          'farmLocationAccuracy':
              double.parse(_farmLocationAccuracy!.toStringAsFixed(4)),
      };

      await HttpService.post("farmer/profile/farms", requestBody);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.farmAddedSuccess),
            backgroundColor: Colors.green,
          ),
        );

        final args = ModalRoute.of(context)?.settings.arguments;
        final bool isFromOnboardingNow = _fromOnboarding ||
            (args is Map && args['fromOnboarding'] == true);

        if (isFromOnboardingNow) {
          await context
              .read<OnboardingController>()
              .completeFarmAndGoToCrop(context);
        } else {
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getLocalizedFarmType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'ORGANIC':
        return l10n.farmTypeOrganic;
      case 'CONVENTIONAL':
        return l10n.farmTypeConventional;
      case 'MIXED':
        return l10n.farmTypeMixed;
      case 'VERMI_COMPOST':
        return l10n.farmTypeVermiCompost;
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedSoilType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'BLACK':
        return l10n.soilBlack;
      case 'RED':
        return l10n.soilRed;
      case 'SANDY':
        return l10n.soilSandy;
      case 'LOAMY':
        return l10n.soilLoamy;
      case 'CLAY':
        return l10n.soilClay;
      case 'MIXED':
        return l10n.soilMixed;
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedIrrigationType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'DRIP':
        return l10n.irrigDrip;
      case 'SPRINKLER':
        return l10n.irrigSprinkler;
      case 'RAINFED':
        return l10n.irrigRainfed;
      case 'CANAL':
        return l10n.irrigCanal;
      case 'BORE_WELL':
        return l10n.irrigBoreWell;
      case 'OPEN_WELL':
        return l10n.irrigOpenWell;
      case 'MIXED':
        return l10n.irrigMixed;
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedOwnership(String type, AppLocalizations l10n) {
    switch (type) {
      case 'OWNED':
        return l10n.ownershipOwned;
      case 'LEASED':
        return l10n.ownershipLeased;
      case 'SHARED':
        return l10n.ownershipShared;
      case 'GOVERNMENT_ALLOTTED':
        return l10n.ownershipGovtAllotted;
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedEncumbrance(String status, AppLocalizations l10n) {
    switch (status) {
      case 'NOT_VERIFIED':
        return l10n.encumNotVerified;
      case 'FREE':
        return l10n.encumFree;
      case 'ENCUMBERED':
        return l10n.encumEncumbered;
      case 'PARTIALLY_ENCUMBERED':
        return l10n.encumPartially;
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Read navigation arguments once to know if this is part of signup flow
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && !_fromOnboarding) {
      _fromOnboarding = args['fromOnboarding'] == true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.addFarm,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_fromOnboarding)
            TextButton(
              onPressed: () async {
                await context
                    .read<OnboardingController>()
                    .skipFarmAndGoToSubscription(context);
              },
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandGreen,
                AppColors.brandGreen.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const OnboardingStepProgressBarConnected(),
              const SizedBox(height: 24),

              SectionContainer(
                title: l10n.basicInformationSection,
                icon: Icons.info_outline_rounded,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _farmNameController,
                      label: "${l10n.farmName} *",
                      hint: l10n.enterFarmName,
                      prefixIcon: Icons.agriculture_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.farmNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomDropdownField<String>(
                      items: _farmTypes,
                      value: _selectedFarmType,
                      onChanged: (value) =>
                          setState(() => _selectedFarmType = value),
                      hint: l10n.selectFarmType,
                      label: l10n.farmType,
                      prefixIcon: Icons.eco_rounded,
                      itemLabelBuilder: (t) => _getLocalizedFarmType(t, l10n),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _totalAreaController,
                      label: "${l10n.totalAreaAcres} *",
                      hint: l10n.enterAreaAcres,
                      prefixIcon: Icons.square_foot_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.areaRequired;
                        }
                        if (double.tryParse(v.trim()) == null ||
                            double.parse(v.trim()) <= 0) {
                          return l10n.validArea;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              SectionContainer(
                title: l10n.locationDetailsSection,
                icon: Icons.location_on_rounded,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _pincodeController,
                            label: "${l10n.pincode} *",
                            hint: l10n.enter6DigitPincode,
                            prefixIcon: Icons.pin_rounded,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return l10n.pincodeRequired;
                              }
                              if (v.trim().length != 6) {
                                return l10n.pincodeMust6Digits;
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.length == 6) {
                                _lookupAddress();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        _isLookingUp
                            ? Container(
                                width: 50,
                                height: 50,
                                margin: const EdgeInsets.only(
                                    bottom: 2), // rough align
                                decoration: BoxDecoration(
                                  color: AppColors.brandGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                    child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.brandGreen))),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _lookupAddress,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brandGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    child: Text(l10n.lookup),
                                  ),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomDropdownField<String>(
                      items: _villageList,
                      value: _selectedVillage,
                      enabled: _villageList.isNotEmpty,
                      onChanged: _villageList.isEmpty
                          ? null
                          : (v) => setState(() => _selectedVillage = v),
                      hint: _villageList.isEmpty
                          ? l10n.enterPincodeToLoadVillages
                          : l10n.selectVillage,
                      label: "${l10n.village} *",
                      prefixIcon: Icons.location_city_rounded,
                      itemLabelBuilder: (v) => v,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _talukaController,
                      label: l10n.taluka,
                      hint: l10n.taluka,
                      prefixIcon: Icons.business_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _districtController,
                      label: l10n.district,
                      hint: l10n.district,
                      prefixIcon: Icons.map_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _stateController,
                      label: l10n.state,
                      hint: l10n.state,
                      prefixIcon: Icons.public_outlined,
                      enabled: false,
                    ),
                  ],
                ),
              ),

              SectionContainer(
                title: l10n.soilAndWaterSection,
                icon: Icons.water_drop_rounded,
                child: Column(
                  children: [
                    CustomDropdownField<String>(
                      items: _soilTypes,
                      value: _selectedSoilType,
                      onChanged: (value) =>
                          setState(() => _selectedSoilType = value),
                      hint: l10n.selectSoilType,
                      label: l10n.soilType,
                      prefixIcon: Icons.terrain_rounded,
                      itemLabelBuilder: (t) => _getLocalizedSoilType(t, l10n),
                    ),
                    const SizedBox(height: 16),
                    CustomDropdownField<String>(
                      items: _irrigationTypes,
                      value: _selectedIrrigationType,
                      onChanged: (value) =>
                          setState(() => _selectedIrrigationType = value),
                      hint: l10n.selectIrrigationType,
                      label: l10n.irrigationType,
                      prefixIcon: Icons.water_rounded,
                      itemLabelBuilder: (t) =>
                          _getLocalizedIrrigationType(t, l10n),
                    ),
                  ],
                ),
              ),

              SectionContainer(
                title: l10n.ownershipLegalInfoSection,
                icon: Icons.gavel_rounded,
                child: Column(
                  children: [
                    CustomDropdownField<String>(
                      items: _landOwnershipTypes,
                      value: _selectedLandOwnership,
                      onChanged: (value) =>
                          setState(() => _selectedLandOwnership = value),
                      hint: l10n.selectLandOwnership,
                      label: "${l10n.landOwnership} *",
                      prefixIcon: Icons.home_rounded,
                      itemLabelBuilder: (t) => _getLocalizedOwnership(t, l10n),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _surveyNumberController,
                      label: l10n.surveyNumber,
                      hint: l10n.enterSurveyNumber,
                      prefixIcon: Icons.pin_invoke_rounded,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _landRegController,
                      label: l10n.landRegNumber,
                      hint: l10n.enterLandRegNumber,
                      prefixIcon: Icons.receipt_long_rounded,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _pattaNumberController,
                      label: l10n.pattaNumber,
                      hint: l10n.enterPattaNumber,
                      prefixIcon: Icons.article_rounded,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _estimatedValueController,
                      label: l10n.estimatedLandValue,
                      hint: l10n.enterEstimatedValue,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.currency_rupee_rounded,
                    ),
                    const SizedBox(height: 16),
                    CustomDropdownField<String>(
                      items: _encumbranceStatuses,
                      value: _selectedEncumbranceStatus,
                      onChanged: (value) =>
                          setState(() => _selectedEncumbranceStatus = value),
                      hint: l10n.selectEncumbranceStatus,
                      label: l10n.encumbranceStatus,
                      prefixIcon: Icons.shield_rounded,
                      itemLabelBuilder: (t) =>
                          _getLocalizedEncumbrance(t, l10n),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _encumbranceRemarksController,
                      label: l10n.encumbranceRemarks,
                      hint: l10n.enterRemarks,
                      maxLines: 3,
                      prefixIcon: Icons.comment_rounded,
                    ),
                  ],
                ),
              ),

              // GPS Location Section
              _buildLocationSection(l10n),
              const SizedBox(height: 28),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveFarm,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    l10n.saveFarm,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Build GPS Location Section
  Widget _buildLocationSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandGreen.withOpacity(0.06),
            AppColors.brandGreen.withOpacity(0.02),
          ],
        ),
        border:
            Border.all(color: AppColors.brandGreen.withOpacity(0.15), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.my_location_rounded,
                    color: AppColors.brandGreen, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.farmLocationGPS,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandGreen,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.captureFarmLocationDesc,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),

          // Location Status
          if (_farmLatitude != null && _farmLongitude != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.brandGreen.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.brandGreen, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.locationCaptured,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${l10n.latitude}: ${_farmLatitude!.toStringAsFixed(6)}",
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${l10n.longitude}: ${_farmLongitude!.toStringAsFixed(6)}",
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                  if (_farmLocationAccuracy != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${l10n.accuracy}: ${_farmLocationAccuracy!.toStringAsFixed(1)} ${l10n.meters}",
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Error Message
          if (_locationError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationError!,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Capture Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCapturingLocation ? null : _captureFarmLocation,
              icon: _isCapturingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Icon(
                      _farmLatitude != null
                          ? Icons.refresh_rounded
                          : Icons.my_location_rounded,
                      size: 18,
                    ),
              label: Text(
                _farmLatitude != null
                    ? l10n.retakeLocation
                    : l10n.captureFarmLocation,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Capture farm GPS location
  Future<void> _captureFarmLocation() async {
    setState(() {
      _isCapturingLocation = true;
      _locationError = null;
    });

    try {
      // Get current position with high accuracy
      Position position = await LocationService.getCurrentPositionWithAccuracy(
        maxAccuracy: 20.0, // Require accuracy better than 20 meters
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      if (mounted) {
        setState(() {
          _farmLatitude = position.latitude;
          _farmLongitude = position.longitude;
          _farmLocationAccuracy = position.accuracy;
          _locationError = null;
          _isCapturingLocation = false;
        });

        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.locationCapturedSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on LocationException catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.message;
          _isCapturingLocation = false;
        });

        // Show error dialog with option to open settings
        if (e.message.contains('permanently denied') ||
            e.message.contains('disabled')) {
          _showLocationSettingsDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = "Failed to capture location: ${e.toString()}";
          _isCapturingLocation = false;
        });
      }
    }
  }

  /// Show dialog to open location settings
  void _showLocationSettingsDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.locationPermissionRequired),
        content: Text(l10n.locationPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await LocationService.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
            ),
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }
}
