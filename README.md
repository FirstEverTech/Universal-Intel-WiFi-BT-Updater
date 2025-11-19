# Universal Intel Wi-Fi and Bluetooth Driver Updater 🚀

[![GitHub release](https://img.shields.io/github/v/release/FirstEverTech/Universal-Intel-WiFi-BT-Updater)](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases)
[![GitHub license](https://img.shields.io/github/license/FirstEverTech/Universal-Intel-WiFi-BT-Updater)](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/FirstEverTech/Universal-Intel-WiFi-BT-Updater)](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/issues)
[![Windows](https://img.shields.io/badge/Windows-10%2B-blue)](https://www.microsoft.com/windows)
[![VirusTotal](https://img.shields.io/badge/VirusTotal-0%2F98-green)](https://www.virustotal.com/gui/url/51bdede44cfa784c65a48cb4a0b5c077960425b8728c98b7110b8bf1d00432e9?nocache=1)

This tool automatically fetches and installs the newest Intel Wi-Fi and Bluetooth drivers directly from Windows Update servers. These are final, WHQL-certified versions that are often one release ahead of what's available on Intel's website or through standard Windows Update, giving you early access to the latest improvements and fixes.

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

# Intel & Killer Wireless Adapter Product Portfolio

## 📡 Wi-Fi Adapters

### **Wi-Fi 7 (BE Series)**
| Series | Intel Models | Killer Models | Key Features |
|--------|--------------|---------------|--------------|
| **BE200 Series** | BE200, BE202 | BE1750x, BE1750w, BE1775x, BE1775w | 320MHz channel width, 2x2 MIMO |
| **BE201 Series** | BE201 | BE1750i, BE1750s | 320MHz channel width, 2x2 MIMO |
| **BE211 Series** | BE211, BE213 | BE1775i, BE1775s | 160-320MHz channel width, 2x2 MIMO |

### **Wi-Fi 6E (AX Series)**
| Series | Intel Models | Killer Models | Key Features |
|--------|--------------|---------------|--------------|
| **AX210 Series** | AX210 | AX1675x, AX1675w | 160MHz channel width, 2x2 MIMO |
| **AX211 Series** | AX211 | AX1675i, AX1675s | 160MHz channel width, 2x2 MIMO |
| **AX411 Series** | AX411 | AX1690i, AX1690s | 160MHz channel width, 2x2 MIMO |

### **Wi-Fi 6 (AX Series)**
| Series | Intel Models | Killer Models | Key Features |
|--------|--------------|---------------|--------------|
| **AX200 Series** | AX200 | AX1650x, AX1650w | 160MHz channel width, 2x2 MIMO |

### **Wi-Fi 5 (AC Series)**
| Series | Intel Models | Killer Models | Key Features |
|--------|--------------|---------------|--------------|
| **AC 9560 Series** | AC 9560 | AC 1550i, AC 1550s | 160MHz channel width, 2x2 MIMO |
| **AC 9260 Series** | AC 9260 | AC 1550 | 160MHz channel width, 2x2 MIMO |
| **AC 9461/62 Series** | AC 9461, AC 9462 | - | 1x1 MIMO configuration |

## 📱 Bluetooth Adapters

### **Intel Bluetooth Solutions**
- **USB Interface Devices**: VID_8087: 0025, 0026, 0029, 0032, 0033, 0036, 0037, 0038, 0AAA
- **PCI Interface Devices**: Various PCIe-based Bluetooth controllers
- **UART Interface Devices**: Serial protocol Bluetooth adapters

### **Killer Bluetooth Solutions**
- Integrated Bluetooth with Killer networking stack
- Optimized for gaming and high-performance applications
- Coexistence with Killer Wi-Fi technologies

## 🏷️ Product Identification

### **Model Number Convention**
- **Intel**: [Technology][Model Number] (e.g., AX210, BE200)
- **Killer**: [Technology][Model Number][Interface] (e.g., AX1675i, BE1750s)

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

## 🔍 Troubleshooting

### Common Issues

1. **"Script cannot run"** - Ensure you're running as Administrator and both files are in the same directory
2. **"No Intel adapters found"** - Verify your system uses Intel Wi-Fi/Bluetooth hardware
3. **Installation failures** - Check internet connection

## 🤝 Contributing

Special thanks to [@atplsx](https://github.com/atplsx) who share driver information that makes tools like this possible.
This tool is updated based on official Intel driver releases and the Windows Update catalog. If you have access to newer driver information or hardware informations, please support the project.

We welcome contributions for:
- New driver versions or hardware
- Bug reports or script improvements

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📸 Screenshot

<img width="602" height="832" alt="Universal Intel WiFi BT Updater" src="https://github.com/user-attachments/assets/4408e0a5-20e9-4f65-9bb0-9d0687e497bc" />

## ⚠️ Disclaimer

This tool is not affiliated with Intel Corporation. Drivers are sourced from official Windows Update servers. Use at your own risk. Always backup your system before updating drivers.

## 📞 Support

If the updater does not detect your hardware, please use the additional tool Intel Chipset HWID Detection Tool and send us the generated log.
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
