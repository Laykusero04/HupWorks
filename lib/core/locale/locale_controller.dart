import 'package:flutter/material.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and notifies app UI locale changes.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static const _prefsKey = 'app_locale_code';

  /// Locales with ARB translations. Default is English (`en`).
  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl'),
    Locale('bn'),
  ];

  static const Locale defaultLocale = Locale('en');

  Locale _locale = defaultLocale;

  Locale get locale => _locale;

  static Future<LocaleController> create() async {
    final controller = LocaleController._();
    await controller._load();
    return controller;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null || code.isEmpty) return;
    for (final locale in supportedLocales) {
      if (locale.languageCode == code) {
        _locale = locale;
        return;
      }
    }
  }

  Future<void> setLocale(Locale locale) async {
    final supported =
        supportedLocales.any((l) => l.languageCode == locale.languageCode);
    if (!supported) return;
    if (_locale.languageCode == locale.languageCode) return;
    _locale = Locale(locale.languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _locale.languageCode);
  }

  bool isSelected(Locale locale) => _locale.languageCode == locale.languageCode;

  /// Localized label for the active (or given) locale code.
  static String displayName(AppLocalizations l10n, String languageCode) {
    switch (languageCode) {
      case 'nl':
        return l10n.languageDutch;
      case 'bn':
        return l10n.languageBengali;
      case 'en':
      default:
        return l10n.languageEnglish;
    }
  }
}
