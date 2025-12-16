import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  // Default language is English
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  // 1. Load saved language when app starts
  Future<void> loadSavedLocale() async {
    final String? savedCode = await StorageService.getLanguage();
    if (savedCode != null) {
      _locale = Locale(savedCode);
      notifyListeners(); // Updates the UI
    }
  }

  // 2. Change Language (Call this from Language Selection Screen)
  void setLocale(Locale locale) {
    if (!['en', 'hi', 'mr'].contains(locale.languageCode)) return;
    
    _locale = locale;
    StorageService.saveLanguage(locale.languageCode); // Save to phone memory
    notifyListeners(); // Trigger App Rebuild
  }
}