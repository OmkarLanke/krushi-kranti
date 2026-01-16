import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import 'package:intl/intl.dart'; 
import '../../../core/constants/app_colors.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedCrop;
  String? _selectedUnit;

  final List<String> _categories = ['Vegetables', 'Fruits', 'Legumes', 'More'];
  
  final Map<String, List<String>> _cropsByCategory = {
    'Vegetables': ['Tomato', 'Potato', 'Spinach', 'Ladyfinger', 'Onion'],
    'Fruits': ['Banana', 'Mango', 'Pomegranate', 'Grapes'],
    'Legumes': ['Soybean', 'Chickpea'],
    'More': ['Other']
  };

  final List<String> _units = ['Kg', 'Ton', 'Quintal'];

  @override
  void dispose() {
    _dateController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
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
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(AppLocalizations.of(context)!.successVcp),
          backgroundColor: AppColors.success,
        ),
      );
      // Navigate back to sell screen after submission
      Navigator.pop(context);
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
          l10n.sellTitle,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. DATE ---
              _buildSectionHeader(Icons.calendar_today_rounded, l10n.dateLabel),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: _inputDecoration(l10n.selectDate).copyWith(
                      suffixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.brandGreen),
                    ),
                    validator: (v) => v!.isEmpty ? l10n.fillAllFields : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. CROP TYPE ---
              _buildSectionHeader(Icons.category_rounded, l10n.cropTypeLabel),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedCategory ?? 'cat_empty'),
                value: _selectedCategory,
                decoration: _inputDecoration(l10n.selectCategory),
                style: GoogleFonts.poppins(fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.brandGreen),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: GoogleFonts.poppins(fontSize: 14)),
                  ); 
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedCrop = null; 
                  });
                },
                validator: (v) => v == null ? l10n.fillAllFields : null,
              ),
              const SizedBox(height: 20),

              // --- 3. SPECIFIC CROP (Dependent) ---
              _buildSectionHeader(Icons.grass_rounded, l10n.selectCropLabel),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('crop_$_selectedCategory'), 
                value: _selectedCrop,
                decoration: _inputDecoration(l10n.selectCropHint),
                style: GoogleFonts.poppins(fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.brandGreen),
                items: _selectedCategory == null 
                    ? [] 
                    : _cropsByCategory[_selectedCategory]!.map((crop) {
                        return DropdownMenuItem(
                          value: crop,
                          child: Text(crop, style: GoogleFonts.poppins(fontSize: 14)),
                        );
                      }).toList(),
                onChanged: (value) => setState(() => _selectedCrop = value),
                validator: (v) => v == null ? l10n.fillAllFields : null,
              ),
              const SizedBox(height: 20),

              // --- 4. QUANTITY & UNIT ---
              _buildSectionHeader(Icons.scale_rounded, "${l10n.quantityLabel} & ${l10n.unitLabel}"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 4, 
                    child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(fontSize: 14),
                          decoration: _inputDecoration("e.g. 100"),
                          validator: (v) => v!.isEmpty ? l10n.fillAllFields : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3, 
                    child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedUnit,
                      style: GoogleFonts.poppins(fontSize: 14),
                          decoration: _inputDecoration("Unit"),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.brandGreen),
                      items: _units.map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(u, style: GoogleFonts.poppins(fontSize: 14)),
                      )).toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v),
                          validator: (v) => v == null ? "" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    l10n.submitVcpBtn,
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
                    elevation: 0,
                  ),
                  onPressed: _handleSubmit,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
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
}

