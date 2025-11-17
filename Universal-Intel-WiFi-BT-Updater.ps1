# Intel Wireless & Bluetooth Drivers Update Script
# Downloads latest drivers from GitHub and updates if newer versions available
# By Marcin Grygiel / www.firstever.tech

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
    exit
}

# GitHub repository URLs
$githubBaseUrl = "https://raw.githubusercontent.com/FirstEver-eu/Intel-WiFi-BT-Updater/main/"
$wifiDriversUrl = $githubBaseUrl + "Intel_WiFi_Drivers_Download.txt"
$bluetoothDriversUrl = $githubBaseUrl + "Intel_BT_Drivers_Download.txt"

# Temporary directory for downloads
$tempDir = "C:\Windows\Temp\IntelDrivers"

# Supported Intel Wi-Fi Hardware IDs
$supportedWiFiHWIDs = @(
    # Wi-Fi 7 (BE) devices
    "PCI\VEN_8086&DEV_272B", "PCI\VEN_8086&DEV_7740", "PCI\VEN_8086&DEV_A840", "PCI\VEN_8086&DEV_E340", "PCI\VEN_8086&DEV_E440",
    
    # Wi-Fi 6E (AX_6G) devices
    "PCI\VEN_8086&DEV_2725", "PCI\VEN_8086&DEV_51F0", "PCI\VEN_8086&DEV_51F1", "PCI\VEN_8086&DEV_54F0", 
    "PCI\VEN_8086&DEV_7A70", "PCI\VEN_8086&DEV_7AF0", "PCI\VEN_8086&DEV_7E40", "PCI\VEN_8086&DEV_7F70",
    
    # Wi-Fi 6 (AX) devices
    "PCI\VEN_8086&DEV_2723", "PCI\VEN_8086&DEV_02F0", "PCI\VEN_8086&DEV_06F0", "PCI\VEN_8086&DEV_34F0",
    "PCI\VEN_8086&DEV_3DF0", "PCI\VEN_8086&DEV_43F0", "PCI\VEN_8086&DEV_4DF0", "PCI\VEN_8086&DEV_A0F0",
    
    # Wi-Fi 5 (AC) devices
    "PCI\VEN_8086&DEV_2526", "PCI\VEN_8086&DEV_30DC", "PCI\VEN_8086&DEV_31DC", "PCI\VEN_8086&DEV_9DF0",
    "PCI\VEN_8086&DEV_A370"
)

# Function to get current driver version for a device
function Get-CurrentDriverVersion {
    param([string]$DeviceInstanceId)
    
    try {
        $device = Get-PnpDevice | Where-Object {$_.InstanceId -eq $deviceInstanceId}
        if ($device) {
            $versionProperty = $device | Get-PnpDeviceProperty -KeyName "DEVPKEY_Device_DriverVersion" -ErrorAction SilentlyContinue
            if ($versionProperty -and $versionProperty.Data) {
                return $versionProperty.Data
            }
        }
    } catch {
        # Fallback to WMI if the above fails
        try {
            $driverInfo = Get-CimInstance -ClassName Win32_PnPSignedDriver | Where-Object { 
                $_.DeviceID -eq $deviceInstanceId -and $_.DriverVersion
            } | Select-Object -First 1
            
            if ($driverInfo) {
                return $driverInfo.DriverVersion
            }
        } catch {
            # Ignore errors
        }
    }
    return $null
}

