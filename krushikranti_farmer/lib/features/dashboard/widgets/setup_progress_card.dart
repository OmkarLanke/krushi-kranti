import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import 'primary_cta_button.dart';

class SetupProgressCard extends StatelessWidget {
  final bool hasPersonalDetails;
  final bool hasFarm;
  final bool? hasCrop;
  final bool isSubscribed;
  final bool? hasKyc;
  final VoidCallback onContinueSetup;

  const SetupProgressCard({
    super.key,
    required this.hasPersonalDetails,
    required this.hasFarm,
    this.hasCrop,
    required this.isSubscribed,
    this.hasKyc,
    required this.onContinueSetup,
  });

  int get _completedSteps {
    int count = 0;
    if (hasPersonalDetails) count++;
    if (hasFarm) count++;
    if (hasCrop == true) count++;
    if (isSubscribed) count++;
    if (hasKyc == true) count++;
    return count;
  }

  int get _totalSteps {
    int count = 3;
    if (hasCrop != null) count++;
    if (hasKyc != null) count++;
    return count;
  }

  double get _progress => _completedSteps / _totalSteps.toDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_completedSteps >= _totalSteps) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.completeSetupTitle,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.progressPercent((_progress * 100).toInt()),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Premium Custom Animated Progress Bar
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * _progress,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandGreen,
                          AppColors.brandGreen.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandGreen.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Steps
          _buildStepRow(
            title: l10n.setupStepCompleteProfileTitle,
            subtitle: l10n.setupStepCompleteProfileSubtitle,
            isCompleted: hasPersonalDetails,
            isActive: !hasPersonalDetails,
            isLocked: false,
          ),
          _buildDivider(),
          _buildStepRow(
            title: l10n.setupStepAddFarmTitle,
            subtitle: l10n.setupStepAddFarmSubtitle,
            isCompleted: hasFarm,
            isActive: hasPersonalDetails && !hasFarm,
            isLocked: !hasPersonalDetails,
          ),
          _buildDivider(),
          if (hasCrop != null) ...[
            _buildStepRow(
              title: l10n.homeOnboardingAddCropTitle,
              subtitle: l10n.myDetailsStepAddCropsBody,
              isCompleted: hasCrop!,
              isActive: hasPersonalDetails && hasFarm && !hasCrop!,
              isLocked: !(hasPersonalDetails && hasFarm),
            ),
            _buildDivider(),
          ],
          _buildStepRow(
            title: l10n.setupStepSubscribeTitle,
            subtitle: l10n.setupStepSubscribeSubtitle,
            isCompleted: isSubscribed,
            isActive: hasPersonalDetails &&
                hasFarm &&
                (hasCrop == null || hasCrop!) &&
                !isSubscribed,
            isLocked: !(hasPersonalDetails &&
                hasFarm &&
                (hasCrop == null || hasCrop!)),
          ),
          if (hasKyc != null) ...[
            _buildDivider(),
            _buildStepRow(
              title: l10n.kyc,
              subtitle: l10n.kycPending,
              isCompleted: hasKyc!,
              isActive: hasPersonalDetails &&
                  hasFarm &&
                  (hasCrop == null || hasCrop!) &&
                  isSubscribed &&
                  !hasKyc!,
              isLocked: !(hasPersonalDetails &&
                  hasFarm &&
                  (hasCrop == null || hasCrop!) &&
                  isSubscribed),
            ),
          ],
          const SizedBox(height: 20),

          // Full-width CTA using the new Premium Button
          PrimaryCTAButton(
            text: l10n.continueSetup,
            onPressed: onContinueSetup,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        color: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildStepRow({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isLocked,
  }) {
    IconData iconData;
    Color iconColor;
    Color iconBgColor;

    if (isCompleted) {
      iconData = Icons.check_circle_rounded;
      iconColor = AppColors.brandGreen;
      iconBgColor = AppColors.brandGreen.withOpacity(0.15);
    } else if (isLocked) {
      iconData = Icons.lock_rounded;
      iconColor = Colors.grey.shade400;
      iconBgColor = Colors.grey.shade100;
    } else {
      iconData = Icons.radio_button_unchecked_rounded;
      iconColor = AppColors.brandGreen;
      iconBgColor = AppColors.brandGreen.withOpacity(0.05);
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isLocked ? 0.6 : 1.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isCompleted || isActive
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: isCompleted
                        ? Colors.black87
                        : (isActive ? Colors.black87 : Colors.grey.shade600),
                  ),
                ),
                if (isActive || isCompleted) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
