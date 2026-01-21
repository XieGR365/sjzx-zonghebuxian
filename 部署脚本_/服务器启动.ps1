$REMOTE_HOST = "192.168.19.58"
$REMOTE_USER = "yroot"

$COLOR_INFO = "Cyan"
$COLOR_SUCCESS = "Green"
$COLOR_ERROR = "Red"
$COLOR_WARNING = "Yellow"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor $COLOR_INFO -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] " -ForegroundColor $COLOR_SUCCESS -NoNewline
    Write-Host $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] " -ForegroundColor $COLOR_ERROR -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] " -ForegroundColor $COLOR_WARNING -NoNewline
    Write-Host $Message
}

function Write-Separator {
    Write-Host "================================================================================"
}

function Invoke-SSH {
    param([string]$Command)
    $fullCommand = "ssh ${REMOTE_USER}@${REMOTE_HOST} `"$Command`""
    $output = Invoke-Expression $fullCommand 2>&1
    return $output
}

function Test-RemoteFiles {
    Write-Info "Checking remote server files..."
    
    $allOk = $true
    
    $backendCheck = Invoke-SSH '[ -d ~/sjzx-zonghebuxian/backend ]'
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Backend directory does not exist"
        $allOk = $false
    } else {
        Write-Success "Backend directory exists"
    }
    
    $frontendCheck = Invoke-SSH '[ -d ~/sjzx-zonghebuxian/frontend ]'
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Frontend directory does not exist"
        $allOk = $false
    } else {
        Write-Success "Frontend directory exists"
    }
    
    if (-not $allOk) {
        return $false
    }
    
    return $true
}

function Test-NodeJS {
    Write-Info "Checking Node.js environment..."
    
    $nodeVersion = Invoke-SSH "node --version" | Out-String
    $nodeVersion = $nodeVersion.Trim()
    
    if ([string]::IsNullOrEmpty($nodeVersion)) {
        Write-Error "Node.js not installed"
        return $false
    } else {
        Write-Success "Node.js installed: $nodeVersion"
        return $true
    }
}

function Test-NPM {
    Write-Info "Checking NPM environment..."
    
    $npmVersion = Invoke-SSH "npm --version" | Out-String
    $npmVersion = $npmVersion.Trim()
    
    if ([string]::IsNullOrEmpty($npmVersion)) {
        Write-Error "NPM not installed"
        return $false
    } else {
        Write-Success "NPM installed: $npmVersion"
        return $true
    }
}

function Test-Ports {
    Write-Info "Checking port usage..."
    
    $backendCheck = Invoke-SSH 'netstat -tuln 2>/dev/null | grep -q ":3001 "; if [ $? -eq 0 ]; then echo "in_use"; else echo "free"; fi' | Out-String
    $backendCheck = $backendCheck.Trim()
    
    if ($backendCheck -eq "in_use") {
        Write-Warning "Backend port 3001 is in use"
    } else {
        Write-Success "Backend port 3001 is available"
    }
    
    $frontendCheck = Invoke-SSH 'netstat -tuln 2>/dev/null | grep -q ":80 "; if [ $? -eq 0 ]; then echo "in_use"; else echo "free"; fi' | Out-String
    $frontendCheck = $frontendCheck.Trim()
    
    if ($frontendCheck -eq "in_use") {
        Write-Warning "Frontend port 80 is in use"
    } else {
        Write-Success "Frontend port 80 is available"
    }
    
    return $true
}

function Install-BackendDependencies {
    Write-Info "Installing backend dependencies..."
    
    Write-Info "Entering backend directory..."
    $result = Invoke-SSH 'cd ~/sjzx-zonghebuxian/backend; if [ $? -ne 0 ]; then exit 1; fi'
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Cannot enter backend directory"
        return $false
    }
    
    Write-Info "Running npm install..."
    Write-Warning "This may take several minutes, please wait..."
    
    $installCmd = "ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/backend; npm install --production'"
    Invoke-Expression $installCmd 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Backend dependencies installed"
        return $true
    } else {
        Write-Error "Backend dependencies installation failed"
        return $false
    }
}

function Install-FrontendDependencies {
    Write-Info "Installing frontend dependencies..."
    
    Write-Info "Entering frontend directory..."
    $result = Invoke-SSH 'cd ~/sjzx-zonghebuxian/frontend; if [ $? -ne 0 ]; then exit 1; fi'
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Cannot enter frontend directory"
        return $false
    }
    
    Write-Info "Running npm install..."
    Write-Warning "This may take several minutes, please wait..."
    
    $installCmd = "ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/frontend; npm install'"
    Invoke-Expression $installCmd 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Frontend dependencies installed"
        return $true
    } else {
        Write-Error "Frontend dependencies installation failed"
        return $false
    }
}

function Start-BackendService {
    Write-Info "Starting backend service..."
    
    Write-Info "Checking backend environment configuration..."
    Invoke-SSH 'cd ~/sjzx-zonghebuxian/backend; if [ ! -f .env ]; then cp .env.example .env; fi'
    
    Write-Info "Starting backend service..."
    $startCmd = "ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/backend; nohup npm start > backend.log 2>&1 &'"
    Invoke-Expression $startCmd 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Backend service started"
        return $true
    } else {
        Write-Error "Backend service startup failed"
        return $false
    }
}

function Start-FrontendService {
    Write-Info "Starting frontend service..."
    
    Write-Info "Building frontend..."
    Write-Warning "This may take several minutes, please wait..."
    
    $buildCmd = "ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/frontend; npm run build'"
    Invoke-Expression $buildCmd 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Frontend build failed"
        return $false
    }
    
    Write-Success "Frontend build completed"
    
    Write-Info "Starting frontend service..."
    $startCmd = "ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ~/sjzx-zonghebuxian/frontend; nohup npm run preview > frontend.log 2>&1 &'"
    Invoke-Expression $startCmd 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Frontend service started"
        return $true
    } else {
        Write-Error "Frontend service startup failed"
        return $false
    }
}

function Test-BackendService {
    Write-Info "Testing backend service..."
    
    Start-Sleep -Seconds 3
    
    $backendProcess = Invoke-SSH 'ps aux | grep "npm start" | grep -v grep; if [ $? -ne 0 ]; then echo "not running"; fi'
    Write-Host $backendProcess
    
    if ($backendProcess -like "*not running*") {
        Write-Error "Backend service not running"
        return $false
    } else {
        Write-Success "Backend service is running"
        return $true
    }
}

function Test-FrontendService {
    Write-Info "Testing frontend service..."
    
    Start-Sleep -Seconds 3
    
    $frontendProcess = Invoke-SSH 'ps aux | grep "npm run preview" | grep -v grep; if [ $? -ne 0 ]; then echo "not running"; fi'
    Write-Host $frontendProcess
    
    if ($frontendProcess -like "*not running*") {
        Write-Error "Frontend service not running"
        return $false
    } else {
        Write-Success "Frontend service is running"
        return $true
    }
}

function Show-ServiceStatus {
    Write-Separator
    Write-Info "Service status"
    Write-Separator
    
    Write-Info "Backend process:"
    $backendProcess = Invoke-SSH 'ps aux | grep "npm start" | grep -v grep; if [ $? -ne 0 ]; then echo "not running"; fi'
    Write-Host $backendProcess
    
    Write-Info "Frontend process:"
    $frontendProcess = Invoke-SSH 'ps aux | grep "npm run preview" | grep -v grep; if [ $? -ne 0 ]; then echo "not running"; fi'
    Write-Host $frontendProcess
    
    Write-Info "Port listening:"
    $portListen = Invoke-SSH 'netstat -tuln 2>/dev/null | grep -E ":3001|:80"; if [ $? -ne 0 ]; then echo "none"; fi'
    Write-Host $portListen
    
    Write-Separator
}

function Main {
    Write-Separator
    Write-Host "Cable Management System - Server Startup Script" -ForegroundColor $COLOR_SUCCESS
    Write-Separator
    Write-Host ""
    
    $startTime = Get-Date
    Write-Info "Start time: $startTime"
    Write-Host ""
    
    if (-not (Test-RemoteFiles)) {
        Write-Error "Remote file check failed, stopping execution"
        Write-Info "Please run 1_拷贝文件到远程服务器.ps1 first"
        return
    }
    Write-Host ""
    
    if (-not (Test-NodeJS)) {
        Write-Error "Node.js environment check failed, stopping execution"
        Write-Info "Please install Node.js on the remote server"
        return
    }
    Write-Host ""
    
    if (-not (Test-NPM)) {
        Write-Error "NPM environment check failed, stopping execution"
        Write-Info "Please install NPM on the remote server"
        return
    }
    Write-Host ""
    
    Test-Ports
    Write-Host ""
    
    if (-not (Install-BackendDependencies)) {
        Write-Error "Backend dependencies installation failed, stopping execution"
        return
    }
    Write-Host ""
    
    if (-not (Install-FrontendDependencies)) {
        Write-Error "Frontend dependencies installation failed, stopping execution"
        return
    }
    Write-Host ""
    
    if (-not (Start-BackendService)) {
        Write-Error "Backend service startup failed, stopping execution"
        return
    }
    Write-Host ""
    
    if (-not (Start-FrontendService)) {
        Write-Error "Frontend service startup failed, stopping execution"
        return
    }
    Write-Host ""
    
    Start-Sleep -Seconds 5
    
    Test-BackendService
    Write-Host ""
    
    Test-FrontendService
    Write-Host ""
    
    Show-ServiceStatus
    
    Write-Separator
    Write-Success "Service startup completed!"
    Write-Separator
    Write-Host ""
    
    $endTime = Get-Date
    Write-Info "End time: $endTime"
    Write-Host ""
    Write-Info "Access URLs:"
    Write-Info "  Frontend: http://${REMOTE_HOST}:80"
    Write-Info "  Backend: http://${REMOTE_HOST}:3001"
    Write-Host ""
    Write-Info "View logs:"
    Write-Info "  Backend: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tail -f ~/sjzx-zonghebuxian/backend/backend.log'"
    Write-Info "  Frontend: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tail -f ~/sjzx-zonghebuxian/frontend/frontend.log'"
    Write-Host ""
}

Main