# Function to clean up temporary driver folders
function Clear-TempDriverFolders {
    try {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {
        # Ignore cleanup errors
    }
}

# Function to download and parse driver information from GitHub
function Get-LatestDriverInfo {
    param([string]$Url)
    
    try {
        $content = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction Stop
        return $content.Content
    } catch {
        Write-Host "Error downloading driver information from GitHub." -ForegroundColor Red
        Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
        return $null
    }
}

# Function to extract CAB URL and version from driver info
function Parse-DriverInfo {
    param([string]$DriverInfo, [string]$Type)
    
    $lines = $DriverInfo -split "`n" | ForEach-Object { $_.Trim() }
    $version = $null
    
    if ($Type -eq "WiFi") {
        $cabUrl = $null
        # For WiFi - simple parsing (one CAB)
        foreach ($line in $lines) {
            if ($line -match 'DriverVer\s*=\s*[^,]+,\s*([0-9.]+)') {
                $version = $matches[1]
            } elseif ($line -match '^http://' -and -not $cabUrl) {
                $cabUrl = $line
            }
        }
        return @{
            Version = $version
            CabUrl = $cabUrl
        }
    } elseif ($Type -eq "Bluetooth") {
        $cabData = @()
        $currentHwIds = @()
        
        # Skip the first line "Intel Wireless Bluetooth"
        $skipNextLine = $true
        
        foreach ($line in $lines) {
            # Skip the header line
            if ($skipNextLine) {
                $skipNextLine = $false
                continue
            }
            
            if ($line -match 'DriverVer\s*=\s*[^,]+,\s*([0-9.]+)') {
                $version = $matches[1]
            } elseif ($line -match '^http://') {
                # This is a CAB URL - save the current block
                if ($currentHwIds.Count -gt 0) {
                    $cabData += @{
                        HardwareIds = $currentHwIds
                        CabUrl = $line
                    }
                    $currentHwIds = @()
                }
            } elseif ($line -match '^(USB|PCI|ACPI)\\' -and $line -notmatch '^Intel Wireless Bluetooth') {
                # This is a hardware ID - add to current block
                $currentHwIds += $line
            }
        }
        
        return @{
            Version = $version
            CabData = $cabData
        }
    }
}

# Function to download and extract CAB file
function Download-Extract-Cab {
    param([string]$CabUrl, [string]$OutputPath)
    
    try {
        $tempCab = "$tempDir\temp_$(Get-Random).cab"
        
        # Download CAB file
        Invoke-WebRequest -Uri $CabUrl -OutFile $tempCab -UseBasicParsing
        
        # Extract CAB file
        if (Test-Path $tempCab) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
            $expandResult = & expand.exe $tempCab $OutputPath -F:* 2>&1
            Remove-Item $tempCab -Force -ErrorAction SilentlyContinue
            
            return $LASTEXITCODE -eq 0
        }
    } catch {
        Write-Host "Error downloading or extracting driver package." -ForegroundColor Red
    }
    return $false
}

# Function to detect WiFi adapter type and select appropriate INF
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
    
    # Check for WiFi 6E/7 adapters
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

# Function to get appropriate CAB for Bluetooth device
function Get-BluetoothCabForDevice {
    param([string]$DeviceInstanceId, [array]$BluetoothCabData)
    
    foreach ($cabItem in $BluetoothCabData) {
        foreach ($hwId in $cabItem.HardwareIds) {
            # Clean the hardware ID for matching
            $cleanHwId = $hwId.Trim()
            
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
                return $cabItem.CabUrl
            }
        }
    }
    
    # If no specific match found, return the first CAB as fallback
    if ($BluetoothCabData.Count -gt 0) {
        return $BluetoothCabData[0].CabUrl
    }
    
    return $null
}

Write-Host "=== Intel Wireless and Bluetooth Drivers Update ===" -ForegroundColor Cyan
Write-Host "Downloading latest driver information..." -ForegroundColor Green

# Create temporary directory
Clear-TempDriverFolders
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Download latest driver information
$wifiInfo = Get-LatestDriverInfo -Url $wifiDriversUrl
$bluetoothInfo = Get-LatestDriverInfo -Url $bluetoothDriversUrl

if (-not $wifiInfo -or -not $bluetoothInfo) {
    Write-Host "Failed to download driver information. Exiting." -ForegroundColor Red
    Clear-TempDriverFolders
    exit
}

# Parse driver information
Write-Host "Parsing driver information..." -ForegroundColor Green
$wifiData = Parse-DriverInfo -DriverInfo $wifiInfo -Type "WiFi"
$bluetoothData = Parse-DriverInfo -DriverInfo $bluetoothInfo -Type "Bluetooth"

if (-not $wifiData.Version -or -not $bluetoothData.Version) {
    Write-Host "Error: Could not parse driver version information." -ForegroundColor Red
    Clear-TempDriverFolders
    exit
}

Write-Host "Latest WiFi Driver: $($wifiData.Version)" -ForegroundColor Yellow
Write-Host "Latest Bluetooth Driver: $($bluetoothData.Version)" -ForegroundColor Yellow
Write-Host ""

# Find Intel Wireless devices
Write-Host "Scanning for supported Intel Wireless adapters..." -ForegroundColor Green

# Find supported Intel Wi-Fi devices by Hardware ID
$wirelessDevices = Get-PnpDevice | Where-Object {
    $_.Class -eq "Net" -and 
    $_.Status -eq "OK" -and
    ($supportedWiFiHWIDs | Where-Object { $_.InstanceId -like "*$_*" })
}

