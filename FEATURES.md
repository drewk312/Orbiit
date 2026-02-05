# Orbiit Features

This document provides a comprehensive overview of Orbiit's features and capabilities.

## 🎨 User Interface

### Modern Design
- **Glassmorphism UI**: Frosted glass effects with blur and transparency
- **Dynamic Backgrounds**: Animated particle systems and gradient shifts
- **Smooth Animations**: 60fps fluid transitions and hover effects
- **Dark Theme**: Eye-friendly design optimized for extended use
- **Responsive Layout**: Adapts to different window sizes

### Visual Polish
- **High-Quality Cover Art**: Fetched from multiple sources (GameTDB, IGDB, MobyGames)
- **3D Box Art**: Full box art and disc art when available
- **Platform Badges**: Visual indicators for Wii, GameCube, Wii U
- **Format Icons**: Easy identification of ISO, WBFS, RVZ files
- **Progress Indicators**: Real-time download and scan progress

## 📚 Library Management

### Game Detection
- **Automatic Scanning**: Detects games on any connected drive
- **Multi-Format Support**: 
  - Wii: .wbfs, .iso, .rvz, .wia
  - GameCube: .iso, .rvz, .gcm
  - Wii U: .wux, .wud
- **Metadata Extraction**: Reads game ID, title, region from file headers
- **Fast Scanning**: Native C++ scanner for performance
- **Incremental Updates**: Only scans new/changed files

### Organization
- **Smart Filtering**: Filter by platform, region, format
- **Search Functionality**: Instant search across your entire library
- **Sorting Options**: Sort by title, size, date added, platform
- **Grid/List Views**: Choose your preferred display mode
- **Favorites**: Mark games for quick access

## 🌐 Online Discovery

### Multi-Source Search
- **Myrient Integration**: Direct access to Redump-verified dumps
- **Archive.org Support**: Legacy and hard-to-find titles
- **Vimm's Lair**: Curated collection of popular games
- **Unified Search**: Search all sources simultaneously

### Download Features
- **High-Speed Downloads**: Optimized for Myrient's CDN
- **Resume Support**: Continue interrupted downloads
- **Progress Tracking**: Real-time speed and ETA
- **Queue Management**: Download multiple games in sequence
- **Format Selection**: Choose between ISO, WBFS, RVZ

## 🔧 Tools & Utilities

### File Operations
- **Format Conversion**: Convert between ISO, WBFS, RVZ
- **File Verification**: SHA-1 checksum validation against Redump
- **Compression**: Compress ISOs to save space
- **Splitting**: Split large files for FAT32 compatibility

### Drive Management
- **USB Setup Wizard**: Prepare drives for USB Loader GX
- **Folder Structure**: Auto-create standard directories
- **Format Detection**: Identify WBFS, FAT32, NTFS, exFAT
- **Safety Checks**: Prevent accidental data loss

### Homebrew
- **App Browser**: Discover and download homebrew apps
- **Categories**: Emulators, utilities, games, media players
- **Version Checking**: Stay up to date with latest releases
- **Direct Install**: Download directly to SD card

## ⚡ Performance

### Native Core
- **C++ Engine**: `forge_core` library for intensive operations
- **Multi-Threading**: Parallel processing for scans and downloads
- **Memory Efficient**: Handles large libraries (1000+ games)
- **Fast Startup**: Cached metadata for instant loading

### Optimizations
- **Lazy Loading**: Load covers only when visible
- **Image Caching**: Persistent cache for artwork
- **Database Indexing**: Quick lookups and searches
- **Async Operations**: UI stays responsive during heavy tasks

## 🎮 Platform-Specific Features

### Wii
- **USB Loader GX Support**: Compatible directory structure
- **WiiFlow Support**: Alternative loader compatibility
- **Nintendont**: GameCube game detection for Wii
- **RVZ Support**: Dolphin's compression format

### GameCube
- **Swiss Compatibility**: Proper folder structure for Swiss
- **Memory Card Management**: (Planned feature)
- **Region Detection**: NTSC-U, PAL, NTSC-J identification

### Wii U
- **Loadiine Format**: .wux file support
- **Title Keys**: Encrypted content handling (future)

## 🔐 Safety & Privacy

### Security
- **No Telemetry**: No tracking or analytics
- **Open Source**: Fully auditable code
- **Local-First**: All data stays on your machine
- **Secure Downloads**: HTTPS for all online operations

### Data Protection
- **No Account Required**: Works completely offline
- **Export/Import**: Backup your library metadata
- **Configurable Paths**: Choose where data is stored
- **Safe Mode**: Confirmation for destructive operations

## 🛠️ Developer Features

### Extensibility
- **Plugin System**: (Planned) Add custom sources and tools
- **API Access**: (Planned) Programmatic library access
- **Custom Themes**: Modify colors and styling
- **Debug Mode**: Detailed logging for troubleshooting

### Integration
- **Command Line**: Batch operations via CLI
- **WiiLoad**: Send DOLs/ELFs over network
- **FTP Support**: Transfer files to Wii/Wii U
- **OSC Protocol**: Control Dolphin emulator

## 🌍 Localization

### Current Support
- English (US)
- Additional languages planned

### Planned Features
- Multi-language UI
- Region-specific game names
- Localized documentation

## 📱 Cross-Platform (Future)

### Planned Platforms
- macOS support
- Linux support
- Possible Android/iOS companion app

## 🔄 Updates

### Auto-Update (Planned)
- In-app update notifications
- One-click updates
- Changelog viewer

### Version Control
- Semantic versioning
- Stable and beta channels
- Rollback support

## 🤝 Community Features (Planned)

- Game ratings and reviews
- Community collections
- Achievement tracking
- Mod support

---

> **Note**: Features marked as "(Planned)" or "(Future)" are on the roadmap but not yet implemented.

For feature requests or suggestions, please [open an issue](https://github.com/drewk312/Orbiit/issues)!
