<p align="left">
  <a href="https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇬🇧 English</a> |
  <a href="https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_PL_2026.md">🇵🇱 Polski</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=de&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇩🇪 Deutsch</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=fr&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇫🇷 Français</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=es&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇪🇸 Español</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=pt&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇧🇷 Português</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=nl&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇳🇱 Nederlands</a>
  <br>
  <a href="https://translate.google.com/translate?sl=en&tl=zh-CN&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇨🇳 中文</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=ja&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇯🇵 日本語</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=ko&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇰🇷 한국어</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=it&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇮🇹 Italiano</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=tr&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇹🇷 Türkçe</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=ar&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇸🇦 العربية</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=hi&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇮🇳 हिन्दी</a> |
  <a href="https://translate.google.com/translate?sl=en&tl=ru&u=https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/docs/MDM-DEPLOYMENT-GUIDE_EN_2026.md">🇷🇺 Русский</a>
</p>

## Deploying Universal Intel Wi-Fi and Bluetooth Drivers Updater via MDM

Managing Intel Wi-Fi and Bluetooth driver updates across a fleet of machines used to mean either hoping Windows Update eventually delivers the right version, or manually touching each device. With the `-quiet` and `-auto` flags introduced in v2026.03.0002, the **Universal Intel Wi-Fi and Bluetooth Drivers Updater** is fully suited for silent, unattended deployment through any enterprise MDM platform.

This guide covers deployment for **Microsoft Intune**, **Microsoft SCCM / Configuration Manager**, **VMware Workspace ONE**, and **PDQ Deploy** — using the current release as of the time of writing.

---

### Prerequisites (all platforms)

Before deploying through any MDM solution, verify the following on your target machines:

- **Windows 10 build 17763 (LTSC 2019) or newer** — required for full TLS 1.2 support out-of-the-box
- **.NET Framework 4.7.2 or newer** — required for GitHub connectivity and hash verification
- **Administrator privileges** — the script auto-elevates, but the deployment context must already run as SYSTEM or a local admin account
- **Internet access to GitHub** — the script downloads driver CAB packages and verifies hashes from `raw.githubusercontent.com` and GitHub release assets; ensure these are not blocked by your proxy or firewall
- **PowerShell execution policy** — the `-ExecutionPolicy Bypass` flag in the launch command handles this; no policy change is needed on the endpoint

**Recommended launch command for all MDM deployments:**
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SystemRoot%\Temp\IntelWiFiBT\universal-intel-wifi-bt-driver-updater.ps1" -quiet
```

> **Note:** `-quiet` implies `-auto` and suppresses all console output. The full installation log is always written to `%ProgramData%\wifi_bt_update.log` regardless of quiet mode — use this for deployment verification.

---

### Microsoft Intune

Intune supports two practical deployment methods for this tool: as a **Win32 app** (recommended) or via a **PowerShell script policy**.

#### Method A: Win32 App (recommended)

This method gives you full detection rules, assignment filters, and reporting.

**1. Prepare the package**

Download the latest SFX executable from the [Releases page](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases):
```
WiFiBTUpdater-2026.03.0002-Win10-Win11.exe
```

Create a wrapper `install.cmd` that runs the SFX silently — the SFX extracts to `%SystemRoot%\Temp\IntelWiFiBT\` and automatically launches the PS1 with `-quiet`:
```batch
WiFiBTUpdater-2026.03.0002-Win10-Win11.exe
```

> The SFX package is pre-configured to extract and launch `universal-intel-wifi-bt-driver-updater.ps1 -quiet` automatically. No additional wrapper is needed unless you want custom pre/post actions.

**2. Package as .intunewin**

Use the [Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool):
```
IntuneWinAppUtil.exe -c "C:\Package" -s "WiFiBTUpdater-2026.03.0002-Win10-Win11.exe" -o "C:\Output"
```

**3. Create the Win32 app in Intune**

- Navigate to **Intune admin center** → **Apps** → **Windows** → **Add** → **Windows app (Win32)**
- Upload the `.intunewin` file
- Set the **Install command**:
  ```
  WiFiBTUpdater-2026.03.0002-Win10-Win11.exe
  ```
- Set the **Uninstall command** (no uninstall needed — drivers are managed by Windows):
  ```
  cmd.exe /c echo No uninstall required
  ```
- **Install behavior**: `System`
- **Device restart behavior**: `Determine behavior based on return codes`
  - Add return code `3010` → `Soft reboot` (Windows may flag a pending restart after driver installation)

**4. Detection rule**

Use a **File** detection rule for the log:
- **Path**: `C:\ProgramData`
- **File**: `wifi_bt_update.log`
- **Detection method**: File or folder exists

Or use a **Registry** detection rule to verify the log was written (confirming the script ran):
- **Key path**: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion`
- **Value name**: *(leave empty — detect key existence only)*

