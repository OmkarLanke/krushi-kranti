import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../onboarding/onboarding_models.dart';

class FormStepper extends StatelessWidget {
  final List<StepStatus> stepStatuses;
  final List<String> labels;

  const FormStepper({
    super.key,
    required this.stepStatuses,
    this.labels = const ['Profile', 'Farm', 'Crop', 'Subscription', 'KYC'],
  }) : assert(stepStatuses.length == 5, 'stepStatuses must have length 5');

  @override
  Widget build(BuildContext context) {
    final totalSteps = stepStatuses.length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index % 2 != 0) {
              // Line
              final stepIndex = (index + 1) ~/ 2; // between stepIndex-1 and stepIndex
              final prevStep = stepIndex - 1;
              final isCompleted = stepStatuses[prevStep] == StepStatus.completed;
              return Container(
                margin: const EdgeInsets.only(top: 14),
                height: 2,
                width: 32,
                color: isCompleted ? AppColors.brandGreen : Colors.grey.shade300,
              );
            }

            // Circle + Label
            final stepIndex = (index ~/ 2); // 0-based
            final status = stepStatuses[stepIndex];
            final isCompleted = status == StepStatus.completed;
            final isActive = status == StepStatus.active;

            Color circleBg;
            Widget circleChild;
            if (isCompleted) {
              circleBg = AppColors.brandGreen;
              circleChild = const Icon(Icons.check, color: Colors.white, size: 16);
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
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            }

            return SizedBox(
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
                            : (isCompleted ? Colors.grey.shade800 : Colors.grey.shade500),
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
