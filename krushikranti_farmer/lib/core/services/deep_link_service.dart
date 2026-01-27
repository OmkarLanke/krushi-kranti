import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../constants/app_routes.dart';

/// Service to handle deep links for the app.
/// Handles password reset links: krushikranti://reset-password?token=xxx
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  // Global navigator key to navigate from anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Initialize deep link handling
  Future<void> init() async {
    // Handle link when app is started from terminated state
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }

    // Handle incoming links when app is running (foreground/background)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  /// Parse and handle the deep link
  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');
    debugPrint('Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
    debugPrint('Query params: ${uri.queryParameters}');

    // Handle krushikranti://reset-password?token=xxx
    if (uri.scheme == 'krushikranti') {
      final path = uri.host.isNotEmpty ? uri.host : uri.path;
      
      if (path == 'reset-password') {
        final token = uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          _navigateToResetPassword(token);
        } else {
          debugPrint('No token found in reset-password link');
        }
      }
    }
  }

  /// Navigate to reset password screen with the token
  void _navigateToResetPassword(String token) {
    debugPrint('Navigating to reset password with token: $token');
    
    // Use the global navigator key to navigate
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      // Push the reset password screen, removing all previous routes
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.resetPassword,
        (route) => false,
        arguments: token,
      );
    } else {
      debugPrint('Navigator not available yet, will retry...');
      // Retry after a short delay if navigator isn't ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToResetPassword(token);
      });
    }
  }

  /// Dispose of the service
  void dispose() {
    _linkSubscription?.cancel();
  }
}
