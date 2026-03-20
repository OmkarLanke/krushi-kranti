import 'package:flutter/material.dart';
import '../../core/services/http_service.dart';
import '../services/storage_service.dart' as storage_service;
import '../../features/subscription/services/subscription_service.dart';
import '../../features/kyc/services/kyc_service.dart';

import 'onboarding_models.dart';
import '../../core/constants/app_routes.dart';

class OnboardingController extends ChangeNotifier {
  bool _isReady = false;
  Future<void>? _initFuture;

  // Completion flags (source of truth for step statuses).
  bool _personalCompleted = false;
  bool _farmCompleted = false;
  bool _cropCompleted = false;
  bool _subscriptionCompleted = false;
  bool _kycCompleted = false;

  // Skip flags.
  bool _isPersonalSkipped = false;
  bool _isFarmSkipped = false;

  // Active step is set by route guard, not by UI.
  OnboardingStep? _activeStep;

  bool get isReady => _isReady;

  bool get isPersonalSkipped => _isPersonalSkipped;
  bool get isFarmSkipped => _isFarmSkipped;

  bool get canEnterPersonal => !_isPersonalSkipped;
  bool get canEnterFarm => _personalCompleted && !_isPersonalSkipped;
  bool get canEnterCrop => _personalCompleted &&
      !_isPersonalSkipped &&
      _farmCompleted &&
      !_isFarmSkipped;
  bool get canEnterSubscription =>
      _personalCompleted && !_isPersonalSkipped;
  bool get canEnterKyc =>
      _personalCompleted && !_isPersonalSkipped && _subscriptionCompleted;

  StepStatus _statusForStep(OnboardingStep step) {
    final isSkippedStep = (step == OnboardingStep.personal && _isPersonalSkipped) ||
        (step == OnboardingStep.farm && _isFarmSkipped) ||
        (step == OnboardingStep.crop && _isFarmSkipped);

    if (isSkippedStep) return StepStatus.pending;

    final isCompleted = switch (step) {
      OnboardingStep.personal => _personalCompleted,
      OnboardingStep.farm => _farmCompleted,
      OnboardingStep.crop => _cropCompleted,
      OnboardingStep.subscription => _subscriptionCompleted,
      OnboardingStep.kyc => _kycCompleted,
    };

    if (isCompleted) return StepStatus.completed;

    if (_activeStep == step) return StepStatus.active;

    return StepStatus.pending;
  }

  List<StepStatus> get stepStatuses => [
        personalStatus,
        farmStatus,
        cropStatus,
        subscriptionStatus,
        kycStatus,
      ];

  StepStatus get personalStatus => _statusForStep(OnboardingStep.personal);
  StepStatus get farmStatus => _statusForStep(OnboardingStep.farm);
  StepStatus get cropStatus => _statusForStep(OnboardingStep.crop);
  StepStatus get subscriptionStatus =>
      _statusForStep(OnboardingStep.subscription);
  StepStatus get kycStatus => _statusForStep(OnboardingStep.kyc);

  OnboardingStep? get activeStep => _activeStep;

