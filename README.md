# Universal Intel Wi-Fi and Bluetooth Driver Updater 🚀

[![GitHub release](https://img.shields.io/github/v/release/FirstEverTech/Universal-Intel-WiFi-BT-Updater)](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases)
[![GitHub license](https://img.shields.io/github/license/FirstEverTech/Universal-Intel-WiFi-BT-Updater)](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/FirstEverTech/Universal-Intel-WiFi-BT-Updater)](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/issues)
[![Windows](https://img.shields.io/badge/Windows-10%2B-blue)](https://www.microsoft.com/windows)
[![VirusTotal](https://img.shields.io/badge/VirusTotal-0%2F98-green)](https://www.virustotal.com/gui/url/51bdede44cfa784c65a48cb4a0b5c077960425b8728c98b7110b8bf1d00432e9?nocache=1)

Automated tool to download and install the latest Intel Wi-Fi and Bluetooth drivers directly from Windows Update servers, including **early access driver versions** that may not yet be available on Intel's official website or distributed through standard Windows Update.

## ✨ Features

- 🔍 **Automatic Detection** - Identifies Intel Wi-Fi and Bluetooth adapters
- 📊 **Version Comparison** - Checks current driver versions vs latest available
- ⬇️ **Direct Download** - Downloads drivers from official Windows Update servers
- 🛡️ **Safe Installation** - Uses Windows pnputil for reliable driver installation
- 🧹 **Clean Operation** - Automatically cleans temporary files
- 🔧 **Debug Mode** - Includes debug version for troubleshooting
- ⚡ **Force Reinstall** - Option to force reinstall drivers even if versions match
- 🔄 **Aggressive Method** - Uses disable/enable + pnputil for reliable updates

## 📋 Supported Devices

### 📡 Wi-Fi Adapters
- **Wi-Fi 7**: BE201, BE202, BE200
- **Wi-Fi 6E**: AX411 (Gig+), AX211 (Gig+), AX210 (Gig+)
- **Wi-Fi 6**: AX203, AX200 (Gig+), AX201 (Gig+), AX101, Desktop Kit
- **Wi-Fi 5**: AC 9560, AC 9462, AC 9461, AC 9260
- **Legacy**: All other Intel wireless adapters

### 📱 Bluetooth Adapters
- **Intel Bluetooth USB** (VID_8087): 0025, 0026, 0029, 0032, 0033, 0036, 0037, 0038, 0AAA
- **Intel Bluetooth PCI** devices
- **Intel Bluetooth UART** devices  
- **Intel Killer Bluetooth** adapters

## 🛠️ Usage

### Option 1: SFX EXE (Recommended)
1. Download the self-extracting executable:  
   `WiFi-BT-Updater-24.0-2025.11-Driver64-Win10-Win11.exe` from the repository
2. Run the EXE as Administrator
3. Follow the on-screen prompts to scan and update your drivers

### Option 2: Simple Batch File
1. Download both `Universal-Intel-WiFi-BT-Updater.bat` and `Universal-Intel-WiFi-BT-Updater.ps1`
2. Place both files in the same directory
3. Run `Universal-Intel-WiFi-BT-Updater.bat` as Administrator
4. Follow the on-screen prompts to scan and update your drivers

### Option 3: Direct PowerShell
1. Download `Universal-Intel-WiFi-BT-Updater.ps1`
2. Open PowerShell as Administrator
3. Run: `powershell -ExecutionPolicy Bypass -File "Universal-Intel-WiFi-BT-Updater.ps1"`

## 🔧 Driver Database & Compatibility

This tool uses real-time driver information from official Windows Update servers:

- **Wi-Fi Drivers**: Version 24.0.2.1 (October 2025)
- **Bluetooth Drivers**: Version 24.0.1.1 (September 2025)
- **Hardware Support**: Complete Intel Wi-Fi 5/6/6E/7 and Bluetooth device coverage
- **Platform Support**: Windows 10 and Windows 11 (64-bit)

The script automatically:
- Detects your specific Intel wireless hardware
- Downloads appropriate drivers for your devices
- Performs safe driver installation using Windows pnputil
- Provides version comparison and update status

## ⚠️ Important Notes

- **Administrator Rights Required**: The script must be run as Administrator for proper functionality
- **Temporary Disconnections**: Wi-Fi and Bluetooth will be temporarily disconnected during update
- **Internet Connection Required**: Needed to download driver information and packages
- **Automatic Cleanup**: Temporary files are automatically removed after installation
- **Force Reinstall Option**: Available for troubleshooting or fresh installations

## 🔍 Troubleshooting

### Common Issues

1. **"Script cannot run"** - Ensure you're running as Administrator and both files are in the same directory
2. **"No Intel adapters found"** - Verify your system uses Intel Wi-Fi/Bluetooth hardware
3. **Installation failures** - Check internet connection and try debug mode
4. **Driver not updating** - Use force reinstall option to override version checks

### Debug Mode

For detailed logging and troubleshooting:
1. Use the debug versions: `Debug-Update-Intel-WiFi-BT.bat` and `Debug-Update-Intel-WiFi-BT.ps1`
2. Provides extensive logging for issue diagnosis
3. Shows detailed driver installation progress

### Manual Update

If automatic detection fails, you can manually update the driver information in the source files with the latest links from official Intel sources.

## 🤝 Contributing

Special thanks to the Station Drivers community, particularly [@atplsx](https://github.com/atplsx) who share driver information that makes tools like this possible.
Driver information is maintained based on official Intel driver releases and Windows Update catalog. If you have access to newer driver information or hardware support improvements, please contribute to the project.

We welcome contributions for:
- New driver versions or hardware support
- Improvements to detection logic
- Bug fixes or feature enhancements
- Additional device compatibility

## 📄 License

MIT License © 2025 [FirstEverTech](https://github.com/FirstEverTech)  
This project is provided as-is for educational and convenience purposes.

## 📸 Screenshot

<img width="602" height="832" alt="Universal Intel WiFi BT Updater" src="https://github.com/user-attachments/assets/4408e0a5-20e9-4f65-9bb0-9d0687e497bc" />

## ⚠️ Disclaimer

This tool is not affiliated with Intel Corporation. Drivers are sourced from official Windows Update servers. Use at your own risk. Always backup your system before updating drivers.

## 📞 Support

If the updater does not detect your hardware, please use the additional tool Intel Chipset HW_ID Detection Tool and send us the generated log.
Files: `Get-Intel-HWIDs.ps1` and `Get-Intel-HWIDs.bat`.

- **Repository**: [https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater)
- **Issues**: [GitHub Issues](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/issues)

## 🧑‍💻 Author/Maintainer

**Marcin Grygiel**
- 🌐 **Website**: [www.firstever.tech](https://www.firstever.tech)
- 💼 **LinkedIn**: [Marcin Grygiel](https://www.linkedin.com/in/marcin-grygiel/)
- 🔧 **GitHub**: [FirstEverTech](https://github.com/FirstEverTech)
- 💖 **Support**: [PayPal](https://www.paypal.com/donate/?hosted_button_id=48VGDSCNJAPTJ) | [Buy Me a Coffee](https://buymeacoffee.com/firstevertech)

---

**Note**: This tool is provided as-is for educational and convenience purposes. While we strive for accuracy, always verify critical driver updates through official channels. The complete hardware compatibility list is available in the script source code.
