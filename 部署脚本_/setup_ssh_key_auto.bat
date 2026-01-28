@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo SSH Key Setup - Automated
echo ========================================
echo.
echo This script will set up SSH key authentication
echo so you don't need to enter passwords in the future.
echo.
echo You will be prompted for your password ONE TIME.
echo Password: Yovole@2026
echo.
echo Press any key to continue...
pause >nul

echo.
echo Adding public key to remote server...
echo.

ssh yroot@192.168.19.58 "mkdir -p ~/.ssh ; chmod 700 ~/.ssh ; echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHPJOi+Lh65JknLGmD45yRQRrWxEe56ekLWH8c0qYlk9lE6hermsg2bKk0x4ck5NRSmkR9q3FLTbVyYu9XZCh9N+qUqgg5sqc1EMYHd6MhIBiey3gzVX7wKeiKAHaRL5rpksq/RkD9G3AS1LT9QHD9P3XuHKv0evb7BpV3pEYOhYXPbzjHtnwcc7e7Cz9NodvjBDIgld0dxi6L8UYFylMQRGwLzhEV5ZbH/q1R+NK3JrBoakDd7kQJbqEnxfYAvi2GAvOkMSnkwMKmB6mY63b0qnVHHM9kza4baqJg2iBPO0jLQEgf3o/0eefQqktmE3g4GhHokJYhXUT8jtiinUc+jt+lYFH8e80Hi0pISl1UlJh/9wHut28pHknpWN4TAxYhAlUL1TY30DyA7KwijYpiEartEGIjh2RHKYKZku0nYPp2wMK2GkMHoHhIbBIR/qS8zWPxt+DWNzuaVlVguISNd807V5RUnwGVLMin33T4TLo+GMepfK+lg6qM/WjAb0A0QIwOZZHC8w7UHcjo642H5ufCziIOdaqNGh+B1Am7KaOBRwu64IObWWJQh70hbgdIZxX35k7ls7ctS7JjC70cNiqCLVnxJbD/Yf7t0Fio9JXcTna4f/Dg75e2o7QBhHF3FQQISlARTFCuAsaiVSdiQqFVec7N5uCdl8b+3693Qw== admin@DESKTOP-N628603' >> ~/.ssh/authorized_keys ; chmod 600 ~/.ssh/authorized_keys"

if errorlevel 1 (
    echo.
    echo Error: Failed to add public key to remote server
    echo Please check your password and network connection
    pause
    exit /b 1
)

echo.
echo Public key added successfully!
echo.

echo Testing SSH connection...
echo.

ssh -o BatchMode=yes yroot@192.168.19.58 "echo 'SSH connection successful'"

if errorlevel 1 (
    echo.
    echo Error: SSH connection test failed
    echo Please check your SSH configuration
    pause
    exit /b 1
)

echo.
echo ========================================
echo SSH key setup completed successfully!
echo ========================================
echo.
echo You can now use SSH without password prompts
echo.
echo Next step: Run the deployment script
echo Command: .\deploy_with_ssh_key.bat
echo.

pause
