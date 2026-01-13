import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.addNewCrop,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandGreen))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Farm Selection (if multiple farms)
            if (farms.length > 1) ...[
              _buildSectionHeader(Icons.agriculture_rounded, l10n.selectFarm),
              const SizedBox(height: 12),
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
            
            // Crop Type Section
            _buildSectionHeader(Icons.category_rounded, l10n.selectCategory),
            const SizedBox(height: 12),
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
            
            // Crop Name Section
            _buildSectionHeader(Icons.grass_rounded, l10n.selectCropName),
            const SizedBox(height: 12),
            _isLoadingCropNames
                ? Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.brandGreen),
                    ),
                  )
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

            // Land Area Section
            _buildSectionHeader(Icons.square_foot_rounded, l10n.landArea),
            const SizedBox(height: 12),
            TextFormField(
              controller: acresController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(l10n.acresHint).copyWith(suffixText: l10n.acresSuffix),
            ),
            const SizedBox(height: 20),

            // Sowing Date Section
            _buildSectionHeader(Icons.calendar_today_rounded, l10n.sowingDate),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _selectDate(context, sowingDateController, l10n.sowingDate),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: sowingDateController,
                  decoration: _inputDecoration(l10n.selectSowingDate).copyWith(
                    suffixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.brandGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Harvesting Date Section
            _buildSectionHeader(Icons.event_rounded, l10n.harvestingDate),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _selectDate(context, harvestingDateController, l10n.harvestingDate),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: harvestingDateController,
                  decoration: _inputDecoration(l10n.selectHarvestingDate).copyWith(
                    suffixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.brandGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Crop Status Section
            _buildSectionHeader(Icons.info_outline_rounded, l10n.cropStatus),
            const SizedBox(height: 12),
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

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (farms.isEmpty || _isLoading) ? null : () => _saveCrop(l10n),
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
                  l10n.saveCropBtn,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: Colors.grey.shade600,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
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

  // Helper method to generate user-friendly error messages
  String _getUserFriendlyErrorMessage(dynamic error, double? acres, AppLocalizations l10n) {
    final errorString = error.toString();
    String actualMessage = errorString;
    
    // Try to extract JSON message from error string
    try {
      // Look for JSON in the error string (format: {...})
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(errorString);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0);
        if (jsonString != null) {
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          if (jsonData.containsKey('message')) {
            actualMessage = jsonData['message'] as String;
          }
        }
      }
    } catch (e) {
      // If JSON parsing fails, use the original error string
    }
    
    final errorLower = actualMessage.toLowerCase();
    
    // Check for crop area exceed errors
    if (errorLower.contains('cannot exceed') || 
        errorLower.contains('exceed') ||
        errorLower.contains('exceeds') ||
        errorLower.contains('available area') ||
        errorLower.contains('total crop area')) {
      
      // Extract numbers from the message
      final numbers = RegExp(r'(\d+\.?\d*)').allMatches(actualMessage);
      String? totalCropArea;
      String? farmArea;
      String? availableArea;
      
      if (numbers.length >= 3) {
        totalCropArea = numbers.elementAt(0).group(0);
        farmArea = numbers.elementAt(1).group(0);
        availableArea = numbers.elementAt(2).group(0);
      } else if (numbers.length >= 2) {
        totalCropArea = numbers.elementAt(0).group(0);
        farmArea = numbers.elementAt(1).group(0);
      }
      
      final acresText = acres != null 
          ? acres == acres.toInt() 
              ? acres.toInt().toString() 
              : acres.toStringAsFixed(2)
          : 'the entered';
      
      if (farmArea != null && availableArea != null) {
        final available = double.tryParse(availableArea) ?? 0;
        if (available <= 0) {
          return l10n.errorCropAreaFullyUsed(acresText, farmArea);
        } else {
          return l10n.errorCropAreaAvailable(acresText, farmArea, availableArea);
        }
      } else if (farmArea != null) {
        return l10n.errorCropAreaExceed(acresText, farmArea);
      } else {
        return l10n.errorCropAreaLimitReached(acresText);
      }
    }
    
    // Check for other crop area limit errors
    if (errorLower.contains('limit') || 
        errorLower.contains('already used') ||
        errorLower.contains('crop limit') ||
        errorLower.contains('area limit') ||
        errorLower.contains('maximum') ||
        errorLower.contains('reached') ||
        errorLower.contains('not available') ||
        errorLower.contains('insufficient')) {
      
      final acresText = acres != null 
          ? acres == acres.toInt() 
              ? acres.toInt().toString() 
              : acres.toStringAsFixed(2)
          : 'the entered';
      
      return l10n.errorCropAreaLimitReached(acresText);
    }
    
    // Return the actual message (cleaned up)
    return actualMessage.replaceFirst("Exception: ", "").replaceFirst("Network Error: ", "").replaceFirst("Error: ", "");
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
        
        // Parse error message for user-friendly display
        final errorMessage = _getUserFriendlyErrorMessage(e, acres, l10n);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}