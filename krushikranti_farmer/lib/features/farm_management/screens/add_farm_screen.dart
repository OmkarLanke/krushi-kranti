import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/http_service.dart';

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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.red,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.addFarm,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farm Name
              _buildLabel("${l10n.farmName} *"),
              const SizedBox(height: 8),
              _buildTextField(_farmNameController, l10n.enterFarmName, validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.farmNameRequired;
                return null;
              }),
              const SizedBox(height: 20),

              // Farm Type
              _buildLabel(l10n.farmType),
              const SizedBox(height: 8),
              _buildLocalizedDropdown(_farmTypes, _selectedFarmType, (value) {
                setState(() => _selectedFarmType = value);
              }, l10n.selectFarmType, (t) => _getLocalizedFarmType(t, l10n)),
              const SizedBox(height: 20),

              // Total Area
              _buildLabel("${l10n.totalAreaAcres} *"),
              const SizedBox(height: 8),
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
              _buildLabel("${l10n.pincode} *"),
              const SizedBox(height: 8),
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
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : ElevatedButton(
                          onPressed: _lookupAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(l10n.lookup),
                        ),
                ],
              ),
              const SizedBox(height: 20),

              // Village
              _buildLabel("${l10n.village} *"),
              const SizedBox(height: 8),
              _buildVillageDropdown(l10n),
              const SizedBox(height: 20),

              // Taluka, District, State (read-only)
              _buildLabel(l10n.taluka),
              const SizedBox(height: 8),
              _buildTextField(_talukaController, "", enabled: false),
              const SizedBox(height: 20),

              _buildLabel(l10n.district),
              const SizedBox(height: 8),
              _buildTextField(_districtController, "", enabled: false),
              const SizedBox(height: 20),

              _buildLabel(l10n.state),
              const SizedBox(height: 8),
              _buildTextField(_stateController, "", enabled: false),
              const SizedBox(height: 20),

              // Soil Type
              _buildLabel(l10n.soilType),
              const SizedBox(height: 8),
              _buildLocalizedDropdown(_soilTypes, _selectedSoilType, (value) {
                setState(() => _selectedSoilType = value);
              }, l10n.selectSoilType, (t) => _getLocalizedSoilType(t, l10n)),
              const SizedBox(height: 20),

              // Irrigation Type
              _buildLabel(l10n.irrigationType),
              const SizedBox(height: 8),
              _buildLocalizedDropdown(_irrigationTypes, _selectedIrrigationType, (value) {
                setState(() => _selectedIrrigationType = value);
              }, l10n.selectIrrigationType, (t) => _getLocalizedIrrigationType(t, l10n)),
              const SizedBox(height: 20),

              // Land Ownership
              _buildLabel("${l10n.landOwnership} *"),
              const SizedBox(height: 8),
              _buildLocalizedDropdown(_landOwnershipTypes, _selectedLandOwnership, (value) {
                setState(() => _selectedLandOwnership = value);
              }, l10n.selectLandOwnership, (t) => _getLocalizedOwnership(t, l10n)),
              const SizedBox(height: 20),

              // Collateral Information Section
              Text(
                l10n.collateralInfo,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandGreen,
                ),
              ),
              const SizedBox(height: 16),

              // Survey Number
              _buildLabel(l10n.surveyNumber),
              const SizedBox(height: 8),
              _buildTextField(_surveyNumberController, l10n.enterSurveyNumber),
              const SizedBox(height: 20),

              // Land Registration Number
              _buildLabel(l10n.landRegNumber),
              const SizedBox(height: 8),
              _buildTextField(_landRegController, l10n.enterLandRegNumber),
              const SizedBox(height: 20),

              // Patta Number
              _buildLabel(l10n.pattaNumber),
              const SizedBox(height: 8),
              _buildTextField(_pattaNumberController, l10n.enterPattaNumber),
              const SizedBox(height: 20),

              // Estimated Land Value
              _buildLabel(l10n.estimatedLandValue),
              const SizedBox(height: 8),
              _buildTextField(_estimatedValueController, l10n.enterEstimatedValue,
                keyboardType: TextInputType.number),
              const SizedBox(height: 20),

              // Encumbrance Status
              _buildLabel(l10n.encumbranceStatus),
              const SizedBox(height: 8),
              _buildLocalizedDropdown(_encumbranceStatuses, _selectedEncumbranceStatus, (value) {
                setState(() => _selectedEncumbranceStatus = value);
              }, l10n.selectEncumbranceStatus, (t) => _getLocalizedEncumbrance(t, l10n)),
              const SizedBox(height: 20),

              // Encumbrance Remarks
              _buildLabel(l10n.encumbranceRemarks),
              const SizedBox(height: 8),
              _buildTextField(_encumbranceRemarksController, l10n.enterRemarks,
                maxLines: 3),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveFarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          l10n.saveFarm,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        border: Border.all(
          color: enabled ? AppColors.brandGreen : Colors.grey.shade400,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          counterText: "",
        ),
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
              child: Text(getLocalizedText(item)),
            );
          }).toList(),
          onChanged: onChanged,
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
          color: _villageList.isEmpty ? Colors.grey.shade400 : AppColors.brandGreen,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            _villageList.isEmpty ? l10n.enterPincodeToLoadVillages : l10n.selectVillage,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          value: _selectedVillage,
          isExpanded: true,
          items: _villageList.map((v) {
            return DropdownMenuItem(
              value: v,
              child: Text(v),
            );
          }).toList(),
          onChanged: _villageList.isEmpty ? null : (v) {
            setState(() => _selectedVillage = v);
          },
        ),
      ),
    );
  }
}


