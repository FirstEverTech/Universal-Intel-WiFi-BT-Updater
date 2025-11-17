@echo off
setlocal enabledelayedexpansion

:: Intel Wi-Fi and Bluetooth Drivers Update Tool
:: Supports Wi-Fi 5 (AC) / Wi-Fi 6 (AX) / Wi-Fi 6E (AXE) / Wi-Fi 7 (BE) and Bluetooth
:: Requires administrator privileges

:: Set console window size to 75 columns and 50 lines
mode con: cols=75 lines=50

echo /*************************************************************************
echo **            UNIVERSAL INTEL WI-FI / BLUETOOH DRIVER UPDATER            **
echo ** --------------------------------------------------------------------- **
echo **                                                                       **
echo **                    Drivers Version: 24.0 (2025.11)                    **
echo **                                                                       **
echo **                 Supports: Wi-Fi 5/6/6E/7 and Bluetooth                **
echo **              Author: Marcin Grygiel / www.firstever.tech              **
echo **                                                                       **
echo ** --------------------------------------------------------------------- **
echo **         This tool is not affiliated with Intel Corporation.           **
echo **         Drivers are sourced from official Intel servers.              **
echo **         Use at your own risk.                                         **
echo ** --------------------------------------------------------------------- **
echo **                                                                       **
echo **        GitHub.com/FirstEverTech/Universal-Intel-WiFi-BT-Updater       **
echo **                                                                       **
echo *************************************************************************/
echo.

:: Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

:: Check if PowerShell script exists in the same directory
if not exist "!SCRIPT_DIR!Universal-Intel-WiFi-BT-Updater.ps1" (
    echo Error: Universal-Intel-WiFi-BT-Updater.ps1 not found in current directory!
    echo.
    echo Please ensure the PowerShell script is in the same folder as this BAT file.
    pause
    exit /b 1
)

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Requesting elevation...
    echo.
    
    :: Re-launch as administrator with the correct directory
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs -WorkingDirectory '!SCRIPT_DIR!'"
    exit /b
)

echo Running Intel drivers update...
echo.

:: Change to script directory to ensure proper file access
cd /d "!SCRIPT_DIR!"

:: Run PowerShell script with execution policy bypass
powershell -ExecutionPolicy Bypass -File "Universal-Intel-WiFi-BT-Updater.ps1"

echo.
pause