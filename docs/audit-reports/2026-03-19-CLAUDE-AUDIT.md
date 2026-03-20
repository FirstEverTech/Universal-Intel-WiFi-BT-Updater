# Security and Code Quality Audit
## Universal Intel Wi-Fi and Bluetooth Drivers Updater v2026.03.0002

**Audit Date:** March 19, 2026  
**Auditor:** Claude (Anthropic AI) — Sonnet 4.6  
**Version Audited:** v2026.03.0002 (initial public release)  
**Companion Audit Reference:** 2026-03-11-CLAUDE-AUDIT.md (Chipset Updater v2026.03.0012, Score: 9.1/10)  
**Repository:** https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater  
**Report Version:** 1.1 (errata — three false-positive bug reports retracted; score revised upward)

---

## Executive Summary

This is the first Claude audit of the Universal Intel Wi-Fi and Bluetooth Drivers Updater — a focused companion tool to the Intel Chipset Device Updater, which has accumulated three audits and a current score of 9.1/10. The Wi-Fi/BT tool inherits the full security architecture of its sibling: self-hash verification, SHA-256 download verification, dual sources, automatic restore points, and auto-elevation. The core engine is proven and mature.

The score for this initial release is **8.7/10**.

The gap relative to the chipset tool (9.1/10) is explained by two factors: (1) this is a v1.0 with no real-world track record yet; and (2) the explicit Intel driver signature verification step present in the chipset tool is absent here. Neither is an architectural weakness; both are expected to resolve as the tool matures. No functional bugs were found.

---

## Errata (v1.0 → v1.1)

The initial draft of this report (v1.0, same date) contained three bug reports. All three were incorrect and have been retracted.

| ID | Original Claim | Correction |
|----|---------------|------------|
| BUG-1 | `-?` accepted by parser but silently ignored | PowerShell intercepts `-?` natively as a `Get-Help` alias before `$args` reaches the script. The script never receives it; `Get-Help` is invoked directly by the shell. Behaviour confirmed correct. |
| BUG-2 | Four Wi-Fi DEV IDs present in database but missing from `$supportedWiFiDEVs` | Intel removed support for these HWIDs (`DEV_9260`, `DEV_9461`, `DEV_2030`, `DEV_1010`) in the current driver package. The omission from the detection array is intentional and correct. The database entry is historical documentation. |
| BUG-3 | `Compare-Versions` ignores year/month — cross-month version boundary would produce wrong result | The version scheme `YYYY.MM.NNNN` uses a *continuously incrementing* release counter that is never reset between months. The scenario where `0001 > 0003` cannot arise by design. Comparison on the third segment alone is correct for this format. |

The retraction of BUG-2 (medium severity, functionality impact) and BUG-1/BUG-3 (low severity) raises the score from 8.4 to **8.7**.

---

## Key Differences vs. Intel Chipset Device Updater

| Dimension | Chipset Updater | Wi-Fi/BT Updater |
|-----------|----------------|------------------|
| Installer type | EXE/MSI | CAB (expand.exe + pnputil) |
| Installation validation | Explicit `Get-AuthenticodeSignature` | Implicit (pnputil enforces signing) |
| Database structure | Large, scanner-generated | Two compact files (flat + multi-block) |
| Data files | `intel-chipset-driver-latest.md` + DL list | `*-wifi-*` + `*-bt-*` (split by component) |
| Detection | PCI VEN/DEV scan | PCI DEV scan (Wi-Fi) + USB VID/PID scan (BT) |
| Companion scanner tool | `Intel-Platform-Scanner.ps1` | Not present (not needed) |
| Line count | 2,483 | 1,919 |
| Track record | 34,000+ downloads, 1 confirmed bug | Initial release |

---

## 1. System Architecture and Security

### 1.1 Execution Flow

```
WiFiBT-Updater-2026.03.0002-Win10-Win11.exe  (SFX, signed)
└── universal-intel-wifi-bt-driver-updater.ps1   (all-in-one)
```

**Flow:**
1. Argument parsing → `$AutoMode`, `$QuietMode`, `$DebugMode`, `$Beta`, `$Developer`, `$SkipVerification`
2. Auto-elevation if not running as Administrator
3. Screen 1 — Compatibility pre-checks (Windows build, .NET 4.7.2+, GitHub TLS connectivity)
4. Self-hash verification against GitHub-hosted `.sha256`
5. Version check — offers download of newer updater version
6. Screen 2 — Hardware detection (Wi-Fi via PnpDevice/PCI, Bluetooth via PnpDevice/USB), version analysis
7. Screen 3 — Confirmation + disconnection warning, system restore point
8. Screen 4 — Download (primary → backup fallback), SHA-256 verification, CAB extraction, pnputil installation
9. Cleanup, summary, credits screen

