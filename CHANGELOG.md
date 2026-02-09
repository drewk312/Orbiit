# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-02-03 (The Big Bang)

### 🚀 Rebranded as Orbiit
*   **New Identity:** Fully rebranded from "WiiGC Fusion" to **Orbiit**.
*   **New Look:** Updated window titles, logos, and UI strings for a cohesive premium experience.

### ✨ New Features
*   **Myrient Integration:** Direct high-speed downloads for Wii and GameCube games via Myrient (RVZ format).
*   **Smart Detection:** Enhanced hardware wizard now auto-detects USBs, SD Cards, and External Drives.
*   **Native Core:** Integrated `forge_core.dll` (C++) for high-performance file operations and heavy lifting.
*   **Glassmorphism UI:** A completely redesigned visual interface with fluid animations and dynamic backgrounds.
*   **Mock Mode:** Added developer tools and proper error handling for offline scenarios.

### 🐛 Bug Fixes
*   **Critical:** Fixed a crash that occurred when cancelling a download mid-progress.
*   **UI:** Resolved layout overflow issues in the Settings menu.
*   **Stability:** Removed unsupported "Pause" button functionality to prevent user confusion.

### 🔧 Improvements
*   **Performance:** Optimized cover art caching and reduced memory usage during large lists.
*   **Build System:** Added `release.ps1` for automated, clean release packaging.
