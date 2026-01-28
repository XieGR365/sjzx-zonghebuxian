# Remote Deployment Script
# Complete automated deployment from local computer to remote Linux server

$REMOTE_HOST = "192.168.19.58"
$REMOTE_USER = "yroot"
$REMOTE_PASSWORD = "Yovole@2026"
$REMOTE_DIR = "~/sjzx-zonghebuxian"
$LOCAL_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Colors
$COLOR_INFO = "Cyan"
$COLOR_SUCCESS = "Green"
$COLOR_ERROR = "Red"
$COLOR_WARNING = "Yellow"
$COLOR_RESET = "White"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = $COLOR_RESET
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Separator {
    Write-ColorOutput "================================================================================" $COLOR_INFO
}

function Write-Step {
    param(
        [string]$StepNum,
        [string]$Description
    )
    Write-Separator
    Write-ColorOutput "Step $StepNum`: $Description" $COLOR_INFO
    Write-Separator
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[OK] $Message" $COLOR_SUCCESS
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" $COLOR_ERROR
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" $COLOR_WARNING
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" $COLOR_INFO
}

function Invoke-RemoteCommand {
    param(
        [string]$Command,
        [int]$Timeout = 300
    )
    
    $fullCommand = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$Timeout ${REMOTE_USER}@${REMOTE_HOST} `"$Command`""
    $output = Invoke-Expression $fullCommand 2>&1
    return $output
}

function Test-SSHConnection {
    Write-Info "Testing SSH connection to ${REMOTE_USER}@${REMOTE_HOST}..."
    
    $result = Invoke-RemoteCommand "echo 'Connection successful'"
    
    if ($LASTEXITCODE -eq 0 -and $result -match "Connection successful") {
        Write-Success "SSH connection successful"
        return $true
    } else {
        Write-Error "SSH connection failed"
        Write-Info "Please check:"
        Write-Info "  1. Network connection"
        Write-Info "  2. Remote server IP: $REMOTE_HOST"
        Write-Info "  3. SSH service running"
        Write-Info "  4. SSH key or password"
        return $false
    }
}

function Get-RemoteOS {
    Write-Info "Getting remote OS information..."
    
    $osInfo = Invoke-RemoteCommand "cat /etc/os-release"
    
    if ($LASTEXITCODE -eq 0) {
        $osName = Invoke-RemoteCommand "grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '\"'"
        $osVersion = Invoke-RemoteCommand "grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '\"'"
        
        Write-Success "OS: $osName"
        Write-Info "Version: $osVersion"
        
        return $osName
    } else {
        Write-Error "Cannot get OS information"
        return ""
    }
}

function Check-NodeJS {
    Write-Info "Checking Node.js installation..."
    
    $nodeVersion = Invoke-RemoteCommand "node --version"
    
    if ($LASTEXITCODE -eq 0 -and $nodeVersion -notmatch "command not found") {
        Write-Success "Node.js installed: $nodeVersion"
        
        $majorVersion = $nodeVersion -replace 'v(\d+).*', '$1'
        if ([int]$majorVersion -lt 18) {
            Write-Warning "Node.js version too low: $nodeVersion (recommend 18 or higher)"
            return $false
        }
        
        return $true
    } else {
        Write-Warning "Node.js not installed"
        return $false
    }
}

function Install-NodeJS {
    Write-Info "Installing Node.js 18..."
    
    $osName = Get-RemoteOS
    
    if ($osName -eq "ubuntu" -or $osName -eq "debian") {
        $installCommand = @"
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
"@
        
        Invoke-RemoteCommand $installCommand
    } elseif ($osName -eq "centos" -or $osName -eq "rhel" -or $osName -eq "fedora") {
        $installCommand = @"
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs
"@
        
        Invoke-RemoteCommand $installCommand
    } else {
        Write-Error "Unsupported OS: $osName"
        return $false
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Node.js 18 installed successfully"
        return $true
    } else {
        Write-Error "Failed to install Node.js"
        return $false
    }
}