**Assessment:** Architecture is identical to the chipset tool and equally sound. **Rating: 9/10**

---

### 1.2 Self-Hash Verification

Unchanged from chipset tool — downloads a `.sha256` file from GitHub Releases, computes local hash via `Get-FileHash -Algorithm SHA256`, compares. Three hash-file format patterns handled; BOM stripped correctly (line 656: `TrimStart([char]0xEF, [char]0xBB, [char]0xBF)`). Three retry attempts on hash calculation.

```powershell
$hashFileUrl = "https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases/download/v$ScriptVersion/universal-intel-wifi-bt-driver-updater-$ScriptVersion-ps1.sha256"
```

**Assessment:** ✅ Correct and robust. **Rating: 8.5/10** (temp directory ACL still not restricted; see Section 10, P1).

---

### 1.3 SHA-256 Verification of Downloaded Drivers

**Wi-Fi:** Single CAB for all devices. One SHA-256 hash in the download list covers the universal package.

**Bluetooth:** Per-PID CAB. Each block in `intel-bt-drivers-download.txt` carries its own SHA-256. The parser correctly maps the detected PID to the right block and passes its hash to `Verify-FileHash`.

```powershell
$btResult = Install-DriverWithFallback `
    -ExpectedHash    $btInfo.Block.SHA256 `
    ...
```

**Assessment:** ✅ Both components properly verified before installation. **Rating: 9/10**

---

### 1.4 Intel Driver Signature Check — Gap vs. Chipset Tool

The chipset updater calls `Get-AuthenticodeSignature` on the downloaded EXE/MSI and validates that the signer is Intel. This tool does not include that step for CAB files.

This is partially mitigated: `pnputil /add-driver` on modern Windows enforces driver signing policy (WHQL or cross-certificate) and will refuse to install unsigned drivers. The security outcome is equivalent in practice. However, the explicit pre-installation check that provides audit-trail logging and user-visible confirmation is absent, creating an inconsistency with the companion tool's approach.

**Recommendation [P2]:** Add an explicit `Get-AuthenticodeSignature` check on the extracted `.cat` file before calling `pnputil`, consistent with the chipset tool.

**Assessment:** ⚠️ Acceptable but inconsistent with companion tool standards. **Rating: 8.0/10**

---

### 1.5 Dual Download Sources

Both Wi-Fi and Bluetooth drivers have a GitHub archive primary source and a Windows Update backup URL. The fallback logic in `Install-DriverWithFallback` is correct and uses the same four-phase error coding (`1a`, `1b`, `2a`, `2b`) as the chipset tool.

**Assessment:** ✅ **Rating: 9.5/10**

---

### 1.6 System Restore Point

Identical implementation to chipset tool. Handles the 1440-minute Windows frequency limit gracefully, with user prompt (or AutoMode auto-continue). `Enable-ComputerRestore` called proactively before `Checkpoint-Computer`.

**Assessment:** ✅ **Rating: 9/10**

---

### 1.7 Security Layers Summary

| Layer | Status | Notes |
|-------|--------|-------|
| Self-hash verification | ✅ Active | GitHub-hosted `.sha256`, BOM-safe |
| SHA-256 download verification | ✅ Active | Per-component, per-PID for BT |
| Dual download sources | ✅ Active | GitHub + Windows Update |
| System Restore Point | ✅ Active | Pre-installation, frequency-aware |
| Auto-elevation | ✅ Active | UAC prompt with graceful failure |
| TLS 1.2 enforcement | ✅ Active | All web requests |
| Intel driver signing | ✅ Implicit | Via pnputil; no explicit pre-check |
| Temp directory ACL | ❌ Not restricted | Carried from chipset audit (P1) |

---

## 2. Code Quality

### 2.1 Inherited Strengths

All code quality improvements from the chipset tool v2026.03.0011/0012 are present from day one:

- `[bool]$DebugMode` and `[bool]$SkipSelfHashVerification` — no integer-flag anti-pattern
- `$env:SystemRoot` and `$env:ProgramData` — no hardcoded paths
- `Clear-Host` throughout — no `cls` alias
- `Join-Path` for all path construction
- `PSScriptInfo` block with GUID, tags, license URI, project URI
- Full `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES` in help block
- Manual argument parser with `$allowedSwitches` whitelist and positional-argument rejection

**Rating: 8.7/10**

---

### 2.2 Polish-Language Comments in Production Code