**5. Assign and deploy**

Assign to a device group. For piloting, use **Assigned** to a test group first, then roll out via **Available** or **Required** to broader groups.

---

#### Method B: PowerShell Script Policy

Simpler but with less reporting granularity. Use this for quick rollouts.

- Navigate to **Intune admin center** → **Devices** → **Scripts and remediations** → **Platform scripts** → **Add** → **Windows 10 and later**
- Upload `universal-intel-wifi-bt-driver-updater.ps1` directly
- Settings:
  - **Run this script using the logged on credentials**: `No` (run as SYSTEM)
  - **Enforce script signature check**: `No`
  - **Run script in 64-bit PowerShell host**: `Yes`
- Assign to a device group

> **Limitation:** Intune PowerShell scripts have a default timeout. For systems that create large restore points or have slow disks, the total execution time can exceed 10 minutes. If timeouts occur, switch to Method A (Win32 app) which has a configurable timeout.

---

### Microsoft SCCM / Configuration Manager

SCCM offers the most control over targeting, scheduling, and compliance reporting.

#### 1. Create the Package

- In the **Configuration Manager console**, go to **Software Library** → **Application Management** → **Packages** → **Create Package**
- **Name**: `Universal Intel Wi-Fi and BT Drivers Updater v2026.03.0002`
- **Source folder**: Point to a network share containing `WiFiBTUpdater-2026.03.0002-Win10-Win11.exe`
- Create a **Standard Program** with:
  - **Command line**:
    ```
    WiFiBTUpdater-2026.03.0002-Win10-Win11.exe
    ```
  - **Run**: `Hidden`
  - **Program can run**: `Whether or not a user is logged on`
  - **Run with administrative rights**: ✅ checked

#### 2. Alternatively — deploy the PS1 directly

If you prefer deploying the script without the SFX wrapper:

- Place `universal-intel-wifi-bt-driver-updater.ps1` on your distribution point
- Set the **Command line** to:
  ```
  powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "universal-intel-wifi-bt-driver-updater.ps1" -quiet
  ```
- **Run**: `Hidden`
- **Program can run**: `Whether or not a user is logged on`

#### 3. Distribution and Deployment

- **Distribute content** to your Distribution Points
- **Deploy** to a Device Collection
  - **Purpose**: `Required` for mandatory rollout, `Available` for self-service
  - **Schedule**: Set a maintenance window if you want to control timing (recommended — the script creates a restore point which can be I/O intensive, and Wi-Fi connectivity will be briefly interrupted during driver installation)
  - **User experience** → **Allow clients to run software independently of assignments**: depends on your policy
  - **Return codes**: Add `3010` as a **Soft Reboot** if not already present

#### 4. Compliance verification

Create a **Configuration Item** that checks for the existence of `%ProgramData%\wifi_bt_update.log` or queries the last write time of that file to confirm the script ran within the expected window.

---

### VMware Workspace ONE (UEM)

Workspace ONE supports deployment via **Freestyle Orchestrator** or the classic **Scripts** and **Sensors** approach.

#### Method A: Internal App (SFX EXE)

- In the **Workspace ONE UEM console**, go to **Apps & Books** → **Applications** → **Native** → **Add Application** → **Upload**
- Upload `WiFiBTUpdater-2026.03.0002-Win10-Win11.exe`
- **Deployment options**:
  - **Install Command**: *(leave default — SFX handles everything)*
  - **Admin Privileges**: `Yes`
  - **Install Context**: `Device`
- Under **Files**, add a **Post-Install Script** if you need to verify the log:
  ```powershell
  Test-Path "$env:ProgramData\wifi_bt_update.log"
  ```

#### Method B: Scripts (PowerShell)

- Navigate to **Resources** → **Scripts** → **Add** → **Windows**
- Upload or paste `universal-intel-wifi-bt-driver-updater.ps1`
- **Execution Context**: `System`
- **Execution Architecture**: `64-bit`
- **Timeout**: Set to `900` seconds (15 minutes) to account for restore point creation on slower systems
- Under **Assignment**, target the appropriate Smart Group

