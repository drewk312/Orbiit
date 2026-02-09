<div align="center">

# 🖼️ Cover Art System

### Multi-Source Download & Cache Management

[![GameTDB](https://img.shields.io/badge/Source-GameTDB-4CAF50?style=flat-square)](https://gametdb.com)
[![IGDB](https://img.shields.io/badge/Source-IGDB-9146FF?style=flat-square)](https://igdb.com)
[![MobyGames](https://img.shields.io/badge/Source-MobyGames-FF6B00?style=flat-square)](https://mobygames.com)

*Automatic fallback across 4 sources for maximum coverage*

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Source Priority](#-source-priority)
- [Quick Start](#-quick-start)
- [API Configuration](#-api-configuration)
- [Advanced Features](#-advanced-features)
- [Cache Management](#-cache-management)
- [UI Integration](#-ui-integration)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 Overview

The cover art system automatically downloads and caches game artwork from multiple sources. When one source fails, it seamlessly falls back to the next.

```
┌─────────────────────────────────────────────────────────────────┐
│                     AUTOMATIC FALLBACK CHAIN                    │
│                                                                 │
│   GameTDB ──▶ IGDB ──▶ MobyGames ──▶ ScreenScraper ──▶ NULL    │
│      │          │          │              │              │      │
│      ✓          ✗          ✗              ✗           (none)    │
│   Return     Try Next  Try Next      Try Next       Placeholder │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🏆 Source Priority

| Priority | Source | Best For | Requires |
|:--------:|--------|----------|----------|
| 🥇 1 | **GameTDB** | Wii & GameCube | Game ID (free) |
| 🥈 2 | **IGDB** | All platforms | Twitch API (free) |
| 🥉 3 | **MobyGames** | Historical games | API Key (paid) |
| 4 | **ScreenScraper** | ROM community | Dev credentials |

<details>
<summary><strong>📖 Source Details</strong></summary>

### GameTDB (Priority 1)

```
┌────────────────────────────────────────────────┐
│  🎮 GAMETDB                                    │
│  ─────────────────────────────────────────     │
│  Coverage:    ★★★★★  (Excellent for Wii/GC)   │
│  Speed:       ★★★★★  (Direct URL access)      │
│  Cost:        FREE   (No API key needed)       │
│                                                │
│  URL Format:                                   │
│  art.gametdb.com/wii/cover/US/{GAMEID}.png    │
│                                                │
│  Cover Types: front, 3D, disc, full box       │
└────────────────────────────────────────────────┘
```

### IGDB (Priority 2)

```
┌────────────────────────────────────────────────┐
│  🔍 IGDB (via Twitch)                          │
│  ─────────────────────────────────────────     │
│  Coverage:    ★★★★☆  (Extensive cross-plat)   │
│  Speed:       ★★★★☆  (API calls required)     │
│  Cost:        FREE   (Twitch app registration) │
│                                                │
│  Features:                                     │
│  • Title-based search                          │
│  • Multiple resolutions                        │
│  • Rich metadata                               │
└────────────────────────────────────────────────┘
```

### MobyGames (Priority 3)

```
┌────────────────────────────────────────────────┐
│  📚 MOBYGAMES                                  │
│  ─────────────────────────────────────────     │
│  Coverage:    ★★★★★  (Deep historical)        │
│  Speed:       ★★★☆☆  (Rate limited)           │
│  Cost:        PAID   (Subscription required)   │
│                                                │
│  Features:                                     │
│  • Complete game history                       │
│  • Box art variants                            │
│  • Regional covers                             │
└────────────────────────────────────────────────┘
```

### ScreenScraper (Priority 4)

```
┌────────────────────────────────────────────────┐
│  🕹️ SCREENSCRAPER                             │
│  ─────────────────────────────────────────     │
│  Coverage:    ★★★★☆  (ROM-focused)            │
│  Speed:       ★★★☆☆  (Community server)       │
│  Cost:        FREE   (Dev registration)        │
│                                                │
│  Features:                                     │
│  • Box art & screenshots                       │
│  • Disc images                                 │
│  • 2D/3D variants                              │
└────────────────────────────────────────────────┘
```

</details>

---

## ⚡ Quick Start

### Single Cover Download

```dart
import 'package:provider/provider.dart';
import 'package:wiigc_fusion/providers/cover_art_provider.dart';

// Get the provider
final coverProvider = context.read<CoverArtProvider>();

// Download a cover
final coverPath = await coverProvider.downloadCover(
  gameTitle: 'Super Mario Galaxy',
  platform: GamePlatform.wii,
  gameId: 'RMGE01',  // Recommended for accuracy
);

// Display the cover
if (coverPath != null) {
  Image.file(File(coverPath));
}
```

### Batch Download

```dart
// Prepare your game list
final games = [
  GameInfo(
    title: 'The Legend of Zelda: Wind Waker',
    platform: GamePlatform.gamecube,
    gameId: 'GZLE01',
  ),
  GameInfo(
    title: 'Metroid Prime',
    platform: GamePlatform.gamecube,
    gameId: 'GM8E01',
  ),
  GameInfo(
    title: 'Super Smash Bros. Melee',
    platform: GamePlatform.gamecube,
    gameId: 'GALE01',
  ),
];

// Download all at once
await coverProvider.batchDownload(games);
```

### Progress Tracking

```dart
Consumer<CoverArtProvider>(
  builder: (context, provider, child) {
    final downloads = provider.activeDownloads;
    
    return ListView.builder(
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final dl = downloads[index];
        
        return ListTile(
          leading: _getStatusIcon(dl.status),
          title: Text(dl.gameTitle),
          subtitle: LinearProgressIndicator(
            value: dl.progress,
          ),
        );
      },
    );
  },
);
```

---

## 🔑 API Configuration

### GameTDB

> ✅ **No configuration required!** Works out of the box.

### IGDB (Twitch)

| Step | Action |
|:----:|--------|
| 1 | Register at [api-docs.igdb.com](https://api-docs.igdb.com/) |
| 2 | Create a Twitch Developer Application |
| 3 | Copy your **Client ID** and generate **Access Token** |

```dart
final igdbSource = IGDBSource(
  clientId: 'your_twitch_client_id',
  accessToken: 'your_access_token',
);
```

### MobyGames

| Step | Action |
|:----:|--------|
| 1 | Subscribe at [mobygames.com/info/api](https://www.mobygames.com/info/api/) |
| 2 | Copy your API key from the dashboard |

```dart
final mobySource = MobyGamesSource(
  apiKey: 'your_api_key',
);
```

### ScreenScraper

| Step | Action |
|:----:|--------|
| 1 | Register at [screenscraper.fr](https://www.screenscraper.fr/) |
| 2 | Apply for developer credentials |

```dart
final skraperSource = SkraperSource(
  devId: 'your_dev_id',
  devPassword: 'your_dev_password',
  userLogin: 'optional_username',
  userPassword: 'optional_password',
);
```

---

## 🔧 Advanced Features

### Extract Game ID from Filename

```dart
import 'package:wiigc_fusion/services/cover_art/sources/gametdb_source.dart';

// For file: "Super Mario Galaxy [RMGE01].wbfs"
final gameId = GameTDBSource.extractGameIdFromFilename(filename);
// Returns: "RMGE01"
```

### Alternate Cover Types

```dart
final result = await gameTDBSource.getByGameId(
  'RMGE01', 
  GamePlatform.wii,
);

if (result?.alternateUrls != null) {
  // Available types:
  final cover3D   = result.alternateUrls!['cover3D'];    // 3D box
  final disc      = result.alternateUrls!['disc'];       // Disc label
  final coverFull = result.alternateUrls!['coverfull'];  // Front + back
}
```

| Cover Type | Description | Best For |
|------------|-------------|----------|
| `cover` | Front box art | Default display |
| `cover3D` | 3D angled box | Shelf views |
| `disc` | Disc label | Detail views |
| `coverfull` | Full box scan | Collectors |

### Force Re-download

```dart
// Bypass cache and fetch fresh
final coverPath = await coverProvider.downloadCover(
  gameTitle: 'Super Mario Galaxy',
  platform: GamePlatform.wii,
  forceDownload: true,  // 👈 Ignores cache
);
```

---

## 📦 Cache Management

### Cache Location

```
📁 {AppDocuments}/WiiGC-Fusion/cover_cache/
   ├── wii_super_mario_galaxy_gametdb.png
   ├── gc_zelda_wind_waker_igdb.jpg
   ├── gc_metroid_prime_gametdb.png
   └── ...
```

### Filename Pattern

```
{platform}_{safe_title}_{source}.{ext}

Examples:
├── wii_super_mario_galaxy_gametdb.png
├── gc_zelda_wind_waker_igdb.jpg
└── wii_metroid_prime_3_mobygames.png
```

### Cache Statistics

```dart
final provider = context.read<CoverArtProvider>();

// Get cache info
final sizeBytes     = provider.cacheSize;        // Raw bytes
final formattedSize = provider.formattedCacheSize; // "12.5 MB"
final cachedCount   = provider.cachedCount;       // Number of covers
```

### Clear Cache

```dart
// Clear all cached covers
await provider.clearCache();

// Auto-cleanup when too large (500 MB threshold)
if (provider.cacheSize > 500 * 1024 * 1024) {
  await provider.clearCache();
}
```

---

## 🎨 UI Integration

### Pre-built Manager Screen

```dart
import 'package:wiigc_fusion/screens/cover_art_manager_screen.dart';

// Navigate to the manager
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CoverArtManagerScreen(),
  ),
);
```

**Features:**
- 📊 Cache statistics dashboard
- 📥 Active downloads list
- 🔄 Batch download trigger
- 🗑️ Cache clearing

### Custom Cover Widget

```dart
Widget buildCoverImage(String? coverPath) {
  if (coverPath == null) {
    // No cover available
    return Container(
      width: 120,
      height: 160,
      color: Colors.grey[800],
      child: const Icon(
        Icons.image_not_supported,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
  
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(
      File(coverPath),
      width: 120,
      height: 160,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, size: 40);
      },
    ),
  );
}
```

### Status Handling

```dart
final progress = provider.getProgress('Super Mario Galaxy');

if (progress != null) {
  switch (progress.status) {
    case DownloadStatus.complete:
      // ✅ Success - use progress.localPath
      break;
      
    case DownloadStatus.downloading:
      // ⏳ In progress - show spinner
      break;
      
    case DownloadStatus.queued:
      // 📋 Waiting to start
      break;
      
    case DownloadStatus.notFound:
      // ❌ No cover on any source
      break;
      
    case DownloadStatus.error:
      // ⚠️ Download failed
      print('Error: ${progress.error}');
      break;
  }
}
```

---

## 🔍 Troubleshooting

<details>
<summary><strong>❌ No covers downloading</strong></summary>

**Checklist:**

| Check | Action |
|-------|--------|
| 🌐 Network | Verify internet connection |
| 🔑 API Keys | Confirm keys are configured |
| 📡 Source Status | Test each source individually |

```dart
// Test source availability
for (final source in coverService._sources) {
  final available = await source.isAvailable();
  print('${source.sourceName}: ${available ? "✓" : "✗"}');
}
```

</details>

<details>
<summary><strong>🔄 Wrong cover downloaded</strong></summary>

**Causes:**
- Title matches multiple games
- Platform mismatch
- Regional variant

**Solutions:**
1. Provide Game ID for exact match
2. Specify correct platform
3. Force re-download with correct params

```dart
// More specific request
await provider.downloadCover(
  gameTitle: 'Super Mario Galaxy',
  platform: GamePlatform.wii,
  gameId: 'RMGE01',       // 👈 Add game ID
  forceDownload: true,    // 👈 Bypass cache
);
```

</details>

<details>
<summary><strong>💾 Cache growing too large</strong></summary>

**Solution:** Implement automatic cleanup

```dart
// In your app initialization
void checkCacheSize() async {
  final provider = context.read<CoverArtProvider>();
  
  // Clear if over 500 MB
  if (provider.cacheSize > 500 * 1024 * 1024) {
    await provider.clearCache();
    print('Cache cleared automatically');
  }
}
```

</details>

<details>
<summary><strong>⏱️ Downloads are slow</strong></summary>

**Performance Tips:**

| Tip | Impact |
|-----|--------|
| Use Game IDs | Direct lookup vs. search |
| Batch downloads | Less overhead |
| Configure only needed sources | Fewer API calls |
| Trust the cache | Skip redundant downloads |

</details>

---

## 📋 Status Reference

| Status | Icon | Meaning |
|--------|:----:|---------|
| `queued` | 📋 | Waiting in download queue |
| `downloading` | ⏳ | Currently downloading |
| `complete` | ✅ | Successfully cached |
| `notFound` | ❌ | No cover on any source |
| `error` | ⚠️ | Download failed |

---

## 🚀 Future Enhancements

| Feature | Status |
|---------|--------|
| Auto-download on library scan | 📋 Planned |
| Manual cover upload/override | 📋 Planned |
| Cover quality preferences | 📋 Planned |
| Regional cover selection UI | 📋 Planned |
| Metadata integration | 📋 Planned |
| Background download queue | 📋 Planned |

---

<div align="center">

**See Also:** [Architecture](ARCHITECTURE.md) • [ROM Sources](ROM_SOURCES.md)

</div>
