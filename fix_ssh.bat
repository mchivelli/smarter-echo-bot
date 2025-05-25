@echo off
REM Remote SSH Recovery Script for Windows
REM Attempts to fix SSH connection issues remotely

set PI_IP=192.168.0.40
set USERNAME=prototype

echo 🔧 Attempting to fix SSH on %PI_IP%...
echo This script will try multiple approaches to restore SSH connectivity.
echo.

echo Method 1: Power cycle recommendation...
echo Please unplug the Pi's power for 30 seconds, then plug it back in.
echo Wait 5 minutes for full boot, then try SSH again.
echo.
pause

echo Method 2: Trying different SSH options...
echo.

echo Trying SSH with legacy algorithms...
ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa %USERNAME%@%PI_IP%
if %errorlevel% equ 0 goto success

echo.
echo Trying SSH with different cipher...
ssh -o Ciphers=aes128-ctr %USERNAME%@%PI_IP%
if %errorlevel% equ 0 goto success

echo.
echo Trying SSH with protocol 1...
ssh -1 %USERNAME%@%PI_IP%
if %errorlevel% equ 0 goto success

echo.
echo Trying SSH with no host key checking...
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null %USERNAME%@%PI_IP%
if %errorlevel% equ 0 goto success

echo.
echo Method 3: Checking Pi responsiveness...
ping -n 3 %PI_IP% >nul
if %errorlevel% equ 0 (
    echo ✅ Pi is responding to ping
) else (
    echo ❌ Pi is not responding to ping - needs power cycle
    goto failed
)

echo.
echo Method 4: Waiting for automatic recovery...
echo The Pi may recover automatically. Trying SSH every 30 seconds for 5 minutes...

for /l %%i in (1,1,10) do (
    echo Attempt %%i/10...
    ssh -o ConnectTimeout=5 -o BatchMode=yes %USERNAME%@%PI_IP% "echo SSH recovered" 2>nul
    if %errorlevel% equ 0 goto success
    timeout /t 30 /nobreak >nul
)

:failed
echo.
echo ❌ All remote recovery methods failed.
echo.
echo 🔧 Next steps:
echo 1. Power cycle the Pi (unplug for 30 seconds)
echo 2. Wait 5 minutes after power on
echo 3. Try SSH again
echo 4. If still failing, you'll need physical access (monitor + keyboard)
echo.
echo 💡 The updated setup script now includes SSH recovery mechanisms
echo    to prevent this issue in future installations.
echo.
pause
exit /b 1

:success
echo.
echo ✅ SSH connection successful!
echo You can now continue with: ssh %USERNAME%@%PI_IP%
echo.
pause
exit /b 0 