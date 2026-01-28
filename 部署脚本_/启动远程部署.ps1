# Remote Deployment Launcher
# Simple launcher for remote deployment script

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Remote Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Server Information:" -ForegroundColor Yellow
Write-Host "  IP: 192.168.19.58" -ForegroundColor White
Write-Host "  User: yroot" -ForegroundColor White
Write-Host "  Password: Yovole@2026" -ForegroundColor White
Write-Host ""

Write-Host "Press any key to start deployment..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host ""
Write-Host "Starting deployment..." -ForegroundColor Yellow
Write-Host ""

$deployScript = "$SCRIPT_DIR\远程部署_自动.ps1"

if (-not (Test-Path $deployScript)) {
    Write-Host "Error: Deployment script not found: $deployScript" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

try {
    & $deployScript
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Deployment completed successfully!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Access URLs:" -ForegroundColor Yellow
        Write-Host "  Frontend: http://192.168.19.58:80" -ForegroundColor White
        Write-Host "  Backend:  http://192.168.19.58:3001" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Deployment failed!" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Please check the error messages above." -ForegroundColor Yellow
        Write-Host ""
    }
} catch {
    Write-Host ""
    Write-Host "Error occurred during deployment:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor White
    Write-Host ""
}

Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
