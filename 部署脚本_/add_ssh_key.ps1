# Add SSH Public Key to Remote Server
# This script adds the public key to the remote server

$REMOTE_HOST = "192.168.19.58"
$REMOTE_USER = "yroot"
$REMOTE_PASSWORD = "Yovole@2026"

$publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHPJOi+Lh65JknLGmD45yRQRrWxEe56ekLWH8c0qYlk9lE6hermsg2bKk0x4ck5NRSmkR9q3FLTbVyYu9XZCh9N+qUqgg5sqc1EMYHd6MhIBiey3gzVX7wKeiKAHaRL5rpksq/RkD9G3AS1LT9QHD9P3XuHKv0evb7BpV3pEYOhYXPbzjHtnwcc7e7Cz9NodvjBDIgld0dxi6L8UYFylMQRGwLzhEV5ZbH/q1R+NK3JrBoakDd7kQJbqEnxfYAvi2GAvOkMSnkwMKmB6mY63b0qnVHHM9kza4baqJg2iBPO0jLQEgf3o/0eefQqktmE3g4GhHokJYhXUT8jtiinUc+jt+lYFH8e80Hi0pISl1UlJh/9wHut28pHknpWN4TAxYhAlUL1TY30DyA7KwijYpiEartEGIjh2RHKYKZku0nYPp2wMK2GkMHoHhIbBIR/qS8zWPxt+DWNzuaVlVguISNd807V5RUnwGVLMin33T4TLo+GMepfK+lg6qM/WjAb0A0QIwOZZHC8w7UHcjo642H5ufCziIOdaqNGh+B1Am7KaOBRwu64IObWWJQh70hbgdIZxX35k7ls7ctS7JjC70cNiqCLVnxJbD/Yf7t0Fio9JXcTna4f/Dg75e2o7QBhHF3FQQISlARTFCuAsaiVSdiQqFVec7N5uCdl8b+3693Qw== admin@DESKTOP-N628603"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Adding SSH Public Key to Remote Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "You will be prompted for the password." -ForegroundColor Yellow
Write-Host "Password: Yovole@2026" -ForegroundColor Cyan
Write-Host ""

# Add public key to remote server
$remoteCommand = "mkdir -p ~/.ssh ; chmod 700 ~/.ssh ; echo '$publicKey' >> ~/.ssh/authorized_keys ; chmod 600 ~/.ssh/authorized_keys"

ssh "${REMOTE_USER}@${REMOTE_HOST}" $remoteCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to add public key to remote server" -ForegroundColor Red
    Write-Host "Please check your SSH connection and password" -ForegroundColor Yellow
    exit 1
}

Write-Host "Public key added successfully" -ForegroundColor Green
Write-Host ""

# Test SSH connection
Write-Host "Testing SSH connection..." -ForegroundColor Yellow
Write-Host ""

$testResult = ssh -o BatchMode=yes "${REMOTE_USER}@${REMOTE_HOST}" "echo 'SSH connection successful'"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: SSH connection test failed" -ForegroundColor Red
    Write-Host "Please check your SSH configuration" -ForegroundColor Yellow
    exit 1
}

Write-Host $testResult -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SSH key setup completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "You can now use SSH without password prompts" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run the deployment script" -ForegroundColor Yellow
Write-Host "Command: .\deploy_with_ssh_key.bat" -ForegroundColor Cyan
Write-Host ""
