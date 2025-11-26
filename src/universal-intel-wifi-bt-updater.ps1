# Intel Wi-Fi and Bluetooth Drivers Update Script
# Based on Intel Wireless Drivers Latest database
# Downloads latest drivers from Windows Update and updates if newer versions available
# By Marcin Grygiel / www.firstever.tech

# =============================================
# SCRIPT VERSION - MUST BE UPDATED WITH EACH RELEASE
# =============================================
$ScriptVersion = "24.0-2025.11.1"
# =============================================

# =============================================
# CONFIGURATION - Set to 1 to enable debug mode
# =============================================
$DebugMode = 0  # 0 = Disabled, 1 = Enabled
$SkipSelfHashVerification = 0  # 0 = Enabled (normal operation), 1 = Disabled (for testing)
# =============================================

# GitHub repository URLs
$githubBaseUrl = "https://raw.githubusercontent.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/main/data/"
$wifiDriversUrl = $githubBaseUrl + "intel-wifi-driver-download.txt"
$bluetoothDriversUrl = $githubBaseUrl + "intel-bt-driver-download.txt"

# Temporary directory for downloads
$tempDir = "C:\Windows\Temp\IntelWiFiBT"

# =============================================
# ENHANCED ERROR HANDLING (BACKGROUND)
# =============================================

$global:InstallationErrors = @()
$global:ScriptStartTime = Get-Date
$logFile = "$tempDir\wifi_bt_update.log"

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    try {
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    } catch {
        # Silent fallback
    }
    
    # Only show errors to user, everything else goes to log only
    if ($Type -eq "ERROR") {
        $global:InstallationErrors += $Message
        Write-Host " ERROR: $Message" -ForegroundColor Red
    }
}

