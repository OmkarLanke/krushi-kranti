import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ✅ Use the generated package import (Standard Flutter way)
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../subscription/widgets/subscription_guard.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../subscription/services/subscription_service.dart';
import '../../dashboard/services/notification_service.dart';
import '../../../core/services/deep_link_service.dart';

// --- IMPORT YOUR TABS ---
import 'home_screen.dart';
import 'profile_screen.dart';
// import '../../finance/screens/finance_screen.dart'; // Finance placeholder for now
// import '../../crop_management/screens/crop_list_screen.dart'; // Keep commented until Crop List is built

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _notificationSubscription;
  final Set<String> _shownNotificationIds = {}; // Track which notifications we've shown

  // --- LIST OF SCREENS ---
  // The order must match the BottomNavigationBar items below
  late final List<Widget> _screens = [
    const HomeScreen(),
    Builder(
      builder: (context) => Center(
        child: Text(AppLocalizations.of(context)!.taskScreenComingSoon),
      ),
    ),
    Builder(
      builder: (context) => Center(
        child: Text(AppLocalizations.of(context)!.sellScreenComingSoon),
      ),
    ),
    Builder(
      builder: (context) => Center(
        child: Text(AppLocalizations.of(context)!.financeScreenComingSoon),
      ),
    ),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _setupGlobalNotificationListener();
    // Start polling for notifications
    _notificationService.startPolling(interval: const Duration(seconds: 10));
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationService.stopPolling();
    super.dispose();
  }

  /// Setup global notification listener to show OTP notifications on all screens
  void _setupGlobalNotificationListener() {
    // Listen to notification stream
    _notificationSubscription = _notificationService.notificationStream.listen(
      (notification) {
        if (notification.type == 'FARM_VERIFICATION_OTP') {
          final now = DateTime.now();
          final age = now.difference(notification.timestamp);
          
          // Only show if notification is recent (within 10 minutes) and not already shown
          if (age < const Duration(minutes: 10) && 
              !_shownNotificationIds.contains(notification.id)) {
            _showGlobalOtpNotification(notification);
            _shownNotificationIds.add(notification.id);
          }
        }
      },
    );

    // Also check for new notifications when service notifies listeners
    _notificationService.addListener(_onNotificationServiceChanged);
    
    // Check for any existing notifications that haven't been shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newNotifications = _notificationService.newOtpNotificationsForPopup;
      for (var notification in newNotifications) {
        if (!_shownNotificationIds.contains(notification.id)) {
          _showGlobalOtpNotification(notification);
          _shownNotificationIds.add(notification.id);
        }
      }
      if (newNotifications.isNotEmpty) {
        _notificationService.markPopupShownForNotifications(newNotifications);
      }
    });
  }

  void _onNotificationServiceChanged() {
    // Check for new OTP notifications when service updates
    final newNotifications = _notificationService.newOtpNotificationsForPopup;
    for (var notification in newNotifications) {
      if (!_shownNotificationIds.contains(notification.id)) {
        _showGlobalOtpNotification(notification);
        _shownNotificationIds.add(notification.id);
      }
    }
    if (newNotifications.isNotEmpty) {
      _notificationService.markPopupShownForNotifications(newNotifications);
    }
  }

  /// Show global OTP notification using navigator key (works on all screens)
  void _showGlobalOtpNotification(NotificationModel notification) {
    final navigatorContext = DeepLinkService.navigatorKey.currentContext;
    if (navigatorContext == null) return;

    ScaffoldMessenger.of(navigatorContext).showSnackBar(
      SnackBar(
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'You will get the OTP. Please check it at notification',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        backgroundColor: AppColors.brandGreen,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<bool>(
      future: _checkSubscriptionStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.brandGreen),
            ),
          );
        }

        final isSubscribed = snapshot.data ?? false;
        final body = _screens[_currentIndex];

        return Scaffold(
          body: body,
          bottomNavigationBar: _buildModernBottomNavBar(l10n, isSubscribed),
        );
      },
    );
  }

  Widget _buildModernBottomNavBar(AppLocalizations l10n, bool isSubscribed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: l10n.home, 
                index: 0,
                isSubscribed: isSubscribed,
                isPremium: false,
              ),
              _buildNavItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment_rounded,
                label: l10n.task, 
                index: 1,
                isSubscribed: isSubscribed,
                isPremium: true,
              ),
              _buildCenterSellButton(l10n),
              _buildNavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: l10n.finance,
                index: 3,
                isSubscribed: isSubscribed,
                isPremium: true,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: l10n.accountTab,
                index: 4,
                isSubscribed: isSubscribed,
                isPremium: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSubscribed,
    required bool isPremium,
  }) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Premium tabs: show friendly upgrade dialog for free users
            if (isPremium && !isSubscribed) {
              await showSubscriptionRequiredDialog(
                context,
                featureName: label,
              );
              return;
            }
            _onItemTapped(index);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandGreen.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? activeIcon : icon,
                        color: isSelected
                            ? AppColors.brandGreen
                            : Colors.grey.shade600,
                        size: 22,
                      ),
                      if (isPremium && !isSubscribed)
                        const Positioned(
                          right: -2,
                          top: -2,
                          child: Icon(
                            Icons.lock,
                            size: 12,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.brandGreen
                          : Colors.grey.shade600,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterSellButton(AppLocalizations l10n) {
    final isSelected = _currentIndex == 2;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(2),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? [
                              AppColors.brandGreen,
                              AppColors.brandGreen.withOpacity(0.8),
                            ]
                          : [
                              AppColors.brandGreen.withOpacity(0.7),
                              AppColors.brandGreen.withOpacity(0.5),
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.brandGreen.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
              ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    l10n.sell,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.brandGreen
                          : Colors.grey.shade600,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}