if ($wirelessDevices.Count -eq 0) {
    Write-Host "No supported Intel Wi-Fi adapters found." -ForegroundColor Yellow
    $wifiUpdateAvailable = $false
} else {
    Write-Host "Found $($wirelessDevices.Count) supported Intel Wireless adapter(s):" -ForegroundColor Green
    $wifiUpdateAvailable = $false
    
    foreach ($device in $wirelessDevices) {
        $currentVersion = Get-CurrentDriverVersion -DeviceInstanceId $device.InstanceId
        
        Write-Host "`nAdapter: $($device.FriendlyName)" -ForegroundColor White
        Write-Host "Instance ID: $($device.InstanceId)" -ForegroundColor Gray
        
        if ($currentVersion) {
            Write-Host "Current Version: $currentVersion" -ForegroundColor Gray
            if ($currentVersion -eq $wifiData.Version) {
                Write-Host "Status: Already on latest version" -ForegroundColor Green
            } else {
                Write-Host "Status: Update available! ($currentVersion -> $($wifiData.Version))" -ForegroundColor Yellow
                $wifiUpdateAvailable = $true
            }
        } else {
            Write-Host "Current Version: Unable to determine" -ForegroundColor Gray
            Write-Host "Status: Will attempt to install driver" -ForegroundColor Yellow
            $wifiUpdateAvailable = $true
        }
    }
}

# Find Intel Bluetooth devices
Write-Host "`nScanning for supported Intel Bluetooth adapters..." -ForegroundColor Green

$intelBluetoothIds = @(
    "*VID_8087&PID_0025*", "*VID_8087&PID_0026*", "*VID_8087&PID_0029*",
    "*VID_8087&PID_0032*", "*VID_8087&PID_0033*", "*VID_8087&PID_0036*", 
    "*VID_8087&PID_0037*", "*VID_8087&PID_0038*", "*VID_8087&PID_0AAA*"
)

# Find devices by Hardware ID
$bluetoothDevices = Get-PnpDevice | Where-Object {
    $device = $_
    $intelBluetoothIds | Where-Object { $device.InstanceId -like $_ }
}

if ($bluetoothDevices.Count -eq 0) {
    Write-Host "No supported Intel Bluetooth adapters found." -ForegroundColor Yellow
    $bluetoothUpdateAvailable = $false
} else {
    Write-Host "Found $($bluetoothDevices.Count) supported Intel Bluetooth adapter(s):" -ForegroundColor Green
    $bluetoothUpdateAvailable = $false
    
    foreach ($device in $bluetoothDevices) {
        $currentVersion = Get-CurrentDriverVersion -DeviceInstanceId $device.InstanceId
        
        Write-Host "`nAdapter: $($device.FriendlyName)" -ForegroundColor White
        Write-Host "Instance ID: $($device.InstanceId)" -ForegroundColor Gray
        
        if ($currentVersion) {
            Write-Host "Current Version: $currentVersion" -ForegroundColor Gray
            if ($currentVersion -eq $bluetoothData.Version) {
                Write-Host "Status: Already on latest version" -ForegroundColor Green
            } else {
                Write-Host "Status: Update available! ($currentVersion -> $($bluetoothData.Version))" -ForegroundColor Yellow
                $bluetoothUpdateAvailable = $true
            }
        } else {
            Write-Host "Current Version: Unable to determine" -ForegroundColor Yellow
            Write-Host "Status: Will attempt to install driver" -ForegroundColor Yellow
            $bluetoothUpdateAvailable = $true
        }
    }
}

# If all devices are up to date, ask if user wants to reinstall anyway
if ((-not $wifiUpdateAvailable -and -not $bluetoothUpdateAvailable) -and ($wirelessDevices.Count -gt 0 -or $bluetoothDevices.Count -gt 0)) {
    Write-Host "`nAll adapters are up to date." -ForegroundColor Green
    $response = Read-Host "Do you want to force reinstall the driver anyway? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        $wifiUpdateAvailable = $true
        $bluetoothUpdateAvailable = $true
    } else {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        Clear-TempDriverFolders
        exit
    }
}

# Ask for update confirmation
if ($wifiUpdateAvailable -or $bluetoothUpdateAvailable) {
    Write-Host ""
    $response = Read-Host "Do you want to proceed with driver update? (Y/N)"
} else {
    $response = "N"
}

