# Frequently Asked Questions (FAQ)

## General

### What is Orbiit?
Orbiit is a modern game library manager for Wii, GameCube, Wii U, and retro console backups. It helps you organize, discover, and download game files with a beautiful, high-performance interface.

### Is Orbiit free?
Yes! Orbiit is completely free and open source under the MIT license.

### Is Orbiit safe to use?
Absolutely. Orbiit is open source, contains no telemetry, and all operations are performed locally on your machine. We never collect any personal data.

### Does Orbiit include ROMs/ISOs?
No. Orbiit is just a manager and downloader. You must provide your own legally obtained game backups. Orbiit helps you organize and download from legal sources like Myrient (preservation projects).

## Installation

### What are the system requirements?
- **OS**: Windows 10/11 (64-bit)
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 500MB for Orbiit + space for your game library
- **GPU**: Any modern GPU with DirectX 11 support

### Do I need Flutter installed?
No, if you're using the prebuilt release. Flutter is only needed if building from source.

### Why won't Orbiit start?
Common fixes:
1. Install [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)
2. Update Windows to the latest version
3. Check antivirus isn't blocking it
4. Run as administrator

### Can I run Orbiit on macOS or Linux?
Not yet, but it's on the roadmap! Currently Windows-only.

## Features

### What game formats are supported?
- **Wii**: .wbfs, .iso, .rvz, .wia
- **GameCube**: .iso, .rvz, .gcm
- **Wii U**: .wux, .wud
- **Retro**: Various formats via Libretro cores

### Can Orbiit play games?
No. Orbiit is a library manager. To play games, use:
- **Dolphin**: For Wii/GameCube emulation
- **Cemu**: For Wii U emulation
- **USB Loader GX**: For real Wii hardware

### Where does Orbiit download games from?
- **Myrient**: Redump-verified dumps (highest quality)
- **Archive.org**: Large preservation library
- **Vimm's Lair**: Curated popular titles

All sources provide legal game preservation archives.

### Can I use my own game files?
Yes! Orbiit scans any folder you point it to. It works great with existing libraries.

### Does Orbiit modify my game files?
Not unless you explicitly use conversion tools. Scanning and library management only reads metadata—it never modifies your files.

## Usage

### How do I add games to my library?
1. Click **"Add Folder"** or go to **Settings > Drive Setup**
2. Select the folder containing your games
3. Orbiit will scan and detect all supported games
4. Games appear in your library automatically

### Why aren't all my games detected?
Possible reasons:
- Unsupported file format
- Corrupted file headers
- Files in nested archives (.zip, .7z)
- Wrong file extension

Try extracting archives first, then rescan.

### How do I get cover art?
Orbiit fetches covers automatically from GameTDB, IGDB, and other sources. If a cover is missing:
1. Right-click the game
2. Select "Refresh Metadata"
3. Or manually download and place in the `covers` folder

### Can I organize games into collections?
Yes! Use folders to organize, or create custom views with filters. Full collection management is coming in v1.1.

### How do I download a game?
1. Go to the **Store** tab
2. Search for your game
3. Click **Download**
4. Choose format and destination
5. Monitor progress in the downloads panel

## Technical

### What's the `forge_core` library?
`forge_core` is Orbiit's native C++ engine that handles:
- Fast file scanning
- Format conversion
- Checksum verification
- Download management

It's what makes Orbiit faster than pure Dart alternatives.

### Why is scanning slow on my external drive?
- **USB 2.0**: Upgrade to USB 3.0+ for 10x speed
- **Too many files**: Large libraries take time
- **Virus scanner**: Temporarily disable real-time scanning
- **HDD**: SSDs are much faster for scanning

### How much memory does Orbiit use?
- **Idle**: ~100-200MB
- **Scanning**: ~300-500MB
- **Downloading**: ~200-400MB

Large libraries (1000+ games) may use more for caching.

### Can I run multiple instances?
Not recommended. Multiple instances may conflict when accessing the database. Use one instance with multiple windows instead.

### Does Orbiit work offline?
Yes! Library management, scanning, and local operations work offline. Only online features (downloads, metadata fetching) require internet.

## Troubleshooting

### Downloads are slow or fail
1. Check your internet connection
2. Try a different source (Myrient vs Archive.org)
3. Restart the download
4. Check available disk space
5. Temporarily disable VPN

### Orbiit crashed
1. Check the logs in `%APPDATA%/Orbiit/logs`
2. Report the crash on [GitHub Issues](https://github.com/drewk312/Orbiit/issues)
3. Include error logs and steps to reproduce

### Cover art won't load
1. Check internet connection
2. Clear cache: Settings > Advanced > Clear Cache
3. Try "Refresh Metadata" on the game
4. Some obscure games may not have covers available

### Library scan finds nothing
1. Verify files are in supported formats
2. Check file permissions (Orbiit needs read access)
3. Try scanning a single file to test
4. Enable debug logging in Settings

## Legal

### Is downloading ROMs legal?
**Gray area.** Laws vary by country. General guidelines:
- **Legal**: Backups of games you own
- **Legal**: Abandoned/preservation projects (varies)
- **Illegal**: Downloading games you don't own

**We're not lawyers.** Research your local laws.

### Can I distribute Orbiit?
Yes! It's MIT licensed. You can:
- Share the program freely
- Modify and redistribute
- Use in commercial projects (with attribution)
- Create your own forks

### Can I use Orbiit for commercial purposes?
Yes, under MIT license. Attribution required.

## Contributing

### How can I help?
- Report bugs
- Suggest features
- Contribute code
- Improve documentation
- Translate to other languages
- Share with friends!

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### I'm not a programmer. Can I still help?
Yes! We need:
- Documentation writers
- UI/UX designers
- Translators
- Testers
- Community moderators

### How do I report a bug?
1. Check if it's already reported on [GitHub Issues](https://github.com/drewk312/Orbiit/issues)
2. If not, create a new issue with:
   - Clear description
   - Steps to reproduce
   - Screenshots/logs
   - System info

Use the bug report template.

## Updates

### How do I update Orbiit?
Currently manual:
1. Download latest release
2. Extract to same location (overwrite)
3. Restart Orbiit

Auto-update coming in v1.1!

### How often are updates released?
- **Bug fixes**: As needed
- **Minor versions**: Monthly
- **Major versions**: Quarterly

### Will my data be safe after updates?
Yes. We maintain backward compatibility. Your library data, settings, and cache are preserved.

## Still have questions?

- **GitHub Discussions**: [Ask the community](https://github.com/drewk312/Orbiit/discussions)
- **GitHub Issues**: [Report bugs](https://github.com/drewk312/Orbiit/issues)
- **Documentation**: Check the [docs](docs/) folder

---

*Last Updated: February 2026*
