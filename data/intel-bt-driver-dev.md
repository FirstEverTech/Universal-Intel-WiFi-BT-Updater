# Intel Wireless Bluetooth Drivers Latest

Latest Version = 24.50.0.4  
Release Date = 08/05/2026

## Supported USB Devices

| PID  | Chipset         | Generation      | Bluetooth | Latest Version | Release Date |
|------|-----------------|-----------------|-----------|----------------|--------------|
| 0038 | BE200 stepping  | Wi-Fi 7         | 5.4       | 24.50.0.4      | 08/05/2026   |
| 0037 | BE202 / BE204   | Wi-Fi 7         | 5.4       | 24.50.0.4      | 08/05/2026   |
| 0036 | BE200           | Wi-Fi 7         | 5.4       | 24.50.0.4      | 08/05/2026   |
| 0033 | AX211           | Wi-Fi 6E (CNVi) | 5.3       | 24.40.10.3     | 28/04/2026   |
| 0043 | AX211           | Wi-Fi 6E (CNVi) | 5.3       | 24.40.10.3     | 28/04/2026   |
| 0032 | AX210           | Wi-Fi 6E        | 5.3       | 24.40.10.3     | 28/04/2026   |
| 0029 | AX200           | Wi-Fi 6         | 5.2       | 24.10.0.4      | 11/10/2025   |
| 0026 | AX201           | Wi-Fi 6 (CNVi)  | 5.2       | 24.40.10.3     | 28/04/2026   |
| 0AAA | 9460 / 9560     | Wi-Fi 5         | 5.2       | 24.40.10.3     | 28/04/2026   |
| 0025 | 9260            | Wi-Fi 5         | 5.2       | 24.40.10.3     | 28/04/2026   |

## Supported PCI Devices

| DEV  | Chipset         | Generation      | Bluetooth | Latest Version | Release Date |
|------|-----------------|-----------------|-----------|----------------|--------------|
| E376 | BE202 / BE204   | Wi-Fi 7         | 5.4       | 24.50.0.4      | 08/05/2026   |
| E476 | AX210 / BE200   | Wi-Fi 6E/7      | 5.3/5.4   | 24.50.0.4      | 08/05/2026   |
| 4D76 | AX211           | Wi-Fi 6E (CNVi) | 5.3       | 24.50.0.4      | 08/05/2026   |
| A876 | AX200 / AX201   | Wi-Fi 6/CNVi    | 5.2       | 24.50.0.4      | 08/05/2026   |


## Explanatory Notes

### Intel's Dual-INF Packaging

Since early 2025, Intel has been bundling multiple Bluetooth controller families into a single CAB file, but with only one version number on the file name. Inside that CAB there are several INF files, each with its own DriverVer. For example, the CAB labelled 24.50.0.4 may contain:
- One INF for newer controllers with version 24.50.0.4
- Another INF for older controllers (including AX201/AX200/AX210 etc.) with version 24.40.10.3

When Windows installs the CAB, it automatically picks the correct INF for your specific hardware and reports that INF's version. The scanner now reads the real DriverVer for each PID directly from the INF file inside the CAB, ensuring the database shows the version that will actually be installed on your system.

### Bluetooth Version Updates

The Bluetooth version reported for each device (e.g., 5.2, 5.3, 5.4) reflects the latest capability supported by the most recent Intel driver package for that specific PID. Intel has increased Bluetooth feature support for several adapters through firmware and driver updates over time. Some chipsets were originally launched with one Bluetooth version but later gained support for newer Bluetooth specifications.

If you believe a Bluetooth version is incorrect based on your HCI/LMP values, please open an issue on GitHub with a screenshot of your Bluetooth specifications.

---

**Source:** [Universal Intel Wi-Fi & Bluetooth Drivers Updater](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater)
**Project by:** [Marcin Grygiel](https://www.linkedin.com/in/marcin-grygiel/)
**Last Update:** 17-06-2026
