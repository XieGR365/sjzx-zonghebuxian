@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Remote Deployment Script
echo ========================================
echo.
echo This script will deploy your application
echo to remote Linux server automatically.
echo.
echo Server Information:
echo   IP: 192.168.19.58
echo   User: yroot
echo   Password: Yovole@2026
echo.
echo Press any key to start deployment...
pause >nul

echo.
echo Starting deployment...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0远程部署_自动.ps1"

if errorlevel 1 (
    echo.
    echo ========================================
    echo Deployment failed!
    echo ========================================
    echo.
    echo Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Deployment completed successfully!
echo ========================================
echo.
echo Access URLs:
echo   Frontend: http://192.168.19.58:80
echo   Backend:  http://192.168.19.58:3001
echo.

pause
