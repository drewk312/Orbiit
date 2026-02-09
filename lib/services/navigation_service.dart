import 'package:flutter/material.dart';

/// Navigation Service - Global navigation state for the app
/// Allows any widget to trigger tab changes in NavigationWrapper
class NavigationService extends ChangeNotifier {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // Tab indices
  static const int home = 0;
  static const int discovery = 1; // "Store"
  static const int games = 2; // "Library"
  static const int downloads = 3;
  static const int homebrew = 4;
  static const int tools = 5;
  static const int settings = 6;

  /// Navigate to a specific tab by index
  void navigateTo(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Navigate to Home tab
  void goToHome() => navigateTo(home);

  /// Navigate to Discovery/Store tab
  void goToStore() => navigateTo(discovery);

  /// Navigate to Library tab
  void goToLibrary() => navigateTo(games);

  /// Navigate to Downloads tab
  void goToDownloads() => navigateTo(downloads);

  /// Navigate to Homebrew tab
  void goToHomebrew() => navigateTo(homebrew);

  /// Navigate to Tools tab
  void goToTools() => navigateTo(tools);

  /// Navigate to Settings tab
  void goToSettings() => navigateTo(settings);
}
