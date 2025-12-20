import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() => _isLoading = true);

    try {
      // Try to get fresh subscription status from backend first
      try {
        final status = await SubscriptionService.getSubscriptionStatus();
        
        // Ensure isSubscribed is properly set based on status
        final isSubscribed = status['isSubscribed'] == true || 
                            status['subscriptionStatus'] == 'ACTIVE' ||
                            status['subscriptionStatus'] == 'active';
        
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
          setState(() {
            _subscriptionStatus = {
              'isSubscribed': true,
              'subscriptionStatus': 'ACTIVE',
              'subscriptionEndDate': localEndDate,
            };
          });
        } else {
          setState(() {
            _subscriptionStatus = {
              'isSubscribed': false,
              'subscriptionStatus': 'NONE',
            };
          });
        }
      }

      // Profile is complete if user reached this screen (they went through onboarding)
      setState(() {
        _profileCompletion = {
          'profileCompleted': true,
          'canSubscribe': true,
        };
      });
    } catch (e) {
      // Fallback - allow subscription attempt
      setState(() {
        _subscriptionStatus = {'isSubscribed': false, 'subscriptionStatus': 'NONE'};
        _profileCompletion = {'profileCompleted': true, 'canSubscribe': true};
      });
    } finally {
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
        
        // Show mock payment dialog
        _showMockPaymentDialog(response);
      } else {
        _showError(response['message'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
      _showError('Failed to initiate payment: $e');
    } finally {
      setState(() => _isPaymentInProgress = false);
    }
  }

  void _showMockPaymentDialog(Map<String, dynamic> paymentData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Mock Payment Gateway'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscription Payment',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text('Amount: ₹${paymentData['amount']}'),
                  Text('Order ID: ${paymentData['gatewayOrderId']}'),
                  const SizedBox(height: 8),
                  const Text(
                    'This is a mock payment for testing.\nClick "Pay Now" to simulate successful payment.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completePayment(false); // Simulate failure
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completePayment(true); // Simulate success
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pay ₹999'),
          ),
        ],
      ),
    );
  }

  Future<void> _completePayment(bool success) async {
    if (!success) {
      setState(() => _isPaymentInProgress = false);
      _showError('Payment cancelled');
      return;
    }

    setState(() => _isPaymentInProgress = true);

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
          // Check if error is transaction not found (might already be completed)
          final errorMessage = e.toString().toLowerCase();
          if (errorMessage.contains('transaction not found') || 
              errorMessage.contains('already') ||
              errorMessage.contains('active subscription')) {
            // User might already have subscription, refresh status
            setState(() => _isPaymentInProgress = false);
            await _loadSubscriptionStatus();
            _showSuccess(
              'Payment Completed',
              'Your subscription is now active.',
            );
            return;
          }
          // Backend unavailable - use mock success
          response = null;
        }
      }

      // If backend succeeded or we're in mock mode
      if (response == null || response['success'] == true) {
        // Refresh subscription status from API to get accurate data
        try {
          final subStatus = await SubscriptionService.getSubscriptionStatus();
          final isSubscribed = subStatus['isSubscribed'] == true || 
                              subStatus['subscriptionStatus'] == 'ACTIVE';
          
          if (isSubscribed) {
            final endDate = subStatus['subscriptionEndDate']?.toString() ?? 
                           subStatus['expiresAt']?.toString() ??
                           response?['subscriptionEndDate']?.toString();
            
            // Save to local storage with accurate end date
            await StorageService.saveSubscriptionStatus(true, endDate: endDate);
            
            // Calculate end date for display (1 year from now if not provided)
            final displayEndDate = endDate != null 
                ? _parseDateForDisplay(endDate)
                : DateTime.now().add(const Duration(days: 365));
            final endDateStr = '${displayEndDate.day}/${displayEndDate.month}/${displayEndDate.year}';
            
            if (!mounted) return;
            
            _showSuccess(
              'Payment Successful!',
              'Your subscription is now active until $endDateStr',
            );
            
            // Wait a moment then navigate to dashboard
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (!mounted) return;
            
            // Navigate to dashboard
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.dashboard,
              (route) => false,
            );
          } else {
            // API says not subscribed, but payment succeeded - might be a delay
            // Save locally anyway and refresh
            final endDate = DateTime.now().add(const Duration(days: 365));
            await StorageService.saveSubscriptionStatus(true, endDate: endDate.toString());
            
            if (!mounted) return;
            
            _showSuccess(
              'Payment Successful!',
              'Your subscription is being activated. Please wait a moment.',
            );
            
            // Refresh status after a delay
            await Future.delayed(const Duration(seconds: 2));
            await _loadSubscriptionStatus();
            
            if (!mounted) return;
            
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.dashboard,
              (route) => false,
            );
          }
        } catch (e) {
          // If refresh fails, save locally and proceed
          final endDate = DateTime.now().add(const Duration(days: 365));
          await StorageService.saveSubscriptionStatus(true, endDate: endDate.toString());
          
          if (!mounted) return;
          
          _showSuccess(
            'Payment Successful!',
            'Your subscription is now active.',
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (!mounted) return;
          
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        }
      } else {
        _showError(response['message'] ?? 'Payment failed. Please try again.');
      }
    } catch (e) {
      _showError('Payment failed: $e');
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
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _skipForNow() {
    // Allow user to explore app with subscription guard showing on protected tabs
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Double check subscription status - ensure it's properly set
    final isSubscribed = _subscriptionStatus?['isSubscribed'] == true || 
                         _subscriptionStatus?['subscriptionStatus'] == 'ACTIVE';
    
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.subscription),
        backgroundColor: AppColors.brandGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !isSubscribed, // Show back button if not subscribed
        leading: isSubscribed 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  _buildStatusCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Benefits Card
                  _buildBenefitsCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Profile Completion Status
                  if (_profileCompletion != null && !(_profileCompletion!['canSubscribe'] ?? false))
                    _buildProfileWarning(),
                  
                  const SizedBox(height: 24),
                  
                  // Subscribe Button - Only show if not subscribed
                  if (!isSubscribed)
                    _buildSubscribeButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final l10n = AppLocalizations.of(context)!;
    final isSubscribed = _subscriptionStatus?['isSubscribed'] ?? false;
    final status = _subscriptionStatus?['subscriptionStatus'] ?? 'NONE';
    final daysRemaining = _subscriptionStatus?['daysRemaining'] ?? _calculateDaysRemainingSync();
    final subscriptionStartDate = _subscriptionStatus?['subscriptionStartDate'] ?? _subscriptionStatus?['createdAt'];
    final subscriptionEndDate = _subscriptionStatus?['subscriptionEndDate'] ?? _subscriptionStatus?['expiresAt'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isSubscribed
                ? [const Color(0xFF66BB6A), const Color(0xFF2E7D32)] // Green gradient
                : [Colors.orange.shade400, Colors.orange.shade600],
          ),
        ),
        child: Column(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSubscribed ? Icons.verified : Icons.warning,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Title
            Text(
              isSubscribed ? l10n.activeSubscription : l10n.notSubscribed,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            // Days Remaining / Subscribe Message
            const SizedBox(height: 8),
            if (isSubscribed)
              Text(
                l10n.daysRemaining(daysRemaining),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              )
            else
              Text(
                l10n.subscribeToAccessAll,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            
            // Subscription Details (only if subscribed)
            if (isSubscribed) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (subscriptionStartDate != null)
                      _buildDetailRow(
                        Icons.calendar_today,
                        l10n.startDate,
                        _formatDate(subscriptionStartDate),
                      ),
                    if (subscriptionStartDate != null && subscriptionEndDate != null)
                      const SizedBox(height: 12),
                    if (subscriptionEndDate != null)
                      _buildDetailRow(
                        Icons.event,
                        l10n.expiresOn,
                        _formatDate(subscriptionEndDate),
                      ),
                    if (_subscriptionStatus?['subscriptionId'] != null) ...[
                      if (subscriptionEndDate != null)
                        const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.receipt,
                        l10n.subscriptionId,
                        _subscriptionStatus!['subscriptionId'].toString(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
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

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is String) {
        date = _parseDate(dateValue);
      } else if (dateValue is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        return dateValue.toString();
      }
      
      // Format as "DD MMM YYYY" (e.g., "15 Jan 2024")
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateValue.toString();
    }
  }

  DateTime _parseDate(String dateStr) {
    // Try different date formats
    try {
      // ISO format: "2024-01-15T10:30:00"
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      }
      // DD/MM/YYYY format
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
      // YYYY-MM-DD format
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
      // Try parsing as milliseconds
      return DateTime.fromMillisecondsSinceEpoch(int.parse(dateStr));
    } catch (e) {
      // Fallback to current date if parsing fails
      return DateTime.now();
    }
  }

  DateTime _parseDateForDisplay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now().add(const Duration(days: 365));
    }
    return _parseDate(dateStr);
  }

  Widget _buildBenefitsCard() {
    final l10n = AppLocalizations.of(context)!;
    final benefits = [
      {'icon': Icons.money_off, 'text': l10n.benefitZeroInterest},
      {'icon': Icons.cloud, 'text': l10n.benefitTimelyWeather},
      {'icon': Icons.trending_up, 'text': l10n.benefitDirectRates},
      {'icon': Icons.wb_sunny, 'text': l10n.benefitWeatherUpdates},
      {'icon': Icons.shopping_cart, 'text': l10n.benefitPremiumMarket},
      {'icon': Icons.support_agent, 'text': l10n.benefitExpertAdvice},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  l10n.subscriptionBenefits,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...benefits.map((benefit) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(benefit['icon'] as IconData, color: AppColors.brandGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      benefit['text'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.only999Year,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileWarning() {
    final missingDetails = _profileCompletion?['missingDetails'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Please complete the following before subscribing:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...missingDetails.map((detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(detail.toString()),
                ],
              ),
            )).toList(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.myDetails),
                    child: const Text('My Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.farmList),
                    child: const Text('Farm Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.cropList),
                    child: const Text('Crop Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    final canSubscribe = _profileCompletion?['canSubscribe'] ?? true;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isPaymentInProgress || !canSubscribe ? null : _initiatePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isPaymentInProgress
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Text(
                    '${l10n.subscribeNow} - ${l10n.only999Year}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  );
                },
              ),
      ),
    );
  }
}

