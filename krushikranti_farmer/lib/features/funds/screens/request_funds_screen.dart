import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class RequestFundsScreen extends StatelessWidget {
  const RequestFundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.requestFundsTitle),
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(l10n.fundRequestComingSoon),
      ),
    );
  }
}