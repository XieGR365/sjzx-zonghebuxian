@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set REMOTE_HOST=192.168.19.58
set REMOTE_USER=yroot
set REMOTE_DIR=~/sjzx-zonghebuxian
set LOCAL_DIR=%~dp0..\

echo ========================================
echo Automated Deployment Script
echo ========================================
echo.
echo Local Directory: %LOCAL_DIR%
echo Remote Server: %REMOTE_USER%@%REMOTE_HOST%:%REMOTE_DIR%
echo.
echo Starting automated deployment...
echo.
echo You will be prompted to enter your password for each file copy.
echo Password: Yovole@2026
echo.
echo Press any key to continue...
pause >nul

echo.
echo 1. Copying backend files...
echo    This may take a few minutes, please wait...
echo.

scp -r "%LOCAL_DIR%backend" %REMOTE_USER%@%REMOTE_HOST%:%REMOTE_DIR%/

if errorlevel 1 (
    echo Error: Backend file copy failed
    echo Please check your password and network connection
    pause
    exit /b 1
)

echo    Backend files copied successfully
echo.

echo 2. Copying frontend files...
echo    This may take a few minutes, please wait...
echo.

scp -r "%LOCAL_DIR%frontend" %REMOTE_USER%@%REMOTE_HOST%:%REMOTE_DIR%/

if errorlevel 1 (
    echo Error: Frontend file copy failed
    echo Please check your password and network connection
    pause
    exit /b 1
)

echo    Frontend files copied successfully
echo.

echo 3. Copying config files...
echo.

if exist "%LOCAL_DIR%config" (
    scp -r "%LOCAL_DIR%config" %REMOTE_USER%@%REMOTE_HOST%:%REMOTE_DIR%/
    
    if errorlevel 1 (
        echo Error: Config file copy failed
        echo Please check your password and network connection
        pause
        exit /b 1
    )
    
    echo    Config files copied successfully
) else (
    echo    Warning: Config directory not found, skipping
)

echo.
echo ========================================
echo All files copied successfully!
echo ========================================
echo.

echo Next step: SSH to server and run install script
echo.
echo Command: ssh %REMOTE_USER%@%REMOTE_HOST%
echo.
echo Then run: cd ~/sjzx-zonghebuxian/部署脚本_ && ./服务器安装.sh
echo.

pause
