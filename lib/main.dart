// ═══════════════════════════════════════════════════════════════════════════
// ORBIIT — "Your games. In orbit."
// Nintendo Game Library Management Application
// ═══════════════════════════════════════════════════════════════════════════
//
// Orbiit is a premium, space-themed application for managing your
// Nintendo Wii, GameCube, and retro game library. Built with Flutter for a
// beautiful, responsive desktop experience.
//
// The name "Orbiit" (double "ii") is a nod to "Wii" while evoking the cosmic
// theme of games orbiting your digital collection.
//
// Features:
//   • Multi-source ROM discovery (Myrient, Archive.org)
//   • Intelligent cover art system with fallback sources
//   • High-performance native downloads via C++ backend
//   • Real-time library health monitoring
//   • Premium space-themed UI with cosmic aesthetics
//
// Architecture:
//   ┌───────────────────────────────────────────────────────────────────────┐
//   │  Flutter UI Layer (Dart)                                             │
//   │  ├── Screens (Dashboard, Library, Downloads, etc.)                   │
//   │  ├── Providers (State management via Provider pattern)               │
//   │  └── Widgets (Reusable UI components)                                │
//   ├───────────────────────────────────────────────────────────────────────┤
//   │  Service Layer (Dart)                                                │
//   │  ├── UnifiedSearchService (Federated ROM search)                     │
//   │  ├── CoverArtService (Multi-source cover fetching)                   │
//   │  ├── DownloadService (Queue management)                              │
//   │  └── LibraryStateService (Game library management)                   │
//   ├───────────────────────────────────────────────────────────────────────┤
//   │  Native Layer (C++ via dart:ffi)                                     │
//   │  └── forge_core.dll (WinHTTP downloads, file operations)             │
//   └───────────────────────────────────────────────────────────────────────┘
//
// Getting Started:
//   flutter pub get
//   flutter run -d windows
//
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Models & Theme ──
import 'models/theme.dart';

// ── Providers ──
import 'providers/discovery_provider.dart';
import 'providers/osc_provider.dart';
import 'providers/wiiload_provider.dart';
import 'providers/forge_provider.dart';
import 'providers/theme_provider.dart';
import 'ui/providers/cover_download_provider.dart';
import 'providers/cover_art_provider.dart';
import 'ui/widgets/fusion_error_widget.dart';
import 'ui/fusion/design_system.dart';

// ── Screens ──
import 'screens/navigation_wrapper.dart';
import 'ui/screens/intro_wizard_screen.dart';

// ── Core Services ──
import 'services/download_service.dart';
import 'services/navigation_service.dart';
import 'core/app_logger.dart';
import 'core/database/database.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GLOBAL SERVICES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Global download service instance
final DownloadService globalDownloadService = DownloadService();

/// Global ScaffoldMessenger key for showing SnackBars without context
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// APP CONFIGURATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Application metadata
abstract class AppConfig {
  static const String appName = 'Orbiit';
  static const String version = '1.0.0';
  static const String codename = 'Cosmos';
  static const String tagline = 'Your games. In orbit.';

  /// Default window dimensions
  static const Size defaultSize = Size(1100, 700);
  static const Size minimumSize = Size(900, 650);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MAIN ENTRY POINT
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Application entry point.
///
/// Initializes core services, sets up error handling, and launches the app.
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize Logging ──
  await AppLogger.instance.initialize();
  AppLogger.instance.info(
    '${AppConfig.appName} v${AppConfig.version} "${AppConfig.codename}" starting...',
  );

  // ── Set Up Global Error Handling ──
  _setupErrorHandling();

  // ── Initialize Window ──
  await _initializeWindow();

  // ── Check Setup Status ──
  final prefs = await SharedPreferences.getInstance();
  final bool setupCompleted = prefs.getBool('setup_completed') ?? false;

  // ── Launch App ──
  runApp(
    MultiProvider(
      providers: [
        // Database
        Provider(create: (_) => AppDatabase()),

        // Navigation
        ChangeNotifierProvider(create: (_) => NavigationService()),

        // Discovery & Search
        ChangeNotifierProvider(create: (_) => DiscoveryProvider()),

        // Network Services (OSC, Wiiload)
        ChangeNotifierProvider(create: (_) => OSCProvider()),
        ChangeNotifierProvider(create: (_) => WiiloadProvider()),

        // Download Management
        ChangeNotifierProvider(create: (_) => ForgeProvider()),
        ChangeNotifierProvider(create: (_) => CoverDownloadProvider()),

        // Cover Art
        ChangeNotifierProvider(create: (_) => CoverArtProvider()),

        // Theme
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: OrbiitApp(showSetupWizard: !setupCompleted),
    ),
  );

  AppLogger.instance.info('App started successfully');
}

/// Configure global error handlers for Flutter and platform errors.
void _setupErrorHandling() {
  // Set custom error widget for UI rendering
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return FusionErrorWidget(details: details);
  };

  // Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.instance.error(
      'Flutter Error: ${details.exceptionAsString()}',
      error: details.exception,
      component: 'Flutter',
    );
    // Show error UI
    FlutterError.presentError(details);
  };

  // Platform/async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.instance.error(
      'Platform Error',
      error: error,
      component: 'Platform',
    );
    
    // Show non-intrusive notification via global key
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: FusionColors.starlight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unexpected Error: ${error.toString().split('\n').first}',
                style: const TextStyle(color: FusionColors.starlight),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: FusionColors.error.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );

    // Return true to prevent app crash
    return true;
  };
}

/// Initialize the window manager with custom options.
Future<void> _initializeWindow() async {
  try {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: AppConfig.defaultSize,
      minimumSize: AppConfig.minimumSize,
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    AppLogger.instance.info('Window initialized: ${AppConfig.defaultSize}');
  } catch (e, stack) {
    AppLogger.instance.error(
      'Window initialization failed',
      error: e,
      component: 'Window',
    );
    // App can still run with default window
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ROOT APP WIDGET
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Root application widget.
///
/// Configures MaterialApp with theme support and navigation.
/// Named "OrbiitApp" to match the new branding.
class OrbiitApp extends StatelessWidget {
  final bool showSetupWizard;

  const OrbiitApp({
    super.key,
    this.showSetupWizard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          // ── App Identity ──
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,

          // ── Theme ──
          theme: _buildThemeData(themeProvider.currentTheme),

          // ── Navigation ──
          home: showSetupWizard 
              ? const IntroWizardScreen() 
              : const NavigationWrapper(),
        );
      },
    );
  }

  /// Build MaterialApp theme from WiiGCTheme.
  ///
  /// Adapts our custom theme model to Flutter's ThemeData.
  ThemeData _buildThemeData(WiiGCTheme theme) {
    // Determine brightness from background color
    final isDark = theme.backgroundColor.computeLuminance() < 0.5;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      // ── Core Colors ──
      brightness: brightness,
      scaffoldBackgroundColor: theme.backgroundColor,
      primaryColor: theme.primaryColor,
      canvasColor: Colors.transparent,

      // ── Color Scheme ──
      colorScheme: ColorScheme.fromSeed(
        seedColor: theme.primaryColor,
        brightness: brightness,
        surface: theme.surfaceColor,
      ),

      // ── Card Theme ──
      cardTheme: CardThemeData(
        color: theme.surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.cornerRadius),
        ),
      ),

      // ── Typography ──
      textTheme: TextTheme(
        // Hero text
        displayLarge: TextStyle(
          fontSize: 32 * theme.fontScale,
          fontWeight: FontWeight.w900,
          color: theme.textColor,
          letterSpacing: -1,
        ),
        // Section headers
        headlineMedium: TextStyle(
          fontSize: 24 * theme.fontScale,
          fontWeight: FontWeight.w700,
          color: theme.textColor,
        ),
        // Card titles
        titleLarge: TextStyle(
          fontSize: 18 * theme.fontScale,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
        // Body text
        bodyLarge: TextStyle(
          fontSize: 16 * theme.fontScale,
          color: theme.textColor.withAlpha(220),
        ),
        bodyMedium: TextStyle(
          fontSize: 14 * theme.fontScale,
          color: theme.textColor.withAlpha(200),
        ),
        // Labels
        labelMedium: TextStyle(
          fontSize: 12 * theme.fontScale,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
          color: theme.primaryColor,
        ),
        labelSmall: TextStyle(
          fontSize: 10 * theme.fontScale,
          letterSpacing: 1,
          color: theme.textColor.withAlpha(150),
        ),
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(theme.cornerRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ── Button Theme ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: isDark ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.cornerRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
        ),
      ),

      // ── Icon Theme ──
      iconTheme: IconThemeData(
        color: theme.textColor.withAlpha(200),
        size: 24,
      ),

      // ── Divider Theme ──
      dividerTheme: DividerThemeData(
        color: theme.textColor.withAlpha(30),
        thickness: 1,
      ),
    );
  }
}