function Copy-Files {
    Write-Info "Copying files to remote server..."
    Write-Info "This may take several minutes, please wait..."
    
    # Create remote directory
    Invoke-RemoteCommand "mkdir -p $REMOTE_DIR"
    
    # Copy backend files
    Write-Info "Copying backend files..."
    $backendCopy = "scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null `"$LOCAL_DIR\backend`" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
    Invoke-Expression $backendCopy
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to copy backend files"
        return $false
    }
    
    Write-Success "Backend files copied successfully"
    
    # Copy frontend files
    Write-Info "Copying frontend files..."
    $frontendCopy = "scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null `"$LOCAL_DIR\frontend`" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
    Invoke-Expression $frontendCopy
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to copy frontend files"
        return $false
    }
    
    Write-Success "Frontend files copied successfully"
    
    # Copy config files
    if (Test-Path "$LOCAL_DIR\config" -PathType Container) {
        Write-Info "Copying config files..."
        $configCopy = "scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null `"$LOCAL_DIR\config`" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
        Invoke-Expression $configCopy
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to copy config files"
            return $false
        }
        
        Write-Success "Config files copied successfully"
    }
    
    return $true
}

function Install-Dependencies {
    Write-Info "Installing dependencies..."
    
    # Install backend dependencies
    Write-Info "Installing backend dependencies..."
    $backendInstall = Invoke-RemoteCommand "cd $REMOTE_DIR/backend && npm install --production"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install backend dependencies"
        return $false
    }
    
    Write-Success "Backend dependencies installed successfully"
    
    # Install frontend dependencies
    Write-Info "Installing frontend dependencies..."
    $frontendInstall = Invoke-RemoteCommand "cd $REMOTE_DIR/frontend && npm install"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install frontend dependencies"
        return $false
    }
    
    Write-Success "Frontend dependencies installed successfully"
    
    return $true
}

function Build-Frontend {
    Write-Info "Building frontend..."
    
    $buildCommand = Invoke-RemoteCommand "cd $REMOTE_DIR/frontend && npm run build"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build frontend"
        return $false
    }
    
    Write-Success "Frontend built successfully"
    return $true
}

function Start-Services {
    Write-Info "Starting services..."
    
    # Check if backend is already running
    $backendRunning = Invoke-RemoteCommand "pgrep -f 'node.*backend/server.js'"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Warning "Backend is already running, stopping..."
        Invoke-RemoteCommand "pkill -f 'node.*backend/server.js'"
        Start-Sleep -Seconds 3
    }
    
    # Check if frontend is already running
    $frontendRunning = Invoke-RemoteCommand "pgrep -f 'npm.*preview'"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Warning "Frontend is already running, stopping..."
        Invoke-RemoteCommand "pkill -f 'npm.*preview'"
        Start-Sleep -Seconds 3
    }
    
    # Start backend
    Write-Info "Starting backend service..."
    $backendStart = Invoke-RemoteCommand "cd $REMOTE_DIR/backend && nohup npm start > backend.log 2>&1 &"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start backend service"
        return $false
    }
    
    Write-Success "Backend service started"
    
    # Wait for backend to start
    Start-Sleep -Seconds 5
    
    # Start frontend
    Write-Info "Starting frontend service..."
    $frontendStart = Invoke-RemoteCommand "cd $REMOTE_DIR/frontend && nohup npm run preview > frontend.log 2>&1 &"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start frontend service"
        return $false
    }
    
    Write-Success "Frontend service started"
    
    return $true
}

function Verify-Services {
    Write-Info "Verifying services..."
    
    # Check backend process
    $backendProcess = Invoke-RemoteCommand "pgrep -f 'node.*backend/server.js'"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Backend process is running"
    } else {
        Write-Error "Backend process is not running"
        return $false
    }
    
    # Check frontend process
    $frontendProcess = Invoke-RemoteCommand "pgrep -f 'npm.*preview'"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Frontend process is running"
    } else {
        Write-Error "Frontend process is not running"
        return $false
    }
    
    # Check backend port
    $backendPort = Invoke-RemoteCommand "netstat -tuln | grep ':3001'"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Backend is listening on port 3001"
    } else {
        Write-Warning "Backend port 3001 is not listening (may still be starting)"
    }
    
    # Check frontend port
    $frontendPort = Invoke-RemoteCommand "netstat -tuln | grep ':80'"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Frontend is listening on port 80"
    } else {
        Write-Warning "Frontend port 80 is not listening (may still be starting)"
    }
    
    return $true
}

function Main {
    Write-Separator
    Write-ColorOutput "Remote Deployment Script" $COLOR_SUCCESS
    Write-Separator
    Write-ColorOutput ""
    
    Write-Info "Local Directory: $LOCAL_DIR"
    Write-Info "Remote Server: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}"
    Write-ColorOutput ""
    
    # Step 1: Test SSH connection
    Write-Step "1" "Test SSH Connection"
    if (-not (Test-SSHConnection)) {
        Write-Error "SSH connection failed, deployment stopped"
        exit 1
    }
    Write-ColorOutput ""
    
    # Step 2: Get OS information
    Write-Step "2" "Get OS Information"
    $osName = Get-RemoteOS
    if ([string]::IsNullOrEmpty($osName)) {
        Write-Error "Cannot get OS information, deployment stopped"
        exit 1
    }
    Write-ColorOutput ""
    
    # Step 3: Check Node.js
    Write-Step "3" "Check Node.js Installation"
    $nodeInstalled = Check-NodeJS
    if (-not $nodeInstalled) {
        Write-Info "Installing Node.js..."
        if (-not (Install-NodeJS)) {
            Write-Error "Failed to install Node.js, deployment stopped"
            exit 1
        }
    }
    Write-ColorOutput ""
    
    # Step 4: Copy files
    Write-Step "4" "Copy Files to Remote Server"
    if (-not (Copy-Files)) {
        Write-Error "Failed to copy files, deployment stopped"
        exit 1
    }
    Write-ColorOutput ""
    
    # Step 5: Install dependencies
    Write-Step "5" "Install Dependencies"
    if (-not (Install-Dependencies)) {
        Write-Error "Failed to install dependencies, deployment stopped"
        exit 1
    }
    Write-ColorOutput ""
    
    # Step 6: Build frontend
    Write-Step "6" "Build Frontend"
    if (-not (Build-Frontend)) {
        Write-Error "Failed to build frontend, deployment stopped"
        exit 1
    }
    Write-ColorOutput ""
    
    # Step 7: Start services
    Write-Step "7" "Start Services"
    if (-not (Start-Services)) {
        Write-Error "Failed to start services, deployment stopped"
        exit 1
    }
    Write-ColorOutput ""
    
    # Step 8: Verify services
    Write-Step "8" "Verify Services"
    if (-not (Verify-Services)) {
        Write-Warning "Service verification failed, but deployment completed"
    }
    Write-ColorOutput ""
    
    # Deployment completed
    Write-Separator
    Write-Success "Deployment completed successfully!"
    Write-Separator
    Write-ColorOutput ""
    
    Write-Info "Access URLs:"
    Write-Info "  Frontend: http://${REMOTE_HOST}:80"
    Write-Info "  Backend:  http://${REMOTE_HOST}:3001"
    Write-ColorOutput ""
    
    Write-Info "To view logs:"
    Write-Info "  Backend: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tail -f $REMOTE_DIR/backend/backend.log'"
    Write-Info "  Frontend: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tail -f $REMOTE_DIR/frontend/frontend.log'"
    Write-ColorOutput ""
    
    Write-Info "To stop services:"
    Write-Info "  ssh ${REMOTE_USER}@${REMOTE_HOST} 'pkill -f node'"
    Write-ColorOutput ""
}

# Execute main function
Main
