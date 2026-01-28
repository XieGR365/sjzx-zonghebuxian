# Simple File Copy Script
# Use scp command to copy files to remote server

$REMOTE_HOST = "192.168.19.58"
$REMOTE_USER = "yroot"
$REMOTE_DIR = "~/sjzx-zonghebuxian"
$LOCAL_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Copy Files to Remote Server" -ForegroundColor Cyan
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

Write-Host "Starting file copy..." -ForegroundColor Yellow
Write-Host ""

# Copy backend files
Write-Host "1. Copying backend files..." -ForegroundColor Yellow
Write-Host "   This may take a few minutes, please wait..." -ForegroundColor Cyan
Write-Host ""

scp -r "$LOCAL_DIR\backend" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Backend file copy failed" -ForegroundColor Red
    exit 1
}

Write-Host "   Backend files copied successfully" -ForegroundColor Green
Write-Host ""

# Copy frontend files
Write-Host "2. Copying frontend files..." -ForegroundColor Yellow
Write-Host "   This may take a few minutes, please wait..." -ForegroundColor Cyan
Write-Host ""

scp -r "$LOCAL_DIR\frontend" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Frontend file copy failed" -ForegroundColor Red
    exit 1
}

Write-Host "   Frontend files copied successfully" -ForegroundColor Green
Write-Host ""

# Copy config files
Write-Host "3. Copying config files..." -ForegroundColor Yellow
Write-Host ""

if (Test-Path "$LOCAL_DIR\config" -PathType Container) {
    scp -r "$LOCAL_DIR\config" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Config file copy failed" -ForegroundColor Red
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