#### Sensor for compliance reporting

Create a **Sensor** to report back whether the update ran successfully:

```powershell
# Returns the last lines of the log containing completion status
if (Test-Path "$env:ProgramData\wifi_bt_update.log") {
    $last = Get-Content "$env:ProgramData\wifi_bt_update.log" | Select-Object -Last 5
    return ($last -join " ")
} else {
    return "Log not found"
}
```

- **Evaluation type**: `String`
- Assign to the same Smart Group as the deployment

---

### PDQ Deploy

PDQ Deploy is the fastest option for on-premise environments and ad-hoc rollouts.

#### 1. Create a new Package

- Open **PDQ Deploy** → **New Package**
- **Name**: `Universal Intel Wi-Fi and BT Drivers Updater v2026.03.0002`

#### 2. Add a Step — Install (SFX)

- **Step type**: `Install`
- **Install file**: Browse to `WiFiBTUpdater-2026.03.0002-Win10-Win11.exe`
- **Run as**: `Deploy User (PDQ)` or `Local System` — either works since the script auto-elevates
- **Success codes**: Add `0`, `3010`

#### 3. Alternatively — PowerShell Step

If deploying the PS1 directly (e.g. from a file share):

- **Step type**: `PowerShell`
- **Script**:
  ```powershell
  $dest = "$env:SystemRoot\Temp\IntelWiFiBT"
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  Copy-Item "\\your-share\scripts\universal-intel-wifi-bt-driver-updater.ps1" "$dest\universal-intel-wifi-bt-driver-updater.ps1" -Force
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$dest\universal-intel-wifi-bt-driver-updater.ps1" -quiet
  ```
- **Run as**: `Local System`
- **Timeout**: `900` seconds

#### 4. Schedule or deploy on-demand

- Use **Auto Deployments** to schedule recurring runs (e.g. monthly, after Intel releases new driver packages)
- Or deploy **On Demand** to individual machines or groups from the PDQ Deploy console

#### 5. Verify results

After deployment, use **PDQ Inventory** to query the log file across machines:
- **Scanner** → **File** → `C:\ProgramData\wifi_bt_update.log` → check **Last Modified** date

---

### Verifying a successful deployment (all platforms)

Regardless of the MDM platform used, the primary verification method is the log file:

```
%ProgramData%\wifi_bt_update.log
```

A successful run ends with a line similar to:
```
[2026-03-16 14:32:07] [INFO] Script execution completed in 3.47 minutes with 0 errors
```

A run with issues will contain `[ERROR]` entries — these are always written to the log even in `-quiet` mode, so the log is always the authoritative source of truth.

**Quick PowerShell check across a fleet (run from your management workstation):**
```powershell
$computers = Get-Content "C:\computers.txt"
foreach ($pc in $computers) {
    $log = "\\$pc\c$\ProgramData\wifi_bt_update.log"
    if (Test-Path $log) {
        $last = Get-Content $log | Select-Object -Last 1
        [PSCustomObject]@{ Computer = $pc; Status = $last }
    } else {
        [PSCustomObject]@{ Computer = $pc; Status = "Log not found" }
    }
} | Format-Table -AutoSize
```

---

### Notes on reboot behavior

The script installs Wi-Fi and Bluetooth drivers delivered as CAB packages. Windows will typically not force an immediate reboot, but a **restart is recommended** to fully activate the new driver version. Additionally, your Wi-Fi and/or Bluetooth connection will be **briefly interrupted** during driver installation — this is expected behavior. Plan your deployment windows accordingly:

- In **Intune**: use the `3010` soft reboot return code and configure a maintenance window or allow the user to defer
- In **SCCM**: configure the deployment's **User Experience** → **Commit changes at deadline or during maintenance window**
- In **Workspace ONE**: use a post-install reboot policy set to `Defer`
- In **PDQ Deploy**: add a **Reboot** step after the install step, or handle via your standard patch reboot policy

---

Deploying Wi-Fi and Bluetooth driver updates at scale used to require custom packaging and scripting from scratch. The `-quiet` flag makes this tool a drop-in for any MDM workflow — the hard part (detecting the right hardware, matching CAB packages, verifying hashes, creating restore points) is handled automatically.

👉 **[Universal Intel Wi-Fi and Bluetooth Drivers Updater — GitHub](https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater)**

---

Author: Marcin Grygiel aka FirstEver ([LinkedIn](https://www.linkedin.com/in/marcin-grygiel))
