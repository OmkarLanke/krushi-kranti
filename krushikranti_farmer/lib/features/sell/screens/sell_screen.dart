import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';  // ✅ Standard Import
import 'package:intl/intl.dart'; 
import '../../../core/constants/app_colors.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
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
      // Navigate to Orders/Sales after submission if needed
      // Navigator.pushReplacementNamed(context, '/orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Check if we can go back (Pushed from Quick Action vs Tab)
    final bool canGoBack = Navigator.canPop(context); 

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.sellTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, 
        leading: canGoBack 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null, 
      ),
      body: SingleChildScrollView(
        // ✅ 1. Safe Padding: 16px horizontal prevents overflow on small screens
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // --- 1. DATE ---
              _buildLabel(l10n.dateLabel),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: _inputDecoration(l10n.selectDate).copyWith(
                      suffixIcon: const Icon(Icons.calendar_month_outlined, color: Colors.grey),
                    ),
                    validator: (v) => v!.isEmpty ? l10n.fillAllFields : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. CROP TYPE ---
              _buildLabel(l10n.cropTypeLabel),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedCategory ?? 'cat_empty'),
                value: _selectedCategory,
                decoration: _inputDecoration(l10n.selectCategory),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat)); 
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
              _buildLabel(l10n.selectCropLabel),
              DropdownButtonFormField<String>(
                key: ValueKey('crop_$_selectedCategory'), 
                value: _selectedCrop,
                decoration: _inputDecoration(l10n.selectCropHint),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: _selectedCategory == null 
                    ? [] 
                    : _cropsByCategory[_selectedCategory]!.map((crop) {
                        return DropdownMenuItem(value: crop, child: Text(crop));
                      }).toList(),
                onChanged: (value) => setState(() => _selectedCrop = value),
                validator: (v) => v == null ? l10n.fillAllFields : null,
              ),
              const SizedBox(height: 20),

              // --- 4. QUANTITY & UNIT ---
              Row(
                children: [
                  Expanded(
                    // ✅ 2. Flex Ratio 4:3 ensures both fields have enough space
                    flex: 4, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(l10n.quantityLabel),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration("e.g. 100"),
                          validator: (v) => v!.isEmpty ? l10n.fillAllFields : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(l10n.unitLabel),
                        DropdownButtonFormField<String>(
                          // ✅ 3. isExpanded prevents overflow if text is long
                          isExpanded: true,
                          value: _selectedUnit,
                          decoration: _inputDecoration("Unit"),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v),
                          validator: (v) => v == null ? "" : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _handleSubmit,
                  child: Text(
                    l10n.submitVcpBtn,
                    style: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.black 
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14, 
          fontWeight: FontWeight.bold, 
          color: AppColors.textPrimary
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade50,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandGreen),
      ),
      errorBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(12),
         borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}