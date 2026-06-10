# Changelog

All notable changes to the Universal Intel Wi-Fi and Bluetooth Drivers Updater project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2026.06.0007] - 2026-06-11

### Added
- **PSGallery Self‑Update Mechanism**: Script now updates itself using `Update-Script -Force` when installed from PowerShell Gallery.
- **Installation Order Changed**: Bluetooth drivers are installed before Wi‑Fi to prevent network disconnection from interrupting driver downloads.

### Fixed
- Fixed an issue where a dual driver update (Wi‑Fi + Bluetooth) would fail to download the Bluetooth CAB after the Wi‑Fi driver disconnected the network.

Full details: [Release Notes](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases/tag/v2026.06.0007)

---

## [2026.06.0006] - 2026-06-10

### Added
- **New Hardware Support**: Intel Bluetooth PCI Enumerator devices (`PCI\VEN_8086&DEV_A876`, `4D76`, `E476`, `E376`) – also known as Intel(R) Bluetooth(R) PCI Enumerator.
- **Unified Driver Management**: Detects both USB (`VID_8087&PID_xxxx`) and PCI (`VEN_8086&DEV_xxxx`) Bluetooth, fetches appropriate CAB.
- **Shared PCI CAB**: All PCI devices use a single CAB file (`intel-bt-<version>_pci.cab`), reducing download size.
- **Updated Banner**: New tool version, revised author line, removed redundant GitHub link, improved layout.
- **Code Cleanup**: All comments now in English.

### Fixed
- **Missing PID `0043`**: Intel AX211 USB Bluetooth (PID `0043`) was absent from the supported device list; affected users received no update offer.
- **False Legacy flag for PCI Bluetooth**: PCI devices (`DEV_A876/4D76/E476/E376`) were incorrectly shown as `[LEGACY]` when USB version was newer; PCI and USB now use independent version tracks.
- **Scanner dead code (v4.5)**: PCI legacy fallback in `BT-Platform-Scanner` was unreachable; known PCI DEVs now correctly fall back to last known version from previous MD.

### Compatibility
- Fully backward compatible with older `intel-bt-driver-latest.md` that only contains USB devices.

Full details: [Release Notes](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases/tag/v2026.06.0006)

---

## [2026.04.0005] - 2026-04-15

### Added
- **Dedicated Release Asset Downloader**: New `Get-ReleaseAssetContent` function uses `WebClient.DownloadString()` (with proper redirect handling) instead of `Invoke-WebRequest`, ensuring raw file content is always retrieved correctly.
- **Removed Monolithic Fallback**: `intel-wifi-drivers-download.txt` and `intel-bt-drivers-download.txt` are no longer used or required; updater now relies exclusively on versioned release assets.
- **Cleaner Codebase**: Removed unused parsers (`Parse-WiFiDownloadList`, `Parse-BTDownloadList`, `Get-WiFiBlockForDevice`, `Get-BTBlockForDevice`) and associated variables.

### Fixed
- **Critical Bug**: GitHub release asset URLs do not support query parameters; the cache buster appended to versioned `.txt` URLs caused silent download failures, preventing driver installation even when all files were correctly in place.

Full details: [Release Notes](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases/tag/v2026.04.0005)

---

## [2026.03.0004] - 2026-03-26

### Added
- **Versioned download files** stored in release assets (`archive-wifi` and `archive-bt`):
  - Wi‑Fi: `intel-wifi-<version>.txt`
  - Bluetooth: `intel-bt-<version>_pid<PID>.txt` (fallback to generic `intel-bt-<version>.txt`)
- **Backward compatibility**: If a versioned file is missing, the updater falls back to the old monolithic `intel-wifi-drivers-download.txt` / `intel-bt-drivers-download.txt`

### Changed
- **File naming** for versioned download files shortened (removed `-drivers` suffix)
- **WiFi-Platform-Scanner** (internal tool) updated to version 5.0; now generates only `intel-wifi-driver-latest.md` and versioned `intel-wifi-<version>.txt` files

