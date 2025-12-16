import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RequestFundsScreen extends StatelessWidget {
  const RequestFundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Funds"),
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text("Fund Request Form Coming Soon"),
      ),
    );
  }
}