import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _useDynamicColors = true;
  ThemeMode _themeMode = ThemeMode.system;

  bool get useDynamicColors => _useDynamicColors;
  ThemeMode get themeMode => _themeMode;

  void setUseDynamicColors(bool value) {
    _useDynamicColors = value;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Locale? _manualLocale;
  Locale get locale => _manualLocale ?? WidgetsBinding.instance.platformDispatcher.locale;
  bool get isSystemLocale => _manualLocale == null;

  // Constructor: Al crear el Provider, cargamos las preferencias guardadas
  ThemeProvider() {
    _loadPreferences();
  }

  // Función privada para cargar el idioma al iniciar
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lang = prefs.getString('language_code');
    final String? country = prefs.getString('country_code'); // Nuevo
    
    if (lang != null) {
      _manualLocale = Locale(lang, country == "" ? null : country);
      notifyListeners();
    }
  }

  // Actualiza el idioma y lo guarda en memoria
  Future<void> setLocale(Locale? newLocale) async {
    _manualLocale = newLocale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    if (newLocale == null) {
      // Si es null, borramos para volver al sistema
      await prefs.remove('language_code');
      await prefs.remove('country_code');
    } else {
      await prefs.setString('language_code', newLocale.languageCode);
      await prefs.setString('country_code', newLocale.countryCode ?? "");
    }
  }
}
