# 🛠️ Orbiit Developer Setup Guide

This guide will help you set up and run Orbiit from the source code on Windows.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

1.  **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install/windows)
2.  **Visual Studio 2022** (or 2019) with "Desktop development with C++" workload.
3.  **Git**: [Install Git](https://git-scm.com/downloads)
4.  **VS Code**: Recommended for editing and running the code.
    *   Install the **Flutter** and **Dart** extensions in VS Code.

## 🚀 Running the App (Quick Start)

1.  **Open the Project**:
    Ensure you have opened the `Orbiit` folder in VS Code or your terminal.
    *   **Correct:** `...\Downloads\Best Wii\Orbiit\`
    *   **Incorrect:** `...\Downloads\Best Wii\` (Parent folder)

2.  **Install Dependencies**:
    Open your terminal in the `Orbiit` folder and run:
    ```powershell
    flutter pub get
    ```

3.  **Run the Application**:
    Start the app in debug mode (allows hot reload):
    ```powershell
    flutter run -d windows
    ```

## 🐛 Troubleshooting

### "No pubspec.yaml file found"
You are running the command from the wrong directory.
**Fix:** Change directory to the project root:
```powershell
cd Orbiit
flutter run -d windows
```

### "Native scanner not detected" / DLL Errors
The app uses a C++ library (`forge_core.dll`) for high-performance scanning.
If this is missing, the app **will still work** using a slower fallback scanner.
To build the native library (optional):
```powershell
cd native
mkdir build
cd build
cmake ..
cmake --build . --config Release
# Copy the resulting forge_core.dll to the project root
```

### Visual Studio Build Tools Missing
If `flutter run` fails with C++ errors, verify you have the **Visual Studio Build Tools 2022** installed with the "Desktop development with C++" workload selected.

## 📦 Building for Release

To create a standalone `.exe` for distribution:
```powershell
flutter build windows --release
```
The output file will be in: `build\windows\x64\runner\Release\Orbiit.exe`
