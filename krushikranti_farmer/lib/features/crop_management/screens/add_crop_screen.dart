import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart'; // ✅ Relative Import
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../dashboard/models/crop_model.dart';
import '../../dashboard/services/crop_service.dart';

class AddCropScreen extends StatefulWidget {
  const AddCropScreen({super.key});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  int? selectedCropTypeId;
  String? selectedCropTypeName;
  int? selectedCropNameId;
  String? selectedCropName;
  int? selectedFarmId;
  
  final TextEditingController acresController = TextEditingController();
  final TextEditingController sowingDateController = TextEditingController();
  final TextEditingController harvestingDateController = TextEditingController();
  
  String? selectedCropStatus;
  
  final List<String> cropStatuses = ['PLANNED', 'SOWN', 'GROWING', 'HARVESTED', 'FAILED'];

  List<Map<String, dynamic>> cropTypes = [];
  List<Map<String, dynamic>> cropNames = [];
  List<Map<String, dynamic>> farms = [];
  bool _isLoading = false;
  bool _isLoadingCropNames = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Set default crop status
    selectedCropStatus = 'PLANNED';
  }

  @override
  void dispose() {
    acresController.dispose();
    sowingDateController.dispose();
    harvestingDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load crop types and farms in parallel
      final results = await Future.wait([
        CropService.getCropTypes(),
        CropService.getFarms(),
      ]);

      if (mounted) {
        setState(() {
          cropTypes = results[0] as List<Map<String, dynamic>>;
          farms = results[1] as List<Map<String, dynamic>>;
          
          // Auto-select first farm if available
          if (farms.isNotEmpty) {
            selectedFarmId = farms[0]['id'] as int;
          } else {
            // Show user-friendly error if no farms - use delayed localization
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final l10n = AppLocalizations.of(context);
                _showNoFarmsDialog(l10n);
              }
            });
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        final errorMsg = e.toString();
        String displayMsg = errorMsg.replaceFirst("Exception: ", "");
        
        // Check if it's a profile not found error
        if (errorMsg.contains("Farmer profile not found") || errorMsg.contains("complete your profile")) {
          displayMsg = "Please complete your profile first before adding crops.";
          
          // Show dialog with option to go to profile
          final l10n = AppLocalizations.of(context)!;
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.profileRequired),
              content: Text(l10n.completeProfileFirst),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Close dialog
                    Navigator.pop(context); // Close add crop screen
                    Navigator.pushNamed(context, AppRoutes.onboardingPersonal);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.completeProfile),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load data: $displayMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadCropNames(int typeId) async {
    setState(() {
      _isLoadingCropNames = true;
      selectedCropNameId = null;
      selectedCropName = null;
    });

    try {
      final names = await CropService.getCropNamesByType(typeId);
      
      if (mounted) {
        setState(() {
          cropNames = names;
          _isLoadingCropNames = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCropNames = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load crop names: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Localization Shortcut
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.addNewCrop), // ✅ Translated
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandGreen))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                  // Farm Selection (if multiple farms)
                  if (farms.length > 1) ...[
                    Text(l10n.selectFarm, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      decoration: _inputDecoration(l10n.farmLabel),
                      value: selectedFarmId,
                      items: farms.map((farm) => DropdownMenuItem(
                        value: farm['id'] as int,
                        child: Text(farm['name'] as String),
                      )).toList(),
                      onChanged: (val) => setState(() => selectedFarmId = val),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  Text(l10n.selectCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            
                  // 1. CROP TYPE DROPDOWN
                  DropdownButtonFormField<int>(
                    key: ValueKey(selectedCropTypeId ?? 'type_reset'),
                    decoration: _inputDecoration(l10n.categoryLabel),
                    value: selectedCropTypeId,
                    items: cropTypes.map((type) => DropdownMenuItem(
                      value: type['id'] as int,
                      child: Text(type['displayName'] as String),
              )).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCropTypeId = val;
                        selectedCropTypeName = cropTypes.firstWhere((t) => t['id'] == val)['displayName'] as String;
                        selectedCropNameId = null;
                        selectedCropName = null;
                        cropNames = [];
                      });
                      if (val != null) {
                        _loadCropNames(val);
                      }
                    },
            ),
            const SizedBox(height: 20),
            
                  Text(l10n.selectCropName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            
            // 2. CROP NAME DROPDOWN
                  _isLoadingCropNames
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: AppColors.brandGreen),
                        ))
                      : DropdownButtonFormField<int>(
                          key: ValueKey("${selectedCropTypeId}_${selectedCropNameId ?? 'name'}"),
                          decoration: _inputDecoration(l10n.cropNameLabel),
                          value: selectedCropNameId,
                          items: cropNames.map((name) => DropdownMenuItem(
                            value: name['id'] as int,
                            child: Text(name['displayName'] as String ?? name['name'] as String),
                    )).toList(),
                          onChanged: selectedCropTypeId == null || cropNames.isEmpty
                              ? null
                              : (val) {
                                  setState(() {
                                    selectedCropNameId = val;
                                    if (val != null) {
                                      final selected = cropNames.firstWhere((n) => n['id'] == val);
                                      selectedCropName = selected['displayName'] as String? ?? selected['name'] as String;
                                    }
                                  });
                                },
            ),
            const SizedBox(height: 20),

            // 3. ACRES INPUT
                  Text(l10n.landArea, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: acresController,
              keyboardType: TextInputType.number,
                    decoration: _inputDecoration(l10n.acresHint).copyWith(suffixText: l10n.acresSuffix),
            ),
            const SizedBox(height: 20),

            // 4. SOWING DATE
            Text(l10n.sowingDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context, sowingDateController, l10n.sowingDate),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: sowingDateController,
                  decoration: _inputDecoration(l10n.selectSowingDate).copyWith(
                    suffixIcon: const Icon(Icons.calendar_today, color: AppColors.brandGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. EXPECTED HARVESTING DATE
            Text(l10n.harvestingDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context, harvestingDateController, l10n.harvestingDate),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: harvestingDateController,
                  decoration: _inputDecoration(l10n.selectHarvestingDate).copyWith(
                    suffixIcon: const Icon(Icons.calendar_today, color: AppColors.brandGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. CROP STATUS
            Text(l10n.cropStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration(l10n.selectCropStatus),
              value: selectedCropStatus,
              items: cropStatuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getLocalizedStatus(status, l10n)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => selectedCropStatus = val);
              },
            ),

            const SizedBox(height: 40),

            // 4. SAVE BUTTON
            SizedBox(
              height: 50,
              child: ElevatedButton(
                      onPressed: (farms.isEmpty || _isLoading) ? null : () => _saveCrop(l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
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
                          : Text(l10n.saveCropBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, String fieldName) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  String? _formatDateForAPI(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      // Convert DD/MM/YYYY to YYYY-MM-DD
      final parts = dateStr.split("/");
      if (parts.length == 3) {
        return "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  // Helper to get localized crop status
  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status.toUpperCase()) {
      case 'PLANNED':
        return l10n.statusPlanned;
      case 'SOWN':
        return l10n.statusSown;
      case 'GROWING':
        return l10n.statusGrowing;
      case 'HARVESTED':
        return l10n.statusHarvested;
      case 'FAILED':
        return l10n.statusFailed;
      default:
        return status.replaceAll('_', ' ');
    }
  }

  void _showNoFarmsDialog(AppLocalizations? l10n) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext) ?? l10n;
        return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.brandGreen, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: const Text(
                "Farm Required",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "To add crops, you need to add a farm first. A farm is required to track your crop details.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.brandGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Click 'Add Farm' below to create your first farm.",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close add crop screen
            },
            child: Text(
              dialogL10n?.cancel ?? "Cancel",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close add crop screen
              Navigator.pushNamed(context, AppRoutes.addFarm).then((result) {
                // If farm was added successfully, user can try adding crop again
                if (result == true && mounted) {
                  final snackL10n = AppLocalizations.of(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Farm added! You can now add crops."),
                      backgroundColor: Colors.green,
                      action: SnackBarAction(
                        label: snackL10n?.addCropBtn ?? "Add Crop",
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.addCrop);
                        },
                      ),
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 20),
                const SizedBox(width: 8),
                Text(
                  dialogL10n?.addFarm ?? "Add Farm",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
        );
      },
    );
  }

  Future<void> _saveCrop(AppLocalizations l10n) async {
    if (selectedFarmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectFarm),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedCropTypeId == null || selectedCropNameId == null || acresController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAllFields),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final acres = double.tryParse(acresController.text);
    if (acres == null || acres <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validAcres),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await CropService.addCrop(
        farmId: selectedFarmId!,
        cropNameId: selectedCropNameId!,
        areaAcres: acres,
        sowingDate: _formatDateForAPI(sowingDateController.text),
        harvestingDate: _formatDateForAPI(harvestingDateController.text),
        cropStatus: selectedCropStatus,
      );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.cropAddedSuccess),
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
}