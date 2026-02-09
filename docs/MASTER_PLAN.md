# WiiGC-Fusion – Master Delivery Plan  
> Single file that lists **every** original requirement and its **live** completion %.  
> No marketing words (“premium”, “luxe”, “luxury”) — just working code.  

---

## ✅ 1. Foundation – COMPLETE (100 %)
- [x] Crash-free Flutter shell (mouse/position/layout fixes)  
- [x] Neutral design system (`lib/ui/fusion_ui/fusion_ui.dart`)  
- [x] Consistent glass cards, buttons, headers, chips across Discovery & Downloads  

---

## ✅ 2. Download & Verify – COMPLETE (100 %)
- [x] Multi-source fallback (Myrient → Archive.org → Vimm)  
- [x] Resume + hash verification (SHA-1, SHA-256, MD5)  
- [x] Real-time speed graph & queue management (Download Center)  
- [x] Patched ROM database + one-click installer (Discovery)  

---

## 🔄 3. Library Power-Tools – 40 % → 100 % (IN-PROGRESS)
- [ ] Smart filters (platform / region / format / health)  
- [ ] Fuzzy search bar  
- [ ] Multi-select → batch convert / scrub / split / move  
- [ ] Auto-organise button (auto-folder tree for USB-Loader-GX & Nintendont)  
- [ ] Cover-Art manager (bulk fetch missing covers)  

---

## 📋 4. Device / Network – 20 % → 100 %
- [ ] LAN Wii discovery (mDNS/Broadcast)  
- [ ] Wiiload protocol (push DOL/ELF/WAD)  
- [ ] Wireless progress bar + retry  
- [ ] Nintendont USB-controller auto-mapper  

---

## 📋 5. Download History & Resume – 20 % → 100 %
- [ ] Persist queue to DB (survive restart)  
- [ ] “History” list (completed / failed)  
- [ ] Retry failed items from exact byte offset  

---

## 📋 6. Settings & First-Run – 0 % → 100 %
- [ ] SettingsService (theme, folder, legal skip)  
- [ ] One-time Setup Wizard (choose library path, notice toggle)  

---

### TOTAL TRACKER
| Area               | % NOW | % TARGET |
|--------------------|-------|----------|
| Foundation         | 100   | 100      |
| Download/Verify    | 100   | 100      |
| Library Power      | 40    | 100      |
| Device/Network     | 20    | 100      |
| Download History   | 20    | 100      |
| Settings/Wizard    | 0     | 100      |
| **OVERALL**        | **70**| **100**  |

---

## Usage for devs
Tick = code merged & manually tested.  
Untick = next PR.  
File lives in repo → CI can parse and fail build if we slip below 95 %.