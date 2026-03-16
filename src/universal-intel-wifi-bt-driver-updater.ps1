<#PSScriptInfo
.VERSION 2026.03.0002
.GUID b3a72f1e-9c4d-4b8a-a1f2-83d5e6c09f12
.NAME universal-intel-wifi-bt-driver-updater
.AUTHOR Marcin Grygiel
.COMPANYNAME FirstEver.tech
.COPYRIGHT (c) 2025-2026 Marcin Grygiel / FirstEver.tech. All rights reserved.
.TAGS Universal Intel Wi-Fi Bluetooth Drivers Updater CAB Windows Automation
.LICENSEURI https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/blob/main/LICENSE
.PROJECTURI https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
v2026.03.0002 - Initial release aligned with Universal Intel Chipset Device Updater architecture
#>

<#
.SYNOPSIS
    Detects and installs the latest Intel Wi-Fi and Bluetooth drivers.

.DESCRIPTION
    Automatically detects, downloads, and installs the latest Intel Wi-Fi (Wi-Fi 5/6/6E/7)
    and Bluetooth drivers for your specific hardware. Compares installed driver versions
    against the latest available release, then downloads and installs the correct CAB
    driver package(s).

    Security: full SHA-256 hash verification before installation.
    Automatic System Restore Point created before any changes.

    Requires Administrator privileges (auto-elevates if needed) and internet access
    to GitHub. Downloads are verified before installation - no unverified files are
    ever installed.

    Supports silent unattended deployment via -quiet flag.

    Usage: .\universal-intel-wifi-bt-driver-updater.ps1 [options]

Options:
  -help, -?          Display this help and exit.
  -version, -v       Display the tool version and exit.
  -auto, -a          All prompts are answered with Yes, no user interaction required.
  -quiet, -q         Run in completely silent mode (no console window). Implies -auto.
  -beta              Use beta database for new hardware testing.
  -debug, -d         Enable debug output.
  -skipverify, -s    Skip script self-hash verification. Use only for testing.

    Logging: All actions are logged to %ProgramData%\wifi_bt_update.log.

.PARAMETER version
    Display the tool version and exit.

.PARAMETER auto
    Run in automatic mode - all prompts are answered with Yes.

.PARAMETER quiet
    Run in completely silent mode with no console window. Implies -auto.

.PARAMETER beta
    Use the beta database for testing new hardware support.

.PARAMETER debug
    Enable debug output.

.PARAMETER skipverify
    Skip the script self-hash verification.

.EXAMPLE
    .\universal-intel-wifi-bt-driver-updater.ps1
    Runs the updater interactively.

.EXAMPLE
    .\universal-intel-wifi-bt-driver-updater.ps1 -auto
    Runs without any user prompts.

.EXAMPLE
    .\universal-intel-wifi-bt-driver-updater.ps1 -quiet
    Runs completely silently. Suitable for MDM deployment.

.NOTES
    Author:  Marcin Grygiel / FirstEver.tech
    License: MIT

    All actions are logged to %ProgramData%\wifi_bt_update.log.

    This tool is not affiliated with Intel Corporation.
    Drivers are sourced from official Intel / Windows Update servers.
    Use at your own risk.

.LINK
    https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater
#>

# =============================================
# COMMAND-LINE PARAMETERS - MANUAL PARSING
# =============================================
$rawArgs = $args
$Help = $false
$Version = $false
$AutoMode = $false
$Debug = $false
$SkipVerification = $false
$QuietMode = $false
$Beta = $false
$Developer = $false

$allowedSwitches = @(
    '-help', '-?',
    '-version', '-v',
    '-auto', '-a',
    '-beta',
    '-developer',
    '-debug', '-d',
    '-skipverify', '-s',
    '-quiet', '-q'
)

for ($i = 0; $i -lt $rawArgs.Count; $i++) {
    $arg = $rawArgs[$i]
    if ($arg -match '^-') {
        if ($allowedSwitches -notcontains $arg) {
            Clear-Host
            Write-Host ""
            Write-Host " Unknown parameter: $arg"
            Write-Host " Use -help or -? to see available options."
            Write-Host ""
            exit 1
        }
        switch -Regex ($arg) {
            '^-help$'                { $Help = $true }
            '^-version$|^-v$'        { $Version = $true }
            '^-auto$|^-a$'           { $AutoMode = $true }
            '^-beta$'                { $Beta = $true }
            '^-developer$'           { $Developer = $true }
            '^-debug$|^-d$'          { $Debug = $true }
            '^-skipverify$|^-s$'     { $SkipVerification = $true }
            '^-quiet$|^-q$'          { $QuietMode = $true }
        }
    } else {
        Clear-Host
        Write-Host ""
        Write-Host " Positional arguments are not allowed."
        Write-Host " Use -help or -? to see available options."
        Write-Host ""
        exit 1
    }
}

if ($QuietMode) {
    $newArgs = @()
    $hasAuto = $false
    foreach ($arg in $rawArgs) {
        if ($arg -match '^-quiet$|^-q$') {
            # skip
        } else {
            $newArgs += $arg
            if ($arg -match '^-auto$|^-a$') { $hasAuto = $true }
        }
    }
    if (-not $hasAuto) { $newArgs += '-auto' }
    $scriptPath = $MyInvocation.MyCommand.Path
    $argString = ($newArgs -join ' ')
    Start-Process -FilePath "powershell.exe" -ArgumentList "-WindowStyle Hidden -File `"$scriptPath`" $argString"
    exit 0
}

[bool]$DebugMode = $Debug
[bool]$SkipSelfHashVerification = $SkipVerification

# =============================================
# SCRIPT VERSION
# =============================================
$ScriptVersion = "2026.03.0002"
# =============================================

$isSFX = $MyInvocation.ScriptName -like "$env:SystemRoot\Temp\universal-intel-wifi-bt-updater*"

if ($ScriptVersion -match '^(\d+\.\d+)-(\d{4}\.\d{2}\.\d+)$') {
    $DisplayVersion = "$($matches[1]) ($($matches[2]))"
} else {
    $DisplayVersion = $ScriptVersion
}

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path
    exit 0
}

if ($Version) {
    Clear-Host
    Write-Host ""
    Write-Host " Universal Intel Wi-Fi and Bluetooth Drivers Updater version $DisplayVersion"
    Write-Host ""
    exit 0
}

# =============================================
# AUTO-ELEVATE IF NOT ADMIN
# =============================================
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Clear-Host
    Write-Host ""
    Write-Host " Administrator privileges required. Restarting with elevation..." -ForegroundColor Yellow
    Write-Host ""
    $scriptPath = $MyInvocation.MyCommand.Path
    $argList = if ($rawArgs.Count -gt 0) { $rawArgs -join " " } else { "" }
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit -File `"$scriptPath`" $argList" -Verb RunAs
    } catch {
        Clear-Host
        Write-Host ""
        Write-Host " Elevation failed. Please run the script as Administrator manually." -ForegroundColor Red
        Write-Host ""
        pause
        exit 1
    }
    exit 0
}

# =============================================
# ELEVATED CONTEXT - CONSOLE SETUP
# =============================================
Write-Host "Running with administrator privileges. Applying console settings..." -ForegroundColor Green

$Host.UI.RawUI.BackgroundColor = "Black"

try {
    [console]::WindowWidth = 75
    [console]::WindowHeight = 58
    [console]::BufferWidth = [console]::WindowWidth
} catch {
    Write-Host "Failed to set console size: $_" -ForegroundColor Red
}

# =============================================
# CONFIGURATION
# =============================================
$githubBaseUrl     = "https://raw.githubusercontent.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/main/data/"
$githubArchiveWiFi = "https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases/download/archive-wifi/"
$githubArchiveBT   = "https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases/download/archive-bt/"

$wifiLatestUrl   = $githubBaseUrl + "intel-wifi-driver-latest.md"
$btLatestUrl     = $githubBaseUrl + "intel-bt-driver-latest.md"
$wifiDownloadUrl = $githubBaseUrl + "intel-wifi-drivers-download.txt"
$btDownloadUrl   = $githubBaseUrl + "intel-bt-drivers-download.txt"
$supportMessageUrl = $githubBaseUrl + "intel-wifi-bt-message.txt"

if ($Developer) {
    $wifiLatestUrl   = $githubBaseUrl + "intel-wifi-driver-dev.md"
    $btLatestUrl     = $githubBaseUrl + "intel-bt-driver-dev.md"
    Write-Host ""
    Write-Host " [DEVELOPER MODE] Using development databases." -ForegroundColor Magenta
    Write-Host ""
} elseif ($Beta) {
    $wifiLatestUrl   = $githubBaseUrl + "intel-wifi-driver-beta.md"
    $btLatestUrl     = $githubBaseUrl + "intel-bt-driver-beta.md"
    Write-Host ""
    Write-Host " [BETA MODE] Using beta databases." -ForegroundColor Yellow
    Write-Host ""
}