Four comments in Polish remain in the production script. While harmless, they are inconsistent with the project's English-only documentation and reduce readability for international contributors.

```powershell
# Line 838:  # Supported Intel Wi-Fi DEV IDs (PCI) - UZUPEŁNIONE O NOWE ID Z BAZY
# Line 969:  # POPRAWIONA FUNKCJA PARSUJĄCA nowy format (4 kolumny)
# Line 1635: # Wyświetlanie Wi-Fi
# Line 1675: # Wyświetlanie Bluetooth
```

**Recommendation [P3]:** Translate to English before the next release.

---

### 2.3 Temp File Naming

`Get-Random` is used for temp file and directory names:
```powershell
$tempCab     = "$tempDir\temp_$(Get-Random).cab"
$extractPath = "$tempDir\extracted_$(Get-Random)"
```

`Get-Random` is not cryptographically random and is theoretically predictable. In a privilege-escalated context, a predictable temp path is a low-risk TOCTOU vector. Carried from chipset audit.

**Recommendation [P3]:** Replace `Get-Random` with `[System.Guid]::NewGuid()`.

---

### 2.4 Commented-Out Code (Screen 4)

Line 595 contains a commented-out `Write-Host ""` with no explanation:

```powershell
function Show-Screen4 {
    ...
#    Write-Host ""
}
```

**Recommendation [P4]:** Remove or document intent.

---

## 3. Data Files and Parsers

### 3.1 `intel-wifi-drivers-download.txt` — Simple Flat Structure

Clean, correctly parsed by `Parse-WiFiDownloadList`. All five fields (`Name`, `DriverVer`, `SHA256`, `Link`, `Backup`) present and correctly extracted.

**Assessment:** ✅ **Rating: 9.5/10**

---

### 3.2 `intel-bt-drivers-download.txt` — Multi-Block Structure

The multi-block format (one header block with `DriverVer`, N per-PID blocks each with `USB\VID...` HWIDs, `SHA256`, `Link`, `Backup`) is correctly handled by `Parse-BTDownloadList`. The parser splits on blank lines, identifies blocks by the presence of HWID lines or `DriverVer`, and builds a typed `List[hashtable]` of blocks.

`Get-BTBlockForDevice` correctly iterates blocks and matches on PID, independent of REV suffix. This is the right design: a single CAB per PID covers all hardware revisions of that adapter, and pnputil/INF HWID matching handles REV-level differentiation at installation time.

**Assessment:** ✅ Structurally sound and correct for the data shape. **Rating: 9/10**

**Note on robustness:** Parsing relies on blank-line block separation. An accidental extra blank line in the data file could split a block in two, causing `$blockData.Link` to be null and the block to be silently dropped. This is a data-maintenance risk, not a code bug. The author controls the data file, so the risk is low.

---

### 3.3 `intel-wifi-driver-latest.md` and `intel-bt-driver-latest.md`

Both files are correctly structured for their parsers. The Wi-Fi MD uses a 4-column table (`Device ID | Chipset | Models | Generation`); the BT MD uses a 4-column table (`PID | Chipset | Generation | Bluetooth`). Parsers correctly handle headers, separator rows, and data rows. `Latest Version` and `Release Date` fields are correctly extracted.

**Assessment:** ✅ **Rating: 9/10**

---

## 4. Hardware Detection

### 4.1 Wi-Fi Detection (`Get-IntelWiFiDevice`)

Queries `Get-PnpDevice -Class "Net"` filtered to `Status -eq "OK"`, then matches `PCI\VEN_8086&DEV_([A-F0-9]{4})`. Correct, minimal, no unnecessary scope. Returns first match — correct, as a system has at most one active Intel Wi-Fi adapter. The `$supportedWiFiDEVs` array is intentionally authoritative, reflecting current Intel driver support.

**Assessment:** ✅ **Rating: 9/10**

---

### 4.2 Bluetooth Detection (`Get-IntelBTDevice`)

Queries `Get-PnpDevice -Class "Bluetooth"` first, falls back to `Get-PnpDevice | Where-Object { $_.HardwareID -like "*VID_8087*" }` if the Bluetooth class returns nothing. This two-stage approach correctly handles configurations where the BT adapter is enumerated under the USB class rather than the Bluetooth class.

**Assessment:** ✅ More robust than a class-only query. **Rating: 9.5/10**

---

### 4.3 Driver Version Detection (`Get-CurrentDriverVersion`)

Two-tier lookup: `DEVPKEY_Device_DriverVersion` property first, then `Win32_PnPSignedDriver` via CIM. Consistent with chipset tool.

