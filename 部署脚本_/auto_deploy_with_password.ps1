# Automated Deployment with Password Input
# This script uses SendKeys to automate password input

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

# Function to copy files with password
function Copy-Files-WithPassword {
    param(
        [string]$Source,
        [string]$Destination
    )
    
    $process = Start-Process -FilePath "scp" -ArgumentList "-r", "`"$Source`"", $Destination -PassThru -RedirectStandardOutput "output.txt" -RedirectStandardError "error.txt"
    
    # Wait for password prompt
    Start-Sleep -Seconds 2
    
    # Send password
    $wshell = New-Object -ComObject WScript.Shell
    $wshell.SendKeys($REMOTE_PASSWORD)
    $wshell.SendKeys("{ENTER}")
    
    # Wait for completion
    $process.WaitForExit()
    
    return $process.ExitCode
}

# Copy backend files
Write-Host "1. Copying backend files..." -ForegroundColor Yellow
Write-Host "   This may take a few minutes, please wait..." -ForegroundColor Cyan
Write-Host ""

$exitCode = Copy-Files-WithPassword "$LOCAL_DIR\backend" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

if ($exitCode -ne 0) {
    Write-Host "Error: Backend file copy failed" -ForegroundColor Red
    Write-Host "Please check error.txt for details" -ForegroundColor Yellow
    exit 1
}

Write-Host "   Backend files copied successfully" -ForegroundColor Green
Write-Host ""

# Copy frontend files
Write-Host "2. Copying frontend files..." -ForegroundColor Yellow
Write-Host "   This may take a few minutes, please wait..." -ForegroundColor Cyan
Write-Host ""

$exitCode = Copy-Files-WithPassword "$LOCAL_DIR\frontend" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

if ($exitCode -ne 0) {
    Write-Host "Error: Frontend file copy failed" -ForegroundColor Red
    Write-Host "Please check error.txt for details" -ForegroundColor Yellow
    exit 1
}

Write-Host "   Frontend files copied successfully" -ForegroundColor Green
Write-Host ""

# Copy config files
Write-Host "3. Copying config files..." -ForegroundColor Yellow
Write-Host ""

if (Test-Path "$LOCAL_DIR\config" -PathType Container) {
    $exitCode = Copy-Files-WithPassword "$LOCAL_DIR\config" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
    
    if ($exitCode -ne 0) {
        Write-Host "Error: Config file copy failed" -ForegroundColor Red
        Write-Host "Please check error.txt for details" -ForegroundColor Yellow
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
