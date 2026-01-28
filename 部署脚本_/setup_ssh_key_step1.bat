@echo off
chcp 65001 >nul

echo ========================================
echo SSH Key Setup - Step 1: Connect to Server
echo ========================================
echo.
echo Connecting to remote server...
echo.
echo Please enter password when prompted: Yovole@2026
echo.

ssh yroot@192.168.19.58

echo.
echo ========================================
echo SSH Key Setup - Step 2: Add Public Key
echo ========================================
echo.
echo Once connected to the server, run these commands:
echo.
echo mkdir -p ~/.ssh
echo chmod 700 ~/.ssh
echo echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHPJOi+Lh65JknLGmD45yRQRrWxEe56ekLWH8c0qYlk9lE6hermsg2bKk0x4ck5NRSmkR9q3FLTbVyYu9XZCh9N+qUqgg5sqc1EMYHd6MhIBiey3gzVX7wKeiKAHaRL5rpksq/RkD9G3AS1LT9QHD9P3XuHKv0evb7BpV3pEYOhYXPbzjHtnwcc7e7Cz9NodvjBDIgld0dxi6L8UYFylMQRGwLzhEV5ZbH/q1R+NK3JrBoakDd7kQJbqEnxfYAvi2GAvOkMSnkwMKmB6mY63b0qnVHHM9kza4baqJg2iBPO0jLQEgf3o/0eefQqktmE3g4GhHokJYhXUT8jtiinUc+jt+lYFH8e80Hi0pISl1UlJh/9wHut28pHknpWN4TAxYhAlUL1TY30DyA7KwijYpiEartEGIjh2RHKYKZku0nYPp2wMK2GkMHoHhIbBIR/qS8zWPxt+DWNzuaVlVguISNd807V5RUnwGVLMin33T4TLo+GMepfK+lg6qM/WjAb0A0QIwOZZHC8w7UHcjo642H5ufCziIOdaqNGh+B1Am7KaOBRwu64IObWWJQh70hbgdIZxX35k7ls7ctS7JjC70cNiqCLVnxJbD/Yf7t0Fio9JXcTna4f/Dg75e2o7QBhHF3FQQISlARTFCuAsaiVSdiQqFVec7N5uCdl8b+3693Qw== admin@DESKTOP-N628603" ^>^> ~/.ssh/authorized_keys
echo chmod 600 ~/.ssh/authorized_keys
echo.
echo Then exit from the server and run: ssh yroot@192.168.19.58 "echo 'SSH connection successful'"
echo.
echo If successful, run: .\deploy_with_ssh_key.bat
echo.

pause