if ($response -eq "Y" -or $response -eq "y") {
    Write-Host "`nStarting driver update process..." -ForegroundColor Green
    
    # VARIABLES TO STORE DOWNLOADED DRIVER PATHS
    $wifiDriverPath = $null
    $bluetoothDriverPaths = @()
    
    # PHASE 1: DOWNLOAD ALL DRIVERS FIRST (before any installation)
    Write-Host "`n=== Downloading drivers ===" -ForegroundColor Cyan
    
    # Download WiFi drivers if needed
    if ($wifiUpdateAvailable -and $wifiData.CabUrl) {
        Write-Host "Downloading WiFi drivers..." -ForegroundColor Green
        $wifiDriverPath = "$tempDir\WiFi"
        if (Download-Extract-Cab -CabUrl $wifiData.CabUrl -OutputPath $wifiDriverPath) {
            Write-Host "WiFi drivers downloaded successfully." -ForegroundColor Green
        } else {
            Write-Host "Failed to download WiFi drivers." -ForegroundColor Red
            $wifiUpdateAvailable = $false
        }
    }
    
    # Download Bluetooth drivers if needed
    if ($bluetoothUpdateAvailable -and $bluetoothData.CabData.Count -gt 0) {
        Write-Host "Downloading Bluetooth drivers..." -ForegroundColor Green
        
        # Find the correct CAB for each device
        $uniqueCabUrls = @()
        foreach ($device in $bluetoothDevices) {
            $cabUrl = Get-BluetoothCabForDevice -DeviceInstanceId $device.InstanceId -BluetoothCabData $bluetoothData.CabData
            if ($cabUrl -and $uniqueCabUrls -notcontains $cabUrl) {
                $uniqueCabUrls += $cabUrl
            }
        }
        
        if ($uniqueCabUrls.Count -gt 0) {
            foreach ($cabUrl in $uniqueCabUrls) {
                $bluetoothTempDir = "$tempDir\Bluetooth_$(Get-Random)"
                if (Download-Extract-Cab -CabUrl $cabUrl -OutputPath $bluetoothTempDir) {
                    $bluetoothDriverPaths += $bluetoothTempDir
                    Write-Host "Bluetooth drivers downloaded successfully." -ForegroundColor Green
                } else {
                    Write-Host "Failed to download Bluetooth drivers." -ForegroundColor Red
                }
            }
        } else {
            Write-Host "Error: Could not find appropriate Bluetooth driver for your device." -ForegroundColor Red
            $bluetoothUpdateAvailable = $false
        }
    }
    
    # PHASE 2: INSTALL ALL DRIVERS (after all downloads are complete)
    Write-Host "`n=== Installing drivers ===" -ForegroundColor Cyan
    
    # Update WiFi drivers if needed
    if ($wifiUpdateAvailable -and $wifiDriverPath -and (Test-Path $wifiDriverPath)) {
        Write-Host "Installing WiFi drivers..." -ForegroundColor Green
        $infFile = Get-RecommendedInfFile -DriverPath $wifiDriverPath
        if ($infFile) {
            Write-Host "Selected WiFi driver: $(Split-Path $infFile -Leaf)" -ForegroundColor Cyan
            pnputil /add-driver "$infFile" /install 2>$null | Out-Null
            
            foreach ($device in $wirelessDevices) {
                pnputil /update-device "$($device.InstanceId)" /install 2>$null | Out-Null
            }
            Write-Host "WiFi driver update completed." -ForegroundColor Green
        } else {
            Write-Host "Error: Could not find appropriate INF file for WiFi driver." -ForegroundColor Red
        }
    }
    
    # Update Bluetooth drivers if needed
    if ($bluetoothUpdateAvailable -and $bluetoothDriverPaths.Count -gt 0) {
        Write-Host "Installing Bluetooth drivers..." -ForegroundColor Green
        
        foreach ($bluetoothDriverPath in $bluetoothDriverPaths) {
            if (Test-Path $bluetoothDriverPath) {
                $infFiles = Get-ChildItem -Path $bluetoothDriverPath -Filter "*.inf" -Recurse
                foreach ($infFile in $infFiles) {
                    pnputil /add-driver "$($infFile.FullName)" /install 2>$null | Out-Null
                }
            }
        }
        
        foreach ($device in $bluetoothDevices) {
            pnputil /update-device "$($device.InstanceId)" /install 2>$null | Out-Null
        }
        Write-Host "Bluetooth driver update completed." -ForegroundColor Green
    }
    
    Write-Host "`nAll driver updates completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Update cancelled." -ForegroundColor Yellow
}

# Clean up
Write-Host "`nCleaning up temporary files..." -ForegroundColor Gray
Clear-TempDriverFolders