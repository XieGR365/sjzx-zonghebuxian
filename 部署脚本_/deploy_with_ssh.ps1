# Automated Deployment Script using PowerShell SSH
# This script uses PowerShell's built-in SSH capabilities

$REMOTE_HOST = "192.168.19.58"
$REMOTE_USER = "yroot"
$REMOTE_PASSWORD = "Yovole@2026"
$REMOTE_DIR = "~/sjzx-zonghebuxian"
$LOCAL_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Automated Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Local Directory: $LOCAL_DIR" -ForegroundColor Yellow
Write-Host "Remote Server: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}" -ForegroundColor Yellow
Write-Host ""

# Check local directories
if (-not (Test-Path "$LOCAL_DIR\backend" -PathType Container)) {
    Write-Host "Error: Backend directory not found" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "$LOCAL_DIR\frontend" -PathType Container)) {
    Write-Host "Error: Frontend directory not found" -ForegroundColor Red
    exit 1
}

Write-Host "Starting automated deployment..." -ForegroundColor Yellow
Write-Host ""

# Create a temporary script file for SSH
$tempScript = [System.IO.Path]::GetTempFileName()

# Create SSH command script
$sshScript = @"
#!/bin/bash
set -e

# Create remote directory
mkdir -p $REMOTE_DIR

echo "Remote directory created: $REMOTE_DIR"
"@

Set-Content -Path $tempScript -Value $sshScript

# Function to run SSH command
function Invoke-SSHCommand {
    param([string]$Command)
    
    $fullCommand = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} `"$Command`""
    $output = Invoke-Expression $fullCommand 2>&1
    return $output
}

# Create remote directory
Write-Host "Creating remote directory..." -ForegroundColor Yellow
Invoke-SSHCommand "mkdir -p $REMOTE_DIR"
Write-Host "Remote directory created successfully" -ForegroundColor Green
Write-Host ""

# Copy backend files
Write-Host "1. Copying backend files..." -ForegroundColor Yellow
Write-Host "   This may take a few minutes, please wait..." -ForegroundColor Cyan
Write-Host ""

# Use scp with password prompt
$process = Start-Process -FilePath "scp" -ArgumentList "-r", "`"$LOCAL_DIR\backend`"", "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" -Wait -PassThru -NoNewWindow

if ($process.ExitCode -ne 0) {
    Write-Host "Error: Backend file copy failed" -ForegroundColor Red
    Write-Host "Please run manually: scp -r backend ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" -ForegroundColor Cyan
    exit 1
}

Write-Host "   Backend files copied successfully" -ForegroundColor Green
Write-Host ""

# Copy frontend files
Write-Host "2. Copying frontend files..." -ForegroundColor Yellow
Write-Host "   This may take a few minutes, please wait..." -ForegroundColor Cyan
Write-Host ""

$process = Start-Process -FilePath "scp" -ArgumentList "-r", "`"$LOCAL_DIR\frontend`"", "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" -Wait -PassThru -NoNewWindow

if ($process.ExitCode -ne 0) {
    Write-Host "Error: Frontend file copy failed" -ForegroundColor Red
    Write-Host "Please run manually: scp -r frontend ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" -ForegroundColor Cyan
    exit 1
}

Write-Host "   Frontend files copied successfully" -ForegroundColor Green
Write-Host ""

# Copy config files
Write-Host "3. Copying config files..." -ForegroundColor Yellow
Write-Host ""

if (Test-Path "$LOCAL_DIR\config" -PathType Container) {
    $process = Start-Process -FilePath "scp" -ArgumentList "-r", "`"$LOCAL_DIR\config`"", "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -ne 0) {
        Write-Host "Error: Config file copy failed" -ForegroundColor Red
        Write-Host "Please run manually: scp -r config ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" -ForegroundColor Cyan
        exit 1
    }
    
    Write-Host "   Config files copied successfully" -ForegroundColor Green
} else {
    Write-Host "   Warning: Config directory not found, skipping" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All files copied successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next step: SSH to server and run install script" -ForegroundColor Yellow
Write-Host "Command: ssh ${REMOTE_USER}@${REMOTE_HOST}" -ForegroundColor Cyan
Write-Host ""
