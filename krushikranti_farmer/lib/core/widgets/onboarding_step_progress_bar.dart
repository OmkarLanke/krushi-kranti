import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';

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

    List<Widget> buildStepRowChildren() {
      return List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = (index + 1) ~/ 2;
          final prevStep = stepIndex - 1;
          final isCompleted = stepStatuses[prevStep] == StepStatus.completed;

          return Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 13, left: 2, right: 2),
              child: Container(
                height: 2,
                color:
                    isCompleted ? AppColors.brandGreen : Colors.grey.shade300,
              ),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        return Expanded(
          flex: 3,
          child: _OnboardingStepItem(
            key: ValueKey<int>(stepIndex),
            stepIndex: stepIndex,
            status: stepStatuses[stepIndex],
            label: labels[stepIndex],
          ),
        );
      });
    }

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: buildStepRowChildren(),
        ),
      ),
    );
  }
}

class _OnboardingStepItem extends StatelessWidget {
  final int stepIndex;
  final StepStatus status;
  final String label;

  const _OnboardingStepItem({
    super.key,
    required this.stepIndex,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = status == StepStatus.completed;
    final bool isActive = status == StepStatus.active;

    final Color circleBg =
        isCompleted || isActive ? AppColors.brandGreen : Colors.grey.shade300;

    final Color labelColor = isActive
        ? AppColors.brandGreen
        : (isCompleted ? Colors.grey.shade800 : Colors.grey.shade500);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: circleBg,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  (stepIndex + 1).toString(),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AutoSizeText(
            label,
            maxLines: 2,
            minFontSize: 8,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              height: 1.15,
              color: labelColor,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Subscribes only to step + locale changes — avoids rebuilding when other
/// onboarding fields or unrelated providers notify.
class OnboardingStepProgressBarConnected extends StatelessWidget {
  const OnboardingStepProgressBarConnected({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<OnboardingController, int>(
      selector: (context, c) => c.stepProgressSignature,
      builder: (context, _, __) {
        final l10n = AppLocalizations.of(context)!;
        final labels = onboardingFormStepperLabels(l10n);
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