$tempDir = Join-Path $env:SystemRoot "Temp\IntelWiFiBT"

# =============================================
# GLOBAL STATE
# =============================================
$global:InstallationErrors = @()
$global:ScriptStartTime    = Get-Date
$global:NewVersionLaunched = $false
$logFile = Join-Path $env:ProgramData "wifi_bt_update.log"

# =============================================
# VERSION MANAGEMENT FUNCTIONS
# =============================================

function Get-VersionNumber {
    param([string]$Version)

    if ($Version -match '^(\d{4})\.(\d{2})\.(\d+)$') {
        return [int]$matches[3]
    }

    throw "Cannot parse version: $Version"
}

function Compare-Versions {
    param([string]$Version1, [string]$Version2)

    $ver1Num = Get-VersionNumber -Version $Version1
    $ver2Num = Get-VersionNumber -Version $Version2

    if ($ver1Num -eq $ver2Num) { return 0 }
    if ($ver1Num -lt $ver2Num) { return -1 }
    return 1
}

# =============================================
# LOGGING FUNCTIONS
# =============================================

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    try {
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    } catch { }

    if ($Type -eq "ERROR") {
        $global:InstallationErrors += $Message
        Write-Host " ERROR: $Message" -ForegroundColor Red
    }
}

function Write-DebugMessage {
    param([string]$Message, [string]$Color = "Gray")
    Write-Log -Message $Message -Type "DEBUG"
    if ($DebugMode) {
        Write-Host " DEBUG: $Message" -ForegroundColor $Color
    }
}

function Show-FinalSummary {
    $duration = (Get-Date) - $global:ScriptStartTime
    if ($global:InstallationErrors.Count -gt 0) {
        Write-Host "`n Completed with $($global:InstallationErrors.Count) error(s)." -ForegroundColor Red
        Write-Host " See $logFile for details." -ForegroundColor Red
    } else {
        Write-Host "`n Operation completed successfully." -ForegroundColor Green
    }
    Write-Log "Script execution completed in $([math]::Round($duration.TotalMinutes, 2)) minutes with $($global:InstallationErrors.Count) errors"
}

# =============================================
# COLOR LINE PARSING FUNCTION
# =============================================
function Write-ColorLine {
    param([string]$Line)

    $validColors = [Enum]::GetNames([ConsoleColor])
    $currentFg = $Host.UI.RawUI.ForegroundColor
    $currentBg = $Host.UI.RawUI.BackgroundColor

    $segments = @()
    $position = 0
    $length = $Line.Length

    while ($position -lt $length) {
        $openBracket = $Line.IndexOf('[', $position)
        if ($openBracket -eq -1) {
            $text = $Line.Substring($position)
            if ($text) {
                $segments += [PSCustomObject]@{ Text = $text; Foreground = $currentFg; Background = $currentBg }
            }
            break
        }

        if ($openBracket -gt $position) {
            $text = $Line.Substring($position, $openBracket - $position)
            if ($text) {
                $segments += [PSCustomObject]@{ Text = $text; Foreground = $currentFg; Background = $currentBg }
            }
        }

        $closeBracket = $Line.IndexOf(']', $openBracket)
        if ($closeBracket -eq -1) {
            $text = $Line.Substring($openBracket)
            if ($text) {
                $segments += [PSCustomObject]@{ Text = $text; Foreground = $currentFg; Background = $currentBg }
            }
            break
        }

        $tagContent = $Line.Substring($openBracket + 1, $closeBracket - $openBracket - 1)
        $parts = $tagContent -split ','

        $newFg = $null
        $newBg = $null

        if ($parts.Count -eq 1 -and $validColors -contains $parts[0]) {
            $newFg = [ConsoleColor]$parts[0]
        } elseif ($parts.Count -eq 2 -and $validColors -contains $parts[0] -and $validColors -contains $parts[1]) {
            $newFg = [ConsoleColor]$parts[0]
            $newBg = [ConsoleColor]$parts[1]
        }

        if ($newFg -ne $null) {
            if ($newBg -ne $null) { $currentBg = $newBg }
            $currentFg = $newFg
            $position = $closeBracket + 1
        } else {
            $text = $Line.Substring($openBracket, $closeBracket - $openBracket + 1)
            $segments += [PSCustomObject]@{ Text = $text; Foreground = $currentFg; Background = $currentBg }
            $position = $closeBracket + 1
        }
    }

    foreach ($seg in $segments) {
        Write-Host $seg.Text -NoNewline -ForegroundColor $seg.Foreground -BackgroundColor $seg.Background
    }
    Write-Host ""
}

