import 'dart:async';
import 'package:flutter/foundation.dart';

/// Notification model for OTP and other notifications
class NotificationModel {
  final String id;
  final String type; // e.g., 'FARM_VERIFICATION_OTP'
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Contains OTP, farmId, etc.
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
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
/// TODO: Integrate with Kafka consumer when notification service is ready
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationModel> _notifications = [];
  final StreamController<NotificationModel> _notificationStreamController =
      StreamController<NotificationModel>.broadcast();

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  Stream<NotificationModel> get notificationStream =>
      _notificationStreamController.stream;

  /// Get unread OTP notifications
  List<NotificationModel> get otpNotifications => _notifications
      .where((n) =>
          n.type == 'FARM_VERIFICATION_OTP' && !n.isRead)
      .toList();

  /// Add a new notification
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    _notificationStreamController.add(notification);
    notifyListeners();
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
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
      );
      notifyListeners();
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

  /// Simulate receiving an OTP notification (for testing)
  /// TODO: Remove when Kafka consumer is integrated
  void simulateOtpNotification({
    required String otp,
    required int farmId,
    required String farmName,
    required String fieldOfficerName,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'FARM_VERIFICATION_OTP',
      title: 'Farm Verification OTP',
      message:
          'Field Officer $fieldOfficerName is verifying your farm "$farmName". Your OTP is: $otp',
      data: {
        'otp': otp,
        'farmId': farmId.toString(),
        'farmName': farmName,
        'fieldOfficerName': fieldOfficerName,
      },
      timestamp: DateTime.now(),
    );
    addNotification(notification);
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }
}
