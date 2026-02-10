import 'package:flutter/material.dart';
import '../models/theme.dart';

class ThemeProvider with ChangeNotifier {
  WiiGCTheme _currentTheme = WiiGCTheme.getTheme(WiiGCThemePreset.wiiClassic);

  WiiGCTheme get currentTheme => _currentTheme;

  void setTheme(WiiGCThemePreset preset) {
    _currentTheme = WiiGCTheme.getTheme(preset);
    notifyListeners();
  }

  void updateTheme(WiiGCTheme newTheme) {
    _currentTheme = newTheme;
    notifyListeners();
  }
}
