<div align="center">

# ⚡ Orbiit Quick Start Guide

### Get up and running in 5 minutes!

</div>

---

## 🎮 For Users

### 📥 Installation

<table>
<tr>
<td width="60">

**1️⃣**

</td>
<td>

Download the latest release ZIP from the **Releases** page

</td>
</tr>
<tr>
<td>

**2️⃣**

</td>
<td>

Extract to your preferred location (e.g., `C:\Orbiit`)

</td>
</tr>
<tr>
<td>

**3️⃣**

</td>
<td>

Double-click `Orbiit.exe` to launch

</td>
</tr>
</table>

> 💡 **Tip:** If Windows SmartScreen blocks it, click "More info" → "Run anyway"

---

### 🚀 First Run Walkthrough

#### Step 1: Add Your Game Library

```
┌──────────────────────────────────────────────────────────┐
│  Click the  ➕ Add Folder  button in the sidebar         │
│                                                          │
│  Select your games folder:                               │
│  • D:\Games                                              │
│  • E:\wbfs                                               │
│  • Any folder with .iso, .wbfs, .rvz files               │
│                                                          │
│  Wait for scanning to complete (watch the progress bar)  │
└──────────────────────────────────────────────────────────┘
```

#### Step 2: View Your Games

<table>
<tr>
<td width="40%">

**What You'll See:**
- Beautiful cards with cover art
- Platform icons (🟦 Wii / 🟪 GameCube)
- File size and format info
- Health indicators

</td>
<td width="60%">

```
┌─────────────────────────────────────┐
│  ┌─────────┐                        │
│  │  COVER  │  Super Mario Galaxy    │
│  │   ART   │  ─────────────────────│
│  │         │  🟦 Wii  •  4.2 GB    │
│  │         │  ID: RMGE01           │
│  └─────────┘  ✅ Healthy            │
└─────────────────────────────────────┘
```

</td>
</tr>
</table>

#### Step 3: Check Library Health

Navigate to the **Dashboard** to see:
- 📊 **Health Score** (0-100 with A-F grade)
- ⚠️ **Issues Found** (duplicates, missing covers, etc.)
- 💾 **Space Savings** (potential RVZ conversion savings)

Click **"Fix Issues"** to get auto-generated optimization suggestions!

---

### 📁 Supported Folder Structures

Orbiit automatically recognizes these common layouts:

<table>
<tr>
<th>Style</th>
<th>Structure</th>
<th>Example Path</th>
</tr>
<tr>
<td><strong>TinyWii/USB Loader</strong></td>
<td>

```
📁 wbfs/
  └── 📁 Game Title [GAMEID]/
       └── GAMEID.wbfs
```

</td>
<td><code>D:\wbfs\Super Mario Galaxy [RMGE01]\RMGE01.wbfs</code></td>
</tr>
<tr>
<td><strong>GameCube BM</strong></td>
<td>

```
📁 games/
  └── 📁 Game Title [GAMEID]/
       └── game.iso
```

</td>
<td><code>D:\games\Metroid Prime [GM8E01]\game.iso</code></td>
</tr>
<tr>
<td><strong>Flat</strong></td>
<td>

```
📁 Games/
  ├── game1.iso
  ├── game2.wbfs
  └── game3.rvz
```

</td>
<td><code>D:\Games\Zelda Twilight Princess.rvz</code></td>
</tr>
</table>

> ✅ All structures are supported! Just point to your root games folder.

---

### 🔧 Troubleshooting

<details>
<summary>❌ "Native scanner not detected"</summary>

**What it means:** The C++ engine (`forge_core.dll`) isn't loading.

**Quick Fixes:**
1. Ensure `forge_core.dll` is next to `Orbiit.exe`
2. Install [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)
3. Try running as Administrator

**Don't worry!** The app automatically uses a Dart fallback scanner.
</details>

<details>
<summary>❌ No covers loading</summary>