**Assessment:** ✅ **Rating: 9/10**

---

## 5. Version Comparison

### 5.1 Updater Self-Update Check (`Compare-Versions`)

Uses `Get-VersionNumber` which extracts only the third segment (`RELEASE`) from `YYYY.MM.RELEASE`. Correct because the release counter is continuously incrementing and never resets between months — the comparison is monotonically valid by design.

**Assessment:** ✅ **Rating: 9/10**

### 5.2 Driver Version Comparison (Installation Decision)

Uses `[version]` casting directly, which correctly handles `major.minor.build.revision` driver version strings like `24.20.2.1`.

**Assessment:** ✅ **Rating: 9.5/10**

---

## 6. User Experience

### 6.1 Screen Structure and Messaging

Four-screen flow is clear and well-labeled. Screen 3 includes an explicit warning that Wi-Fi and Bluetooth connections will temporarily drop during installation — valuable context that many driver tools omit. `AutoMode` respected at every prompt.

**Assessment:** ✅ **Rating: 9/10**

---

### 6.2 Final Credits Screen

The dynamic `intel-wifi-bt-message.txt` approach (with embedded fallback) is cleanly implemented. `Write-ColorLine` parser handles tag nesting, gracefully degrades on malformed tags, and maps keypresses to URLs dynamically. Interactive and `-auto` paths handled correctly.

**Assessment:** ✅ **Rating: 9/10**

---

### 6.3 CAB Installation Feedback

Step-by-step feedback at each stage. The four-phase error code system (`1a`/`1b`/`2a`/`2b`) for download failures gives both user and log enough context to diagnose failures.

**Assessment:** ✅ **Rating: 8.5/10**

---

## 7. Documentation

### 7.1 README.md

Comprehensive, mirrors the quality of the chipset project: full table of contents with anchor links, feature descriptions, system requirements, quick start, security section, FAQ, performance metrics, platform support table, VirusTotal badge (0/95), known issues link, support/donation section.

**Note:** The `AI_Audits_Score` badge currently reads `NA/10` — update to `8.7/10` after publication of this report.

**Assessment:** ✅ **Rating: 9.0/10**

---

### 7.2 Absent Articles vs. Chipset Project

No equivalent of "The Whole Truth About Intel Chipset Device Software" or "Behind the Project: Making Of". Given the simpler design of the Wi-Fi/BT tool, this is an acceptable gap. MDM deployment guide and driver verification guides have been ported.

**Assessment:** Acceptable. Not penalised.

---

## 8. Compatibility and Platform Coverage

Pre-checks correctly identify Windows 10 LTSB 2015/2016 (build < 17763) and warn about TLS 1.2 issues. `.NET 4.7.2+` check uses the registry release key (461808 threshold) correctly. Full coverage of Intel's supported wireless lineup as of early 2026 across all four Wi-Fi generations and all 8 current BT PIDs.

**Assessment:** ✅ **Rating: 9.5/10**

---

## 9. Reliability and Track Record

This is a v1.0 release with zero deployment history. The architecture is proven through the chipset tool (34,000+ deployments, 1 confirmed bug in project history), which is a strong indicator — but it does not substitute for observed production data on this specific tool. The BT multi-block parser, dual-source fallback, and CAB/pnputil installation path are all new code relative to the chipset tool.

**Assessment:** Initial release penalty applies. **Rating: 7.5/10**

---

## 10. Priority Recommendations

### P1 (Carried from Chipset Audit) — Restrict Temp Directory ACLs