### Fixed
- **Block splitting** in `Parse-WiFiDownloadList` and `Parse-BTDownloadList` now handles CRLF line endings correctly using `(?:\r?\n){2,}` regex
- **Variable name conflict**: Changed parameter `$PID` to `$BtPID` in `Get-VersionedBTDownloadInfo` to avoid clash with PowerShell's built‑in `$PID` variable

---

## [2026.03.0003] - 2026-03-21

### Added
- **Microsoft WHCP Digital Signature Verification**: All downloaded CAB driver packages are now verified against the `Microsoft Windows Hardware Compatibility Publisher` certificate before installation — after SHA-256 hash check and before `expand.exe` extraction; installation is aborted on any failure; security architecture is now fully symmetric with Universal Intel Chipset Device Updater
- **Legacy Device Support**: Database files (`intel-bt-driver-latest.md`, `intel-wifi-driver-latest.md`) now support optional per-device `Latest Version` and `Release Date` columns; a dedicated `## Legacy Devices` section tracks EOL devices with their last available driver version; script displays `[LEGACY]` indicator and installs the correct last-available CAB automatically — no script update required when Intel discontinues a device
- **First Legacy Entry**: Intel AX200 Bluetooth (PID `0029`) — dropped by Intel in `24.10.0.4` (11/10/2025); Wi-Fi for AX200 remains fully supported
- **Per-DEV Wi-Fi Download Blocks**: `intel-wifi-drivers-download.txt` rebuilt to support per-device CAB blocks, mirroring the existing BT parser structure; global header ensures full backward compatibility with v2026.03.0002
- **Auto-Launch After Update Download**: After downloading a newer version, the updater now prompts to exit and launch the new version automatically (`Start-Process` + `exit 100`) — consistent with Universal Intel Chipset Device Updater behavior
- **Expanded Wi-Fi Hardware Coverage**: Added 5 previously missing adapter DEV IDs — AX203 (`2030`), AX101 (`1010`), Wireless-AC 9260 (`9260`), Wireless-AC 9461 (`9461`), Wireless-AC 9462 (`31DC`)
- **`.ICONURI` in PSScriptInfo**: PowerShell Gallery listing now displays the project icon

### Fixed
- **`pnputil` Exit Code Handling**: Both `pnputil /add-driver` and `pnputil /update-device` calls now correctly handle all real-world exit codes — `259` (driver already staged), `1` (device already on best driver, relevant for force reinstall), `3010` (success, reboot required); force reinstall now works correctly in all scenarios
- **Auto-Update Filename**: Download URL corrected from `WiFiBT-Updater-*` to `WiFi-BT-Updater-*` to match actual release filenames; v2026.03.0002 users who encounter a hash error during auto-update should download v2026.03.0003 manually
- **`$isSFX` Detection Pattern**: Pattern corrected to match actual script filename `universal-intel-wifi-bt-driver-updater*`

### Security
- **WHCP Digital Signature Verification**: See Added section above

---

## [2026.03.0002] - 2026-03-16

### Added
- **PowerShell Gallery Publishing**: Script available via `Install-Script universal-intel-wifi-bt-driver-updater`
- **Multi-Database Support**: `-beta` flag uses `intel-wifi-driver-beta.md` / `intel-bt-driver-beta.md`; `-developer` flag uses dev databases; default behavior unchanged (stable `*-latest.md`)
- **Dynamic Support Message**: Credits screen loads support message from GitHub (`data/intel-wifi-bt-message.txt`) at runtime with inline color tag support; falls back to built-in static version if GitHub is unreachable
- **Help System Unified**: `-help` and `-?` now show identical output via native `Get-Help`
- **Improved Console Exit**: When launched from a PowerShell console (not SFX), screen is cleared after credits and a clean thank-you message is displayed before returning to the prompt

