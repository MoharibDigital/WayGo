import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('en');
  
  Locale get currentLocale => _currentLocale;
  
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
  ];
  
  static const Map<String, String> languageNames = {
    'en': 'English',
    'fr': 'Français',
  };
  
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }
  
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == _currentLocale.languageCode) return;
    
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }
  
  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }
}
