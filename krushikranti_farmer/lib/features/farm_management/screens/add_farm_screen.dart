import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/http_service.dart';
import '../../../core/services/location_service.dart';

class AddFarmScreen extends StatefulWidget {
  const AddFarmScreen({super.key});

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLookingUp = false;

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
  final TextEditingController _estimatedValueController = TextEditingController();
  final TextEditingController _encumbranceRemarksController = TextEditingController();

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
  final List<String> _farmTypes = ['ORGANIC', 'CONVENTIONAL', 'MIXED', 'VERMI_COMPOST'];
  final List<String> _soilTypes = ['BLACK', 'RED', 'SANDY', 'LOAMY', 'CLAY', 'MIXED'];
  final List<String> _irrigationTypes = ['DRIP', 'SPRINKLER', 'RAINFED', 'CANAL', 'BORE_WELL', 'OPEN_WELL', 'MIXED'];
  final List<String> _landOwnershipTypes = ['OWNED', 'LEASED', 'SHARED', 'GOVERNMENT_ALLOTTED'];
  final List<String> _encumbranceStatuses = ['NOT_VERIFIED', 'FREE', 'ENCUMBERED', 'PARTIALLY_ENCUMBERED'];

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
      final response = await HttpService.get("farmer/profile/address/lookup?pincode=$pincode");
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
        if (_selectedIrrigationType != null) 'irrigationType': _selectedIrrigationType,
        'landOwnership': _selectedLandOwnership!,
        if (_surveyNumberController.text.trim().isNotEmpty) 'surveyNumber': _surveyNumberController.text.trim(),
        if (_landRegController.text.trim().isNotEmpty) 'landRegistrationNumber': _landRegController.text.trim(),
        if (_pattaNumberController.text.trim().isNotEmpty) 'pattaNumber': _pattaNumberController.text.trim(),
        if (_estimatedValueController.text.trim().isNotEmpty) 'estimatedLandValue': double.parse(_estimatedValueController.text.trim()),
        if (_selectedEncumbranceStatus != null) 'encumbranceStatus': _selectedEncumbranceStatus,
        if (_encumbranceRemarksController.text.trim().isNotEmpty) 'encumbranceRemarks': _encumbranceRemarksController.text.trim(),
        // GPS coordinates (optional but recommended)
        // Round to 4 decimal places to match backend validation
        if (_farmLatitude != null) 'farmLatitude': double.parse(_farmLatitude!.toStringAsFixed(8)),
        if (_farmLongitude != null) 'farmLongitude': double.parse(_farmLongitude!.toStringAsFixed(8)),
        if (_farmLocationAccuracy != null) 'farmLocationAccuracy': double.parse(_farmLocationAccuracy!.toStringAsFixed(4)),
      };

      await HttpService.post("farmer/profile/farms", requestBody);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.farmAddedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
      case 'ORGANIC': return l10n.farmTypeOrganic;
      case 'CONVENTIONAL': return l10n.farmTypeConventional;
      case 'MIXED': return l10n.farmTypeMixed;
      case 'VERMI_COMPOST': return l10n.farmTypeVermiCompost;
      default: return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedSoilType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'BLACK': return l10n.soilBlack;
      case 'RED': return l10n.soilRed;
      case 'SANDY': return l10n.soilSandy;
      case 'LOAMY': return l10n.soilLoamy;
      case 'CLAY': return l10n.soilClay;
      case 'MIXED': return l10n.soilMixed;
      default: return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedIrrigationType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'DRIP': return l10n.irrigDrip;
      case 'SPRINKLER': return l10n.irrigSprinkler;
      case 'RAINFED': return l10n.irrigRainfed;
      case 'CANAL': return l10n.irrigCanal;
      case 'BORE_WELL': return l10n.irrigBoreWell;
      case 'OPEN_WELL': return l10n.irrigOpenWell;
      case 'MIXED': return l10n.irrigMixed;
      default: return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedOwnership(String type, AppLocalizations l10n) {
    switch (type) {
      case 'OWNED': return l10n.ownershipOwned;
      case 'LEASED': return l10n.ownershipLeased;
      case 'SHARED': return l10n.ownershipShared;
      case 'GOVERNMENT_ALLOTTED': return l10n.ownershipGovtAllotted;
      default: return type.replaceAll('_', ' ');
    }
  }

  String _getLocalizedEncumbrance(String status, AppLocalizations l10n) {
    switch (status) {
      case 'NOT_VERIFIED': return l10n.encumNotVerified;
      case 'FREE': return l10n.encumFree;
      case 'ENCUMBERED': return l10n.encumEncumbered;
      case 'PARTIALLY_ENCUMBERED': return l10n.encumPartially;
      default: return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
              // Farm Name
              _buildSectionHeader(Icons.agriculture_rounded, "${l10n.farmName} *"),
              const SizedBox(height: 12),
              _buildTextField(_farmNameController, l10n.enterFarmName, validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.farmNameRequired;
                return null;
              }),
              const SizedBox(height: 20),

              // Farm Type
              _buildSectionHeader(Icons.eco_rounded, l10n.farmType),
              const SizedBox(height: 12),
              _buildLocalizedDropdown(_farmTypes, _selectedFarmType, (value) {
                setState(() => _selectedFarmType = value);
              }, l10n.selectFarmType, (t) => _getLocalizedFarmType(t, l10n)),
              const SizedBox(height: 20),

              // Total Area
              _buildSectionHeader(Icons.square_foot_rounded, "${l10n.totalAreaAcres} *"),
              const SizedBox(height: 12),
              _buildTextField(_totalAreaController, l10n.enterAreaAcres, 
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.areaRequired;
                  if (double.tryParse(v.trim()) == null || double.parse(v.trim()) <= 0) {
                    return l10n.validArea;
                  }
                  return null;
                }),
              const SizedBox(height: 20),

              // Pincode
              _buildSectionHeader(Icons.pin_rounded, "${l10n.pincode} *"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_pincodeController, l10n.enter6DigitPincode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l10n.pincodeRequired;
                        if (v.trim().length != 6) return l10n.pincodeMust6Digits;
                        return null;
                      },
                      onChanged: (value) {
                        if (value.length == 6) {
                          _lookupAddress();
                        }
                      }),
                  ),
                  const SizedBox(width: 10),
                  _isLookingUp
                      ? const SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandGreen)),
                        )
                      : ElevatedButton(
                          onPressed: _lookupAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(l10n.lookup),
                        ),
                ],
              ),
              const SizedBox(height: 20),

              // Village
              _buildSectionHeader(Icons.location_city_rounded, "${l10n.village} *"),
              const SizedBox(height: 12),
              _buildVillageDropdown(l10n),
              const SizedBox(height: 20),

              // Taluka, District, State (read-only)
              _buildSectionHeader(Icons.location_on_rounded, l10n.taluka),
              const SizedBox(height: 12),
              _buildTextField(_talukaController, "", enabled: false),
              const SizedBox(height: 20),

              _buildSectionHeader(Icons.map_rounded, l10n.district),
              const SizedBox(height: 12),
              _buildTextField(_districtController, "", enabled: false),
              const SizedBox(height: 20),

              _buildSectionHeader(Icons.public_rounded, l10n.state),
              const SizedBox(height: 12),
              _buildTextField(_stateController, "", enabled: false),
              const SizedBox(height: 20),

              // Soil Type
              _buildSectionHeader(Icons.terrain_rounded, l10n.soilType),
              const SizedBox(height: 12),
              _buildLocalizedDropdown(_soilTypes, _selectedSoilType, (value) {
                setState(() => _selectedSoilType = value);
              }, l10n.selectSoilType, (t) => _getLocalizedSoilType(t, l10n)),
              const SizedBox(height: 20),

              // Irrigation Type
              _buildSectionHeader(Icons.water_drop_rounded, l10n.irrigationType),
              const SizedBox(height: 12),
              _buildLocalizedDropdown(_irrigationTypes, _selectedIrrigationType, (value) {
                setState(() => _selectedIrrigationType = value);
              }, l10n.selectIrrigationType, (t) => _getLocalizedIrrigationType(t, l10n)),
              const SizedBox(height: 20),

              // Land Ownership
              _buildSectionHeader(Icons.home_rounded, "${l10n.landOwnership} *"),
              const SizedBox(height: 12),
              _buildLocalizedDropdown(_landOwnershipTypes, _selectedLandOwnership, (value) {
                setState(() => _selectedLandOwnership = value);
              }, l10n.selectLandOwnership, (t) => _getLocalizedOwnership(t, l10n)),
              const SizedBox(height: 20),

              // Collateral Information Section
              _buildSectionHeader(Icons.description_rounded, l10n.collateralInfo),
              const SizedBox(height: 20),

              // Survey Number
              _buildLabel(l10n.surveyNumber),
              const SizedBox(height: 12),
              _buildTextField(_surveyNumberController, l10n.enterSurveyNumber),
              const SizedBox(height: 20),

              // Land Registration Number
              _buildLabel(l10n.landRegNumber),
              const SizedBox(height: 12),
              _buildTextField(_landRegController, l10n.enterLandRegNumber),
              const SizedBox(height: 20),

              // Patta Number
              _buildLabel(l10n.pattaNumber),
              const SizedBox(height: 12),
              _buildTextField(_pattaNumberController, l10n.enterPattaNumber),
              const SizedBox(height: 20),

              // Estimated Land Value
              _buildLabel(l10n.estimatedLandValue),
              const SizedBox(height: 12),
              _buildTextField(_estimatedValueController, l10n.enterEstimatedValue,
                keyboardType: TextInputType.number),
              const SizedBox(height: 20),

              // Encumbrance Status
              _buildLabel(l10n.encumbranceStatus),
              const SizedBox(height: 12),
              _buildLocalizedDropdown(_encumbranceStatuses, _selectedEncumbranceStatus, (value) {
                setState(() => _selectedEncumbranceStatus = value);
              }, l10n.selectEncumbranceStatus, (t) => _getLocalizedEncumbrance(t, l10n)),
              const SizedBox(height: 20),

              // Encumbrance Remarks
              _buildLabel(l10n.encumbranceRemarks),
              const SizedBox(height: 12),
              _buildTextField(_encumbranceRemarksController, l10n.enterRemarks,
                maxLines: 3),
              const SizedBox(height: 28),

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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.brandGreen),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: enabled ? Colors.black87 : Colors.grey.shade600,
      ),
        decoration: InputDecoration(
          hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.brandGreen, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        counterText: "",
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String? value,
    void Function(String?) onChanged,
    String hint,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.brandGreen, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade600)),
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item.replaceAll('_', ' ')),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLocalizedDropdown(
    List<String> items,
    String? value,
    void Function(String?) onChanged,
    String hint,
    String Function(String) getLocalizedText,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                getLocalizedText(item),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVillageDropdown(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _villageList.isEmpty ? Colors.grey.shade100 : Colors.white,
        border: Border.all(
          color: _villageList.isEmpty ? Colors.grey.shade300 : Colors.grey.shade200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            _villageList.isEmpty ? l10n.enterPincodeToLoadVillages : l10n.selectVillage,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          value: _selectedVillage,
          isExpanded: true,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black87,
          ),
          items: _villageList.map((v) {
            return DropdownMenuItem(
              value: v,
              child: Text(
                v,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: _villageList.isEmpty ? null : (v) {
            setState(() => _selectedVillage = v);
          },
          dropdownColor: Colors.white,
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
        border: Border.all(color: AppColors.brandGreen.withOpacity(0.15), width: 1),
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
                child: Icon(Icons.my_location_rounded, color: AppColors.brandGreen, size: 16),
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
                border: Border.all(color: AppColors.brandGreen.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.brandGreen, size: 18),
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
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${l10n.longitude}: ${_farmLongitude!.toStringAsFixed(6)}",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  if (_farmLocationAccuracy != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${l10n.accuracy}: ${_farmLocationAccuracy!.toStringAsFixed(1)} ${l10n.meters}",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
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
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationError!,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade700),
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
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Icon(
                      _farmLatitude != null ? Icons.refresh_rounded : Icons.my_location_rounded,
                      size: 18,
                    ),
              label: Text(
                _farmLatitude != null ? l10n.retakeLocation : l10n.captureFarmLocation,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        if (e.message.contains('permanently denied') || e.message.contains('disabled')) {
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


