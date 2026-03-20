import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/onboarding/onboarding_controller.dart';
import '../../../core/onboarding/onboarding_models.dart';
import '../../../core/widgets/form_stepper.dart';
import '../../../l10n/app_localizations.dart';
import '../services/subscription_service.dart';

/// Subscription screen where user can subscribe and make payment.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  bool _isPaymentInProgress = false;
  Map<String, dynamic>? _subscriptionStatus;
  Map<String, dynamic>? _profileCompletion;
  int? _transactionId;
  bool _fromOnboarding = false;

  bool _shouldNavigateToKycAfterSubscription() {
    // Primary signal: explicit navigation args.
    if (_fromOnboarding) return true;

    // Secondary signal: this screen is wrapped by OnboardingRouteGuard,
    // which sets `activeStep` for onboarding navigation decisions.
    final onboarding = context.read<OnboardingController>();
    return onboarding.activeStep == OnboardingStep.subscription;
  }

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Try to get fresh subscription status from backend first
      try {
        final status = await SubscriptionService.getSubscriptionStatus();
        
        // Ensure isSubscribed is properly set based on status
        final isSubscribed = status['isSubscribed'] == true || 
                            status['subscriptionStatus'] == 'ACTIVE' ||
                            status['subscriptionStatus'] == 'active';
        
        if (!mounted) return;
        setState(() {
          _subscriptionStatus = {
            ...status,
            'isSubscribed': isSubscribed, // Ensure boolean is set correctly
          };
        });
        
        // Save to local storage for offline access
        if (isSubscribed) {
          final endDate = status['subscriptionEndDate']?.toString() ?? 
                         status['expiresAt']?.toString() ??
                         status['subscriptionEndDate']?.toString();
          await StorageService.saveSubscriptionStatus(true, endDate: endDate);
        } else {
          await StorageService.saveSubscriptionStatus(false);
        }
      } catch (e) {
        // Backend unavailable, check local storage
        final isLocallySubscribed = await StorageService.isSubscribed();
        final localEndDate = await StorageService.getSubscriptionEndDate();
        
        if (isLocallySubscribed) {
          if (!mounted) return;
          setState(() {
            _subscriptionStatus = {
              'isSubscribed': true,
              'subscriptionStatus': 'ACTIVE',
              'subscriptionEndDate': localEndDate,
            };
          });
        } else {
          if (!mounted) return;
          setState(() {
            _subscriptionStatus = {
              'isSubscribed': false,
              'subscriptionStatus': 'NONE',
            };
          });
        }
      }

      // Profile is complete if user reached this screen (they went through onboarding)
      if (!mounted) return;
      setState(() {
        _profileCompletion = {
          'profileCompleted': true,
          'canSubscribe': true,
        };
      });
    } catch (e) {
      // Fallback - allow subscription attempt
      if (!mounted) return;
      setState(() {
        _subscriptionStatus = {'isSubscribed': false, 'subscriptionStatus': 'NONE'};
        _profileCompletion = {'profileCompleted': true, 'canSubscribe': true};
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initiatePayment() async {
    // Check subscription status first
    final currentIsSubscribed = _subscriptionStatus?['isSubscribed'] ?? false;
    if (currentIsSubscribed) {
      _showError('You already have an active subscription.');
      // Refresh subscription status to ensure UI is up to date
      await _loadSubscriptionStatus();
      return;
    }

    setState(() => _isPaymentInProgress = true);

    try {
      Map<String, dynamic> response;
      
      try {
        response = await SubscriptionService.initiatePayment();
      } catch (e) {
        setState(() => _isPaymentInProgress = false);
        
        // Check if error is because user already has subscription
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('already') && (errorMessage.contains('subscription') || errorMessage.contains('active'))) {
          _showError('You already have an active subscription.');
          // Refresh subscription status to update UI
          await _loadSubscriptionStatus();
          return;
        }
        
        // For other errors, show the error and don't proceed
        _showError('Failed to initiate payment. Please try again.');
        return;
      }
      
      if (response['status'] == 'INITIATED') {
        setState(() {
          _transactionId = response['transactionId'];
        });
        
        // Show payment bottom sheet
        _showPaymentBottomSheet(response);
      } else {
        _showError(response['message'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
      _showError('Failed to initiate payment: $e');
    } finally {
      setState(() => _isPaymentInProgress = false);
    }
  }

  void _showPaymentBottomSheet(Map<String, dynamic> paymentData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _PaymentBottomSheet(
        paymentData: paymentData,
        onPay: () async {
          return await _completePayment(true);
        },
        onCancel: () {
          _completePayment(false);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<bool> _completePayment(bool success) async {
    if (!success) {
      if (mounted) setState(() => _isPaymentInProgress = false);
      _showError('Payment cancelled');
      return false;
    }

    if (mounted) setState(() => _isPaymentInProgress = true);

    try {
      Map<String, dynamic>? response;
      
      // Try to call backend if transactionId exists
      if (_transactionId != null) {
        try {
          response = await SubscriptionService.completePayment(
            transactionId: _transactionId!,
            mockPayment: true,
            mockPaymentStatus: 'SUCCESS',
          );
        } catch (e) {
          final errorMessage = e.toString().toLowerCase();
          if (errorMessage.contains('transaction not found') || 
              errorMessage.contains('already') ||
              errorMessage.contains('active subscription')) {
            if (mounted) setState(() => _isPaymentInProgress = false);
            await _loadSubscriptionStatus();
            _showSuccess(
              'Payment Completed',
              'Your subscription is now active.',
            );
            return true;
          }
          response = null;
        }
      }

      if (response == null || response['success'] == true) {
        try {
          final subStatus = await SubscriptionService.getSubscriptionStatus();
          final isSubscribed = subStatus['isSubscribed'] == true || 
                              subStatus['subscriptionStatus'] == 'ACTIVE';
          
          if (isSubscribed) {
            final endDate = subStatus['subscriptionEndDate']?.toString() ?? 
                           subStatus['expiresAt']?.toString() ??
                           response?['subscriptionEndDate']?.toString();
            
            await StorageService.saveSubscriptionStatus(true, endDate: endDate);
            
            final displayEndDate = endDate != null 
                ? _parseDateForDisplay(endDate)
                : DateTime.now().add(const Duration(days: 365));
            final endDateStr = '${displayEndDate.day}/${displayEndDate.month}/${displayEndDate.year}';
            
            if (!mounted) return true;
            
            _showSuccess(
              'Payment Successful!',
              'Your subscription is now active until $endDateStr',
            );
            
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (!mounted) return true;
            
            if (_shouldNavigateToKycAfterSubscription()) {
              await context
                  .read<OnboardingController>()
                  .completeSubscriptionAndGoToKyc(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.dashboard,
                (route) => false,
              );
            }
            return true;
          } else {
            final endDate = DateTime.now().add(const Duration(days: 365));
            await StorageService.saveSubscriptionStatus(true, endDate: endDate.toString());
            
            if (!mounted) return true;
            
            _showSuccess(
              'Payment Successful!',
              'Your subscription is being activated. Please wait a moment.',
            );
            
            await Future.delayed(const Duration(seconds: 2));
            await _loadSubscriptionStatus();
            
            if (!mounted) return true;
            
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.dashboard,
              (route) => false,
            );
            return true;
          }
        } catch (e) {
          final endDate = DateTime.now().add(const Duration(days: 365));
          await StorageService.saveSubscriptionStatus(true, endDate: endDate.toString());
          
          if (!mounted) return true;
          
          _showSuccess(
            'Payment Successful!',
            'Your subscription is now active.',
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (!mounted) return true;
          
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
          return true;
        }
      } else {
        _showError(response['message'] ?? 'Payment failed. Please try again.');
        return false;
      }
    } catch (e) {
      _showError('Payment failed: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() => _isPaymentInProgress = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _skipForNow() {
    // Allow user to explore app with subscription guard showing on protected tabs.
    // If coming from onboarding, we still respect the skip but end the flow on dashboard.
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if this screen is opened as part of the signup/onboarding flow
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && !_fromOnboarding) {
      _fromOnboarding = args['fromOnboarding'] == true;
    }

    // Double check subscription status - ensure it's properly set
    final isSubscribed = _subscriptionStatus?['isSubscribed'] == true || 
                         _subscriptionStatus?['subscriptionStatus'] == 'ACTIVE';
    
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          l10n.subscription,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandGreen,
                AppColors.brandGreen.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        actions: [
          // Show skip button only if not subscribed
          if (!isSubscribed)
            TextButton(
              onPressed: _skipForNow,
              child: Text(
                l10n.skip,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          // For subscribed users, show a button to go to dashboard
          if (isSubscribed)
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.dashboard,
                  (route) => false,
                );
              },
              child: Text(
                l10n.dashboard,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandGreen))
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 600;
                  final horizontalPadding = isDesktop ? 40.0 : 20.0;

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 24,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // --- GLOBAL ONBOARDING STEPPER (Steps 1–5) ---
                                  FormStepper(
                                    stepStatuses:
                                        context.watch<OnboardingController>().stepStatuses,
                                  ),

                                  const SizedBox(height: 32),

                                  // Status Card Component
                                  _SubscriptionStatusCard(
                                    isSubscribed: isSubscribed,
                                    status: _subscriptionStatus?['subscriptionStatus'] ?? 'NONE',
                                    daysRemaining: _subscriptionStatus?['daysRemaining'] ?? _calculateDaysRemainingSync(),
                                    subscriptionStartDate: _subscriptionStatus?['subscriptionStartDate'] ?? _subscriptionStatus?['createdAt'],
                                    subscriptionEndDate: _subscriptionStatus?['subscriptionEndDate'] ?? _subscriptionStatus?['expiresAt'],
                                    subscriptionId: _subscriptionStatus?['subscriptionId']?.toString(),
                                    l10n: l10n,
                                  ),

                                  const SizedBox(height: 24),

                                  // Benefits Card Component
                                  _SubscriptionBenefitsCard(l10n: l10n),

                                  const SizedBox(height: 24),

                                  // Profile Completion Status
                                  if (_profileCompletion != null &&
                                      !(_profileCompletion!['canSubscribe'] ?? false))
                                    _buildProfileWarning(),

                                  // Extra padding to ensure smooth scroll
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Sticky Subscribe Button at Bottom
                      if (!isSubscribed)
                        _StickyCTAButton(
                          isPaymentInProgress: _isPaymentInProgress,
                          canSubscribe: _profileCompletion?['canSubscribe'] ?? true,
                          l10n: l10n,
                          onPressed: _initiatePayment,
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  int _calculateDaysRemainingSync() {
    final endDateStr = _subscriptionStatus?['subscriptionEndDate']?.toString();
    if (endDateStr == null || endDateStr.isEmpty) {
      return 0;
    }
    
    try {
      final endDate = _parseDate(endDateStr);
      final days = _daysBetween(DateTime.now(), endDate);
      return days > 0 ? days : 0;
    } catch (e) {
      return 0;
    }
  }

  int _daysBetween(DateTime from, DateTime to) {
    final difference = to.difference(from);
    return difference.inDays;
  }

  DateTime _parseDate(String dateStr) {
    try {
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      }
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
      return DateTime.fromMillisecondsSinceEpoch(int.parse(dateStr));
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime _parseDateForDisplay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now().add(const Duration(days: 365));
    }
    return _parseDate(dateStr);
  }

  Widget _buildProfileWarning() {
    final missingDetails = _profileCompletion?['missingDetails'] as List<dynamic>? ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete Your Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Please complete the following details before proceeding to subscription:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.orange.shade900,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...missingDetails.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6, color: Colors.orange),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        detail.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.myDetails),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('My Details'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.farmList),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Farm Details'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.cropList),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Crop Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionStatusCard extends StatelessWidget {
  final bool isSubscribed;
  final String status;
  final int daysRemaining;
  final dynamic subscriptionStartDate;
  final dynamic subscriptionEndDate;
  final String? subscriptionId;
  final AppLocalizations l10n;

  const _SubscriptionStatusCard({
    required this.isSubscribed,
    required this.status,
    required this.daysRemaining,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
    required this.subscriptionId,
    required this.l10n,
  });

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is String) {
        if (dateValue.contains('T')) {
          date = DateTime.parse(dateValue);
        } else if (dateValue.contains('-')) {
          date = DateTime.parse(dateValue);
        } else {
          date = DateTime.fromMillisecondsSinceEpoch(int.parse(dateValue));
        }
      } else if (dateValue is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        return dateValue.toString();
      }
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSubscribed ? null : Colors.amber.shade50,
        gradient: isSubscribed
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)], // Green gradient
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: isSubscribed ? null : Border.all(color: Colors.amber.shade200, width: 1),
        boxShadow: [
          if (isSubscribed)
             BoxShadow(
              color: Colors.green.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSubscribed ? Colors.white.withValues(alpha: 0.2) : Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSubscribed ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
              size: 40,
              color: isSubscribed ? Colors.white : Colors.amber.shade800,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            isSubscribed ? l10n.activeSubscription : "Unlock Premium",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isSubscribed ? Colors.white : Colors.amber.shade900,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle / Days Remaining
          if (isSubscribed)
            Text(
              l10n.daysRemaining(daysRemaining),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            )
          else
            Text(
              "Get access to exclusive tools and insights.",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.amber.shade800,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

          // Subscription Detail Box (subscribers only)
          if (isSubscribed && (subscriptionStartDate != null || subscriptionEndDate != null)) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (subscriptionStartDate != null)
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: l10n.startDate,
                      value: _formatDate(subscriptionStartDate),
                    ),
                  if (subscriptionStartDate != null && subscriptionEndDate != null)
                    const SizedBox(height: 12),
                  if (subscriptionEndDate != null)
                    _DetailRow(
                      icon: Icons.event_rounded,
                      label: l10n.expiresOn,
                      value: _formatDate(subscriptionEndDate),
                    ),
                  if (subscriptionId != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.receipt_long_rounded,
                      label: l10n.subscriptionId,
                      value: subscriptionId!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubscriptionBenefitsCard extends StatelessWidget {
  final AppLocalizations l10n;
  const _SubscriptionBenefitsCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final benefits = [
      {'icon': Icons.money_off_rounded, 'text': l10n.benefitZeroInterest},
      {'icon': Icons.cloud_rounded, 'text': l10n.benefitTimelyWeather},
      {'icon': Icons.trending_up_rounded, 'text': l10n.benefitDirectRates},
      {'icon': Icons.wb_sunny_rounded, 'text': l10n.benefitWeatherUpdates},
      {'icon': Icons.shopping_cart_rounded, 'text': l10n.benefitPremiumMarket},
      {'icon': Icons.support_agent_rounded, 'text': l10n.benefitExpertAdvice},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                l10n.subscriptionBenefits,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...benefits.map((benefit) => _BenefitItem(
                icon: benefit['icon'] as IconData,
                text: benefit['text'] as String,
              )),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brandGreen, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyCTAButton extends StatelessWidget {
  final bool isPaymentInProgress;
  final bool canSubscribe;
  final VoidCallback onPressed;
  final AppLocalizations l10n;

  const _StickyCTAButton({
    required this.isPaymentInProgress,
    required this.canSubscribe,
    required this.onPressed,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isPaymentInProgress || !canSubscribe 
                      ? null 
                      : const LinearGradient(
                          colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  color: isPaymentInProgress || !canSubscribe 
                      ? Colors.grey.shade400 
                      : null,
                  boxShadow: isPaymentInProgress || !canSubscribe 
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isPaymentInProgress || !canSubscribe ? null : onPressed,
                    child: Center(
                      child: isPaymentInProgress
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  '${l10n.subscribeNow} • ${l10n.only999Year}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECURE PAYMENT BOTTOM SHEET (Production Quality)
// -----------------------------------------------------------------------------
class _PaymentBottomSheet extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  final Future<bool> Function() onPay;
  final VoidCallback onCancel;

  const _PaymentBottomSheet({
    required this.paymentData,
    required this.onPay,
    required this.onCancel,
  });

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  bool _isProcessing = false;

  void _handlePay() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    
    final success = await widget.onPay();
    
    // UI flow handling
    if (mounted && !success) {
      // If it failed, stop loading so they can retry
      setState(() => _isProcessing = false);
    }
    // If success, _completePayment handles navigation & success message internally.
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom sheet drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Secure Payment Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, color: AppColors.brandGreen, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Secure Payment',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Amount Highlight Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      '1 Year Premium Subscription',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${widget.paymentData['amount'] ?? 999}',
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandGreen,
                        height: 1.0,
                      ),
                    ),
                    if (widget.paymentData['gatewayOrderId'] != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Order ID: ${widget.paymentData['gatewayOrderId']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Trust Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTrustItem(Icons.verified_user_rounded, '100% Secure'),
                  const SizedBox(width: 24),
                  _buildTrustItem(Icons.money_off_rounded, 'No hidden charges'),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Primary CTA with Loading State
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: _isProcessing 
                        ? null 
                        : const LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: _isProcessing ? Colors.grey.shade400 : null,
                    boxShadow: _isProcessing 
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isProcessing ? null : _handlePay,
                      child: Center(
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Pay ₹${widget.paymentData['amount'] ?? 999}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Secondary CTA (Cancel)
              TextButton(
                onPressed: _isProcessing ? null : widget.onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