**Possible causes:**
- No internet connection
- GameTDB servers temporarily down
- Game ID not in database (homebrew/hacks)

**Fixes:**
1. Check your internet connection
2. Try the **Cover Art Manager** in Tools to manually refresh
3. Regional variants may need different cover IDs
</details>

<details>
<summary>❌ Scan finds no games</summary>

**Checklist:**
- [x] Files are supported formats (`.iso`, `.wbfs`, `.rvz`, `.gcz`, `.nkit.iso`)
- [x] File sizes are at least 10MB (too small = invalid)
- [x] Folder isn't too deeply nested (try selecting a parent folder)
- [x] Files aren't corrupted (try opening in Dolphin)
</details>

<details>
<summary>❌ App crashes on startup</summary>

**Try these:**
1. Delete the `%APPDATA%\Orbiit` folder (resets settings)
2. Run as Administrator
3. Check Windows Event Viewer for detailed error
4. Re-download and extract fresh copy
</details>

---

## 👨‍💻 For Developers

### 🛠️ Build from Source

#### Prerequisites

| Requirement | Version | Download |
|-------------|---------|----------|
| Flutter SDK | ≥3.5.0 | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| CMake | ≥3.15 | [cmake.org](https://cmake.org/download/) |
| Visual Studio | 2019+ | [visualstudio.com](https://visualstudio.microsoft.com/) |
| Git | Latest | [git-scm.com](https://git-scm.com/) |

#### Quick Build (PowerShell)

```powershell
# One-liner build
.\build.ps1
```

#### Manual Build Steps

```powershell
# 1. Build native C++ library
cd native
cmake -B build
cmake --build build --config Release
cd ..

# 2. Copy DLL to project root
Copy-Item "native/build/bin/Release/forge_core.dll" "."

# 3. Get Flutter dependencies
flutter pub get

# 4. Build Flutter app
flutter build windows --release
```

The built app is at: `build/windows/x64/runner/Release/`

---

### 🐛 Debug Mode

```powershell
# Run in debug with hot reload
flutter run -d windows

# Run with verbose logging
flutter run -d windows --verbose

# Analyze code for issues
flutter analyze
```

---

### 📦 Create Distribution Package

```powershell
# Build release
flutter build windows --release

# Run deploy script (creates zip-ready folder)
.\deploy.ps1
```

Creates: `dist/Orbiit/` folder ready to zip and distribute.

---

### 📂 Project Structure Overview

```
Orbiit/
├── 📁 lib/                    # Flutter/Dart source
│   ├── 📁 screens/            # UI screens
│   │   ├── manager.dart       # Library manager
│   │   ├── discovery.dart     # Game discovery/search
│   │   ├── settings.dart      # App settings
│   │   └── cover_art_manager_screen.dart
│   ├── 📁 services/           # Business logic
│   │   ├── scanner_service.dart
│   │   ├── gametdb_service.dart
│   │   ├── cover_art/         # Multi-source cover system
│   │   └── ...
│   ├── 📁 providers/          # State management
│   ├── 📁 widgets/            # Reusable UI components
│   └── 📁 ffi/                # Native bridge
│
├── 📁 native/                 # C++ source
│   └── 📁 forge/
│       └── 📁 src/
│           └── forge_core_v2.cpp  # Main native code
│
├── 📁 docs/                   # Documentation
├── 📁 windows/                # Windows platform code
└── 📁 build/                  # Build outputs (gitignored)
```

---

### 🔗 Useful Commands

| Command | Description |
|---------|-------------|
| `flutter run -d windows` | Run in debug mode |
| `flutter build windows --release` | Build release binary |
| `flutter analyze` | Check code quality |
| `flutter pub get` | Install dependencies |
| `flutter clean` | Clean build cache |
| `cmake --build . --config Release` | Build native DLL |

---

<div align="center">

### 🎉 You're Ready!

Now explore the app, add your games, and enjoy your organized library!

**Need help?** Check the full [README](README.md) or open an issue.

</div>