  String _routeNameForStep(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.personal => AppRoutes.onboardingPersonal,
      OnboardingStep.farm => AppRoutes.addFarm,
      OnboardingStep.crop => AppRoutes.addCrop,
      OnboardingStep.subscription => AppRoutes.subscription,
      OnboardingStep.kyc => AppRoutes.kycStatus,
    };
  }

  // Returns null if requested step is already allowed.
  String? redirectRouteForStep(
    OnboardingStep requestedStep, {
    bool fromOnboarding = false,
  }) {
    if (_isPersonalSkipped) {
      // Business rule: if personal is skipped, onboarding ends immediately.
      return AppRoutes.dashboard;
    }

    switch (requestedStep) {
      case OnboardingStep.personal:
        // Personal can only be blocked by the “personal skipped” rule.
        return canEnterPersonal ? null : AppRoutes.dashboard;
      case OnboardingStep.farm:
        return canEnterFarm ? null : _routeNameForStep(OnboardingStep.personal);
      case OnboardingStep.crop:
        // Crop depends on farm completion; if farm is skipped, crop is invalid
        // and should be treated as auto-skipped (go straight to subscription).
        if (!canEnterFarm) return _routeNameForStep(OnboardingStep.personal);
        if (_isFarmSkipped) {
          // Business rule applies only to onboarding flow.
          // Outside onboarding, we should route user to farm first.
          return fromOnboarding
              ? _routeNameForStep(OnboardingStep.subscription)
              : _routeNameForStep(OnboardingStep.farm);
        }
        return _farmCompleted ? null : _routeNameForStep(OnboardingStep.farm);
      case OnboardingStep.subscription:
        // Subscription depends only on Step 1 being completed.
        return canEnterSubscription
            ? null
            : _routeNameForStep(OnboardingStep.personal);
      case OnboardingStep.kyc:
        // KYC depends only on subscription being completed (independent of farm/crop).
        if (_kycCompleted) return AppRoutes.dashboard;
        return canEnterKyc
            ? null
            : _routeNameForStep(OnboardingStep.subscription);
    }
  }

  void setActiveStep(OnboardingStep step) {
    if (_activeStep == step) return;
    _activeStep = step;
    notifyListeners();
  }

  Future<void> ensureReady() async {
    if (_isReady) return;
    _initFuture ??= _hydrateFromStorageAndApi().then((_) {
      _isReady = true;
      notifyListeners();
    });
    await _initFuture;
  }

  Future<void> _hydrateFromStorageAndApi() async {
    // Skip flags are persisted so stepper always respects the business rules.
    _isPersonalSkipped =
        (await storage_service.StorageService.getOnboardingPersonalSkipped()) ?? false;
    _isFarmSkipped =
        (await storage_service.StorageService.getOnboardingFarmSkipped()) ?? false;

    // KYC completion can be persisted locally so users don't get stuck
    // if the backend token/session expires right after verification.
    _kycCompleted =
        (await storage_service.StorageService.getOnboardingKycCompleted()) ?? false;

    // Personal completion:
    // - If user previously marked personal as completed, trust it.
    // - Otherwise, derive from local user details.
    _personalCompleted =
        (await storage_service.StorageService.getOnboardingPersonalCompleted()) ?? false;
    if (!_personalCompleted) {
      final userData = await storage_service.StorageService.getUserDetails();
      final derived = (userData['firstName']?.trim().isNotEmpty ?? false) &&
          (userData['lastName']?.trim().isNotEmpty ?? false) &&
          (userData['dob']?.trim().isNotEmpty ?? false) &&
          (userData['gender']?.trim().isNotEmpty ?? false) &&
          (userData['altPhone']?.trim().isNotEmpty ?? false);
      _personalCompleted = derived;
    }

    if (_isPersonalSkipped) {
      _personalCompleted = false;
    }

    // Subscription completion:
    // Important: use backend truth for onboarding progress.
    // Local cached subscription flags can be stale across signups on the
    // same device.
    try {
      _subscriptionCompleted = await SubscriptionService.isSubscribed();
    } catch (_) {
      // Fallback to local cache (still better than incorrectly marking completed).
      _subscriptionCompleted = await storage_service.StorageService.isSubscribed();
    }

    // Farm/crop completion:
    // Derived from backend existence to keep things robust for existing users.
    // We still apply skip overrides for strict onboarding behavior.
    try {
      final farms = await HttpService.get("farmer/profile/farms");
      final farmData = farms['data'] ?? [];
      _farmCompleted = (farmData as List).isNotEmpty;
    } catch (_) {
      // If API fails, keep default false.
    }

    try {
      final crops = await HttpService.get("farmer/profile/crops");
      final cropData = crops['data'] ?? [];
      _cropCompleted = (cropData as List).isNotEmpty;
    } catch (_) {
      // If API fails, keep default false.
    }

    try {
      final kyc = await KycService.getKycStatus();
      _kycCompleted = kyc.isComplete;
      await storage_service.StorageService.saveOnboardingKycCompleted(
        _kycCompleted,
      );
    } catch (_) {
      // If backend fails, keep whatever was persisted locally.
    }
  }

  // -------------------------
  // Skip / Complete actions
  // -------------------------

  Future<void> skipPersonalAndEndOnboarding(BuildContext context) async {
    _isPersonalSkipped = true;
    _personalCompleted = false;

    // Farm and crop are now irrelevant for onboarding.
    _farmCompleted = false;
    _cropCompleted = false;
    _isFarmSkipped = false;

    // Persist skip.
    await storage_service.StorageService.saveOnboardingPersonalSkipped(true);
    await storage_service.StorageService.saveOnboardingPersonalCompleted(false);
    await storage_service.StorageService.saveOnboardingFarmSkipped(false);

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (r) => false);
  }

  /// Called from Home "Complete profile" CTA.
  /// If the user previously skipped Step 1, we explicitly clear the skip flag
  /// so the Personal onboarding flow can be re-entered to complete profile.
  Future<void> allowPersonalOnboardingFromHome(BuildContext context) async {
    _isPersonalSkipped = false;
    await storage_service.StorageService.saveOnboardingPersonalSkipped(false);

    // Re-hydrate to restore derived completion flags (e.g., if backend has farm/crop data).
    await _hydrateFromStorageAndApi();
    notifyListeners();
  }

  Future<void> completePersonalAndGoToFarm(BuildContext context) async {
    _isPersonalSkipped = false;
    _personalCompleted = true;
    await storage_service.StorageService.saveOnboardingPersonalSkipped(false);
    await storage_service.StorageService.saveOnboardingPersonalCompleted(true);

    if (!context.mounted) return;
    setActiveStep(OnboardingStep.farm);
    Navigator.pushNamed(context, AppRoutes.addFarm, arguments: {'fromOnboarding': true});
  }

  Future<void> skipFarmAndGoToSubscription(BuildContext context) async {
    _isFarmSkipped = true;
    _farmCompleted = false;
    _cropCompleted = false;

    await storage_service.StorageService.saveOnboardingFarmSkipped(true);

    if (!context.mounted) return;
    setActiveStep(OnboardingStep.subscription);
    Navigator.pushNamed(context, AppRoutes.subscription, arguments: {'fromOnboarding': true});
  }

  Future<void> completeFarmAndGoToCrop(BuildContext context) async {
    _isFarmSkipped = false;
    _farmCompleted = true;
    await storage_service.StorageService.saveOnboardingFarmSkipped(false);

    if (!context.mounted) return;
    setActiveStep(OnboardingStep.crop);
    Navigator.pushNamed(context, AppRoutes.addCrop, arguments: {'fromOnboarding': true});
  }

  Future<void> completeCropAndGoToSubscription(BuildContext context) async {
    _cropCompleted = true;
    if (!context.mounted) return;
    setActiveStep(OnboardingStep.subscription);
    Navigator.pushNamed(context, AppRoutes.subscription, arguments: {'fromOnboarding': true});
  }

  Future<void> completeSubscriptionAndGoToKyc(BuildContext context) async {
    _subscriptionCompleted = true;
    if (!context.mounted) return;
    setActiveStep(OnboardingStep.kyc);
    Navigator.pushNamed(context, AppRoutes.kycStatus, arguments: {'fromOnboarding': true});
  }

  Future<void> refreshKycCompletion() async {
    try {
      final kyc = await KycService.getKycStatus();
      _kycCompleted = kyc.isComplete;
      await storage_service.StorageService.saveOnboardingKycCompleted(_kycCompleted);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshSubscriptionCompletion() async {
    try {
      _subscriptionCompleted = await SubscriptionService.isSubscribed();
    } catch (_) {
      _subscriptionCompleted = await storage_service.StorageService.isSubscribed();
    }
    notifyListeners();
  }
}

