import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'onboarding_controller.dart';
import 'onboarding_models.dart';
import '../constants/app_routes.dart';

class OnboardingRouteGuard extends StatefulWidget {
  final OnboardingStep step;
  final Widget child;

  const OnboardingRouteGuard({
    super.key,
    required this.step,
    required this.child,
  });

  @override
  State<OnboardingRouteGuard> createState() => _OnboardingRouteGuardState();
}

class _OnboardingRouteGuardState extends State<OnboardingRouteGuard> {
  bool _redirectQueued = false;
  bool _activeStepQueued = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final bool fromOnboarding =
        // For onboarding transitions we explicitly pass `fromOnboarding: true`.
        (args is Map && args['fromOnboarding'] == true) ||
        // The personal wrapper routes are onboarding entrypoints and may not
        // pass any arguments.
        widget.step == OnboardingStep.personal;
    return Consumer<OnboardingController>(
      builder: (context, onboarding, _) {
        return FutureBuilder(
          future: onboarding.ensureReady(),
          builder: (context, snapshot) {
            final ready =
                onboarding.isReady || snapshot.connectionState == ConnectionState.done;
            if (!ready) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

                // IMPORTANT: Never call `notifyListeners()` during build.
                // `setActiveStep()` triggers `notifyListeners()`, so we defer it
                // to the next frame once the widget is built.
                if (onboarding.activeStep != widget.step && !_activeStepQueued) {
                  _activeStepQueued = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    onboarding.setActiveStep(widget.step);
                    _activeStepQueued = false;
                  });
                }

            final redirectRoute = onboarding.redirectRouteForStep(
              widget.step,
              fromOnboarding: fromOnboarding,
            );
            if (redirectRoute != null && !_redirectQueued) {
              // Avoid calling navigation repeatedly during rebuild.
              _redirectQueued = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;

                    final bool clearStackOnKycCompletion =
                        widget.step == OnboardingStep.kyc &&
                            redirectRoute == AppRoutes.dashboard;

                    if (clearStackOnKycCompletion) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        redirectRoute,
                        (route) => false,
                        arguments: args,
                      );
                    } else {
                      Navigator.of(context).pushReplacementNamed(
                        redirectRoute,
                        arguments: args,
                      );
                    }
              });
              return const SizedBox.shrink();
            }

            return widget.child;
          },
        );
      },
    );
  }
}

