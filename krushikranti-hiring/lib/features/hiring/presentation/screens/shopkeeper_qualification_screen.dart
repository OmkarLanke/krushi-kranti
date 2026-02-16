import 'dart:ui';
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

  @override
  Widget build(BuildContext context) {
    // ✅ Listen to Language Changes
    return ValueListenableBuilder<String>(
      valueListenable: currentLanguage,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
            centerTitle: true,
            title: Text(AppStrings.tr('enter_qualification'), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
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
                      _buildLabel(AppStrings.tr('shop_name')), 
                      _buildTextField(_shopNameController, "Rajiv Mart"),

                      _buildLabel(AppStrings.tr('shop_address')), 
                      _buildTextField(_shopAddressController, "Near Maharashtra Bank"),

                      _buildLabel(AppStrings.tr('gst_number')), 
                      _buildTextField(
                        _gstNumberController, 
                        "598454987451494",
                        maxLength: 15,
                        validator: (val) {
                          if (val == null || val.isEmpty) return AppStrings.tr('required');
                          if (val.length != 15) return '15 chars required'; // You can localize this too if needed
                          return null;
                        }
                      ),

                      _buildLabel(AppStrings.tr('years_business')), 
                      _buildTextField(_yearsInBusinessController, "5", isNumber: true, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),

                      _buildLabel(AppStrings.tr('shop_type')), 
                      _buildDropdown(),

                      const SizedBox(height: 30),

                      _buildUploadButton(
                        label: _shopPhotoFileName ?? AppStrings.tr('upload_shop_photo'), 
                        icon: Icons.storefront, 
                        onTap: _pickShopPhoto, 
                        isSelected: _shopPhotoFileName != null
                      ),

                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SubmissionSuccessScreen()));
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  // --- Helper Widgets ---
  Widget _buildDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16), 
    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)), 
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _shopTypeValue, 
        hint: Text(AppStrings.tr('shop_type'), style: GoogleFonts.poppins(color: Colors.grey[400])), 
        isExpanded: true, 
        items: [
          DropdownMenuItem(value: "Retail", child: Text(AppStrings.tr('retail'))), 
          DropdownMenuItem(value: "Wholesale", child: Text(AppStrings.tr('wholesale'))), 
          DropdownMenuItem(value: "Distributor", child: Text(AppStrings.tr('distributor')))
        ], 
        onChanged: (val) => setState(() => _shopTypeValue = val)
      )
    )
  );

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0, top: 16.0), child: Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)));

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false, int? maxLength, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller, 
      keyboardType: isNumber ? TextInputType.number : TextInputType.text, 
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 16), 
      decoration: InputDecoration(
        hintText: hint, 
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]), 
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
        counterText: "", 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)), 
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 1.5))
      ), 
      validator: validator ?? (val) => val!.isEmpty ? AppStrings.tr('required') : null
    );
  }

  Widget _buildUploadButton({required String label, required IconData icon, required VoidCallback onTap, required bool isSelected}) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: CustomPaint(painter: DashedBorderPainter(), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 16, color: isSelected ? Colors.green : Colors.grey[600], fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))), Icon(isSelected ? Icons.check_circle : icon, color: isSelected ? Colors.green : Colors.indigo)]))));
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.grey[400]!..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final Path path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));
    final Path dashPath = Path();
    double dashWidth = 6.0; double dashSpace = 4.0; double distance = 0.0;
    for (final PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) { dashPath.addPath(pathMetric.extractPath(distance, distance + dashWidth), Offset.zero); distance += dashWidth + dashSpace; }
    }
    canvas.drawPath(dashPath, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}