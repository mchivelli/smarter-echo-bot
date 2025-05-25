@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cls

echo ╔══════════════════════════════════════════════════════════════╗
echo ║                    SSH RECOVERY AUTOMATION                  ║
echo ║                         Version 2.0                         ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
echo 🔧 This script will automatically fix your SSH connection issue.
echo 📋 The ReSpeaker driver has corrupted SSH on your Raspberry Pi.
echo.

:check_files
echo 📁 Checking required files...
if not exist "ssh_fix_boot_v2.sh" (
    echo ❌ Error: ssh_fix_boot_v2.sh not found!
    echo 📥 Please ensure you're running this from the SmarterAlexa folder.
    pause
    exit /b 1
)

if not exist "cmdline_recovery_v2.txt" (
    echo ❌ Error: cmdline_recovery_v2.txt not found!
    echo 📥 Please ensure you're running this from the SmarterAlexa folder.
    pause
    exit /b 1
)

echo ✅ All required files found.
echo.

:detect_drives
echo 🔍 Detecting removable drives...
echo.
echo Current removable drives:
for /f "tokens=1,2" %%a in ('wmic logicaldisk where "drivetype=2" get deviceid^,volumename /format:table ^| findstr /r /v "^$"') do (
    if not "%%a"=="DeviceID" if not "%%a"=="" (
        echo   Drive %%a - %%b
    )
)
echo.

:prompt_insert
echo 📱 STEP 1: Insert your Raspberry Pi SD card into this computer
echo.
echo ⚠️  IMPORTANT: 
echo    - Power OFF your Raspberry Pi completely first
echo    - Remove the SD card from the Pi
echo    - Insert it into this Windows computer
echo.
pause

:detect_boot_drive
echo.
echo 🔍 Looking for SD card boot partition...
set "boot_drive="
for %%d in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\cmdline.txt" (
        echo ✅ Found boot partition at %%d:\
        set "boot_drive=%%d:"
        goto :found_boot
    )
)

echo ❌ Could not find SD card boot partition automatically.
echo.
echo 📋 Please check:
echo    - SD card is properly inserted
echo    - Windows recognizes the SD card
echo    - You can see a drive with files like cmdline.txt, config.txt
echo.
echo 💡 Manual drive selection:
set /p "boot_drive=Enter the drive letter of your SD card boot partition (e.g., E:): "

if not exist "%boot_drive%\cmdline.txt" (
    echo ❌ Error: cmdline.txt not found on %boot_drive%
    echo 🔄 Please try again...
    goto :detect_boot_drive
)

:found_boot
echo.
echo ✅ Boot partition found: %boot_drive%
echo.

:backup_and_copy
echo 📋 STEP 2: Backing up and copying recovery files...
echo.

REM Backup original cmdline.txt
if exist "%boot_drive%\cmdline.txt" (
    if not exist "%boot_drive%\cmdline_original_backup.txt" (
        echo 💾 Backing up original cmdline.txt...
        copy "%boot_drive%\cmdline.txt" "%boot_drive%\cmdline_original_backup.txt" >nul
        if !errorlevel! equ 0 (
            echo ✅ Original cmdline.txt backed up
        ) else (
            echo ❌ Failed to backup cmdline.txt
            goto :error_exit
        )
    ) else (
        echo ℹ️  Original cmdline.txt already backed up
    )
)

REM Copy recovery script
echo 📁 Copying SSH recovery script...
copy "ssh_fix_boot_v2.sh" "%boot_drive%\ssh_fix_boot_v2.sh" >nul
if !errorlevel! equ 0 (
    echo ✅ Recovery script copied
) else (
    echo ❌ Failed to copy recovery script
    goto :error_exit
)

REM Replace cmdline.txt
echo 🔄 Installing recovery boot configuration...
copy "cmdline_recovery_v2.txt" "%boot_drive%\cmdline.txt" >nul
if !errorlevel! equ 0 (
    echo ✅ Recovery boot configuration installed
) else (
    echo ❌ Failed to install recovery configuration
    goto :error_exit
)

echo.
echo ✅ All files successfully copied to SD card!
echo.

:eject_instructions
echo 📤 STEP 3: Safely eject SD card and boot Pi
echo.
echo 🔧 Please do the following:
echo    1. Safely eject the SD card from Windows
echo    2. Insert the SD card back into your Raspberry Pi
echo    3. Power on your Raspberry Pi
echo    4. Wait 5-10 minutes for the recovery process
echo.
echo ⏱️  The recovery process will:
echo    - Automatically detect and fix SSH corruption
echo    - Generate new SSH keys
echo    - Create a clean SSH configuration
echo    - Restore normal boot process
echo    - Log everything to /boot/ssh_recovery.log
echo.

pause

:test_connection
echo.
echo 🌐 STEP 4: Test SSH connection
echo.
echo ⏱️  Please wait 5-10 minutes after powering on the Pi, then test SSH:
echo.
echo 💻 Command to try: ssh prototype@192.168.0.40
echo.
echo 📋 If SSH works:
echo    ✅ Recovery successful! Your Pi is ready to use.
echo.
echo 📋 If SSH still fails:
echo    1. Check /boot/ssh_recovery.log on the SD card for details
echo    2. Try power cycling the Pi one more time
echo    3. Contact support with the recovery log
echo.

:completion
echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                    RECOVERY COMPLETE                        ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
echo 🎉 SSH recovery files have been installed on your SD card.
echo 📋 The recovery will run automatically when you boot the Pi.
echo 🔍 Check /boot/ssh_recovery.log for detailed recovery status.
echo.
pause
exit /b 0

:error_exit
echo.
echo ❌ An error occurred during the recovery process.
echo 🔄 Please check:
echo    - SD card is not write-protected
echo    - You have administrator privileges
echo    - SD card has enough free space
echo.
pause
exit /b 1 