### Changed
- **Architecture Rebuilt — BAT Launcher Retired**: `Universal-Intel-WiFi-BT-Updater.bat` removed from the release; the script now auto-elevates natively; tool distributed exclusively as PS1 (for administrators) or SFX EXE (for end users)
- **Script Renamed**: From `Universal-Intel-WiFi-BT-Updater.ps1` to `universal-intel-wifi-bt-driver-updater.ps1` to align with PSGallery naming convention
- **Path Handling**: Replaced hardcoded `C:\Windows\Temp` and `C:\ProgramData` with `$env:SystemRoot` and `$env:ProgramData` for compatibility with non-standard Windows installations
- **Auto Mode Cleanup**: Removed unnecessary wait at the end of `-auto` / `-quiet` runs — script exits immediately after completion

### Technical Improvements
- **Boolean Flags**: Refactored `$DebugMode` and `$SkipSelfHashVerification` from integer `0`/`1` flags to native PowerShell `[bool]` types
- **Dual Independent Detection**: Wi-Fi (PCI bus, VEN_8086) and Bluetooth (USB bus, VID_8087) detected and installed independently
- **Bluetooth Device Fallback**: BT detection attempts `Bluetooth` device class first, then falls back to full USB bus scan (`VID_8087`)
- **Version Comparison**: Replaced string comparison with `[version]` cast for correct multi-part driver version handling
- **Code Cleanup**: Removed redundant wrapper functions — logic inlined directly into core verification routines
- **Consistency**: Replaced all `cls` alias occurrences with `Clear-Host`
- **Logging**: All actions written to `%ProgramData%\wifi_bt_update.log` with timestamps and severity levels

### Security
- **Maintained Integrity Checks**: Self-hash SHA-256 verification and Intel Authenticode digital signature validation remain intact
- **Secure Temporary File Handling**: Automatic cleanup of all temporary files after completion

---

## [v24.0 (2025.11)] - 2025-11-xx — Legacy Release

### Added
- **Initial Public Release** of Universal Intel Wi-Fi and Bluetooth Drivers Updater
- **Automatic Hardware Detection**: Scans for Intel Wi-Fi and Bluetooth adapters
- **Wi-Fi and Bluetooth Support**: Wi-Fi 5 (AC) / Wi-Fi 6 (AX) / Wi-Fi 6E (AXE) / Wi-Fi 7 (BE) and Bluetooth
- **Dual-Script Architecture**: BAT launcher (`Universal-Intel-WiFi-BT-Updater.bat`) for UAC elevation + PowerShell script for core functionality
- **SHA-256 Hash Verification**: Every downloaded CAB package validated before installation
- **System Restore Point Creation**: Automatic restore point before any driver changes
- **Digital Signature Validation**: Verification of Intel Authenticode certificates

### Security
- **Multi-layer Verification**: SHA-256 hash checks + Intel digital signature validation
- **Administrator Rights Required**: Mandatory elevation via BAT launcher for system-level operations
- **Dual-Source Download**: Primary and backup download sources for reliability

---

## Release Notes Format

### Version Naming Convention
- **YYYY.MM.REVISION** format (e.g., `2026.03.0003`)
- Date component reflects release year and month
- Revision number increments with each update

### Categories Used
- **Added**: New features and capabilities
- **Changed**: Modifications to existing functionality
- **Fixed**: Bug fixes and issue resolutions
- **Security**: Security-related improvements and fixes
- **Deprecated**: Features marked for future removal (if applicable)
- **Removed**: Features removed in this version (if applicable)

---

## Links

- [Latest Release](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases/latest)
- [All Releases](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases)
- [Issue Tracker](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/issues)
- [Security Policy](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/SECURITY.md)

---

## Support

If you encounter any issues or have questions about a specific release:
1. Check [Known Issues](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/KNOWN_ISSUES.md)
2. Search [Existing Issues](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/issues)
3. Create a [New Issue](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/issues/new) with detailed information

---

**Note**: This project is independent and not affiliated with Intel Corporation. All driver packages are official Intel releases downloaded from Intel's servers.
