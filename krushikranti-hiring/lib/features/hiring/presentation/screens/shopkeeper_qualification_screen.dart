import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; 
import 'submission_success_screen.dart';
// Import Localization
import '../../../../core/app_localizations.dart';

class ShopkeeperQualificationScreen extends StatefulWidget {
  const ShopkeeperQualificationScreen({super.key});

  @override
  State<ShopkeeperQualificationScreen> createState() => _ShopkeeperQualificationScreenState();
}

class _ShopkeeperQualificationScreenState extends State<ShopkeeperQualificationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _yearsInBusinessController = TextEditingController();
  
  String? _shopTypeValue; 
  String? _shopPhotoFileName;

  // --- 📂 FILE PICKING LOGIC ---
  Future<void> _pickShopPhoto() async {
    final ImagePicker picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo), title: const Text('Gallery'), onTap: () async { Navigator.pop(context); var img = await picker.pickImage(source: ImageSource.gallery); if(img != null) setState(() => _shopPhotoFileName = img.name); }),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () async { Navigator.pop(context); var img = await picker.pickImage(source: ImageSource.camera); if(img != null) setState(() => _shopPhotoFileName = img.name); }),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0, top: 20.0),
    child: Row(
      children: [
        Text(text, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blueGrey[900])),
        if (required) const SizedBox(width: 4),
        if (required) const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _textField(TextEditingController controller, String hint, {bool required = true, bool isNumber = false, int? maxLength, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator, IconData? prefixIcon}) {
    return TextFormField(
      controller: controller, 
      keyboardType: isNumber ? TextInputType.number : TextInputType.text, 
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 16), 
      decoration: InputDecoration(
        hintText: hint, 
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        counterText: "", 
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[600], size: 22) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)), 
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)), 
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ), 
      validator: validator ?? (val) {
         if (!required) return null;
         return (val == null || val.isEmpty) ? AppStrings.tr('required') : null;
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
            centerTitle: true,
            title: Text(AppStrings.tr('enter_qualification'), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(AppStrings.tr('shop_name'), required: true), 
                      _textField(_shopNameController, "Rajiv Mart", prefixIcon: Icons.store_outlined),

                      _label(AppStrings.tr('shop_address'), required: true), 
                      _textField(_shopAddressController, "Near Maharashtra Bank", prefixIcon: Icons.location_on_outlined),

                      _label(AppStrings.tr('gst_number'), required: true), 
                      _textField(
                        _gstNumberController, 
                        "598454987451494",
                        maxLength: 15,
                        prefixIcon: Icons.receipt_long_outlined,
                        validator: (val) {
                          if (val == null || val.isEmpty) return AppStrings.tr('required');
                          if (val.length != 15) return '15 chars required';
                          return null;
                        }
                      ),

                      _label(AppStrings.tr('years_business'), required: true), 
                      _textField(_yearsInBusinessController, "5", isNumber: true, inputFormatters: [FilteringTextInputFormatter.digitsOnly], prefixIcon: Icons.access_time),

                      _label(AppStrings.tr('shop_type'), required: true), 
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          prefixIcon: const Icon(Icons.category_outlined, color: Colors.grey, size: 22),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)), 
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)), 
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5)),
                        ),
                        value: _shopTypeValue, 
                        hint: Text(AppStrings.tr('shop_type'), style: GoogleFonts.poppins(color: Colors.grey[400])), 
                        isExpanded: true, 
                        items: [
                          DropdownMenuItem(value: "Retail", child: Text(AppStrings.tr('retail'))), 
                          DropdownMenuItem(value: "Wholesale", child: Text(AppStrings.tr('wholesale'))), 
                          DropdownMenuItem(value: "Distributor", child: Text(AppStrings.tr('distributor')))
                        ], 
                        onChanged: (val) => setState(() => _shopTypeValue = val),
                        validator: (val) => val == null ? AppStrings.tr('required') : null,
                      ),

                      const SizedBox(height: 30),

                      _label(AppStrings.tr('upload_shop_photo'), required: true),
                      InkWell(
                        onTap: _pickShopPhoto,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(_shopPhotoFileName ?? AppStrings.tr('upload_shop_photo'), 
                                style: GoogleFonts.poppins(color: _shopPhotoFileName != null ? Colors.black : Colors.grey[600], fontWeight: _shopPhotoFileName != null ? FontWeight.w500 : FontWeight.normal))),
                              Icon(_shopPhotoFileName != null ? Icons.check_circle : Icons.add_a_photo_outlined, color: _shopPhotoFileName != null ? Colors.green : Colors.grey)
                            ],
                          ),
                        ),
                      ),
                      if (_shopPhotoFileName == null) Padding(
                        padding: const EdgeInsets.only(top:8.0, left: 4),
                        child: Text(AppStrings.tr('required'), style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),

                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              if (_shopPhotoFileName == null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.tr('required'))));
                                return;
                              }
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SubmissionSuccessScreen()));
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          child: Text(AppStrings.tr('submit_form'), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}