# SSH Key Setup Script
# This script sets up SSH key authentication to avoid password prompts

$REMOTE_HOST = "192.168.19.58"
$REMOTE_USER = "yroot"
$REMOTE_PASSWORD = "Yovole@2026"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SSH Key Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if SSH key already exists
$sshDir = "$env:USERPROFILE\.ssh"
$privateKey = "$sshDir\id_rsa"
$publicKey = "$sshDir\id_rsa.pub"

if (Test-Path $privateKey) {
    Write-Host "SSH key already exists at: $privateKey" -ForegroundColor Yellow
    Write-Host "Skipping key generation..." -ForegroundColor Yellow
} else {
    Write-Host "Generating SSH key pair..." -ForegroundColor Yellow
    Write-Host ""
    
    # Create .ssh directory if it doesn't exist
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }
    
    # Generate SSH key
    ssh-keygen -t rsa -b 4096 -f $privateKey -N '""'
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to generate SSH key" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "SSH key generated successfully" -ForegroundColor Green
    Write-Host ""
}

# Copy public key to remote server
Write-Host "Copying public key to remote server..." -ForegroundColor Yellow
Write-Host "You will be prompted for the password one last time." -ForegroundColor Cyan
Write-Host ""

# Use ssh-copy-id if available, otherwise use manual method
$sshCopyId = Get-Command ssh-copy-id -ErrorAction SilentlyContinue

if ($sshCopyId) {
    ssh-copy-id -i $publicKey "${REMOTE_USER}@${REMOTE_HOST}"
} else {
    # Manual method
    $publicKeyContent = Get-Content $publicKey
    
    $remoteCommand = "mkdir -p ~/.ssh ; chmod 700 ~/.ssh ; echo '$publicKeyContent' >> ~/.ssh/authorized_keys ; chmod 600 ~/.ssh/authorized_keys"
    
    ssh "${REMOTE_USER}@${REMOTE_HOST}" $remoteCommand
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to copy public key to remote server" -ForegroundColor Red
    Write-Host "Please copy the public key manually:" -ForegroundColor Yellow
    Write-Host "1. Copy the content of: $publicKey" -ForegroundColor Cyan
    Write-Host "2. SSH to server: ssh ${REMOTE_USER}@${REMOTE_HOST}" -ForegroundColor Cyan
    Write-Host "3. Add it to ~/.ssh/authorized_keys" -ForegroundColor Cyan
    exit 1
}

Write-Host "Public key copied successfully" -ForegroundColor Green
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
