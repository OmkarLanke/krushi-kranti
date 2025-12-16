import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class ForgotPasswordPhoneScreen extends StatefulWidget {
  const ForgotPasswordPhoneScreen({super.key});

  @override
  State<ForgotPasswordPhoneScreen> createState() => _ForgotPasswordPhoneScreenState();
}

class _ForgotPasswordPhoneScreenState extends State<ForgotPasswordPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.passwordRecovery, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              l10n.verifyNumber,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.verifyNumberSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Phone Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100, // Light grey background like screenshot
              ),
              child: Row(
                children: [
                   const Text("+91", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(width: 10),
                   Container(width: 1, height: 24, color: Colors.grey), // Divider
                   const SizedBox(width: 10),
                   Expanded(
                     child: TextField(
                       controller: _phoneController,
                       keyboardType: TextInputType.number,
                       maxLength: 10,
                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                       decoration: const InputDecoration(
                         border: InputBorder.none,
                         counterText: "",
                         hintText: "Enter Mobile Number",
                       ),
                     ),
                   )
                ],
              ),
            ),

            const Spacer(),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Using Green
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_phoneController.text.length == 10) {
                    Navigator.pushNamed(context, AppRoutes.forgotPasswordOtp);
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text("Please enter valid number")),
                     );
                  }
                },
                child: Text(
                  l10n.nextBtn,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}