function Write-DebugMessage {
    param([string]$Message, [string]$Color = "Gray")
    Write-Log -Message $Message -Type "DEBUG"
    if ($DebugMode -eq 1) {
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
# HEADER DISPLAY FUNCTION
# =============================================
function Show-Header {
    Clear-Host
    # CAŁY HEADER na DarkBlue
    Write-Host "/*************************************************************************" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "            UNIVERSAL INTEL WI-FI AND BLUETOOTH DRIVERS UPDATER          " -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "** --------------------------------------------------------------------- **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "                   Drivers Version: 24.0 (2025.11.1)                   " -NoNewline -ForegroundColor Yellow -BackgroundColor DarkBlue
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
    Write-Host "         Drivers are sourced from official Microsoft servers.          " -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "         Use at your own risk.                                         " -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "** --------------------------------------------------------------------- **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "         GitHub: FirstEverTech/Universal-Intel-WiFi-BT-Updater         " -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
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
    
    # Show configuration status
    if ($DebugMode -eq 1) {
        Write-Host " DEBUG MODE: ENABLED" -ForegroundColor Magenta
    }
    if ($SkipSelfHashVerification -eq 1) {
        Write-Host "`n SELF-HASH VERIFICATION: DISABLED (Testing Mode)" -ForegroundColor Yellow
    }
    
    Write-Host ""
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
}

function Show-Screen4 {
    Show-Header
    Write-Host " [SCREEN 4/4] DOWNLOAD AND INSTALLATION PROGRESS" -ForegroundColor Cyan
    Write-Host " ===============================================" -ForegroundColor Cyan
    Write-Host ""
}

# =============================================
# SELF-HASH VERIFICATION FUNCTION
# =============================================

function Verify-ScriptHash {
    # Skip verification if disabled in configuration
    if ($SkipSelfHashVerification -eq 1) {
        Write-Host " SKIPPED: Self-hash verification disabled (Testing Mode)." -ForegroundColor Yellow
        Write-Host ""
        return $true
    }
    
    try {
        Write-Host " Verifying Updater source file integrity..." -ForegroundColor Yellow
        
        # Get current script path using multiple methods for reliability
        $scriptPath = $null
        if ($PSCommandPath) {
            $scriptPath = $PSCommandPath
        } elseif ($MyInvocation.MyCommand.Path) {
            $scriptPath = $MyInvocation.MyCommand.Path
        } else {
            # Fallback: try to find the script in current directory
            $potentialPath = Join-Path (Get-Location) "Universal-Intel-WiFi-BT-Updater.ps1"
            if (Test-Path $potentialPath) {
                $scriptPath = $potentialPath
            }
        }
        
        if (-not $scriptPath -or -not (Test-Path $scriptPath)) {
            Write-Host " FAIL: Cannot locate script file for hash verification." -ForegroundColor Red
            return $false
        }
        
        Write-DebugMessage "Script path: $scriptPath"
        
        # Calculate current script hash with retry logic
        $currentHash = $null
        $retryCount = 0
        $maxRetries = 3
        
        while ($retryCount -lt $maxRetries -and -not $currentHash) {
            try {
                $hashResult = Get-FileHash -Path $scriptPath -Algorithm SHA256
                $currentHash = $hashResult.Hash.ToUpper()
                Write-DebugMessage "Successfully calculated script hash (attempt $($retryCount + 1)): $currentHash"
            } catch {
                $retryCount++
                if ($retryCount -eq $maxRetries) {
                    Write-Host " FAIL: Could not calculate script hash after $maxRetries attempts." -ForegroundColor Red
                    Write-Host " Error: $($_.Exception.Message)" -ForegroundColor Red
                    return $false
                }
                Start-Sleep -Milliseconds 500
            }
        }
        
        if (-not $currentHash) {
            Write-Host " FAIL: Could not calculate script hash." -ForegroundColor Red
            return $false
        }
        
        # Construct URL for hash verification file
        $hashFileUrl = "https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases/download/v$ScriptVersion/universal-intel-wifi-bt-updater-ps1.sha256"
        
        Write-DebugMessage "Downloading hash from: $hashFileUrl"
        
        # Download expected hash file
        try {
            $expectedHashResponse = Invoke-WebRequest -Uri $hashFileUrl -UseBasicParsing -ErrorAction Stop
            
            # Convert content to string properly
            $expectedHashLine = ""
            if ($expectedHashResponse.Content -is [byte[]]) {
                $expectedHashLine = [System.Text.Encoding]::UTF8.GetString($expectedHashResponse.Content).Trim()
            } else {
                $expectedHashLine = $expectedHashResponse.Content.ToString().Trim()
            }
            
            Write-DebugMessage "Raw hash file content: '$expectedHashLine'"
            
            # Parse hash from the file - handle multiple formats
            $expectedHash = $null
            $expectedFileName = $null
            
            # Try different parsing patterns
            if ($expectedHashLine -match '^([A-Fa-f0-9]{64})\s+(\S+)$') {
                # Format: HASH FILENAME
                $expectedHash = $matches[1].ToUpper()
                $expectedFileName = $matches[2]
                Write-DebugMessage "Parsed format: HASH FILENAME"
            } elseif ($expectedHashLine -match '^([A-Fa-f0-9]{64})$') {
                # Format: HASH only
                $expectedHash = $expectedHashLine.ToUpper()
                $expectedFileName = "Universal-Intel-WiFi-BT-Updater.ps1"
                Write-DebugMessage "Parsed format: HASH only"
            } elseif ($expectedHashLine -match '^([A-Fa-f0-9]{64})\s*\*?\s*(\S+)$') {
                # Format: HASH * FILENAME (some hash tools use this)
                $expectedHash = $matches[1].ToUpper()
                $expectedFileName = $matches[2]
                Write-DebugMessage "Parsed format: HASH * FILENAME"
            }
            
            if (-not $expectedHash) {
                Write-Host " FAIL: Could not parse hash from file. Content: $expectedHashLine" -ForegroundColor Red
                return $false
            }
            
            Write-DebugMessage "Expected hash: $expectedHash"
            Write-DebugMessage "Current hash: $currentHash"
            Write-DebugMessage "Expected file: $expectedFileName"
            
            # Compare hashes
            if ($currentHash -eq $expectedHash) {
                Write-Host " PASS: Updater hash verification passed." -ForegroundColor Green
                Write-DebugMessage "Hash verification successful"
                return $true
            } else {
                Write-Host " FAIL: Updater hash verification failed. Hash doesn't match." -ForegroundColor Red
                Write-Host "`n WARNING: The updater file may have been modified or corrupted!" -ForegroundColor Red
                Write-Host " Please download the Updater from the official source:" -ForegroundColor Red
                Write-Host " https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases" -ForegroundColor Cyan
                Write-Host ""
                Write-Host " Hash verification failed: $($expectedFileName)" -ForegroundColor Yellow
                Write-Host " Source: $expectedHash" -ForegroundColor Green
                Write-Host " Actual: $currentHash" -ForegroundColor Red
                return $false
            }
        }
        catch {
            Write-Host " ERROR: Could not download or parse hash file." -ForegroundColor Red
            Write-Host "`n Please download the Updater from the official source and try again:" -ForegroundColor Red
            Write-Host " https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases" -ForegroundColor Red
            
            Write-Host ""
            Write-Host " Hash verification failed: Universal-Intel-WiFi-BT-Updater.ps1" -ForegroundColor Yellow
            Write-Host " Source: I can't read the source HASH from the GitHub repository." -ForegroundColor Red
            Write-Host " Actual: $currentHash" -ForegroundColor Red
            Write-Host ""
            
            return $false
        }
    }
    catch {
        Write-Host " ERROR: Could not verify script hash." -ForegroundColor Red
        Write-Host " Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`n Please download the Updater from the official source and try again:" -ForegroundColor Red
        Write-Host " https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases" -ForegroundColor Red
        
        return $false
    }
}

# =============================================
# UPDATE CHECK FUNCTION
# =============================================

function Get-DownloadsFolder {
    try {
        # Try to get Downloads folder from registry
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        $downloadsGuid = "{374DE290-123F-4565-9164-39C4925E467B}"
        
        if (Test-Path $registryPath) {
            $downloadsValue = Get-ItemProperty -Path $registryPath -Name $downloadsGuid -ErrorAction SilentlyContinue
            if ($downloadsValue -and $downloadsValue.$downloadsGuid) {
                $downloadsPath = [Environment]::ExpandEnvironmentVariables($downloadsValue.$downloadsGuid)
                Write-DebugMessage "Found Downloads folder in registry: $downloadsPath"
                return $downloadsPath
            }
        }
        
        # Fallback to default Downloads folder
        $defaultDownloads = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
        Write-DebugMessage "Using default Downloads folder: $defaultDownloads"
        return $defaultDownloads
    }
    catch {
        Write-DebugMessage "Error getting Downloads folder: $($_.Exception.Message)"
        return [Environment]::GetFolderPath("UserProfile") + "\Downloads"
    }
}

function Check-ForUpdaterUpdates {
    try {
        Write-Host "`n Checking for newer updater version..." -ForegroundColor Yellow
        
        # Download version file from GitHub
        $versionFileUrl = "https://raw.githubusercontent.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/main/src/universal-intel-wifi-bt-updater.ver"
        $latestVersionContent = Invoke-WebRequest -Uri $versionFileUrl -UseBasicParsing -ErrorAction Stop
        $latestVersion = $latestVersionContent.Content.Trim()
        
        Write-DebugMessage "Current version: $ScriptVersion, Latest version: $latestVersion"
        
        # Direct comparison - no normalization needed
        if ($ScriptVersion -eq $latestVersion) {
            Write-Host " Status: Already on latest version." -ForegroundColor Green
            Write-Host ""
            Write-Host " Starting the updater..." -ForegroundColor Gray
            Write-Host ""
            Start-Sleep -Seconds 3
            return $true
        } else {
            Write-Host " A new version $latestVersion is available (current: $ScriptVersion)." -ForegroundColor Yellow
            
            # Get valid user input
            do {
                $continueChoice = Read-Host "`n Do you want to continue with the current version? (Y/N)"
                Write-Host ""
                $continueChoice = $continueChoice.Trim().ToUpper()
                
                if ($continueChoice -ne 'Y' -and $continueChoice -ne 'N') {
                    Write-Host " Invalid input. Please enter Y or N." -ForegroundColor Red
                }
            } while ($continueChoice -ne 'Y' -and $continueChoice -ne 'N')
            
            if ($continueChoice -eq 'Y') {
                return $true
            } else {
                # User chose not to continue with current version
                do {
                    $downloadChoice = Read-Host " Do you want to download the latest version? (Y/N)"
                    $downloadChoice = $downloadChoice.Trim().ToUpper()
                    
                    if ($downloadChoice -ne 'Y' -and $downloadChoice -ne 'N') {
                        Write-Host " Invalid input. Please enter Y or N." -ForegroundColor Red
                    }
                } while ($downloadChoice -ne 'Y' -and $downloadChoice -ne 'N')
                
                if ($downloadChoice -eq 'Y') {
                    # For download, use the exact version from GitHub
                    $downloadUrl = "https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases/download/v$latestVersion/WiFi-BT-Updater-$latestVersion-Win10-Win11.exe"
                    $downloadsFolder = Get-DownloadsFolder
                    $outputPath = Join-Path $downloadsFolder "WiFi-BT-Updater-$latestVersion-Win10-Win11.exe"
                    
                    Write-Host " Downloading new version to:" -ForegroundColor Yellow
                    Write-Host " $outputPath" -ForegroundColor Yellow
                    Write-Host ""
                    
                    # Add retry logic and better error handling for download
                    $maxRetries = 3
                    $retryCount = 0
                    $downloadSuccess = $false
                    
                    while ($retryCount -lt $maxRetries -and -not $downloadSuccess) {
                        try {
                            Write-Host " Attempt $($retryCount + 1) of $maxRetries..." -ForegroundColor Yellow
                            Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -UseBasicParsing -ErrorAction Stop
                            $downloadSuccess = $true
                            Write-Host "`n SUCCESS: New version downloaded successfully." -ForegroundColor Green
                            Write-Host "`n File saved to:" -ForegroundColor Yellow
                            Write-Host " $outputPath" -ForegroundColor Yellow
                        }
                        catch {
                            $retryCount++
                            if ($retryCount -eq $maxRetries) {
                                Write-Host " ERROR: Failed to download new version after $maxRetries attempts - $($_.Exception.Message)" -ForegroundColor Red
                                Write-Host " Please download manually from: https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater/releases" -ForegroundColor Red
                            } else {
                                Write-Host " Download attempt $retryCount failed, retrying..." -ForegroundColor Yellow
                                Start-Sleep -Seconds 2
                            }
                        }
                    }
                    
                    if ($downloadSuccess) {
                        do {
                            $exitChoice = Read-Host "`n Do you want to exit now to run the new version? (Y/N)"
                            $exitChoice = $exitChoice.Trim().ToUpper()
                            
                            if ($exitChoice -ne 'Y' -and $exitChoice -ne 'N') {
                                Write-Host " Invalid input. Please enter Y or N." -ForegroundColor Red
                            }
                        } while ($exitChoice -ne 'Y' -and $exitChoice -ne 'N')
                        
                        if ($exitChoice -eq 'Y') {
                            Write-Host " Starting the new version and closing current updater..." -ForegroundColor Green
                            
                            # Start the new version WITHOUT cleaning temp files
                            Start-Process -FilePath $outputPath
                            
                            # Exit immediately without any user interaction
                            # Use exit code 100 to indicate successful launch of new version
                            [Environment]::Exit(100)
                        } else {
                            Write-Host "`n Update cancelled by user." -ForegroundColor Yellow
                            Cleanup
                            Write-Host "`n Press any key..." -ForegroundColor Yellow
                            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                            Show-FinalCredits
                            exit 0
                        }
                    } else {
                        Write-Host "`n Update process cancelled due to download failure." -ForegroundColor Red
                        Cleanup
                        Write-Host "`n Press any key..." -ForegroundColor Yellow
                        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                        Show-FinalCredits
                        exit 1
                    }
                } else {
                    # User chose not to download new version
                    Write-Host "`n Update cancelled by user." -ForegroundColor Yellow
                    Cleanup
                    Write-Host "`n Press any key..." -ForegroundColor Yellow
                    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                    Show-FinalCredits
                    exit 0
                }
            }
        }
    }
    catch {
        Write-Host " WARNING: Could not check for updates." -ForegroundColor Yellow
        Write-Host " Error: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host " Continuing with current version in 3 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        return $true
    }
}

# =============================================
# FILE INTEGRITY VERIFICATION FUNCTIONS
# =============================================

function Get-FileHash256 {
    param([string]$FilePath)
    
    try {
        if (Test-Path $FilePath) {
            $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
            Write-DebugMessage "Calculated SHA256 for $FilePath : $($hash.Hash)"
            return $hash.Hash
        } else {
            Write-Log "File not found for hash calculation: $FilePath" -Type "ERROR"
            return $null
        }
    } catch {
        Write-Log "Error calculating hash for $FilePath : $($_.Exception.Message)" -Type "ERROR"
        return $null
    }
}

function Verify-FileHash {
    param(
        [string]$FilePath, 
        [string]$ExpectedHash,
        [string]$HashType = "Primary",
        [string]$OriginalFileName = $null
    )

    if (-not $ExpectedHash) {
        Write-DebugMessage "No expected $HashType hash provided, skipping verification."
        return $true
    }

    $actualHash = Get-FileHash256 -FilePath $FilePath
    if (-not $actualHash) {
        Write-Log "Failed to calculate hash for $FilePath" -Type "ERROR"
        return $false
    }

    if ($actualHash -eq $ExpectedHash) {
        Write-DebugMessage "$HashType hash verification passed for $FilePath"
        Write-Host " PASS: $HashType hash verification passed." -ForegroundColor Green
        return $true
    } else {
        $displayName = if ($OriginalFileName) { $OriginalFileName } else { Split-Path $FilePath -Leaf }
        
        $errorMessage = "$HashType hash verification failed for $displayName. Source: $ExpectedHash, Actual: $actualHash"
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [ERROR] $errorMessage"
        try {
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
        } catch {
            # Silent fallback
        }
        $global:InstallationErrors += $errorMessage

        Write-Host ""
        Write-Host " $HashType hash verification failed: $displayName" -ForegroundColor Red
        Write-Host " Source: $ExpectedHash" -ForegroundColor Red
        Write-Host " Actual: $actualHash" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

# =============================================
# DIGITAL SIGNATURE VERIFICATION FUNCTIONS
# =============================================

function Verify-FileSignature {
    param([string]$FilePath)

    try {
        Write-DebugMessage "Verifying digital signature for: $FilePath"
        
        $signature = Get-AuthenticodeSignature -FilePath $FilePath
        Write-DebugMessage "Signature status: $($signature.Status)"
        Write-DebugMessage "Signer: $($signature.SignerCertificate.Subject)"
        Write-DebugMessage "Signature Algorithm: $($signature.SignerCertificate.SignatureAlgorithm.FriendlyName)"

        if ($signature.Status -ne 'Valid') {
            Write-Log "Digital signature is not valid. Status: $($signature.Status)" -Type "ERROR"
            Write-Host " FAIL: Digital signature verification - Status: $($signature.Status)" -ForegroundColor Red
            return $false
        }

        if ($signature.SignerCertificate.Subject -notmatch 'CN=Microsoft Windows Hardware Compatibility Publisher') {
            Write-Log "File not signed by Microsoft Windows Hardware Compatibility Publisher. Signer: $($signature.SignerCertificate.Subject)" -Type "ERROR"
            Write-Host " FAIL: Digital signature verification - Not signed by Microsoft Windows Hardware Compatibility Publisher." -ForegroundColor Red
            return $false
        }

        if ($signature.SignerCertificate.SignatureAlgorithm.FriendlyName -notmatch 'sha256') {
            Write-Log "Signature not using SHA256 algorithm. Algorithm: $($signature.SignerCertificate.SignatureAlgorithm.FriendlyName)" -Type "ERROR"
            Write-Host " FAIL: Digital signature verification - Not using SHA256 algorithm" -ForegroundColor Red
            return $false
        }

        Write-Host " PASS: Digitally signed by Microsoft Windows Hardware Compatibility Publisher." -ForegroundColor Green
        Write-DebugMessage "Digital signature verification passed for $FilePath"
        return $true
    }
    catch {
        Write-Log "Error verifying digital signature: $($_.Exception.Message)" -Type "ERROR"
        Write-Host " FAIL: Digital signature verification - Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# =============================================
# UPDATED PARSER FOR DRIVER FORMAT
# =============================================

function Parse-DownloadList {
    param([string]$DownloadListContent)

    Write-DebugMessage "Starting download list parsing."
    $downloadData = @{}
    
    try {
        $lines = $DownloadListContent -split "`n" | ForEach-Object { $_.Trim() }
        
        $currentType = $null
        $driverVer = $null
        $currentIndex = 0
        $currentHWIDs = @()
        $currentLink = $null
        $currentBackup = $null
        $currentSHA256 = $null

        foreach ($line in $lines) {
            if ($line -eq "Intel Wireless Wi-Fi") {
                $currentType = "WiFi"
                $currentIndex = 0
                continue
            } elseif ($line -eq "Intel Wireless Bluetooth") {
                $currentType = "Bluetooth"
                $currentIndex = 0
                continue
            }

            if ($line -match 'DriverVer\s*=\s*[^,]+,([0-9.]+)') {
                $driverVer = $matches[1]
                Write-DebugMessage "Found DriverVer: $driverVer for type: $currentType"
                continue
            }

            if ($line -match '^HWID_(\d+)_\d+\s*=\s*(.+)') {
                $index = [int]$matches[1]
                $hwid = $matches[2]
                
                if ($index -ne $currentIndex) {
                    # Save previous entry
                    if ($currentIndex -gt 0 -and $currentLink) {
                        $key = "$driverVer-$currentType-$currentIndex"
                        $downloadData[$key] = @{
                            Type = $currentType
                            DriverVer = $driverVer
                            Index = $currentIndex
                            HWIDs = $currentHWIDs
                            Link = $currentLink
                            Backup = $currentBackup
                            SHA256 = $currentSHA256
                        }
                        Write-DebugMessage "Added download entry: $key with $($currentHWIDs.Count) HWIDs"
                    }
                    
                    # Start new entry
                    $currentIndex = $index
                    $currentHWIDs = @()
                    $currentLink = $null
                    $currentBackup = $null
                    $currentSHA256 = $null
                }
                
                $currentHWIDs += $hwid
                Write-DebugMessage "Added HWID for index $currentIndex: $hwid"
            }
            elseif ($line -match '^Link_(\d+)\s*=\s*(.+)') {
                $index = [int]$matches[1]
                if ($index -eq $currentIndex) {
                    $currentLink = $matches[2]
                    Write-DebugMessage "Set Link for index $currentIndex: $currentLink"
                }
            }
            elseif ($line -match '^Backup_(\d+)\s*=\s*(.+)') {
                $index = [int]$matches[1]
                if ($index -eq $currentIndex) {
                    $currentBackup = $matches[2]
                    Write-DebugMessage "Set Backup for index $currentIndex: $currentBackup"
                }
            }
            elseif ($line -match '^SHA256_(\d+)\s*=\s*([A-F0-9]+)') {
                $index = [int]$matches[1]
                if ($index -eq $currentIndex) {
                    $currentSHA256 = $matches[2]
                    Write-DebugMessage "Set SHA256 for index $currentIndex: $currentSHA256"
                }
            }
        }

        # Save the last entry
        if ($currentIndex -gt 0 -and $currentLink) {
            $key = "$driverVer-$currentType-$currentIndex"
            $downloadData[$key] = @{
                Type = $currentType
                DriverVer = $driverVer
                Index = $currentIndex
                HWIDs = $currentHWIDs
                Link = $currentLink
                Backup = $currentBackup
                SHA256 = $currentSHA256
            }
            Write-DebugMessage "Added final download entry: $key with $($currentHWIDs.Count) HWIDs"
        }

        Write-DebugMessage "Download list parsing completed. Found $($downloadData.Count) entries."
        return $downloadData
    }
    catch {
        Write-Log "Download list parsing failed: $($_.Exception.Message)" -Type "ERROR"
        return @{}
    }
}

# =============================================
# ENHANCED DOWNLOAD FUNCTION FOR CAB FILES
# =============================================

function Download-Extract-Cab {
    param(
        [string]$Url, 
        [string]$OutputPath, 
        [string]$ExpectedHash,
        [string]$SourceName = "Primary"
    )

    try {
        $tempFile = "$tempDir\temp_$(Get-Random).cab"

        Write-DebugMessage "Downloading from $SourceName source: $Url to $tempFile"
        Write-Host " Downloading from $SourceName source..." -ForegroundColor Yellow
        
        $downloadSuccess = $true
        $downloadError = $null
        
        try {
            Invoke-WebRequest -Uri $Url -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
        } catch {
            $downloadSuccess = $false
            $downloadError = $_.Exception.Message
        }

        if (-not $downloadSuccess) {
            Write-Log "Download failed for $SourceName source $Url : $downloadError" -Type "ERROR"
            return @{ Success = $false; ErrorType = "DownloadFailed"; Message = "Download failed: $downloadError" }
        }

        if (-not (Test-Path $tempFile)) {
            return @{ Success = $false; ErrorType = "DownloadFailed"; Message = "File not found after download" }
        }

        # Verify digital signature first
        Write-Host " Verifying $SourceName source digital signature..." -ForegroundColor Yellow
        if (-not (Verify-FileSignature -FilePath $tempFile)) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            return @{ Success = $false; ErrorType = "SignatureInvalid"; Message = "Digital signature verification failed." }
        }

        if ($ExpectedHash) {
            Write-Host " Verifying $SourceName source file integrity..." -ForegroundColor Yellow
            $originalFileName = [System.IO.Path]::GetFileName($Url)
            if (-not (Verify-FileHash -FilePath $tempFile -ExpectedHash $ExpectedHash -HashType $SourceName -OriginalFileName $originalFileName)) {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                return @{ Success = $false; ErrorType = "HashMismatch"; Message = "Hash verification failed." }
            }
        }

        # Extract CAB file
        try {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
            $expandResult = & expand.exe $tempFile $OutputPath -F:* 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host " CAB file extracted successfully." -ForegroundColor Green
                Write-DebugMessage "CAB extraction successful to: $OutputPath"
            } else {
                Write-Log "CAB extraction failed with exit code: $LASTEXITCODE" -Type "ERROR"
                return @{ Success = $false; ErrorType = "ExtractionFailed"; Message = "CAB extraction failed: $expandResult" }
            }
        } catch {
            Write-Log "Error extracting CAB file: $_" -Type "ERROR"
            return @{ Success = $false; ErrorType = "ExtractionFailed"; Message = "CAB extraction failed: $_" }
        }

        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        Write-DebugMessage "Removed temporary file: $tempFile"
        return @{ Success = $true; ErrorType = "None"; Message = "Success" }
    }
    catch {
        Write-Log "Error in Download-Extract-Cab: $_" -Type "ERROR"
        return @{ Success = $false; ErrorType = "UnknownError"; Message = "Unexpected error: $_" }
    }
}

# =============================================
# HARDWARE DETECTION FUNCTIONS
# =============================================

function Get-IntelWirelessHWIDs {
    $intelWireless = @()
    $wifiCount = 0
    $btCount = 0

    try {
        # Detect Wi-Fi devices
        $wifiDevices = Get-PnpDevice -Class 'Net' -ErrorAction SilentlyContinue | 
                      Where-Object { 
                          $_.FriendlyName -like "*Intel*" -and 
                          ($_.FriendlyName -like "*Wi-Fi*" -or $_.FriendlyName -like "*Wireless*" -or $_.FriendlyName -like "*WLAN*") -and
                          $_.Status -eq 'OK'
                      }

        foreach ($device in $wifiDevices) {
            foreach ($hwid in $device.HardwareID) {
                if ($hwid -like '*PCI\VEN_8086*') {
                    $intelWireless += [PSCustomObject]@{
                        Type = "WiFi"
                        HWID = $hwid
                        Description = $device.FriendlyName
                        HardwareID = $hwid
                        InstanceId = $device.InstanceId
                    }
                    $wifiCount++
                    break
                }
            }
        }

        # Detect Bluetooth devices
        $btDevices = Get-PnpDevice -Class 'Bluetooth' -ErrorAction SilentlyContinue | 
                    Where-Object { 
                        $_.FriendlyName -like "*Intel*" -and $_.Status -eq 'OK'
                    }

        foreach ($device in $btDevices) {
            foreach ($hwid in $device.HardwareID) {
                if ($hwid -like '*USB\VID_8087*' -or $hwid -like '*PCI\VEN_8086*') {
                    $intelWireless += [PSCustomObject]@{
                        Type = "Bluetooth"
                        HWID = $hwid
                        Description = $device.FriendlyName
                        HardwareID = $hwid
                        InstanceId = $device.InstanceId
                    }
                    $btCount++
                    break
                }
            }
        }

        Write-DebugMessage "Scanning completed: found $wifiCount Wi-Fi devices and $btCount Bluetooth devices"
        return $intelWireless
    }
    catch {
        Write-Log "Wireless hardware detection failed: $($_.Exception.Message)" -Type "ERROR"
        return @()
    }
}

function Get-CurrentDriverVersion {
    param([string]$DeviceInstanceId)

    try {
        $device = Get-PnpDevice | Where-Object {$_.InstanceId -eq $DeviceInstanceId}
        if ($device) {
            $versionProperty = $device | Get-PnpDeviceProperty -KeyName "DEVPKEY_Device_DriverVersion" -ErrorAction SilentlyContinue
            if ($versionProperty -and $versionProperty.Data) {
                Write-DebugMessage "Got version from DEVPKEY_Device_DriverVersion: $($versionProperty.Data)"
                return $versionProperty.Data
            }
        }

        $driverInfo = Get-CimInstance -ClassName Win32_PnPSignedDriver | Where-Object { 
            $_.DeviceID -eq $DeviceInstanceId -and $_.DriverVersion
        } | Select-Object -First 1

        if ($driverInfo) {
            Write-DebugMessage "Got version from WMI: $($driverInfo.DriverVersion)"
            return $driverInfo.DriverVersion
        }

        Write-DebugMessage "Could not determine version for device: $DeviceInstanceId"
        return $null
    }
    catch {
        Write-DebugMessage "Error getting driver version: $_"
        return $null
    }
}

# =============================================
# TEMP DIRECTORY CLEANUP FUNCTION
# =============================================

function Clear-TempDriverFolders {
    try {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-DebugMessage "Cleaned up temporary directory: $tempDir"
        }
    }
    catch {
        Write-DebugMessage "Error during cleanup: $_"
    }
}

# =============================================
# DATA DOWNLOAD AND PARSING FUNCTIONS
# =============================================

function Get-LatestDriverInfo {
    param([string]$Url)

    try {
        $cacheBuster = "t=" + (Get-Date -Format 'yyyyMMddHHmmss')
        if ($Url.Contains('?')) {
            $finalUrl = $Url + "&" + $cacheBuster
        } else {
            $finalUrl = $Url + "?" + $cacheBuster
        }
        
        Write-DebugMessage "Downloading from: $finalUrl (with cache-buster)"
        $content = Invoke-WebRequest -Uri $finalUrl -UseBasicParsing -ErrorAction Stop
        Write-DebugMessage "Successfully downloaded content from $finalUrl"
        return $content.Content
    }
    catch {
        Write-Log "Error downloading from GitHub: $($_.Exception.Message)" -Type "ERROR"
        return $null
    }
}

# =============================================
# DRIVER INSTALLATION FUNCTIONS
# =============================================

function Get-RecommendedInfFile {
    param([string]$DriverPath)
    
    $infFiles = Get-ChildItem -Path $DriverPath -Filter "Netwtw*.inf" | Sort-Object Name
    
    if ($infFiles.Count -eq 0) {
        return $null
    }
    
    # Find Intel Wireless devices and check for newer adapters
    $wirelessDevices = Get-PnpDevice | Where-Object {
        $_.Class -eq "Net" -and 
        $_.FriendlyName -like "*Intel*" -and 
        ($_.FriendlyName -like "*Wi-Fi*" -or $_.FriendlyName -like "*Wireless*" -or $_.FriendlyName -like "*WLAN*") -and
        $_.Status -eq "OK"
    }
    
    # Check for Wi-Fi 6E/7 adapters
    foreach ($device in $wirelessDevices) {
        $deviceName = $device.FriendlyName
        if ($deviceName -like "*AX21*" -or $deviceName -like "*BE200*" -or $deviceName -like "*Wi-Fi 6E*" -or $deviceName -like "*Wi-Fi 7*") {
            # Prefer Netwtw6e.inf for newer adapters
            $recommendedInf = $infFiles | Where-Object { $_.Name -like "*6e*" } | Select-Object -First 1
            if ($recommendedInf) {
                return $recommendedInf.FullName
            }
        }
    }
    
    # Fallback to Netwtw08.inf for older adapters
    $fallbackInf = $infFiles | Where-Object { $_.Name -like "*08*" } | Select-Object -First 1
    if ($fallbackInf) {
        return $fallbackInf.FullName
    }
    
    # If no specific INF found, use the first available
    if ($infFiles.Count -gt 0) {
        return $infFiles[0].FullName
    }
    
    return $null
}

function Get-BluetoothCabForDevice {
    param([string]$DeviceInstanceId, [array]$DownloadData, [string]$DriverVer)

    $matchingEntries = @()
    
    foreach ($key in $downloadData.Keys) {
        $entry = $downloadData[$key]
        if ($entry.Type -eq "Bluetooth" -and $entry.DriverVer -eq $DriverVer) {
            foreach ($hwid in $entry.HWIDs) {
                # Clean the hardware ID for matching
                $cleanHwId = $hwid.Trim()
                
                # Multiple matching strategies
                $matchFound = $false
                
                # Strategy 1: Exact substring match
                if ($DeviceInstanceId -like "*$cleanHwId*") {
                    $matchFound = $true
                }
                
                # Strategy 2: Match by VID&PID only (more flexible)
                if (-not $matchFound) {
                    $deviceVidPid = $null
                    $hwIdVidPid = $null
                    
                    # Extract VID&PID from device instance ID
                    if ($DeviceInstanceId -match 'VID_[0-9A-F]{4}&PID_[0-9A-F]{4}') {
                        $deviceVidPid = $Matches[0]
                    }
                    
                    # Extract VID&PID from hardware ID
                    if ($cleanHwId -match 'VID_[0-9A-F]{4}&PID_[0-9A-F]{4}') {
                        $hwIdVidPid = $Matches[0]
                    }
                    
                    if ($deviceVidPid -and $hwIdVidPid -and $deviceVidPid -eq $hwIdVidPid) {
                        $matchFound = $true
                    }
                }
                
                if ($matchFound) {
                    $matchingEntries += $entry
                    break
                }
            }
        }
    }
    
    return $matchingEntries
}

# METHOD: Aggressive disable/enable + pnputil
function Force-ReinstallDriver {
    param(
        [string]$DeviceInstanceId,
        [string]$InfFilePath,
        [string]$DeviceType
    )
    
    try {
        Write-Host "Forcing driver reinstallation for $DeviceType..." -ForegroundColor Yellow
        
        # Get the device
        $device = Get-PnpDevice -InstanceId $DeviceInstanceId -ErrorAction SilentlyContinue
        if (-not $device) {
            Write-Host "Device not found: $DeviceInstanceId" -ForegroundColor Red
            return $false
        }
        
        Write-Host "Step 1: Disabling device..." -ForegroundColor Gray
        $device | Disable-PnpDevice -Confirm:$false 2>&1 | Out-Null
        Start-Sleep -Seconds 3
        
        Write-Host "Step 2: Installing driver from INF..." -ForegroundColor Gray
        pnputil /add-driver "$InfFilePath" /install 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        
        Write-Host "Step 3: Enabling device..." -ForegroundColor Gray
        $device | Enable-PnpDevice -Confirm:$false 2>&1 | Out-Null
        Start-Sleep -Seconds 3
        
        Write-Host "Step 4: Updating device with new driver..." -ForegroundColor Gray
        pnputil /update-device "$DeviceInstanceId" /install 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        
        Write-Host "Force reinstall completed for $DeviceType" -ForegroundColor Green
        return $true
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Force reinstall failed for $DeviceType`: $errorMessage" -ForegroundColor Red
        return $false
    }
}

function Install-WiFiDriver {
    param([string]$DriverPath)

    try {
        $infFile = Get-RecommendedInfFile -DriverPath $DriverPath
        if (-not $infFile) {
            Write-Log "Could not find appropriate INF file for Wi-Fi driver" -Type "ERROR"
            return $false
        }

        Write-Host " Selected Wi-Fi driver: $(Split-Path $infFile -Leaf)" -ForegroundColor Cyan
        
        # Get all Wi-Fi devices
        $wifiDevices = Get-PnpDevice | Where-Object {
            $_.Class -eq "Net" -and 
            $_.FriendlyName -like "*Intel*" -and 
            ($_.FriendlyName -like "*Wi-Fi*" -or $_.FriendlyName -like "*Wireless*" -or $_.FriendlyName -like "*WLAN*") -and
            $_.Status -eq "OK"
        }

        $successCount = 0
        foreach ($device in $wifiDevices) {
            if (Force-ReinstallDriver -DeviceInstanceId $device.InstanceId -InfFilePath $infFile -DeviceType "Wi-Fi") {
                $successCount++
            }
        }

        return $successCount -gt 0
    }
    catch {
        Write-Log "Error installing Wi-Fi driver: $_" -Type "ERROR"
        return $false
    }
}

function Install-BluetoothDriver {
    param([string]$DriverPath)

    try {
        $infFiles = Get-ChildItem -Path $DriverPath -Filter "*.inf" -Recurse
        if ($infFiles.Count -eq 0) {
            Write-Log "No INF files found in Bluetooth driver package" -Type "ERROR"
            return $false
        }

        # Get all Bluetooth devices
        $btDevices = Get-PnpDevice -Class 'Bluetooth' -ErrorAction SilentlyContinue | 
                    Where-Object { 
                        $_.FriendlyName -like "*Intel*" -and $_.Status -eq 'OK'
                    }

        $successCount = 0
        foreach ($device in $btDevices) {
            foreach ($infFile in $infFiles) {
                if (Force-ReinstallDriver -DeviceInstanceId $device.InstanceId -InfFilePath $infFile.FullName -DeviceType "Bluetooth") {
                    $successCount++
                    break
                }
            }
        }

        return $successCount -gt 0
    }
    catch {
        Write-Log "Error installing Bluetooth driver: $_" -Type "ERROR"
        return $false
    }
}

# =============================================
# CUSTOM PAUSE FUNCTION WITH SPACES
# =============================================

function Invoke-PauseSpaced {
    Write-Host " Press any key to continue..." -NoNewline
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Write-Host ""
}

# =============================================
# SUPPORT MESSAGE FUNCTION
# =============================================

function Show-SupportMessage {
    Write-Host ""
    Write-Host " SUPPORT THIS PROJECT" -ForegroundColor Magenta
    Write-Host " ====================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host " This project is maintained in my free time."
    Write-Host " Your support ensures regular updates and compatibility."
    Write-Host ""
    Write-Host " Support options:"
    Write-Host ""
    Write-Host " - PayPal Donation: tinyurl.com/fet-paypal" -ForegroundColor Yellow
    Write-Host " - Buy Me a Coffee: tinyurl.com/fet-coffee" -ForegroundColor Yellow
    Write-Host " - GitHub Sponsors: tinyurl.com/fet-github" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " If this project helped you, please consider:"
    Write-Host ""
    Write-Host " - Giving it a STAR on GitHub"
    Write-Host " - Sharing with friends and colleagues"
    Write-Host " - Reporting issues or suggesting features"
    Write-Host " - Supporting development financially"
    Write-Host ""
    Write-Host " Thank you for using Universal Intel Wi-Fi and BT Driver Updater!"
}

# =============================================
# FINAL CREDITS FUNCTION
# =============================================

function Show-FinalCredits {
    Clear-Host
    Write-Host "/*************************************************************************" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "            UNIVERSAL INTEL WI-FI AND BLUETOOTH DRIVERS UPDATER          " -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "** --------------------------------------------------------------------- **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "                   Drivers Version: 24.0 (2025.11.1)                   " -NoNewline -ForegroundColor Yellow -BackgroundColor DarkBlue
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
    Write-Host "         Drivers are sourced from official Microsoft servers.          " -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "         Use at your own risk.                                         " -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "** --------------------------------------------------------------------- **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**" -NoNewline -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "         GitHub: FirstEverTech/Universal-Intel-WiFi-BT-Updater         " -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "**" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "**                                                                       **" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host "*************************************************************************/" -ForegroundColor Gray -BackgroundColor DarkBlue
    Write-Host ""
    
    Write-Host " THANK YOU FOR USING UNIVERSAL INTEL WI-FI AND BT DRIVER UPDATER" -ForegroundColor Cyan
    Write-Host " ===============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " We hope this tool has been helpful in updating your system." -ForegroundColor Yellow
    Write-Host ""
    
    # Display support message
    Show-SupportMessage
    
    Write-Host ""
    Write-Host " This tool will close automatically in 10 seconds..." -ForegroundColor Green
    Start-Sleep -Seconds 10
}

# =============================================
# CLEANUP FUNCTION
# =============================================

function Cleanup {
    Write-Host "`n Cleaning up temporary files..." -ForegroundColor Yellow
    if (Test-Path $tempDir) {
        try {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction Stop
            Write-Host " Temporary files cleaned successfully." -ForegroundColor Green
        }
        catch {
            Write-Host " Warning: Could not clean all temporary files." -ForegroundColor Yellow
        }
    }
}

# =============================================
# MAIN SCRIPT EXECUTION
# =============================================

try {
    # SCREEN 1: Initialization and Security Checks
    Show-Screen1
    
    # Run self-hash verification (can be skipped with configuration)
    if (-not (Verify-ScriptHash)) {
        Write-Host "`n Update process aborted for security reasons." -ForegroundColor Red
        Cleanup
        Write-Host "`n Press any key..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Show-FinalCredits
        exit 1
    }

    # Check for updater updates
    $updateCheckResult = Check-ForUpdaterUpdates
    if (-not $updateCheckResult) {
        Write-Host "`n Update process cancelled or failed." -ForegroundColor Yellow
        Cleanup
        Write-Host "`n Press any key..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Show-FinalCredits
        exit 1
    }

    Write-Host " Scanning for Intel Wireless devices..." -ForegroundColor Green
    Write-Host ""

    # Create temporary directory
    Clear-TempDriverFolders
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-DebugMessage "Created temporary directory: $tempDir"

    # SCREEN 2: Hardware Detection and Version Analysis
    Show-Screen2

    # Detect Intel Wireless devices
    $detectedWirelessDevices = Get-IntelWirelessHWIDs

    if ($detectedWirelessDevices.Count -eq 0) {
        Write-Host " No Intel Wireless devices found." -ForegroundColor Yellow
        Write-Host " If you have Intel Wi-Fi or Bluetooth, make sure devices are enabled and working." -ForegroundColor Yellow
        Cleanup
        Write-Host "`n Press any key..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Show-FinalCredits
        exit
    }

    Write-Host " Found $($detectedWirelessDevices.Count) Intel Wireless device(s)" -ForegroundColor Green

    # Debug information
    if ($DebugMode -eq 1) {
        Write-Host "`n === DEBUG INFORMATION ===" -ForegroundColor Cyan
        Write-Host " Checking versions for detected devices:" -ForegroundColor Gray
        foreach ($device in $detectedWirelessDevices) {
            $currentVersion = Get-CurrentDriverVersion -DeviceInstanceId $device.InstanceId
            Write-Host " Device: $($device.Description)" -ForegroundColor Gray
            Write-Host "   Type: $($device.Type) | Version: $currentVersion" -ForegroundColor Gray
        }
        Write-Host " === END DEBUG ===`n" -ForegroundColor Cyan
    }

    # Download latest driver information
    Write-Host " Downloading latest driver information..." -ForegroundColor Green
    $wifiInfo = Get-LatestDriverInfo -Url $wifiDriversUrl
    $bluetoothInfo = Get-LatestDriverInfo -Url $bluetoothDriversUrl

    if (-not $wifiInfo -or -not $bluetoothInfo) {
        Write-Host " Failed to download driver information. Exiting." -ForegroundColor Red
        Cleanup
        Write-Host "`n Press any key..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Show-FinalCredits
        exit
    }

    # Parse driver information
    Write-Host " Parsing driver information..." -ForegroundColor Green
    $downloadData = Parse-DownloadList -DownloadListContent $wifiInfo
    $btDownloadData = Parse-DownloadList -DownloadListContent $bluetoothInfo

    # Merge both download data
    foreach ($key in $btDownloadData.Keys) {
        $downloadData[$key] = $btDownloadData[$key]
    }

    if ($downloadData.Count -eq 0) {
        Write-Host " Error: Could not parse driver information." -ForegroundColor Red
        Write-Host " Please check the format of driver download files." -ForegroundColor Yellow
        Cleanup
        Write-Host "`n Press any key..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        Show-FinalCredits
        exit
    }

    # Extract latest versions
    $latestWiFiVersion = $null
    $latestBluetoothVersion = $null

    foreach ($key in $downloadData.Keys) {
        $entry = $downloadData[$key]
        if ($entry.Type -eq "WiFi" -and (-not $latestWiFiVersion -or $entry.DriverVer -gt $latestWiFiVersion)) {
            $latestWiFiVersion = $entry.DriverVer
        }
        if ($entry.Type -eq "Bluetooth" -and (-not $latestBluetoothVersion -or $entry.DriverVer -gt $latestBluetoothVersion)) {
            $latestBluetoothVersion = $entry.DriverVer
        }
    }

    Write-Host " Latest Wi-Fi Driver: $latestWiFiVersion" -ForegroundColor Yellow
    Write-Host " Latest Bluetooth Driver: $latestBluetoothVersion" -ForegroundColor Yellow
    Write-Host ""

    # Group devices by type and check for updates
    $wifiDevices = $detectedWirelessDevices | Where-Object { $_.Type -eq "WiFi" }
    $bluetoothDevices = $detectedWirelessDevices | Where-Object { $_.Type -eq "Bluetooth" }

    $wifiUpdateAvailable = $false
    $bluetoothUpdateAvailable = $false

    Write-Host " === Device Information ===" -ForegroundColor Cyan

    # Wi-Fi devices
    if ($wifiDevices.Count -gt 0) {
        Write-Host "`n Wi-Fi Devices:" -ForegroundColor White
        foreach ($device in $wifiDevices) {
            $currentVersion = Get-CurrentDriverVersion -DeviceInstanceId $device.InstanceId
            
            Write-Host " Device: $($device.Description)" -ForegroundColor Gray
            Write-Host " Instance ID: $($device.InstanceId)" -ForegroundColor Gray
            
            if ($currentVersion) {
                Write-Host " Current Version: $currentVersion" -ForegroundColor Gray
                if ($currentVersion -eq $latestWiFiVersion) {
                    Write-Host " Status: Already on latest version" -ForegroundColor Green
                } else {
                    Write-Host " Status: Update available! ($currentVersion -> $latestWiFiVersion)" -ForegroundColor Yellow
                    $wifiUpdateAvailable = $true
                }
            } else {
                Write-Host " Current Version: Unable to determine" -ForegroundColor Gray
                Write-Host " Status: Will attempt to install driver" -ForegroundColor Yellow
                $wifiUpdateAvailable = $true
            }
            Write-Host ""
        }
    }

    # Bluetooth devices
    if ($bluetoothDevices.Count -gt 0) {
        Write-Host " Bluetooth Devices:" -ForegroundColor White
        foreach ($device in $bluetoothDevices) {
            $currentVersion = Get-CurrentDriverVersion -DeviceInstanceId $device.InstanceId
            
            Write-Host " Device: $($device.Description)" -ForegroundColor Gray
            Write-Host " Instance ID: $($device.InstanceId)" -ForegroundColor Gray
            
            if ($currentVersion) {
                Write-Host " Current Version: $currentVersion" -ForegroundColor Gray
                if ($currentVersion -eq $latestBluetoothVersion) {
                    Write-Host " Status: Already on latest version" -ForegroundColor Green
                } else {
                    Write-Host " Status: Update available! ($currentVersion -> $latestBluetoothVersion)" -ForegroundColor Yellow
                    $bluetoothUpdateAvailable = $true
                }
            } else {
                Write-Host " Current Version: Unable to determine" -ForegroundColor Gray
                Write-Host " Status: Will attempt to install driver" -ForegroundColor Yellow
                $bluetoothUpdateAvailable = $true
            }
            Write-Host ""
        }
    }

    # If all devices are up to date, ask if user wants to reinstall anyway
    if ((-not $wifiUpdateAvailable -and -not $bluetoothUpdateAvailable) -and ($wifiDevices.Count -gt 0 -or $bluetoothDevices.Count -gt 0)) {
        Write-Host " All devices are up to date." -ForegroundColor Green
        $response = Read-Host " Do you want to force reinstall the driver(s) anyway? (Y/N)"
        if ($response -eq "Y" -or $response -eq "y") {
            $wifiUpdateAvailable = $true
            $bluetoothUpdateAvailable = $true
            Write-Host " Force reinstall enabled for all devices." -ForegroundColor Yellow
        } else {
            Write-Host "`n Installation cancelled." -ForegroundColor Yellow
            Cleanup
            Write-Host "`n Press any key..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            Show-FinalCredits
            exit
        }
    }

    # SCREEN 3: Update Confirmation and System Preparation
    Show-Screen3

    if ($wifiUpdateAvailable -or $bluetoothUpdateAvailable) {
        Write-Host " IMPORTANT NOTICE:" -ForegroundColor Yellow
        Write-Host " The driver update process may take several minutes to complete." -ForegroundColor Yellow
        Write-Host " During installation, Wi-Fi and Bluetooth will be temporarily disconnected." -ForegroundColor Yellow
        Write-Host " This is normal behavior and connectivity will be restored once the" -ForegroundColor Yellow
        Write-Host " installation is complete. Do not interrupt the process." -ForegroundColor Yellow
        Write-Host ""
        $response = Read-Host " Do you want to proceed with driver update? (Y/N)"
    } else {
        $response = "N"
    }

    if ($response -eq "Y" -or $response -eq "y") {
        Write-Host "`n Starting driver update process..." -ForegroundColor Green

        # CREATE SYSTEM RESTORE POINT
        Write-Host " Creating system restore point..." -ForegroundColor Yellow
        try {
            $restorePointDescription = "Before Intel Wi-Fi/BT Driver Update - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            
            try {
                $null = Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
            } catch {
                Write-DebugMessage "System restore might already be enabled or not available: $($_.Exception.Message)"
            }
            
            Checkpoint-Computer -Description $restorePointDescription -RestorePointType "MODIFY_SETTINGS"
            Write-Host " System restore point created successfully: " -ForegroundColor Green
            Write-Host " '$restorePointDescription'" -ForegroundColor Green
            Write-DebugMessage "System restore point created: $restorePointDescription"
            
            # 5 seconds delay after success
            Write-Host "`n Preparing for installation..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
        catch {
            Write-Log "Failed to create system restore point: $($_.Exception.Message)" -Type "ERROR"
            Write-Host " WARNING: Could not create system restore point. Continuing anyway..." -ForegroundColor Yellow
            Write-Host " If the update causes issues, you may not be able to easily revert the changes." -ForegroundColor Yellow
            
            # 5 seconds delay after error
            Write-Host "`n Preparing for installation..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }

        # SCREEN 4: Download and Installation Progress
        Show-Screen4

        $successCount = 0

        # Download and install Wi-Fi drivers if needed
        if ($wifiUpdateAvailable) {
            Write-Host " Processing Wi-Fi drivers..." -ForegroundColor Cyan
            
            # Find Wi-Fi download entry
            $wifiEntry = $null
            foreach ($key in $downloadData.Keys) {
                $entry = $downloadData[$key]
                if ($entry.Type -eq "WiFi" -and $entry.DriverVer -eq $latestWiFiVersion) {
                    $wifiEntry = $entry
                    break
                }
            }

            if ($wifiEntry) {
                $driverPath = "$tempDir\WiFi"
                
                Write-Host " Downloading Wi-Fi driver version $($wifiEntry.DriverVer)..." -ForegroundColor Yellow
                $primaryResult = Download-Extract-Cab -Url $wifiEntry.Link -OutputPath $driverPath -ExpectedHash $wifiEntry.SHA256 -SourceName "Primary"

                if (-not $primaryResult.Success -and $primaryResult.ErrorType -eq "DownloadFailed" -and $wifiEntry.Backup) {
                    Write-Host " Primary source failed, trying backup..." -ForegroundColor Yellow
                    $primaryResult = Download-Extract-Cab -Url $wifiEntry.Backup -OutputPath $driverPath -ExpectedHash $wifiEntry.SHA256 -SourceName "Backup"
                }

                if ($primaryResult.Success) {
                    Write-Host " Installing Wi-Fi driver..." -ForegroundColor Yellow
                    if (Install-WiFiDriver -DriverPath $driverPath) {
                        $successCount++
                        Write-Host " Wi-Fi driver installed successfully." -ForegroundColor Green
                    } else {
                        Write-Host " Failed to install Wi-Fi driver." -ForegroundColor Red
                    }
                } else {
                    Write-Host " Failed to download Wi-Fi driver." -ForegroundColor Red
                }
            } else {
                Write-Host " Error: Could not find download information for Wi-Fi driver." -ForegroundColor Red
            }
        }

        # Download and install Bluetooth drivers if needed
        if ($bluetoothUpdateAvailable) {
            Write-Host "`n Processing Bluetooth drivers..." -ForegroundColor Cyan
            
            # Find appropriate Bluetooth entries for detected devices
            $btEntriesToDownload = @()
            foreach ($device in $bluetoothDevices) {
                $matchingEntries = Get-BluetoothCabForDevice -DeviceInstanceId $device.InstanceId -DownloadData $downloadData -DriverVer $latestBluetoothVersion
                foreach ($entry in $matchingEntries) {
                    if ($btEntriesToDownload -notcontains $entry) {
                        $btEntriesToDownload += $entry
                    }
                }
            }

            if ($btEntriesToDownload.Count -gt 0) {
                $btSuccessCount = 0
                foreach ($btEntry in $btEntriesToDownload) {
                    $driverPath = "$tempDir\Bluetooth_$($btEntry.Index)"
                    
                    Write-Host " Downloading Bluetooth driver package $($btEntry.Index)..." -ForegroundColor Yellow
                    $primaryResult = Download-Extract-Cab -Url $btEntry.Link -OutputPath $driverPath -ExpectedHash $btEntry.SHA256 -SourceName "Primary"

                    if (-not $primaryResult.Success -and $primaryResult.ErrorType -eq "DownloadFailed" -and $btEntry.Backup) {
                        Write-Host " Primary source failed, trying backup..." -ForegroundColor Yellow
                        $primaryResult = Download-Extract-Cab -Url $btEntry.Backup -OutputPath $driverPath -ExpectedHash $btEntry.SHA256 -SourceName "Backup"
                    }

                    if ($primaryResult.Success) {
                        Write-Host " Installing Bluetooth driver package $($btEntry.Index)..." -ForegroundColor Yellow
                        if (Install-BluetoothDriver -DriverPath $driverPath) {
                            $btSuccessCount++
                        } else {
                            Write-Host " Failed to install Bluetooth driver package $($btEntry.Index)." -ForegroundColor Red
                        }
                    } else {
                        Write-Host " Failed to download Bluetooth driver package $($btEntry.Index)." -ForegroundColor Red
                    }
                }

                if ($btSuccessCount -gt 0) {
                    $successCount++
                    Write-Host " Bluetooth driver installation completed ($btSuccessCount package(s) installed)." -ForegroundColor Green
                }
            } else {
                Write-Host " Error: Could not find appropriate Bluetooth driver for your devices." -ForegroundColor Red
            }
        }

        if ($successCount -gt 0) {
            Write-Host "`n IMPORTANT NOTICE:" -ForegroundColor Yellow
            Write-Host " Driver installation completed successfully!" -ForegroundColor Green
            Write-Host " You may need to restart your computer for all changes to take effect." -ForegroundColor Yellow
            
            Write-Host "`n Summary: Successfully processed $successCount driver type(s)." -ForegroundColor Green
            Write-DebugMessage "Installation summary: $successCount successful driver types."
        } else {
            Write-Host "`n No drivers were successfully installed." -ForegroundColor Red
            Write-DebugMessage "No drivers were successfully installed."
        }
    } else {
        Write-Host "`n Update cancelled." -ForegroundColor Yellow
        Write-DebugMessage "User cancelled the update."
    }

    # Clean up
    Cleanup

    # Show final summary
    Show-FinalSummary

    Write-Host "`n Driver update process completed." -ForegroundColor Cyan
    Write-Host " If you have any issues with this tool, please report them at:"
    Write-Host " https://github.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater" -ForegroundColor Cyan

    if ($DebugMode -eq 1) {
        Write-Host "`n [DEBUG MODE ENABLED - All debug messages were shown]" -ForegroundColor Magenta
    }

    Write-Host "`n Press any key..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

    # Show final credits
    Show-FinalCredits
    exit 0
}
catch {
    Write-Log "Unhandled error in main execution: $($_.Exception.Message)" -Type "ERROR"
    Write-Host " An unexpected error occurred. Please check the log file at $logFile for details." -ForegroundColor Red
    Cleanup
    Write-Host "`n Press any key..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Show-FinalCredits
    exit 1
}