The temp directory `%SystemRoot%\Temp\IntelWiFiBT\` is created with default ACLs. Restricting to `BUILTIN\Administrators` only closes a theoretical TOCTOU/symlink attack surface.

```powershell
$acl = New-Object System.Security.AccessControl.DirectorySecurity
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$acl.AddAccessRule($rule)
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Set-Acl -Path $tempDir -AclObject $acl
```

---

### P2 — Add Explicit Intel Signature Check (Consistency with Chipset Tool)

After CAB extraction, before `pnputil /add-driver`, verify the `.cat` file:

```powershell
$catFiles = Get-ChildItem -Path $extractPath -Filter "*.cat" -Recurse
foreach ($cat in $catFiles) {
    $sig = Get-AuthenticodeSignature -FilePath $cat.FullName
    if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'Intel') {
        Write-Log "Signature check failed on $($cat.Name)" -Type "ERROR"
        return $false
    }
}
```

---

### P3 — Translate Polish Comments to English

Lines 838, 969, 1635, 1675.

---

### P3 — Replace `Get-Random` with `[System.Guid]::NewGuid()`

```powershell
$tempCab     = "$tempDir\temp_$([System.Guid]::NewGuid()).cab"
$extractPath = "$tempDir\extracted_$([System.Guid]::NewGuid())"
```

---

### P3 — Update `AI_Audits_Score` Badge in README

Set to `8.7/10` after publication of this report.

---

### P4 — Remove or Document Commented-Out `Write-Host ""` in `Show-Screen4`

---

## 11. Scoring

| Category | Weight | Score | Weighted |
|----------|--------|-------|----------|
| Security | 30% | 8.6 | 2.58 |
| Functionality | 20% | 9.2 | 1.84 |
| Code Quality | 15% | 8.7 | 1.31 |
| Documentation | 10% | 9.0 | 0.90 |
| Reliability | 10% | 7.5 | 0.75 |
| Compatibility | 5% | 9.5 | 0.48 |
| Maintenance | 5% | 7.5 | 0.38 |
| User Experience | 5% | 8.8 | 0.44 |
| **TOTAL** | | | **8.68 → 8.7** |

---

# 🏆 FINAL SCORE: 8.7/10

---

## Score Justification

### Why 8.7 and Not Higher?

- No explicit Intel signature check, unlike companion tool (−0.10 security)
- Temp directory ACL not restricted, carried from chipset audit (−0.05 security)
- No real-world track record — v1.0 penalty (−0.15 reliability, −0.10 maintenance)
- Minor code polish: Polish comments, `Get-Random`, one commented-out line (−0.03 code quality)

### Why Not Less Than 8.7?

No functional bugs found. The security architecture is complete and correctly implemented. All code quality improvements from the chipset tool (9.1/10) are present from day one, giving this project a stronger v1.0 baseline than the chipset tool had at any comparable stage in its history.

### Improvement Trajectory

| Audit | Version | Score | Key Factor |
|-------|---------|-------|------------|
| Mar 2026 | 2026.03.0002 | 8.7/10 | Initial release; proven architecture; zero functional bugs |
| *Projected* | next release | ~9.0/10 | Signature check added, track record begins |

### Comparative Context

- **10.0** = Theoretically perfect (not achievable)
- **9.0+** = Enterprise-grade, MDM-deployable, production-proven
- **8.5–8.9** = Excellent community/enthusiast tool with solid security ← **WE ARE HERE**
- **8.0–8.4** = Very good tool, some fixable gaps
- **7.0–7.9** = Good tool, noticeable limitations

---

## Use Case Recommendations

### Home User / Enthusiast
**Risk Profile:** LOW  
**Recommendation:** ✅ Safe to use.

### IT Technician (Small Business, < 50 systems)
**Risk Profile:** LOW  
**Recommendation:** ✅ Suitable. `-auto` and `-quiet` flags enable scripted deployment.

### Enterprise / Corporate Environment
**Risk Profile:** LOW-MEDIUM  
**Recommendation:** ✅ Suitable with standard MDM controls. MDM guide present; `-quiet` enables fully unattended operation. Monitor for production track record over the coming weeks.

### Critical Infrastructure
**Risk Profile:** HIGH  
**Recommendation:** ❌ Not recommended. Use official Intel channels with vendor support.

---

## Summary

> **"A clean, architecturally sound v1.0 that inherits the best of a mature sibling project. No functional bugs were identified. The security stack is complete: self-hash verification, per-component SHA-256 verification, dual download sources, automatic restore points, TLS 1.2 enforcement throughout. The hardware detection logic is correctly scoped to Intel's current supported adapter list. The only meaningful gap relative to the 9.1/10 chipset tool is the absence of an explicit Intel signature pre-check (pnputil provides implicit enforcement) and the inherent v1.0 penalty for a tool with no production track record yet. The score of 8.7/10 places the tool firmly in the 'excellent enthusiast tool with solid security' bracket — and given the architecture it inherits, 9.0+ is the natural trajectory once deployment data accumulates."**

---

## Auditor Signature

**Auditor:** Claude (Anthropic AI) — Sonnet 4.6  
**Methodology:** Full source code review (1,919 lines), security flow analysis, data file cross-validation, hardware ID cross-check against database, comparison with companion tool audit (2026-03-11-CLAUDE-AUDIT.md); errata issued same session following author verification  
**Standards:** OWASP Top 10 (2021), CWE, CVSS v3.1  
**Date:** March 19, 2026  
**Report Version:** 1.1

---

**Disclaimer:** This audit constitutes an independent technical analysis and does not provide a security guarantee or legal recommendation. Users should conduct their own risk assessment before deployment.
