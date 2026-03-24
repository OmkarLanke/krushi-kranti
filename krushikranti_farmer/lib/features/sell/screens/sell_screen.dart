import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Placeholder until the Sell flow is implemented (matches Task tab pattern).
class SellScreen extends StatelessWidget {
  const SellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.sellScreenComingSoon,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
