import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart'; // ✅ Relative Import
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_dropdown_field.dart';
import '../../../core/widgets/form_stepper.dart';
import '../../../core/widgets/section_container.dart';
import '../../../core/onboarding/onboarding_controller.dart';

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
  final TextEditingController harvestingDateController =
      TextEditingController();

  String? selectedCropStatus;

  final List<String> cropStatuses = [
    'PLANNED',
    'SOWN',
    'GROWING',
    'HARVESTED',
    'FAILED'
  ];

  List<Map<String, dynamic>> cropTypes = [];
  List<Map<String, dynamic>> cropNames = [];
  List<Map<String, dynamic>> farms = [];
  bool _isLoading = false;
  bool _isLoadingCropNames = false;
  bool _fromOnboarding = false;

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
      // Load crop types and farms in parallel.
      // Both futures return `List<Map<String, dynamic>>`, so we can keep the
      // result types strongly typed and avoid unnecessary casts.
      final List<List<Map<String, dynamic>>> results =
          await Future.wait<List<Map<String, dynamic>>>([
        CropService.getCropTypes(),
        CropService.getFarms(),
      ]);

      if (mounted) {
        setState(() {
          cropTypes = results[0];
          farms = results[1];

          // Auto-select first farm if available
          if (farms.isNotEmpty) {
            selectedFarmId = farms[0]['id'];
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
        if (errorMsg.contains("Farmer profile not found") ||
            errorMsg.contains("complete your profile")) {
          displayMsg =
              "Please complete your profile first before adding crops.";

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
            content: Text(
                'Failed to load crop names: ${e.toString().replaceFirst("Exception: ", "")}'),
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
          l10n.addNewCrop,
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  FormStepper(
                    stepStatuses: context.watch<OnboardingController>().stepStatuses,
                  ),
                  const SizedBox(height: 24),

                  SectionContainer(
                    title: "Crop Information",
                    icon: Icons.grass_rounded,
                    child: Column(
                      children: [
                        if (farms.length > 1) ...[
                          CustomDropdownField<int>(
                            value: selectedFarmId,
                            items: farms.map((f) => f['id'] as int).toList(),
                            onChanged: (val) => setState(() => selectedFarmId = val),
                            hint: l10n.selectFarm,
                            label: l10n.farmLabel,
                            prefixIcon: Icons.agriculture_rounded,
                            itemLabelBuilder: (id) =>
                                farms.firstWhere((f) => f['id'] == id)['name'] as String,
                          ),
                          const SizedBox(height: 16),
                        ],
                        CustomDropdownField<int>(
                          key: ValueKey(selectedCropTypeId ?? 'type_reset'),
                          value: selectedCropTypeId,
                          items: cropTypes.map((t) => t['id'] as int).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedCropTypeId = val;
                              if (val != null) {
                                selectedCropTypeName = cropTypes.firstWhere(
                                    (t) => t['id'] == val)['displayName'] as String;
                              }
                              selectedCropNameId = null;
                              selectedCropName = null;
                              cropNames = [];
                            });
                            if (val != null) {
                              _loadCropNames(val);
                            }
                          },
                          hint: l10n.selectCategory,
                          label: l10n.categoryLabel,
                          prefixIcon: Icons.category_rounded,
                          itemLabelBuilder: (id) => cropTypes.firstWhere(
                              (t) => t['id'] == id)['displayName'] as String,
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingCropNames)
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.brandGreen),
                            ),
                          )
                        else
                          CustomDropdownField<int>(
                            key: ValueKey(
                                "${selectedCropTypeId}_${selectedCropNameId ?? 'name'}"),
                            value: selectedCropNameId,
                            items: cropNames.map((n) => n['id'] as int).toList(),
                            onChanged: selectedCropTypeId == null || cropNames.isEmpty
                                ? null
                                : (val) {
                                    setState(() {
                                      selectedCropNameId = val;
                                      if (val != null) {
                                        final selected = cropNames
                                            .firstWhere((n) => n['id'] == val);
                                        selectedCropName =
                                            selected['displayName'] as String? ??
                                                selected['name'] as String;
                                      }
                                    });
                                  },
                            hint: l10n.selectCropName,
                            label: l10n.cropNameLabel,
                            prefixIcon: Icons.grass_rounded,
                            itemLabelBuilder: (id) {
                              final n = cropNames.firstWhere((n) => n['id'] == id);
                              return (n['displayName'] as String?) ??
                                  (n['name'] as String);
                            },
                          ),
                        const SizedBox(height: 16),
                        CustomDropdownField<String>(
                          value: selectedCropStatus,
                          items: cropStatuses,
                          onChanged: (val) {
                            setState(() => selectedCropStatus = val);
                          },
                          hint: l10n.selectCropStatus,
                          label: l10n.cropStatus,
                          prefixIcon: Icons.info_outline_rounded,
                          itemLabelBuilder: (s) => _getLocalizedStatus(s, l10n),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionContainer(
                    title: "Cultivation Details",
                    icon: Icons.square_foot_rounded,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: acresController,
                          label: l10n.landArea,
                          hint: l10n.acresHint,
                          prefixIcon: Icons.square_foot_rounded,
                          keyboardType: TextInputType.number,
                          suffixIcon: Text(
                            l10n.acresSuffix,
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _selectDate(
                              context, sowingDateController, l10n.sowingDate),
                          child: AbsorbPointer(
                            child: CustomTextField(
                              controller: sowingDateController,
                              label: l10n.sowingDate,
                              hint: l10n.selectSowingDate,
                              prefixIcon: Icons.calendar_today_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _selectDate(
                              context, harvestingDateController, l10n.harvestingDate),
                          child: AbsorbPointer(
                            child: CustomTextField(
                              controller: harvestingDateController,
                              label: l10n.harvestingDate,
                              hint: l10n.selectHarvestingDate,
                              prefixIcon: Icons.event_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: (farms.isEmpty || _isLoading)
                          ? null
                          : () => _saveCrop(l10n),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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

  Future<void> _selectDate(BuildContext context,
      TextEditingController controller, String fieldName) async {
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
        controller.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.brandGreen, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dialogL10n?.farmRequired ?? "Farm Required",
                  style: const TextStyle(
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
              Text(
                dialogL10n?.farmRequiredMessage ??
                    "To add crops, you need to add a farm first. A farm is required to track your crop details.",
                style: const TextStyle(
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
                  border: Border.all(
                      color: AppColors.brandGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: AppColors.brandGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dialogL10n?.farmRequiredInstruction ??
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
                        content: Text(snackL10n?.farmAddedCanAddCrops ??
                            "Farm added! You can now add crops."),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
  String _getUserFriendlyErrorMessage(
      dynamic error, double? acres, AppLocalizations l10n) {
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
      String? farmArea;
      String? availableArea;

      if (numbers.length >= 3) {
        farmArea = numbers.elementAt(1).group(0);
        availableArea = numbers.elementAt(2).group(0);
      } else if (numbers.length >= 2) {
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
          return l10n.errorCropAreaAvailable(
              acresText, farmArea, availableArea);
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
    return actualMessage
        .replaceFirst("Exception: ", "")
        .replaceFirst("Network Error: ", "")
        .replaceFirst("Error: ", "");
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

    if (selectedCropTypeId == null ||
        selectedCropNameId == null ||
        acresController.text.isEmpty) {
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

        final args = ModalRoute.of(context)?.settings.arguments;
        final bool isFromOnboardingNow = _fromOnboarding ||
            (args is Map && args['fromOnboarding'] == true);

        if (isFromOnboardingNow) {
          await context
              .read<OnboardingController>()
              .completeCropAndGoToSubscription(context);
        } else {
          Navigator.pop(context, true); // Return true to indicate success
        }
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
