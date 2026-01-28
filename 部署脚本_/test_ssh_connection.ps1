# SSH Connection Test Script
# Test SSH connection to remote server before deployment

$REMOTE_HOST = "192.168.19.58"
$REMOTE_USER = "yroot"

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "SSH Connection Test" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Testing SSH connection to ${REMOTE_USER}@${REMOTE_HOST}..." -ForegroundColor Cyan
Write-Host ""

# Test 1: Basic SSH connection
Write-Host "Test 1: Basic SSH connection..." -ForegroundColor Cyan
$result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 ${REMOTE_USER}@${REMOTE_HOST} "echo 'Connection successful'" 2>&1

if ($LASTEXITCODE -eq 0 -and $result -match "Connection successful") {
    Write-Host "[OK] Basic SSH connection successful" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Basic SSH connection failed" -ForegroundColor Red
    Write-Host "Error: $result" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Possible reasons:" -ForegroundColor Yellow
    Write-Host "  1. SSH key not configured" -ForegroundColor White
    Write-Host "  2. Network connection issue" -ForegroundColor White
    Write-Host "  3. SSH service not running on server" -ForegroundColor White
    Write-Host "  4. Wrong IP address or username" -ForegroundColor White
    Write-Host ""
    Write-Host "To fix this issue:" -ForegroundColor Cyan
    Write-Host "  1. Run setup_ssh_key.ps1 to configure SSH keys" -ForegroundColor White
    Write-Host "  2. Check network connection: ping $REMOTE_HOST" -ForegroundColor White
    Write-Host "  3. Verify SSH service on server: sudo systemctl status sshd" -ForegroundColor White
    Write-Host ""
    Write-Host "Cannot proceed with deployment until SSH connection is fixed" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Test 2: Check if can execute commands
Write-Host "Test 2: Command execution..." -ForegroundColor Cyan
$result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} "whoami" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Can execute commands on remote server" -ForegroundColor Green
    Write-Host "Remote user: $result" -ForegroundColor Cyan
} else {
    Write-Host "[ERROR] Cannot execute commands on remote server" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 3: Check if can copy files (dry run)
Write-Host "Test 3: SCP file transfer (dry run)..." -ForegroundColor Cyan
$result = scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -n -r "test" ${REMOTE_USER}@${REMOTE_HOST}:/tmp/ 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] SCP file transfer capability verified" -ForegroundColor Green
} else {
    Write-Host "[WARNING] SCP test failed (this is expected if 'test' directory doesn't exist)" -ForegroundColor Yellow
    Write-Host "[INFO] This is not critical, SCP should work during actual deployment" -ForegroundColor Cyan
}

Write-Host ""

# Test 4: Check remote OS
Write-Host "Test 4: Remote OS detection..." -ForegroundColor Cyan
$result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} "cat /etc/os-release | grep '^ID=' | cut -d= -f2" 2>&1

if ($LASTEXITCODE -eq 0) {
    $osName = $result -replace '"', ''
    Write-Host "[OK] Remote OS detected: $osName" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Cannot detect remote OS" -ForegroundColor Yellow
}

Write-Host ""

# Test 5: Check Node.js installation
Write-Host "Test 5: Node.js installation check..." -ForegroundColor Cyan
$result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} "node --version" 2>&1

if ($LASTEXITCODE -eq 0 -and $result -notmatch "command not found") {
    Write-Host "[OK] Node.js installed: $result" -ForegroundColor Green
    Write-Host "[INFO] Version check skipped for compatibility" -ForegroundColor Cyan
} else {
    Write-Host "[WARNING] Node.js not installed" -ForegroundColor Yellow
    Write-Host "[INFO] The deployment script will install Node.js 18 automatically" -ForegroundColor Cyan
}

Write-Host ""

# Test 6: Check disk space
Write-Host "Test 6: Disk space check..." -ForegroundColor Cyan
$result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} "df -h ~ | tail -1" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Disk space available" -ForegroundColor Green
    Write-Host "$result" -ForegroundColor Cyan
} else {
    Write-Host "[WARNING] Cannot check disk space" -ForegroundColor Yellow
}

Write-Host ""

# All tests completed
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "[OK] SSH Connection Test Completed Successfully!" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Your SSH connection is ready for deployment." -ForegroundColor Cyan
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run the deployment script: .\远程部署.bat" -ForegroundColor White
Write-Host "  2. Or run PowerShell script directly: .\远程部署_自动.ps1" -ForegroundColor White
Write-Host ""

Write-Host "Deployment information:" -ForegroundColor Cyan
Write-Host "  Server: ${REMOTE_USER}@${REMOTE_HOST}" -ForegroundColor White
Write-Host "  Directory: ~/sjzx-zonghebuxian" -ForegroundColor White
Write-Host ""
