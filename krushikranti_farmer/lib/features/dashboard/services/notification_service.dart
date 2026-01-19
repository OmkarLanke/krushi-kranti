import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/services/http_service.dart';
import '../../../core/services/storage_service.dart';

/// Notification model for OTP and other notifications
class NotificationModel {
  final String id;
  final String type; // e.g., 'FARM_VERIFICATION_OTP'
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Contains OTP, farmId, etc.
  final DateTime timestamp;
  final bool isRead;
  final int? recipientUserId; // User ID this notification is intended for

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.timestamp,
    this.isRead = false,
    this.recipientUserId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Parse data field - it might be a string (JSON) or already a Map
    Map<String, dynamic>? dataMap;
    if (json['data'] != null) {
      if (json['data'] is String) {
        try {
          dataMap = jsonDecode(json['data'] as String) as Map<String, dynamic>;
        } catch (e) {
          // If parsing fails, set to null
          dataMap = null;
        }
      } else if (json['data'] is Map) {
        dataMap = json['data'] as Map<String, dynamic>;
      }
    }

    // Parse timestamp - handle ISO string, DateTime, or array format [year, month, day, hour, minute, second, nanosecond]
    DateTime timestamp;
    if (json['createdAt'] != null) {
      final createdAtValue = json['createdAt'];
      if (createdAtValue is String) {
        timestamp = DateTime.parse(createdAtValue);
      } else if (createdAtValue is List && createdAtValue.length >= 6) {
        // Handle array format: [year, month, day, hour, minute, second, nanosecond?]
        try {
          timestamp = DateTime(
            createdAtValue[0] as int,  // year
            createdAtValue[1] as int,  // month
            createdAtValue[2] as int,  // day
            createdAtValue[3] as int,  // hour
            createdAtValue[4] as int,  // minute
            createdAtValue[5] as int,  // second
            createdAtValue.length > 6 ? (createdAtValue[6] as int) ~/ 1000000 : 0, // nanoseconds to milliseconds
          );
        } catch (e) {
          debugPrint('Error parsing createdAt array: $e');
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }
    } else if (json['timestamp'] != null) {
      final timestampValue = json['timestamp'];
      if (timestampValue is String) {
        timestamp = DateTime.parse(timestampValue);
      } else if (timestampValue is List && timestampValue.length >= 6) {
        try {
          timestamp = DateTime(
            timestampValue[0] as int,
            timestampValue[1] as int,
            timestampValue[2] as int,
            timestampValue[3] as int,
            timestampValue[4] as int,
            timestampValue[5] as int,
            timestampValue.length > 6 ? (timestampValue[6] as int) ~/ 1000000 : 0,
          );
        } catch (e) {
          debugPrint('Error parsing timestamp array: $e');
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }
    } else {
      timestamp = DateTime.now();
    }

    return NotificationModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['eventType'] ?? json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: dataMap,
      timestamp: timestamp,
      recipientUserId: json['recipientUserId'] != null 
          ? (json['recipientUserId'] is int 
              ? json['recipientUserId'] as int 
              : int.tryParse(json['recipientUserId'].toString()))
          : null,
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

/// Service for managing notifications
/// Now integrated with notification-service backend API
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationModel> _notifications = [];
  final StreamController<NotificationModel> _notificationStreamController =
      StreamController<NotificationModel>.broadcast();
  final Set<String> _popupShownNotificationIds = {};
  
  Timer? _pollingTimer;
  bool _isPolling = false;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  Stream<NotificationModel> get notificationStream =>
      _notificationStreamController.stream;

  /// Get unread OTP notifications that are not expired (within 10 minutes)
  List<NotificationModel> get otpNotifications {
    final now = DateTime.now();
    const otpExpirationDuration = Duration(minutes: 10);
    
    return _notifications
        .where((n) {
          if (n.type != 'FARM_VERIFICATION_OTP' || n.isRead) {
            return false;
          }
          // Check if notification is expired (older than 10 minutes)
          final age = now.difference(n.timestamp);
          return age < otpExpirationDuration;
        })
        .toList();
  }

  /// Get all OTP notifications (read and unread) that are not expired
  List<NotificationModel> get allOtpNotifications {
    final now = DateTime.now();
    const otpExpirationDuration = Duration(minutes: 10);
    
    return _notifications
        .where((n) {
          if (n.type != 'FARM_VERIFICATION_OTP') {
            return false;
          }
          // Check if notification is expired (older than 10 minutes)
          final age = now.difference(n.timestamp);
          return age < otpExpirationDuration;
        })
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first
  }

  /// Get OTP notifications for which popup has not been shown yet
  List<NotificationModel> get newOtpNotificationsForPopup {
    final now = DateTime.now();
    const otpExpirationDuration = Duration(minutes: 10);
    
    return _notifications
        .where((n) {
          if (n.type != 'FARM_VERIFICATION_OTP') {
            return false;
          }
          if (_popupShownNotificationIds.contains(n.id)) {
            return false;
          }
          final age = now.difference(n.timestamp);
          return age < otpExpirationDuration;
        })
        .toList();
  }

  void markPopupShownForNotifications(List<NotificationModel> notifications) {
    for (var n in notifications) {
      _popupShownNotificationIds.add(n.id);
    }
  }

  /// Get count of unread OTP notifications (for badge display)
  int get unreadOtpNotificationsCount {
    return otpNotifications.length;
  }
  
  /// Remove expired OTP notifications (older than 10 minutes)
  void removeExpiredOtpNotifications() {
    final now = DateTime.now();
    const otpExpirationDuration = Duration(minutes: 10);
    
    final initialCount = _notifications.length;
    _notifications.removeWhere((n) {
      if (n.type == 'FARM_VERIFICATION_OTP') {
        final age = now.difference(n.timestamp);
        if (age >= otpExpirationDuration) {
          debugPrint('Removing expired OTP notification: ID=${n.id}, Age=${age.inMinutes} minutes');
          return true;
        }
      }
      return false;
    });
    
    final removedCount = initialCount - _notifications.length;
    if (removedCount > 0) {
      debugPrint('Removed $removedCount expired OTP notification(s)');
      notifyListeners();
    }
  }

  /// Start polling for notifications from backend
  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    if (_isPolling) return;
    
    _isPolling = true;
    // Fetch immediately
    fetchNotifications();
    
    // Then poll periodically
    _pollingTimer = Timer.periodic(interval, (_) {
      fetchNotifications();
    });
  }

  /// Stop polling for notifications
  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Fetch notifications from backend API
  Future<void> fetchNotifications() async {
    try {
      final userId = await StorageService.getUserId();
      final token = await StorageService.getToken();
      debugPrint('=== FETCHING NOTIFICATIONS ===');
      debugPrint('User ID from storage: $userId');
      debugPrint('Token exists: ${token != null && token.isNotEmpty}');
      debugPrint('Token length: ${token?.length ?? 0}');
      
      if (userId == null || userId.isEmpty) {
        debugPrint('User ID is null or empty - skipping notification fetch');
        return; // User not logged in
      }

      if (token == null || token.isEmpty) {
        debugPrint('Token is missing - cannot fetch notifications. User needs to login again.');
        return; // Token missing - user needs to login
      }

      debugPrint('Calling API: notification/unread/FARM_VERIFICATION_OTP');
      final response = await HttpService.get(
        'notification/unread/FARM_VERIFICATION_OTP',
      );

      debugPrint('=== NOTIFICATION API RESPONSE ===');
      debugPrint('Response type: ${response.runtimeType}');
      debugPrint('Response: $response');

      if (response is Map && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final notificationsList = data?['notifications'] as List<dynamic>? ?? [];
        
        debugPrint('Notifications count from API: ${notificationsList.length}');

        // Convert backend notifications to NotificationModel
        final fetchedNotifications = notificationsList
            .map((json) {
              try {
                return NotificationModel.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                debugPrint('Error parsing notification JSON: $e, JSON: $json');
                return null;
              }
            })
            .whereType<NotificationModel>()
            .toList();

        debugPrint('Parsed notifications count: ${fetchedNotifications.length}');

        // CRITICAL: The backend should filter by X-User-Id header, but we'll add client-side filter as safeguard
        debugPrint('Fetched notifications for User ID: $userId (string)');
        
        // Convert userId string to int for comparison
        final userIdInt = int.tryParse(userId);
        debugPrint('Parsed User ID as int: $userIdInt');
        
        // Additional client-side safeguard: Filter notifications to ensure they belong to current user
        // This prevents cross-user data leakage if backend filtering fails
        final userSpecificNotifications = fetchedNotifications
            .where((n) {
              // If recipientUserId is null, allow it (backward compatibility)
              if (n.recipientUserId == null) {
                debugPrint('Notification ${n.id}: recipientUserId is null - ALLOWING (backward compatibility)');
                return true;
              }
              // If userIdInt is null (parsing failed), don't filter (show all)
              if (userIdInt == null) {
                debugPrint('WARNING: Could not parse userId as int: $userId - ALLOWING ALL notifications');
                return true;
              }
              // Compare int to int
              final matches = n.recipientUserId == userIdInt;
              if (!matches) {
                debugPrint('Notification ${n.id}: recipientUserId (${n.recipientUserId}) != userId ($userIdInt) - FILTERING OUT');
              } else {
                debugPrint('Notification ${n.id}: recipientUserId (${n.recipientUserId}) == userId ($userIdInt) - ALLOWING');
              }
              return matches;
            })
            .toList();
        
        if (userSpecificNotifications.length != fetchedNotifications.length) {
          debugPrint('WARNING: Filtered out ${fetchedNotifications.length - userSpecificNotifications.length} notifications that did not match User ID: $userId');
        } else {
          debugPrint('All ${fetchedNotifications.length} notifications match User ID: $userId');
        }
        
        for (var notification in userSpecificNotifications) {
          debugPrint('Notification - ID: ${notification.id}, RecipientUserId: ${notification.recipientUserId}, OTP: ${notification.data?['otp']}, FarmId: ${notification.data?['farmId']}');
        }

        // Filter out expired OTP notifications immediately when fetched
        final now = DateTime.now();
        const otpExpirationDuration = Duration(minutes: 10);
        final validNotifications = userSpecificNotifications.where((n) {
          // For OTP notifications, check if they're expired
          if (n.type == 'FARM_VERIFICATION_OTP') {
            final age = now.difference(n.timestamp);
            if (age >= otpExpirationDuration) {
              debugPrint('Skipping expired OTP notification: ID=${n.id}, Age=${age.inMinutes} minutes');
              return false;
            }
          }
          return true;
        }).toList();
        
        debugPrint('Valid (non-expired) notifications count: ${validNotifications.length}');

        // Update local notifications - merge with existing, avoiding duplicates
        // Also update existing notifications if they're in the fetched list (to sync isRead status)
        final existingIds = _notifications.map((n) => n.id).toSet();
        final newNotifications = validNotifications
            .where((n) => !existingIds.contains(n.id))
            .toList();
        
        // Update existing notifications that were fetched (to sync any changes from backend)
        for (var fetchedNotification in validNotifications) {
          final existingIndex = _notifications.indexWhere((n) => n.id == fetchedNotification.id);
          if (existingIndex != -1) {
            // Update existing notification to sync with backend (especially isRead status)
            _notifications[existingIndex] = fetchedNotification;
            debugPrint('Updated existing notification: ID=${fetchedNotification.id}, isRead=${fetchedNotification.isRead}');
          }
        }

        debugPrint('New notifications count: ${newNotifications.length}');
        debugPrint('Total notifications in list: ${_notifications.length}');

        // Remove expired OTPs before adding new ones to ensure clean state
        removeExpiredOtpNotifications();
        
        if (newNotifications.isNotEmpty) {
          _notifications.insertAll(0, newNotifications);
          for (var notification in newNotifications) {
            debugPrint('Adding notification: ID=${notification.id}, Type=${notification.type}, OTP=${notification.data?['otp']}, FarmId=${notification.data?['farmId']}, isRead=${notification.isRead}, Age=${now.difference(notification.timestamp).inMinutes} minutes');
            _notificationStreamController.add(notification);
          }
          notifyListeners();
          debugPrint('Notifications updated and listeners notified');
        } else {
          debugPrint('No new notifications to add (but may have updated existing ones)');
          // Still notify listeners in case existing notifications were updated
          notifyListeners();
        }
      } else {
        debugPrint('API response indicates failure or unexpected format');
        debugPrint('Success field: ${response is Map ? response['success'] : 'N/A'}');
        debugPrint('Message: ${response is Map ? response['message'] : 'N/A'}');
      }
    } catch (e, stackTrace) {
      debugPrint('=== ERROR FETCHING NOTIFICATIONS ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      // Silently fail - don't disrupt user experience
    }
  }

  /// Fetch all notifications (not just unread)
  Future<void> fetchAllNotifications({int page = 0, int size = 20}) async {
    try {
      final userId = await StorageService.getUserId();
      if (userId == null || userId.isEmpty) {
        return;
      }

      final response = await HttpService.get(
        'notification?page=$page&size=$size',
      );

      if (response is Map && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final notificationsList = data?['notifications'] as List<dynamic>? ?? [];

        final fetchedNotifications = notificationsList
            .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (page == 0) {
          // First page - replace all
          _notifications.clear();
          _notifications.addAll(fetchedNotifications);
        } else {
          // Subsequent pages - append
          _notifications.addAll(fetchedNotifications);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching all notifications: $e');
    }
  }

  /// Add a new notification (for local use)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    _notificationStreamController.add(notification);
    notifyListeners();
  }

  /// Mark notification as read on backend and locally
  Future<void> markAsRead(String notificationId) async {
    try {
      // Update locally first for immediate UI feedback
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          data: _notifications[index].data,
          timestamp: _notifications[index].timestamp,
          isRead: true,
          recipientUserId: _notifications[index].recipientUserId,
        );
        notifyListeners();
      }

      // Update on backend
      await HttpService.put(
        'notification/$notificationId/read',
        {},
      );
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      // Revert local change if backend update fails
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          data: _notifications[index].data,
          timestamp: _notifications[index].timestamp,
          isRead: false,
          recipientUserId: _notifications[index].recipientUserId,
        );
        notifyListeners();
      }
    }
  }

  /// Remove a notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Clear all notifications when user logs out
  /// This ensures that notifications from one user are not visible to another user
  void clearOnLogout() {
    debugPrint('=== CLEARING NOTIFICATIONS ON LOGOUT ===');
    _notifications.clear();
    stopPolling();
    notifyListeners();
    debugPrint('All notifications cleared');
  }

  /// Filter existing notifications to ensure they belong to the current user
  /// This is a safeguard in case notifications from another user somehow got into the list
  Future<void> filterNotificationsByCurrentUser() async {
    try {
      final userIdStr = await StorageService.getUserId();
      if (userIdStr == null || userIdStr.isEmpty) {
        return;
      }
      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        return;
      }

      final initialCount = _notifications.length;
      _notifications.removeWhere((n) => 
        n.recipientUserId != null && n.recipientUserId != userId
      );
      
      final removedCount = initialCount - _notifications.length;
      if (removedCount > 0) {
        debugPrint('WARNING: Removed $removedCount notifications that did not belong to User ID: $userId');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error filtering notifications by current user: $e');
    }
  }

  @override
  void dispose() {
    stopPolling();
    _notificationStreamController.close();
    super.dispose();
  }
}
