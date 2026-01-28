# Simple SSH Test Script
# Test basic SSH connection and command execution

$REMOTE_HOST = "192.168.19.58"
$REMOTE_USER = "yroot"

Write-Host "Testing SSH connection..." -ForegroundColor Cyan

# Test 1: Simple echo command
Write-Host "Test 1: Simple echo command..." -ForegroundColor Yellow
$result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 ${REMOTE_USER}@${REMOTE_HOST} "echo 'test'" 2>&1
Write-Host "Result: $result" -ForegroundColor White
Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor White
Write-Host ""

# Test 2: Command with pipe
Write-Host "Test 2: Command with pipe..." -ForegroundColor Yellow
$result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} "echo 'test' | grep 'test'" 2>&1
Write-Host "Result: $result" -ForegroundColor White
Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor White
Write-Host ""

# Test 3: Get OS info
Write-Host "Test 3: Get OS info..." -ForegroundColor Yellow
$result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} "cat /etc/os-release | grep '^ID=' | cut -d= -f2" 2>&1
Write-Host "Result: $result" -ForegroundColor White
Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor White
Write-Host ""

# Test 4: Check Node.js
Write-Host "Test 4: Check Node.js..." -ForegroundColor Yellow
$result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${REMOTE_USER}@${REMOTE_HOST} "node --version" 2>&1
Write-Host "Result: $result" -ForegroundColor White
Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor White
Write-Host ""

Write-Host "All tests completed!" -ForegroundColor Green
