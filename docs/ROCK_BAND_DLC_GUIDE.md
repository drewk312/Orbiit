# Installing Rock Band, Just Dance, and Guitar Hero DLC on Wii

*Based on the tutorial by SaulFabre*

**DISCLAIMER:** This guide involves modifying game files and using homebrew software. Proceed at your own risk. Orbiit is not responsible for any damage or data loss.

## What you need
*   A computer (Windows, Mac, or Linux)
*   [Wii Mod Lite](https://github.com/RiiConnect24/Wii-Mod-Lite/releases/latest)
*   An SD Card
*   The WAD(s) of the song(s) you want to install
*   [wad2bin (GUI version)](https://github.com/DarkMatterCore/wad2bin/tree/v0.7)
*   [xyzzy-mod](https://wiidatabase.de/downloads/wii-tools/xyzzy/)

## Instructions

### Section 1: Preparing

1.  **Get the WADs**:
    *   “Big WADs” contain all DLC but are large.
    *   “Split WADs” allow picking individual songs.
2.  **Copy Tools**: Copy `xyzzy-mod` and `Wii Mod Lite` to the `apps` folder of your SD Card.
3.  **Dump Keys**: Launch `xyzzy-mod` from the Homebrew Channel to dump your Wii's keys (required for wad2bin). *Only needs to be done once.*

### Section 2: Patching IOS (Disc Channel Only)

*If using a USB Loader, skip to [cIOS Guide](https://wii.guide/cios).*

1.  Launch **Wii Mod Lite**.
2.  Go to **IOSs menu**.
3.  Select the IOS for your game:
    *   **IOS37**: Rock Band 2
    *   **IOS56**: Rock Band 3, Just Dance 2-4, Guitar Hero
    *   **IOS57**: Just Dance 2014-2015
4.  Select **Install IOS** -> Select Revision (5663 for IOS37, 5662 for IOS56, 5919 for IOS57).
5.  Select **Download IOS from NUS**.

### Section 3: Making the WADs

1.  Open **wad2bin**.
2.  **SD Root**: Select your SD Card root.
3.  **Keys/Cert**: Select `keys.txt` and `device.cert` (dumped by xyzzy-mod).
4.  **Title ID**: Enter the ID for your game (append `45` for USA, `50` for EUR).
    *   *Examples:*
        *   Just Dance 2014: `00010000534A4F`
        *   Rock Band 3: `00010000535A42`
5.  Select **Add WAD** or **Add Folder**.
6.  Click **Run**.
7.  Verify `.bin` files were created in `/private/wii/data/...`.
8.  Move the resulting `...bogus.wad` file to a `wad` folder on your SD Card.

### Section 4: Finalizing

1.  Launch **Wii Mod Lite** -> **WAD Manager**.
2.  Select the `wad` folder.
3.  Highlight the `...bogus.wad`.
4.  Press **Uninstall** (minus button) first. (Ignore errors if it wasn't installed).
5.  Press **Install** (plus/A button).
6.  Load the game and check the DLC.