function Get-KeyAndUrlFromLine {
    param([string]$Line)

    $validColors = [Enum]::GetNames([ConsoleColor])
    $colorPattern = '\[(?:' + (($validColors | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')(?:,(?:' + (($validColors | ForEach-Object { [regex]::Escape($_) }) -join '|') + '))?\]'
    $cleanLine = $Line -replace $colorPattern, ''

    if ($cleanLine -match 'press \[([A-Za-z])\]') {
        $key = $matches[1]
        if ($cleanLine -match '(https?://)?([a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?:/[^\s]*)?)') {
            $urlCandidate = $matches[0]
            if ($urlCandidate -notmatch '^https?://') { $urlCandidate = "https://$urlCandidate" }
            return @{ Key = $key; Url = $urlCandidate }
        }
    }
    return $null
}

# =============================================
# HEADER DISPLAY FUNCTION
# =============================================
function Show-Header {
    Clear-Host
    Write-Host "/*************************************************************************" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "          UNIVERSAL INTEL WI-FI AND BLUETOOTH DRIVERS UPDATER          " -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "** --------------------------------------------------------------------- **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue

    $paddedVersion = $DisplayVersion.PadRight(14)
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "                       Tool Version: $paddedVersion                    " -NoNewline -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue

    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "              Author: Marcin Grygiel / www.firstever.tech              " -NoNewline -ForegroundColor Green -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "** --------------------------------------------------------------------- **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "         This tool is not affiliated with Intel Corporation.           " -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "         Drivers are sourced from official Intel/WU servers.           " -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "         Use at your own risk.                                         " -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "** --------------------------------------------------------------------- **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "    Visit: GitHub.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater    " -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "*************************************************************************/" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host ""
}

# =============================================
# SCREEN MANAGEMENT FUNCTIONS
# =============================================

function Show-Screen1 {
    Show-Header
    Write-Host " [SCREEN 1/4] INITIALIZATION AND SECURITY CHECKS" -ForegroundColor Cyan
    Write-Host " ===============================================" -ForegroundColor Cyan

    if ($DebugMode) {
        Write-Host " DEBUG MODE: ENABLED" -ForegroundColor Magenta
    }
    if ($SkipSelfHashVerification) {
        Write-Host "`n SELF-HASH VERIFICATION: DISABLED (Testing Mode)" -ForegroundColor Yellow
    }

    Write-Host ""

    Write-Host " Checking Windows system requirements..." -ForegroundColor Yellow
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $build = [int]$os.BuildNumber

        if ($build -lt 17763) {
            Write-Host " [WARNING] Windows 10 LTSB 2015/2016 detected." -ForegroundColor Red
            Write-Host " TLS 1.2 may not work properly." -ForegroundColor Gray
        } else {
            Write-Host " Windows Build: $build" -ForegroundColor Gray
            Write-Host " Operating system compatibility: PASSED" -ForegroundColor Green
        }
    } catch {
        Write-Host " [INFO] Could not determine Windows build." -ForegroundColor Gray
    }
    Write-Host ""

    Write-Host " Checking .NET Framework prerequisites..." -ForegroundColor Yellow
    try {
        $netRelease = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -Name "Release" -ErrorAction Stop
        if ($netRelease -ge 461808) {
            Write-Host " .NET Framework 4.7.2 or newer detected: PASSED" -ForegroundColor Green
        } else {
            Write-Host " [WARNING] .NET Framework older than 4.7.2" -ForegroundColor Red
        }
    } catch {
        Write-Host " [WARNING] .NET Framework 4.7.2+ not found or couldn't be checked" -ForegroundColor Red
    }
    Write-Host ""

    Write-Host " Testing GitHub connectivity..." -ForegroundColor Yellow
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $null = Invoke-WebRequest -Uri "https://raw.githubusercontent.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Host " Repository access verification: PASSED" -ForegroundColor Green
    } catch {
        Write-Host " [WARNING] Cannot reach GitHub servers" -ForegroundColor Red
        Write-Host " Self-hash verification will be skipped." -ForegroundColor Gray
    }
    Write-Host ""

    Write-Host " Pre-check summary..." -ForegroundColor Yellow

    if ($build -lt 17763 -or !$netRelease -or $netRelease -lt 461808) {
        Write-Host " [IMPORTANT] Some issues were detected." -ForegroundColor Yellow
        Write-Host ""

        if ($AutoMode) {
            $choice = "Y"
            Write-Host " Auto mode: automatically continuing (Y)." -ForegroundColor Cyan
        } else {
            do {
                $choice = Read-Host " Continue despite warnings? (Y/N)"
                $choice = $choice.Trim().ToUpper()
                if ($choice -ne 'Y' -and $choice -ne 'N') {
                    Write-Host " Invalid input. Please enter Y or N." -ForegroundColor Red
                }
            } while ($choice -ne 'Y' -and $choice -ne 'N')
        }

        if ($choice -eq 'N') {
            Write-Host " Operation cancelled." -ForegroundColor Red
            if (-not $AutoMode) {
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            exit 0
        }

        Write-Host " Continuing with limited functionality..." -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host " All system requirements verified successfully." -ForegroundColor Green
    }
}

function Show-Screen2 {
    Show-Header
    Write-Host " [SCREEN 2/4] HARDWARE DETECTION AND VERSION ANALYSIS" -ForegroundColor Cyan
    Write-Host " ====================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Screen3 {
    Show-Header
    Write-Host " [SCREEN 3/4] UPDATE CONFIRMATION AND SYSTEM PREPARATION" -ForegroundColor Cyan
    Write-Host " =======================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host " IMPORTANT NOTICE:" -ForegroundColor Yellow
    Write-Host " The driver update process may take several minutes to complete." -ForegroundColor Yellow
    Write-Host " During installation, your Wi-Fi and/or Bluetooth connection may" -ForegroundColor Yellow
    Write-Host " temporarily disconnect. This is normal behavior and connectivity" -ForegroundColor Yellow
    Write-Host " will be restored once the installation is complete." -ForegroundColor Yellow
    Write-Host ""

    if ($AutoMode) {
        $response = "Y"
        Write-Host " Auto mode: automatically proceeding (Y)." -ForegroundColor Cyan
    } else {
        $response = Read-Host " Do you want to proceed with driver update? (Y/N)"
    }

    return $response
}

function Show-Screen4 {
    Show-Header
    Write-Host " [SCREEN 4/4] DOWNLOAD AND INSTALLATION PROGRESS" -ForegroundColor Cyan
    Write-Host " ===============================================" -ForegroundColor Cyan
#    Write-Host ""
}

# =============================================
# SELF-HASH VERIFICATION
# =============================================

function Verify-ScriptHash {
    if ($SkipSelfHashVerification) {
        Write-Host " SKIPPED: Self-hash verification disabled (Testing Mode)." -ForegroundColor Yellow
        Write-Host ""
        return $true
    }

    try {
        Write-Host " Verifying Updater source file integrity..." -ForegroundColor Yellow

        $scriptPath = $null
        if ($PSCommandPath) {
            $scriptPath = $PSCommandPath
        } elseif ($MyInvocation.MyCommand.Path) {
            $scriptPath = $MyInvocation.MyCommand.Path
        } else {
            $potentialPath = Join-Path (Get-Location) "universal-intel-wifi-bt-driver-updater.ps1"
            if (Test-Path $potentialPath) { $scriptPath = $potentialPath }
        }

        if (-not $scriptPath -or -not (Test-Path $scriptPath)) {
            Write-Host " FAIL: Cannot locate script file for hash verification." -ForegroundColor Red
            return $false
        }

        $currentHash = $null
        $retryCount = 0
        $maxRetries = 3

        while ($retryCount -lt $maxRetries -and -not $currentHash) {
            try {
                $hashResult = Get-FileHash -Path $scriptPath -Algorithm SHA256
                $currentHash = $hashResult.Hash.ToUpper()
            } catch {
                $retryCount++
                if ($retryCount -eq $maxRetries) {
                    Write-Host " FAIL: Could not calculate script hash after $maxRetries attempts." -ForegroundColor Red
                    return $false
                }
                Start-Sleep -Milliseconds 500
            }
        }

        $hashFileUrl = "https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases/download/v$ScriptVersion/universal-intel-wifi-bt-driver-updater-$ScriptVersion-ps1.sha256"
        Write-DebugMessage "Downloading hash from: $hashFileUrl"

        try {
            $expectedHashResponse = Invoke-WebRequest -Uri $hashFileUrl -UseBasicParsing -ErrorAction Stop
            $expectedHashLine = if ($expectedHashResponse.Content -is [byte[]]) {
                [System.Text.Encoding]::UTF8.GetString($expectedHashResponse.Content).Trim()
            } else {
                $expectedHashResponse.Content.ToString().Trim()
            }

            $expectedHashLine = $expectedHashLine.TrimStart([char]0xEF, [char]0xBB, [char]0xBF).Trim()

            $expectedHash = $null
            if ($expectedHashLine -match '^([A-Fa-f0-9]{64})\s+(\S+)$') {
                $expectedHash = $matches[1].ToUpper()
            } elseif ($expectedHashLine -match '^([A-Fa-f0-9]{64})$') {
                $expectedHash = $expectedHashLine.ToUpper()
            } elseif ($expectedHashLine -match '^([A-Fa-f0-9]{64})\s*\*?\s*(\S+)$') {
                $expectedHash = $matches[1].ToUpper()
            }

            if (-not $expectedHash) {
                Write-Host " FAIL: Could not parse hash from file." -ForegroundColor Red
                return $false
            }

            if ($currentHash -eq $expectedHash) {
                Write-Host " Updater hash verification: PASSED" -ForegroundColor Green
                Write-Host ""
                return $true
            } else {
                Write-Host " FAIL: Updater hash verification failed. Hash doesn't match." -ForegroundColor Red
                Write-Host "`n WARNING: The updater file may have been modified or corrupted!" -ForegroundColor Red
                Write-Host " Please download the Updater from the official source:" -ForegroundColor Red
                Write-Host " https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases" -ForegroundColor Cyan
                Write-Host ""
                Write-Host " Source: $expectedHash" -ForegroundColor Green
                Write-Host " Actual: $currentHash" -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Host " ERROR: Could not download or parse hash file." -ForegroundColor Red
            Write-Host " Please download the Updater from the official source:" -ForegroundColor Red
            Write-Host " https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases" -ForegroundColor Red
            Write-Host ""
            Write-Host " Actual: $currentHash" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host " ERROR: Could not verify script hash: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# =============================================
# UPDATER UPDATE CHECK
# =============================================

function Get-DownloadsFolder {
    try {
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        $downloadsGuid = "{374DE290-123F-4565-9164-39C4925E467B}"
        if (Test-Path $registryPath) {
            $downloadsValue = Get-ItemProperty -Path $registryPath -Name $downloadsGuid -ErrorAction SilentlyContinue
            if ($downloadsValue -and $downloadsValue.$downloadsGuid) {
                return [Environment]::ExpandEnvironmentVariables($downloadsValue.$downloadsGuid)
            }
        }
        return [Environment]::GetFolderPath("UserProfile") + "\Downloads"
    } catch {
        return [Environment]::GetFolderPath("UserProfile") + "\Downloads"
    }
}

function Check-ForUpdaterUpdates {
    try {
        Write-Host " Checking for newer updater version..." -ForegroundColor Yellow

        $versionFileUrl = "https://raw.githubusercontent.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/main/src/universal-intel-wifi-bt-driver-updater.ver"
        $latestVersionContent = Invoke-WebRequest -Uri $versionFileUrl -UseBasicParsing -ErrorAction Stop
        $latestVersion = $latestVersionContent.Content.Trim()

        $comparisonResult = Compare-Versions -Version1 $ScriptVersion -Version2 $latestVersion
        Write-DebugMessage "Current version: $ScriptVersion, Latest: $latestVersion, Result: $comparisonResult"

        if ($comparisonResult -eq 0) {
            Write-Host " Status: Already on latest version." -ForegroundColor Green
            Write-Host ""
            Write-Host " Starting hardware detection..." -ForegroundColor Gray
            Write-Host ""
            Start-Sleep -Seconds 3
            return $true
        } elseif ($comparisonResult -lt 0) {
            Write-Host " A new version $latestVersion is available (current: $ScriptVersion)." -ForegroundColor Yellow

            if ($AutoMode) {
                $continueChoice = "Y"
                Write-Host " Auto mode: automatically continuing with current version (Y)." -ForegroundColor Cyan
            } else {
                do {
                    Write-Host ""
                    $continueChoice = Read-Host " Do you want to continue with the current version? (Y/N)"
                    $continueChoice = $continueChoice.Trim().ToUpper()
                    if ($continueChoice -ne 'Y' -and $continueChoice -ne 'N') {
                        Write-Host " Invalid input. Please enter Y or N." -ForegroundColor Red
                    }
                } while ($continueChoice -ne 'Y' -and $continueChoice -ne 'N')
            }

            if ($continueChoice -eq 'Y') { return $true }

            if ($AutoMode) {
                $downloadChoice = "N"
            } else {
                do {
                    $downloadChoice = Read-Host " Do you want to download the latest version? (Y/N)"
                    $downloadChoice = $downloadChoice.Trim().ToUpper()
                    if ($downloadChoice -ne 'Y' -and $downloadChoice -ne 'N') {
                        Write-Host " Invalid input. Please enter Y or N." -ForegroundColor Red
                    }
                } while ($downloadChoice -ne 'Y' -and $downloadChoice -ne 'N')
            }

            if ($downloadChoice -eq 'Y') {
                $downloadUrl = "https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases/download/v$latestVersion/WiFiBT-Updater-$latestVersion-Win10-Win11.exe"
                $downloadsFolder = Get-DownloadsFolder
                $outputPath = Join-Path $downloadsFolder "WiFiBT-Updater-$latestVersion-Win10-Win11.exe"

                Write-Host " Downloading new version to: $outputPath" -ForegroundColor Yellow
                Write-Host ""

                try {
                    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -UseBasicParsing -ErrorAction Stop
                    Write-Host " Download completed. Please run the new version." -ForegroundColor Green
                } catch {
                    Write-Host " Download failed: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host " Please visit: https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases" -ForegroundColor Cyan
                }
            }

            Cleanup
            if (-not $AutoMode) {
                Write-Host "`n Press any key..."
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            Show-FinalCredits
            $global:NewVersionLaunched = $true
            return $false
        } else {
            Write-Host " Status: Running a newer version than published ($ScriptVersion)." -ForegroundColor Cyan
            Write-Host ""
            Start-Sleep -Seconds 2
            return $true
        }
    } catch {
        Write-Host " WARNING: Could not check for updates. Continuing..." -ForegroundColor Yellow
        Write-DebugMessage "Update check failed: $($_.Exception.Message)"
        return $true
    }
}

# =============================================
# TEMP DIRECTORY MANAGEMENT
# =============================================

function Clear-TempDriverFolders {
    try {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-DebugMessage "Cleaned up temporary directory: $tempDir"
        }
    } catch {
        Write-DebugMessage "Error during cleanup: $_"
    }
}

function Cleanup {
    Write-Host "`n Cleaning up temporary files..." -ForegroundColor Yellow
    if (Test-Path $tempDir) {
        try {
            Get-ChildItem -Path $tempDir -Exclude "*.ps1" -Recurse | Remove-Item -Force -Recurse -ErrorAction Stop
            Write-Host " Temporary files cleaned successfully." -ForegroundColor Green
        } catch {
            Write-Host " Warning: Could not clean all temporary files." -ForegroundColor Yellow
        }
    }
}

# =============================================
# HARDWARE DETECTION FUNCTIONS
# =============================================

# Supported Intel Wi-Fi DEV IDs (PCI) - UZUPEŁNIONE O NOWE ID Z BAZY
$supportedWiFiDEVs = @(
    # Wi-Fi 7 (BE)
    "272B", "A840", "A841", "E340", "E440",
    # Wi-Fi 6E (AX - 6 GHz)
    "2725", "51F0", "51F1", "54F0", "7A70", "7AF0", "7E40", "7F70",
    # Wi-Fi 6 (AX)
    "2723", "02F0", "06F0", "34F0", "3DF0", "43F0", "4DF0", "A0F0", "7740",
    # Wi-Fi 5 (AC)
    "2526", "30DC", "31DC", "9DF0", "A370"
)

# Supported Intel Bluetooth PID IDs (USB VID_8087)
$supportedBTPIDs = @("0025", "0AAA", "0026", "0032", "0033", "0036", "0037", "0038")

function Get-IntelWiFiDevice {
    try {
        $devices = Get-PnpDevice -Class "Net" -ErrorAction SilentlyContinue |
            Where-Object { $_.Status -eq "OK" }

        foreach ($device in $devices) {
            foreach ($hwid in $device.HardwareID) {
                if ($hwid -match 'PCI\\VEN_8086&DEV_([A-F0-9]{4})') {
                    $devId = $matches[1].ToUpper()
                    if ($supportedWiFiDEVs -contains $devId) {
                        Write-DebugMessage "Found Intel Wi-Fi device: $devId ($($device.FriendlyName))"
                        return [PSCustomObject]@{
                            DEV          = $devId
                            InstanceId   = $device.InstanceId
                            FriendlyName = $device.FriendlyName
                            HardwareID   = $hwid
                        }
                    }
                }
            }
        }
    } catch {
        Write-DebugMessage "Error scanning for Wi-Fi devices: $_"
    }
    return $null
}

function Get-IntelBTDevice {
    try {
        # Try Bluetooth class first
        $devices = Get-PnpDevice -Class "Bluetooth" -ErrorAction SilentlyContinue |
            Where-Object { $_.Status -eq "OK" }

        # Fall back to USB class if nothing found
        if (-not $devices -or $devices.Count -eq 0) {
            $devices = Get-PnpDevice -ErrorAction SilentlyContinue |
                Where-Object { $_.Status -eq "OK" -and $_.HardwareID -like "*VID_8087*" }
        }

        foreach ($device in $devices) {
            foreach ($hwid in $device.HardwareID) {
                if ($hwid -match 'USB\\VID_8087&PID_([0-9A-F]{4})') {
                    $btPid = $matches[1].ToUpper()
                    if ($supportedBTPIDs -contains $btPid) {
                        Write-DebugMessage "Found Intel BT device: PID=$btPid ($($device.FriendlyName))"
                        return [PSCustomObject]@{
                            PID          = $btPid
                            InstanceId   = $device.InstanceId
                            FriendlyName = $device.FriendlyName
                            HardwareID   = $hwid
                        }
                    }
                }
            }
        }
    } catch {
        Write-DebugMessage "Error scanning for BT devices: $_"
    }
    return $null
}

function Get-CurrentDriverVersion {
    param([string]$DeviceInstanceId)

    try {
        $device = Get-PnpDevice | Where-Object { $_.InstanceId -eq $DeviceInstanceId }
        if ($device) {
            $versionProperty = $device | Get-PnpDeviceProperty -KeyName "DEVPKEY_Device_DriverVersion" -ErrorAction SilentlyContinue
            if ($versionProperty -and $versionProperty.Data) {
                Write-DebugMessage "Got version from DEVPKEY: $($versionProperty.Data)"
                return $versionProperty.Data
            }
        }

        $driverInfo = Get-CimInstance -ClassName Win32_PnPSignedDriver |
            Where-Object { $_.DeviceID -eq $DeviceInstanceId -and $_.DriverVersion } |
            Select-Object -First 1

        if ($driverInfo) {
            Write-DebugMessage "Got version from WMI: $($driverInfo.DriverVersion)"
            return $driverInfo.DriverVersion
        }
    } catch {
        Write-DebugMessage "Error getting driver version: $_"
    }
    return $null
}

# =============================================
# DATA DOWNLOAD FUNCTION
# =============================================

function Get-RemoteContent {
    param([string]$Url)

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $cacheBuster = "t=" + (Get-Date -Format 'yyyyMMddHHmmss')
        if ($Url.Contains('?')) {
            $finalUrl = $Url + "&" + $cacheBuster
        } else {
            $finalUrl = $Url + "?" + $cacheBuster
        }
        Write-DebugMessage "Downloading: $finalUrl"
        $content = Invoke-WebRequest -Uri $finalUrl -UseBasicParsing -ErrorAction Stop
        return $content.Content
    } catch {
        Write-Log "Error downloading from: $Url - $($_.Exception.Message)" -Type "ERROR"
        return $null
    }
}

# =============================================
# DATA PARSING FUNCTIONS
# =============================================

# POPRAWIONA FUNKCJA PARSUJĄCA nowy format (4 kolumny)
function Parse-WiFiLatestMd {
    param([string]$Content)

    $result = @{
        LatestVersion = $null
        ReleaseDate   = $null
        Devices       = @{}   # DEV_xxxx -> @{ Chipset, Models, Generation }
    }

    try {
        $lines = $Content -split "`n"
        foreach ($line in $lines) {
            $line = $line.Trim()
            if ($line -match '^Latest Version\s*=\s*([0-9.]+)') {
                $result.LatestVersion = $matches[1]
                Write-DebugMessage "WiFi Latest Version: $($result.LatestVersion)"
            } elseif ($line -match '^Release Date\s*=\s*(.+)') {
                $result.ReleaseDate = $matches[1].Trim()
            } elseif ($line -match '^\|\s*(DEV_[A-F0-9]{4})\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|') {
                $devId    = $matches[1] -replace 'DEV_', ''
                $chipset  = $matches[2].Trim()
                $models   = $matches[3].Trim()
                $gen      = $matches[4].Trim()
                $result.Devices[$devId] = @{
                    Chipset    = $chipset
                    Models     = $models
                    Generation = $gen
                }
                Write-DebugMessage "WiFi device parsed: $devId -> Chipset=$chipset, Models=$models, Gen=$gen"
            }
        }
    } catch {
        Write-Log "WiFi MD parsing failed: $($_.Exception.Message)" -Type "ERROR"
    }

    return $result
}

function Parse-BTLatestMd {
    param([string]$Content)

    $result = @{
        LatestVersion = $null
        ReleaseDate   = $null
        Devices       = @{}   # PID (4 hex) -> @{ Chipset, Generation, Bluetooth }
    }

    try {
        $lines = $Content -split "`n"

        foreach ($line in $lines) {
            $line = $line.Trim()

            if ($line -match '^Latest Version\s*=\s*([0-9.]+)') {
                $result.LatestVersion = $matches[1]
                Write-DebugMessage "BT Latest Version: $($result.LatestVersion)"
            } elseif ($line -match '^Release Date\s*=\s*(.+)') {
                $result.ReleaseDate = $matches[1].Trim()
            } elseif ($line -match '^\|\s*([0-9A-Fa-f]{4})\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|') {
                $btPid   = $matches[1].ToUpper()
                $chipset = $matches[2].Trim()
                $gen     = $matches[3].Trim()
                $bt      = $matches[4].Trim()
                $result.Devices[$btPid] = @{ Chipset = $chipset; Generation = $gen; Bluetooth = $bt }
                Write-DebugMessage "BT device parsed: $btPid -> $chipset BT $bt"
            }
        }
    } catch {
        Write-Log "BT MD parsing failed: $($_.Exception.Message)" -Type "ERROR"
    }

    return $result
}

function Parse-WiFiDownloadList {
    param([string]$Content)

    $result = @{
        Name    = $null
        Version = $null
        Date    = $null
        SHA256  = $null
        Link    = $null
        Backup  = $null
    }

    try {
        $lines = $Content -split "`n" | ForEach-Object { $_.Trim() }
        foreach ($line in $lines) {
            if     ($line -match '^Name\s*=\s*(.+)')                              { $result.Name    = $matches[1].Trim() }
            elseif ($line -match '^DriverVer\s*=\s*([^,]+),\s*([0-9.]+)')        { $result.Date    = $matches[1].Trim(); $result.Version = $matches[2].Trim() }
            elseif ($line -match '^SHA256\s*=\s*([A-Fa-f0-9]{64})')              { $result.SHA256  = $matches[1].ToUpper() }
            elseif ($line -match '^Link\s*=\s*(https?://.+)')                    { $result.Link    = $matches[1].Trim() }
            elseif ($line -match '^Backup\s*=\s*(https?://.+)')                  { $result.Backup  = $matches[1].Trim() }
        }
        Write-DebugMessage "WiFi download list parsed: Version=$($result.Version)"
    } catch {
        Write-Log "WiFi download list parsing failed: $($_.Exception.Message)" -Type "ERROR"
    }

    return $result
}

function Parse-BTDownloadList {
    param([string]$Content)

    # Returns @{ Version, Date, Blocks: [ @{ HWIDs, SHA256, Link, Backup } ] }
    $result = @{
        Version = $null
        Date    = $null
        Blocks  = [System.Collections.Generic.List[hashtable]]::new()
    }

    try {
        $blocks = $Content -split "`n`n" | Where-Object { $_.Trim() }

        foreach ($block in $blocks) {
            $lines = $block -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }

            $hasDriverVer = $lines | Where-Object { $_ -match '^DriverVer\s*=' }
            $hasHWID      = $lines | Where-Object { $_ -match '^USB\\VID_' }

            # Parse global header (Name + DriverVer)
            if ($hasDriverVer) {
                foreach ($line in $lines) {
                    if ($line -match '^DriverVer\s*=\s*([^,]+),\s*([0-9.]+)') {
                        $result.Date    = $matches[1].Trim()
                        $result.Version = $matches[2].Trim()
                        Write-DebugMessage "BT download list version: $($result.Version)"
                    }
                }
            }

            # Parse per-PID data blocks
            if ($hasHWID) {
                $blockData = @{
                    HWIDs  = [System.Collections.Generic.List[string]]::new()
                    SHA256 = $null
                    Link   = $null
                    Backup = $null
                }

                foreach ($line in $lines) {
                    if     ($line -match '^USB\\VID_[0-9A-Fa-f]+&PID_([0-9A-Fa-f]{4})') { $blockData.HWIDs.Add($line) }
                    elseif ($line -match '^SHA256\s*=\s*([A-Fa-f0-9]{64})')              { $blockData.SHA256 = $matches[1].ToUpper() }
                    elseif ($line -match '^Link\s*=\s*(https?://.+)')                    { $blockData.Link   = $matches[1].Trim() }
                    elseif ($line -match '^Backup\s*=\s*(https?://.+)')                  { $blockData.Backup = $matches[1].Trim() }
                }

                if ($blockData.HWIDs.Count -gt 0 -and $blockData.Link) {
                    $result.Blocks.Add($blockData)
                    Write-DebugMessage "BT block parsed: PIDs=$($blockData.HWIDs -join ', '), Link=$($blockData.Link)"
                }
            }
        }
    } catch {
        Write-Log "BT download list parsing failed: $($_.Exception.Message)" -Type "ERROR"
    }

    return $result
}

function Get-BTBlockForDevice {
    param([string]$DevicePID, [object]$BTDownloadData)

    foreach ($block in $BTDownloadData.Blocks) {
        foreach ($hwid in $block.HWIDs) {
            if ($hwid -match "PID_([0-9A-Fa-f]{4})") {
                if ($matches[1].ToUpper() -eq $DevicePID.ToUpper()) {
                    return $block
                }
            }
        }
    }
    return $null
}

# =============================================
# HASH VERIFICATION
# =============================================

function Verify-FileHash {
    param(
        [string]$FilePath,
        [string]$ExpectedHash,
        [string]$HashType = "Primary",
        [string]$OriginalFileName = ""
    )

    if (-not $ExpectedHash) {
        Write-Host " WARNING: No expected hash provided. Skipping verification." -ForegroundColor Yellow
        return $true
    }

    try {
        if (-not (Test-Path $FilePath)) {
            Write-Log "File not found for hash check: $FilePath" -Type "ERROR"
            return $false
        }
        $actualHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
        Write-DebugMessage "SHA256 for $FilePath : $actualHash"
    } catch {
        Write-Log "Error calculating hash: $($_.Exception.Message)" -Type "ERROR"
        return $false
    }

    if ($actualHash -eq $ExpectedHash) {
        Write-Host " PASS: $HashType hash verification passed." -ForegroundColor Green
        return $true
    } else {
        $displayName = if ($OriginalFileName) { $OriginalFileName } else { Split-Path $FilePath -Leaf }
        Write-Host " $HashType hash verification FAILED: $displayName" -ForegroundColor Red
        Write-Host " Source: $ExpectedHash" -ForegroundColor Red
        Write-Host " Actual: $actualHash" -ForegroundColor Red
        Write-Log "$HashType hash mismatch for $displayName. Source: $ExpectedHash, Actual: $actualHash" -Type "ERROR"
        return $false
    }
}

# =============================================
# DOWNLOAD FUNCTION
# =============================================

function Download-VerifyFile {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$ExpectedHash,
        [string]$SourceName = "Primary"
    )

    try {
        Write-Host " Downloading from $SourceName source..." -ForegroundColor Yellow
        Write-DebugMessage "URL: $Url"

        try {
            Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
        } catch {
            Write-Log "Download failed [$SourceName]: $($_.Exception.Message)" -Type "ERROR"
            return @{ Success = $false; ErrorType = "DownloadFailed" }
        }

        if (-not (Test-Path $OutFile)) {
            return @{ Success = $false; ErrorType = "DownloadFailed" }
        }

        if ($ExpectedHash) {
            Write-Host " Verifying $SourceName source file integrity..." -ForegroundColor Yellow
            $fileName = [System.IO.Path]::GetFileName($Url)
            if (-not (Verify-FileHash -FilePath $OutFile -ExpectedHash $ExpectedHash -HashType $SourceName -OriginalFileName $fileName)) {
                Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
                return @{ Success = $false; ErrorType = "HashMismatch" }
            }
        }

        return @{ Success = $true; ErrorType = "None" }
    } catch {
        Write-Log "Unexpected error in Download-VerifyFile: $_" -Type "ERROR"
        return @{ Success = $false; ErrorType = "UnknownError" }
    }
}

# =============================================
# CAB EXTRACTION AND DRIVER INSTALLATION
# =============================================

function Install-DriverFromCab {
    param(
        [string]$CabPath,
        [string]$DeviceInstanceId,
        [string]$DeviceType
    )

    $extractPath = "$tempDir\extracted_$(Get-Random)"

    try {
        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

        Write-Host " Extracting driver package..." -ForegroundColor Yellow
        Write-DebugMessage "Extracting $CabPath to $extractPath"

        $expandResult = & expand.exe "$CabPath" "$extractPath" -F:* 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "CAB extraction failed (exit $LASTEXITCODE): $expandResult" -Type "ERROR"
            return $false
        }

        $infFiles = Get-ChildItem -Path $extractPath -Filter "*.inf" -Recurse -ErrorAction SilentlyContinue
        if ($infFiles.Count -eq 0) {
            Write-Log "No INF files found in extracted CAB: $CabPath" -Type "ERROR"
            return $false
        }

        Write-DebugMessage "Found $($infFiles.Count) INF file(s): $($infFiles.Name -join ', ')"

        Write-Host " Staging driver to Windows driver store..." -ForegroundColor Yellow
        foreach ($inf in $infFiles) {
            $pnpOut = pnputil /add-driver "$($inf.FullName)" /install 2>&1
            Write-DebugMessage "pnputil /add-driver: $pnpOut"
        }

        if ($DeviceInstanceId) {
            Write-Host " Updating $DeviceType device driver..." -ForegroundColor Yellow
            $updateOut = pnputil /update-device "$DeviceInstanceId" /install 2>&1
            Write-DebugMessage "pnputil /update-device: $updateOut"
        }

        Write-Host " $DeviceType driver installed successfully." -ForegroundColor Green
        Write-Log "$DeviceType driver installed from: $CabPath"
        return $true

    } catch {
        Write-Log "Error installing $DeviceType driver from CAB: $_" -Type "ERROR"
        return $false
    } finally {
        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Install-DriverWithFallback {
    param(
        [string]$PrimaryUrl,
        [string]$BackupUrl,
        [string]$ExpectedHash,
        [string]$DeviceInstanceId,
        [string]$DeviceType,
        [string]$VersionLabel
    )

    Write-Host "`n Installing $DeviceType driver ($VersionLabel)" -ForegroundColor Cyan

    $tempCab = "$tempDir\temp_$(Get-Random).cab"
    $downloadSuccess = $false
    $errorPhase = $null

    Write-Host " Attempting download from primary source..." -ForegroundColor Yellow
    $primaryResult = Download-VerifyFile -Url $PrimaryUrl -OutFile $tempCab -ExpectedHash $ExpectedHash -SourceName "Primary"

    if ($primaryResult.Success) {
        $downloadSuccess = $true
        Write-Host " SUCCESS: Primary source - download and hash verification successful." -ForegroundColor Green
    } else {
        $errorPhase = if ($primaryResult.ErrorType -eq "HashMismatch") { "1b" } else { "1a" }

        if ($BackupUrl) {
            Write-Host " Attempting download from backup source..." -ForegroundColor Yellow
            $backupResult = Download-VerifyFile -Url $BackupUrl -OutFile $tempCab -ExpectedHash $ExpectedHash -SourceName "Backup"

            if ($backupResult.Success) {
                $downloadSuccess = $true
                Write-Host " SUCCESS: Backup source - download and hash verification successful." -ForegroundColor Green
            } else {
                $errorPhase = if ($backupResult.ErrorType -eq "HashMismatch") { "2b" } else { "2a" }
            }
        } else {
            Write-Host " No backup source available." -ForegroundColor Red
        }
    }

    if (-not $downloadSuccess) {
        $msg = switch ($errorPhase) {
            "1a" { "Primary source download failed and no backup available." }
            "1b" { "Primary source file corrupted (hash mismatch) and no backup available." }
            "2a" { "Both primary and backup sources download failed." }
            "2b" { "Both primary and backup sources have hash mismatches." }
            default { "Unknown download error." }
        }
        Write-Host "`n ERROR: $msg" -ForegroundColor Red
        if (Test-Path $tempCab) { Remove-Item $tempCab -Force -ErrorAction SilentlyContinue }
        return $false
    }

    $installResult = Install-DriverFromCab -CabPath $tempCab -DeviceInstanceId $DeviceInstanceId -DeviceType $DeviceType

    if (Test-Path $tempCab) { Remove-Item $tempCab -Force -ErrorAction SilentlyContinue }
    return $installResult
}

# =============================================
# FINAL CREDITS FUNCTION
# =============================================

function Show-FinalCredits {
    Clear-Host
    Write-Host "/*************************************************************************" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "          UNIVERSAL INTEL WI-FI AND BLUETOOTH DRIVERS UPDATER          " -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "** --------------------------------------------------------------------- **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue

    $paddedVersion = $DisplayVersion.PadRight(14)
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "                       Tool Version: $paddedVersion                    " -NoNewline -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue

    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "              Author: Marcin Grygiel / www.firstever.tech              " -NoNewline -ForegroundColor Green -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "** --------------------------------------------------------------------- **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "         This tool is not affiliated with Intel Corporation.           " -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "         Drivers are sourced from official Intel/WU servers.           " -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "         Use at your own risk.                                         " -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "** --------------------------------------------------------------------- **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "  GitHub: FirstEverTech/Universal-Intel-WiFi-BT-Updater               " -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "*************************************************************************/" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host ""

    Write-Host " THANK YOU FOR USING UNIVERSAL INTEL WI-FI AND BLUETOOTH DRIVERS UPDATER" -ForegroundColor Cyan
    Write-Host " ========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " I hope this tool has been helpful in updating your system." -ForegroundColor Yellow
    Write-Host ""

    $keyActions = @{}

    $cacheBuster = "?t=$(Get-Date -Format 'yyyyMMddHHmmss')"
    try {
        $content = Invoke-WebRequest -Uri ($supportMessageUrl + $cacheBuster) -UseBasicParsing -ErrorAction Stop
        $lines = $content.Content -split "`r?`n"
    } catch {
        $lines = @(
            "[Magenta]",
            "[Magenta] SUPPORT THIS PROJECT",
            "[Magenta] ====================",
            "",
            " This project is maintained in my free time.",
            " Your support ensures regular updates and compatibility.",
            "",
            " Support options:",
            "",
            "[Green] - PayPal Donation:[Yellow] tinyurl.com/fet-paypal[Gray] - press [Black,Gray][P][Gray,Black] key",
            "[Green] - Buy Me a Coffee:[Yellow] tinyurl.com/fet-coffee[Gray] - press [Black,Gray][C][Gray,Black] key",
            "[Green] - GitHub Sponsors:[Yellow] tinyurl.com/fet-github[Gray] - press [Black,Gray][G][Gray,Black] key",
            "",
            " If this project helped you, please consider:",
            "",
            "[Green] - Giving it a STAR on GitHub",
            "[Green] - Sharing with friends and colleagues",
            "[Green] - Reporting issues or suggesting features",
            "[Green] - Supporting development financially",
            "",
            "[Magenta]",
            "[Magenta] CAREER OPPORTUNITY",
            "[Magenta] ==================",
            "",
            " I'm currently seeking new challenges where I can apply my expertise",
            " in solving complex IT infrastructure problems. If your organization",
            " struggles with system compatibility, automation, or tooling gaps,",
            " let's discuss how I can help.",
            "",
            "[Green] - Connect with me:[Yellow] linkedin.com/in/marcin-grygiel[Gray] - press [Black,Gray][L][Gray,Black] key"
        )
    }

    foreach ($line in $lines) {
        Write-ColorLine $line
        $keyInfo = Get-KeyAndUrlFromLine -Line $line
        if ($keyInfo) {
            if ($keyInfo.Key -match '[a-zA-Z]') {
                $keyActions[$keyInfo.Key.ToUpper()] = $keyInfo.Url
                $keyActions[$keyInfo.Key.ToLower()] = $keyInfo.Url
            } else {
                $keyActions[$keyInfo.Key] = $keyInfo.Url
            }
        }
    }

    if ($AutoMode) { return }

    Write-Host "`n Press " -NoNewline -ForegroundColor Gray
    Write-Host "P" -NoNewline -ForegroundColor Yellow
    Write-Host "=PayPal, " -NoNewline -ForegroundColor Gray
    Write-Host "C" -NoNewline -ForegroundColor Yellow
    Write-Host "=Coffee, " -NoNewline -ForegroundColor Gray
    Write-Host "G" -NoNewline -ForegroundColor Yellow
    Write-Host "=GitHub, " -NoNewline -ForegroundColor Gray
    Write-Host "L" -NoNewline -ForegroundColor Yellow
    Write-Host "=LinkedIn, or any other key to exit." -ForegroundColor Gray

    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $pressed = $key.Character.ToString()

    if ($keyActions.ContainsKey($pressed)) {
        Start-Process $keyActions[$pressed]
    }

    if (-not $isSFX) {
        Clear-Host
        Write-Host "`n Thank you for using Universal Intel Wi-Fi and Bluetooth Drivers Updater!`n" -ForegroundColor Cyan
    }
    exit
}

# =============================================
# MAIN SCRIPT EXECUTION
# =============================================

try {
    Show-Screen1

    Write-Host ""
    if (-not (Verify-ScriptHash)) {
        Write-Host " Update process aborted for security reasons." -ForegroundColor Red
        Cleanup
        if (-not $AutoMode) {
            Write-Host "`n Press any key..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
        Show-FinalCredits
        exit 1
    }

    $updateCheckResult = Check-ForUpdaterUpdates
    if (-not $updateCheckResult) { exit 100 }

    Clear-TempDriverFolders
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-DebugMessage "Created temporary directory: $tempDir"

    # ------------------------------------------
    Show-Screen2
    # ------------------------------------------

    # Hardware detection
    Write-Host " Scanning for Intel Wi-Fi and Bluetooth devices..." -ForegroundColor Yellow
    Write-Host ""

    $wifiDevice = Get-IntelWiFiDevice
    $btDevice   = Get-IntelBTDevice

    $totalFound = 0
    if ($wifiDevice) { $totalFound++ }
    if ($btDevice)   { $totalFound++ }

    if ($totalFound -eq 0) {
        Write-Host " No supported Intel Wi-Fi or Bluetooth devices found." -ForegroundColor Yellow
        Write-Host " Supported: Wi-Fi 5 (AC) / Wi-Fi 6 (AX) / Wi-Fi 6E (AXE) / Wi-Fi 7 (BE)" -ForegroundColor Gray
        Cleanup
        if (-not $AutoMode) {
            Write-Host "`n Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
        Show-FinalCredits
        exit
    }

    Write-Host " Found $totalFound Intel Wireless device(s)" -ForegroundColor Green
    Write-Host " Downloading latest driver information..." -ForegroundColor Yellow

    # Download databases
    $wifiLatestContent = $null
    $btLatestContent   = $null
    $wifiDlContent     = $null
    $btDlContent       = $null

    if ($wifiDevice) { $wifiLatestContent = Get-RemoteContent -Url $wifiLatestUrl }
    if ($btDevice)   { $btLatestContent   = Get-RemoteContent -Url $btLatestUrl }
    if ($wifiDevice) { $wifiDlContent     = Get-RemoteContent -Url $wifiDownloadUrl }
    if ($btDevice)   { $btDlContent       = Get-RemoteContent -Url $btDownloadUrl }

    if (($wifiDevice -and (-not $wifiLatestContent -or -not $wifiDlContent)) -or
        ($btDevice   -and (-not $btLatestContent   -or -not $btDlContent))) {
        Write-Host " Failed to download driver information. Please check your internet connection." -ForegroundColor Red
        Cleanup
        if (-not $AutoMode) {
            Write-Host "`n Press any key..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
        Show-FinalCredits
        exit
    }

    Write-Host " Parsing driver information..." -ForegroundColor Green
    Write-Host ""

    # Parse databases
    $wifiData   = if ($wifiLatestContent) { Parse-WiFiLatestMd -Content $wifiLatestContent }  else { $null }
    $btData     = if ($btLatestContent)   { Parse-BTLatestMd   -Content $btLatestContent }    else { $null }
    $wifiDlData = if ($wifiDlContent)     { Parse-WiFiDownloadList -Content $wifiDlContent }   else { $null }
    $btDlData   = if ($btDlContent)       { Parse-BTDownloadList   -Content $btDlContent }     else { $null }

    # ---- Match detected devices to database ----

    $wifiInfo = $null
    $btInfo   = $null

    if ($wifiDevice -and $wifiData -and $wifiDlData) {
        $devEntry = $wifiData.Devices[$wifiDevice.DEV]
        if ($devEntry) {
            Write-Host " Found compatible device: Intel Wireless Wi-Fi (HWID: $($wifiDevice.DEV))" -ForegroundColor Green
            $wifiCurrentVersion = Get-CurrentDriverVersion -DeviceInstanceId $wifiDevice.InstanceId
            $wifiInfo = @{
                DEV            = $wifiDevice.DEV
                InstanceId     = $wifiDevice.InstanceId
                Chipset        = $devEntry.Chipset
                Models         = $devEntry.Models
                Generation     = $devEntry.Generation
                LatestVersion  = $wifiData.LatestVersion
                ReleaseDate    = $wifiData.ReleaseDate
                CurrentVersion = $wifiCurrentVersion
                DlData         = $wifiDlData
            }
        } else {
            Write-Host " [WARNING] Wi-Fi device DEV_$($wifiDevice.DEV) not found in database." -ForegroundColor Yellow
        }
    }

    if ($btDevice -and $btData -and $btDlData) {
        $pidEntry = $btData.Devices[$btDevice.PID]
        if ($pidEntry) {
            Write-Host " Found compatible device: Intel Wireless Bluetooth (PID: $($btDevice.PID))" -ForegroundColor Green
            $btCurrentVersion = Get-CurrentDriverVersion -DeviceInstanceId $btDevice.InstanceId
            $btBlock = Get-BTBlockForDevice -DevicePID $btDevice.PID -BTDownloadData $btDlData
            $btInfo = @{
                PID            = $btDevice.PID
                InstanceId     = $btDevice.InstanceId
                Chipset        = $pidEntry.Chipset
                Generation     = $pidEntry.Generation
                Bluetooth      = $pidEntry.Bluetooth
                LatestVersion  = $btData.LatestVersion
                ReleaseDate    = $btData.ReleaseDate
                CurrentVersion = $btCurrentVersion
                Block          = $btBlock
            }
        } else {
            Write-Host " [WARNING] Bluetooth PID $($btDevice.PID) not found in database." -ForegroundColor Yellow
        }
    }

    if (-not $wifiInfo -and -not $btInfo) {
        Write-Host "`n No compatible devices matched in the database." -ForegroundColor Yellow
        Cleanup
        if (-not $AutoMode) {
            Write-Host "`n Press any key..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
        Show-FinalCredits
        exit
    }

    # ---- Platform Information display ----

    Write-Host ""
    Write-Host " =============== Platform Information ===============" -ForegroundColor Cyan
    Write-Host ""

    $wifiNeedsUpdate = $false
    $btNeedsUpdate   = $false

    if ($wifiInfo) {
        # Wyświetlanie Wi-Fi
        Write-Host " Chipset: Intel $($wifiInfo.Generation) $($wifiInfo.Chipset)" -ForegroundColor White
        Write-Host " Model: $($wifiInfo.Models)" -ForegroundColor Gray

        if ($wifiInfo.CurrentVersion) {
            Write-Host " Current Version: $($wifiInfo.CurrentVersion) ---> Latest Version: $($wifiInfo.LatestVersion)" -ForegroundColor Gray
        } else {
            Write-Host " Current Version: Unable to determine ---> Latest Version: $($wifiInfo.LatestVersion)" -ForegroundColor Gray
        }

        Write-Host " Driver Date: $($wifiInfo.ReleaseDate)" -ForegroundColor Yellow

        if ($wifiInfo.CurrentVersion) {
            try {
                $curVer    = [version]$wifiInfo.CurrentVersion
                $latestVer = [version]$wifiInfo.LatestVersion
                if ($curVer -lt $latestVer) {
                    Write-Host " Status: Update available - current: $($wifiInfo.CurrentVersion), latest: $($wifiInfo.LatestVersion)" -ForegroundColor Yellow
                    $wifiNeedsUpdate = $true
                } elseif ($curVer -gt $latestVer) {
                    Write-Host " Status: Newer version installed (may be a pre-release)." -ForegroundColor Cyan
                } else {
                    Write-Host " Status: Already on latest version." -ForegroundColor Green
                }
            } catch {
                if ($wifiInfo.CurrentVersion -ne $wifiInfo.LatestVersion) {
                    Write-Host " Status: Update available - current: $($wifiInfo.CurrentVersion), latest: $($wifiInfo.LatestVersion)" -ForegroundColor Yellow
                    $wifiNeedsUpdate = $true
                } else {
                    Write-Host " Status: Already on latest version." -ForegroundColor Green
                }
            }
        } else {
            Write-Host " Status: Driver will be installed." -ForegroundColor Yellow
            $wifiNeedsUpdate = $true
        }
        Write-Host ""
    }

    if ($btInfo) {
        # Wyświetlanie Bluetooth
        if ($wifiInfo) {
            Write-Host " Chipset: Intel $($btInfo.Generation) $($btInfo.Chipset)" -ForegroundColor White
        } else {
            Write-Host " Chipset: Intel Standalone USB Bluetooth Adapter" -ForegroundColor White
        }
        Write-Host " Device: Intel Wireless Bluetooth $($btInfo.Bluetooth)" -ForegroundColor Gray

        if ($btInfo.CurrentVersion) {
            Write-Host " Current Version: $($btInfo.CurrentVersion) ---> Latest Version: $($btInfo.LatestVersion)" -ForegroundColor Gray
        } else {
            Write-Host " Current Version: Unable to determine ---> Latest Version: $($btInfo.LatestVersion)" -ForegroundColor Gray
        }

        Write-Host " Driver Date: $($btInfo.ReleaseDate)" -ForegroundColor Yellow

        if ($btInfo.CurrentVersion) {
            try {
                $curVer    = [version]$btInfo.CurrentVersion
                $latestVer = [version]$btInfo.LatestVersion
                if ($curVer -lt $latestVer) {
                    Write-Host " Status: Update available - current: $($btInfo.CurrentVersion), latest: $($btInfo.LatestVersion)" -ForegroundColor Yellow
                    $btNeedsUpdate = $true
                } elseif ($curVer -gt $latestVer) {
                    Write-Host " Status: Newer version installed (may be a pre-release)." -ForegroundColor Cyan
                } else {
                    Write-Host " Status: Already on latest version." -ForegroundColor Green
                }
            } catch {
                if ($btInfo.CurrentVersion -ne $btInfo.LatestVersion) {
                    Write-Host " Status: Update available - current: $($btInfo.CurrentVersion), latest: $($btInfo.LatestVersion)" -ForegroundColor Yellow
                    $btNeedsUpdate = $true
                } else {
                    Write-Host " Status: Already on latest version." -ForegroundColor Green
                }
            }
        } else {
            Write-Host " Status: Driver will be installed." -ForegroundColor Yellow
            $btNeedsUpdate = $true
        }
        Write-Host ""
    }

    # ---- Update / reinstall prompt ----

    $updateCount = 0
    if ($wifiNeedsUpdate) { $updateCount++ }
    if ($btNeedsUpdate)   { $updateCount++ }

    if ($updateCount -gt 0) {
        $driverWord = if ($updateCount -gt 1) { "drivers" } else { "driver" }
        Write-Host " A newer version of the $driverWord is available." -ForegroundColor Green

        if ($AutoMode) {
            $response = "Y"
            Write-Host " Auto mode: automatically installing (Y)." -ForegroundColor Cyan
        } else {
            $response = Read-Host " Do you want to install the latest $driverWord? (Y/N)"
        }

        if (-not ($response -eq "Y" -or $response -eq "y")) {
            Write-Host "`n Installation cancelled." -ForegroundColor Yellow
            Cleanup
            if (-not $AutoMode) {
                Write-Host "`n Press any key..."
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            Show-FinalCredits
            exit
        }
    } else {
        # Both up to date - offer force reinstall
        Write-Host " All drivers are up to date." -ForegroundColor Green

        if ($AutoMode) {
            $response = "Y"
            Write-Host " Auto mode: automatically forcing reinstall (Y)." -ForegroundColor Cyan
        } else {
            $response = Read-Host " Do you want to force reinstall this driver(s) anyway? (Y/N)"
        }

        if ($response -eq "Y" -or $response -eq "y") {
            if ($wifiInfo) { $wifiNeedsUpdate = $true }
            if ($btInfo)   { $btNeedsUpdate   = $true }
        } else {
            Write-Host "`n Installation cancelled." -ForegroundColor Yellow
            Cleanup
            if (-not $AutoMode) {
                Write-Host "`n Press any key..."
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
            Show-FinalCredits
            exit
        }
    }

    # ------------------------------------------
    $confirmResponse = Show-Screen3
    # ------------------------------------------

    if (-not ($confirmResponse -eq "Y" -or $confirmResponse -eq "y")) {
        Write-Host "`n Update cancelled." -ForegroundColor Yellow
        Cleanup
        if (-not $AutoMode) {
            Write-Host "`n Press any key..."
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
        Show-FinalCredits
        exit
    }

    # System Restore Point
    Write-Host "`n Starting driver update process..." -ForegroundColor Green
    Write-Host " Creating system restore point..." -ForegroundColor Yellow

    try {
        try { $null = Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue } catch { }

        $restorePointDescription = "Before Intel Wi-Fi BT Driver Update - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $warningMessages = @()
        Checkpoint-Computer -Description $restorePointDescription -RestorePointType "MODIFY_SETTINGS" -WarningVariable warningMessages -WarningAction SilentlyContinue -ErrorAction Stop

        if ($warningMessages.Count -gt 0) {
            $warnText = $warningMessages -join " "
            if ($warnText -match "1440 minutes" -or $warnText -match "past.*minutes") {
                throw "RestorePointFrequencyLimit"
            }
        }

        Write-Host " System restore point created successfully." -ForegroundColor Green
        Write-Host " '$restorePointDescription'" -ForegroundColor Green
        Write-Host "`n Preparing for installation..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5

    } catch {
        $errMsg = $_.Exception.Message
        if ($errMsg -match "RestorePointFrequencyLimit" -or $errMsg -match "1440 minutes") {
            Write-Host "`n IMPORTANT NOTICE:" -ForegroundColor Yellow
            Write-Host " Another restore point was created within the last 24 hours." -ForegroundColor Yellow
            Write-Host " Windows currently cannot create more restore points." -ForegroundColor Yellow
            Write-Host ""

            if ($AutoMode) {
                $continueResponse = "Y"
                Write-Host " Auto mode: automatically continuing without restore point (Y)." -ForegroundColor Cyan
            } else {
                $continueResponse = Read-Host " Do you want to continue without creating a restore point? (Y/N)"
            }

            if (-not ($continueResponse -eq "Y" -or $continueResponse -eq "y")) {
                Write-Host "`n Installation cancelled." -ForegroundColor Yellow
                Cleanup
                if (-not $AutoMode) {
                    Write-Host "`n Press any key..."
                    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                }
                Show-FinalCredits
                exit
            }
        } else {
            Write-Host " WARNING: Could not create system restore point. Continuing anyway..." -ForegroundColor Yellow
        }
        Write-Host "`n Preparing for installation..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }

    # ------------------------------------------
    Show-Screen4
    # ------------------------------------------

    $successCount = 0

    # Install Wi-Fi driver
    if ($wifiNeedsUpdate -and $wifiInfo -and $wifiInfo.DlData.Link) {
        $wifiResult = Install-DriverWithFallback `
            -PrimaryUrl      $wifiInfo.DlData.Link `
            -BackupUrl       $wifiInfo.DlData.Backup `
            -ExpectedHash    $wifiInfo.DlData.SHA256 `
            -DeviceInstanceId $wifiInfo.InstanceId `
            -DeviceType      "Intel Wi-Fi" `
            -VersionLabel    $wifiInfo.LatestVersion

        if ($wifiResult) { $successCount++ }
    } elseif ($wifiNeedsUpdate) {
        Write-Host "`n ERROR: No download information found for Wi-Fi driver." -ForegroundColor Red
        Write-Host " Please check intel-wifi-drivers-download.txt for missing entries." -ForegroundColor Yellow
    }

    # Install Bluetooth driver
    if ($btNeedsUpdate -and $btInfo -and $btInfo.Block) {
        $btResult = Install-DriverWithFallback `
            -PrimaryUrl      $btInfo.Block.Link `
            -BackupUrl       $btInfo.Block.Backup `
            -ExpectedHash    $btInfo.Block.SHA256 `
            -DeviceInstanceId $btInfo.InstanceId `
            -DeviceType      "Intel Bluetooth" `
            -VersionLabel    $btInfo.LatestVersion

        if ($btResult) { $successCount++ }
    } elseif ($btNeedsUpdate) {
        Write-Host "`n ERROR: No download information found for Bluetooth driver (PID: $($btInfo.PID))." -ForegroundColor Red
        Write-Host " Please check intel-bt-drivers-download.txt for missing entries." -ForegroundColor Yellow
    }

    # Summary
    if ($successCount -gt 0) {
        Write-Host "`n IMPORTANT NOTICE:" -ForegroundColor Yellow
        Write-Host " Computer restart may be required to complete driver installation!" -ForegroundColor Yellow
        $driverWord = if ($successCount -gt 1) { "drivers" } else { "driver" }
        Write-Host "`n Summary: Successfully installed $successCount $driverWord." -ForegroundColor Green
    } else {
        Write-Host "`n No drivers were successfully installed." -ForegroundColor Red
    }

    Cleanup

    Show-FinalSummary

    Write-Host "`n Driver update process completed." -ForegroundColor Cyan
    Write-Host " If you have any issues with this tool, please report them at:"
    Write-Host " https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater" -ForegroundColor Cyan

    if ($DebugMode) {
        Write-Host "`n [DEBUG MODE ENABLED - All debug messages were shown]" -ForegroundColor Magenta
    }

    if (-not $AutoMode) {
        Write-Host "`n Press any key to continue..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }

    Show-FinalCredits
    exit 0

} catch {
    Write-Log "Unhandled error in main execution: $($_.Exception.Message)" -Type "ERROR"
    Write-Host " An unexpected error occurred. Please check the log file at $logFile for details." -ForegroundColor Red
    Cleanup
    if (-not $AutoMode) {
        Write-Host "`n Press any key..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
    Show-FinalCredits
    exit 1
}