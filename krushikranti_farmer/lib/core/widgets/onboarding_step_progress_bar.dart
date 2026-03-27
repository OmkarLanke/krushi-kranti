import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../onboarding/onboarding_controller.dart';
import '../onboarding/onboarding_models.dart';

/// Localized labels for the global onboarding stepper (5 steps).
List<String> onboardingFormStepperLabels(AppLocalizations l10n) => [
      l10n.profile,
      l10n.farmLabel,
      l10n.onboardingStepCrop,
      l10n.subscription,
      l10n.kyc,
    ];

/// Top onboarding progress UI only — pass explicit [stepStatuses] + [labels].
/// Prefer [OnboardingStepProgressBarConnected] so the parent screen does not
/// rebuild this bar on unrelated [OnboardingController] updates.
class OnboardingStepProgressBar extends StatelessWidget {
  final List<StepStatus> stepStatuses;
  final List<String> labels;

  const OnboardingStepProgressBar({
    super.key,
    required this.stepStatuses,
    required this.labels,
  }) : assert(stepStatuses.length == 5, 'stepStatuses must have length 5');

  @override
  Widget build(BuildContext context) {
    final totalSteps = stepStatuses.length;
    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index % 2 != 0) {
                final stepIndex = (index + 1) ~/ 2;
                final prevStep = stepIndex - 1;
                final isCompleted =
                    stepStatuses[prevStep] == StepStatus.completed;
                return Container(
                  margin: const EdgeInsets.only(top: 14),
                  height: 2,
                  width: 32,
                  color: isCompleted
                      ? AppColors.brandGreen
                      : Colors.grey.shade300,
                );
              }

              final stepIndex = index ~/ 2;
              final status = stepStatuses[stepIndex];
              final isCompleted = status == StepStatus.completed;
              final isActive = status == StepStatus.active;

              final Color circleBg;
              final Widget circleChild;
              if (isCompleted) {
                circleBg = AppColors.brandGreen;
                circleChild =
                    const Icon(Icons.check, color: Colors.white, size: 16);
              } else if (isActive) {
                circleBg = AppColors.brandGreen;
                circleChild = Text(
                  (stepIndex + 1).toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else {
                circleBg = Colors.grey.shade300;
                circleChild = Text(
                  (stepIndex + 1).toString(),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }

              return SizedBox(
                key: ValueKey<String>('onboarding_step_$stepIndex'),
                width: 65,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: circleBg,
                      child: circleChild,
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[stepIndex],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: isActive
                              ? AppColors.brandGreen
                              : (isCompleted
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade500),
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Subscribes only to step + locale changes — avoids rebuilding when other
/// onboarding fields or unrelated providers notify.
class OnboardingStepProgressBarConnected extends StatelessWidget {
  const OnboardingStepProgressBarConnected({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = onboardingFormStepperLabels(l10n);
    return Selector<OnboardingController, int>(
      selector: (context, c) => Object.hash(
        c.stepProgressSignature,
        Localizations.localeOf(context).languageCode,
      ),
      builder: (context, _, __) {
        final controller = context.read<OnboardingController>();
        return OnboardingStepProgressBar(
          stepStatuses: controller.stepStatuses,
          labels: labels,
        );
      },
    );
  }
}

/// Backwards-compatible name for [OnboardingStepProgressBar].
typedef FormStepper = OnboardingStepProgressBar;
