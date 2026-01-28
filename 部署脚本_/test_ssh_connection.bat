@echo off
echo ========================================
echo SSH Connection Test
echo ========================================
echo.
echo Testing SSH connection to remote server...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0test_ssh_connection.ps1"

if errorlevel 1 (
    echo.
    echo ========================================
    echo SSH Connection Test Failed!
    echo ========================================
    echo.
    echo Please fix the SSH connection issues before running deployment.
    pause
    exit /b 1
)

echo.
echo ========================================
echo SSH Connection Test Passed!
echo ========================================
echo.
echo You can now run the deployment script.
echo.

pause
