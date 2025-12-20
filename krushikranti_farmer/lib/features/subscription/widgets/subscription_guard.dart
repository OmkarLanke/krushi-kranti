import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../services/subscription_service.dart';

/// A widget that shows subscription required warning if user is not subscribed.
/// Can be used to wrap any protected content.
class SubscriptionGuard extends StatelessWidget {
  final Widget child;
  final String featureName;
  final bool showOverlay;

  const SubscriptionGuard({
    super.key,
    required this.child,
    this.featureName = "this feature",
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkSubscriptionStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brandGreen),
          );
        }

        final isSubscribed = snapshot.data ?? false;

        if (isSubscribed) {
          return child;
        }

        if (showOverlay) {
          return Stack(
            children: [
              // Blurred/Dimmed content
              IgnorePointer(
                child: Opacity(
                  opacity: 0.3,
                  child: child,
                ),
              ),
              // Subscription required overlay
              _buildSubscriptionOverlay(context),
            ],
          );
        } else {
          return _buildSubscriptionRequired(context);
        }
      },
    );
  }

  Widget _buildSubscriptionOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: _buildSubscriptionRequired(context),
    );
  }

  Widget _buildSubscriptionRequired(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizedFeatureName = featureName == "this feature" ? l10n.thisFeature : featureName;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 60,
                color: Colors.orange.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              l10n.subscriptionRequired,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              l10n.toAccessFeature(localizedFeatureName),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Price
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.only999Year,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandGreen,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Subscribe Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.subscription);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.subscribeNow,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Benefits Preview
            Text(
              l10n.benefitsInclude,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _buildBenefitChip(l10n.weatherUpdates),
                _buildBenefitChip(l10n.expertAdvice),
                _buildBenefitChip(l10n.marketAccess),
                _buildBenefitChip(l10n.zeroPercentLoan),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  /// Check subscription status from API first, fallback to local storage
  Future<bool> _checkSubscriptionStatus() async {
    try {
      // Try to get fresh subscription status from API
      final subStatus = await SubscriptionService.getSubscriptionStatus();
      final isSubscribed = subStatus['isSubscribed'] == true || 
                          subStatus['subscriptionStatus'] == 'ACTIVE';
      
      // Update local storage with fresh status
      if (isSubscribed) {
        final endDate = subStatus['subscriptionEndDate']?.toString() ?? 
                       subStatus['expiresAt']?.toString();
        await StorageService.saveSubscriptionStatus(true, endDate: endDate);
      } else {
        await StorageService.saveSubscriptionStatus(false);
      }
      
      return isSubscribed;
    } catch (_) {
      // If API fails, fallback to local storage
      return await StorageService.isSubscribed();
    }
  }
}

/// Simple subscription check dialog - can be shown from anywhere
Future<void> showSubscriptionRequiredDialog(BuildContext context, {
  String featureName = "this feature",
}) async {
  final l10n = AppLocalizations.of(context)!;
  final localizedFeatureName = featureName == "this feature" ? l10n.thisFeature : featureName;
  
  // Check subscription status before showing dialog
  bool isSubscribed = false;
  try {
    final subStatus = await SubscriptionService.getSubscriptionStatus();
    isSubscribed = subStatus['isSubscribed'] == true || 
                   subStatus['subscriptionStatus'] == 'ACTIVE';
    
    if (isSubscribed) {
      // User is subscribed, don't show dialog
      return;
    }
  } catch (_) {
    // If API fails, check local storage
    isSubscribed = await StorageService.isSubscribed();
    if (isSubscribed) {
      return;
    }
  }

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.orange.shade600),
          const SizedBox(width: 12),
          Text(l10n.subscriptionRequired),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.toAccessFeature(localizedFeatureName)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${l10n.annualSubscription} ", style: const TextStyle(fontSize: 14)),
                const Text(
                  "₹999",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.later),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.subscription);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.subscribeNow),
        ),
      ],
    ),
  );
}

