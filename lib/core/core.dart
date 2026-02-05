// ═══════════════════════════════════════════════════════════════════════════
// CORE MODULE - BARREL EXPORT
// WiiGC-Fusion - Central export for all core utilities
// ═══════════════════════════════════════════════════════════════════════════
//
// This barrel file provides a single import point for all core utilities.
//
// Usage:
//   import 'package:wiigc_fusion/core/core.dart';
//
//   // Now you have access to:
//   // - AppLogger
//   // - Result<T, E>
//   // - AppError hierarchy
//   // - Extension methods
//   // - Constants
//
// ═══════════════════════════════════════════════════════════════════════════

// Logging
export 'app_logger.dart';

// Functional error handling
export 'result.dart';

// Structured error types
export 'errors.dart';

// Extension methods on built-in types
export 'extensions.dart';

// Application constants and configuration
export 'constants.dart';

// Error handling utilities
export 'error_handler.dart';
