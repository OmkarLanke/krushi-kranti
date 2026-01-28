import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<NotificationModel>? _notificationSubscription;
  Timer? _expiredNotificationCleanupTimer;
  Timer? _countdownTimer;
  VoidCallback? _notificationServiceListener;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
    // Mark all notifications as read after a short delay to ensure UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllNotificationsAsRead();
    });
    // Start countdown timer that updates every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Update UI every second for countdown
      }
    });
    // Start periodic cleanup of expired OTP notifications
    _expiredNotificationCleanupTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _notificationService.removeExpiredOtpNotifications();
        setState(() {}); // Refresh UI to remove expired notifications
      }
    });
  }

  Future<void> _markAllNotificationsAsRead() async {
    final unreadNotifications = _notificationService.otpNotifications;
    for (var notification in unreadNotifications) {
      try {
        await _notificationService.markAsRead(notification.id);
      } catch (e) {
        // Silently handle errors
        debugPrint('Error marking notification as read: $e');
      }
    }
  }

  void _setupNotificationListener() {
    _notificationSubscription = _notificationService.notificationStream.listen(
      (notification) {
        if (mounted && notification.type == 'FARM_VERIFICATION_OTP') {
          setState(() {}); // Refresh UI to show new notification
        }
      },
    );
    
    // Also listen to notification service changes
    _notificationServiceListener = () {
      if (mounted) {
        setState(() {}); // Refresh UI when notifications change
      }
    };
    _notificationService.addListener(_notificationServiceListener!);
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _expiredNotificationCleanupTimer?.cancel();
    _countdownTimer?.cancel();
    if (_notificationServiceListener != null) {
      _notificationService.removeListener(_notificationServiceListener!);
    }
    super.dispose();
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('dd MMM yyyy').format(timestamp);
    }
  }

  String _formatExpiryTime(DateTime timestamp) {
    final now = DateTime.now();
    final expiresAt = timestamp.add(const Duration(minutes: 10));
    final difference = expiresAt.difference(now);

    if (difference.inSeconds <= 0) {
      return 'Expired';
    }

    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final otpNotifications = _notificationService.allOtpNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandGreen,
                AppColors.brandGreen.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: otpNotifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: AppColors.brandGreen.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will receive OTP notifications here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _notificationService.fetchNotifications();
              },
              color: AppColors.brandGreen,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: otpNotifications.length,
                itemBuilder: (context, index) {
                  final notification = otpNotifications[index];
                  return _buildOtpNotificationCard(notification, l10n);
                },
              ),
            ),
    );
  }

  Widget _buildOtpNotificationCard(NotificationModel notification, AppLocalizations l10n) {
    final otp = notification.data?['otp']?.toString() ?? '000000';
    final fieldOfficerName = notification.data?['fieldOfficerName']?.toString() ?? 'Field Officer';
    final farmName = notification.data?['farmName']?.toString() ?? 'Farm';
    final expiresAt = notification.timestamp.add(const Duration(minutes: 10));
    final isExpired = DateTime.now().isAfter(expiresAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: AppColors.brandGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farm Verification OTP',
                        style: GoogleFonts.poppins(    
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fieldOfficerName is verifying "$farmName"',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTimeAgo(notification.timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!isExpired && !notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.brandGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // OTP Code Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF9800).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your OTP Code',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        otp,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFFFF9800), size: 24),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: otp));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('OTP copied to clipboard: $otp'),
                          backgroundColor: AppColors.brandGreen,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy OTP',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Expiry Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isExpired 
                    ? Colors.red.shade50 
                    : const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: isExpired ? Colors.red : const Color(0xFFFF9800),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isExpired 
                        ? 'Expired' 
                        : 'Expires in: ${_formatExpiryTime(notification.timestamp)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isExpired ? Colors.red : const Color(0xFFFF9800),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Instruction
            Text(
              'Please share this OTP with the field officer to complete verification.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
