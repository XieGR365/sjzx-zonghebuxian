# Remote Deployment Script with Password Authentication
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

function Test-SSHConnection {
    Write-Info "Testing SSH connection to ${REMOTE_USER}@${REMOTE_HOST}..."
    
    try {
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
    } catch {
        Write-Error "SSH connection error: $($_.Exception.Message)"
        return $false
    }
}

function Invoke-RemoteCommand {
    param(
        [string]$Command,
        [int]$Timeout = 300
    )
    
    $fullCommand = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=$Timeout ${REMOTE_USER}@${REMOTE_HOST} `"$Command`""
    
    try {
        $output = Invoke-Expression $fullCommand 2>&1
        
        if ($output -match "password:") {
            Write-Error "SSH requires password authentication"
            Write-Info "Please configure SSH key authentication first"
            Write-Info "Run: .\setup_ssh_key.ps1"
            $global:LASTEXITCODE = 1
            return $null
        }
        
        return $output
    } catch {
        Write-Error "Command execution error: $($_.Exception.Message)"
        $global:LASTEXITCODE = 1
        return $null
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
        Write-Info "Please ensure SSH key authentication is set up"
        Write-Info "Or use the setup_ssh_key.ps1 script to configure SSH keys"
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
    
    # Copy config files if exists
    if (Test-Path "$LOCAL_DIR\config" -PathType Container) {
        Write-Info "Copying config files..."
        $configCopy = "scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null `"$LOCAL_DIR\config`" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
        Invoke-Expression $configCopy
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to copy config files (continuing...)"
        } else {
            Write-Success "Config files copied successfully"
        }
    }
    
    # Copy package.json files if they exist at root
    if (Test-Path "$LOCAL_DIR\package.json" -PathType Leaf) {
        Write-Info "Copying root package.json..."
        $rootPackageCopy = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null `"$LOCAL_DIR\package.json`" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
        Invoke-Expression $rootPackageCopy
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Root package.json copied successfully"
        }
    }
    
    return $true
}

function Get-RemoteOS {
    Write-Info "Getting remote OS information..."
    
    try {
        $osInfo = Invoke-RemoteCommand "cat /etc/os-release"
        
        if ($LASTEXITCODE -eq 0) {
            # Use simple command without pipe
            $osName = Invoke-RemoteCommand "cat /etc/os-release | head -1"
            $osName = $osName -replace 'ID=', ''
            $osName = $osName -replace '"', ''
            
            $osVersion = Invoke-RemoteCommand "cat /etc/os-release | head -2 | tail -1"
            $osVersion = $osVersion -replace 'VERSION_ID=', ''
            $osVersion = $osVersion -replace '"', ''
            
            Write-Success "OS: $osName"
            Write-Info "Version: $osVersion"
            
            return $osName
        } else {
            Write-Error "Cannot get OS information"
            return ""
        }
    } catch {
        Write-Error "Error getting OS information: $($_.Exception.Message)"
        return ""
    }
}

function Check-NodeJS {
    Write-Info "Checking Node.js installation..."
    
    try {
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
    } catch {
        Write-Error "Error checking Node.js: $($_.Exception.Message)"
        return $false
    }
}

function Install-NodeJS {
    Write-Info "Installing Node.js 18..."
    
    try {
        $osName = Get-RemoteOS
        
        if ([string]::IsNullOrEmpty($osName)) {
            Write-Error "Cannot determine OS type"
            return $false
        }
        
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
            Write-Info "Please install Node.js 18 manually on the server"
            return $false
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Node.js 18 installed successfully"
            return $true
        } else {
            Write-Error "Failed to install Node.js"
            Write-Info "Please install Node.js 18 manually on the server"
            return $false
        }
    } catch {
        Write-Error "Error installing Node.js: $($_.Exception.Message)"
        return $false
    }
}

function Install-Dependencies {
    Write-Info "Installing dependencies..."
    
    try {
        # Install backend dependencies
        Write-Info "Installing backend dependencies..."
        $backendInstall = Invoke-RemoteCommand "cd $REMOTE_DIR/backend && npm install --production"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install backend dependencies"
            Write-Info "Error output: $backendInstall"
            return $false
        }
        
        Write-Success "Backend dependencies installed successfully"
        
        # Install frontend dependencies
        Write-Info "Installing frontend dependencies..."
        $frontendInstall = Invoke-RemoteCommand "cd $REMOTE_DIR/frontend && npm install"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install frontend dependencies"
            Write-Info "Error output: $frontendInstall"
            return $false
        }
        
        Write-Success "Frontend dependencies installed successfully"
        
        return $true
    } catch {
        Write-Error "Error installing dependencies: $($_.Exception.Message)"
        return $false
    }
}

function Build-Frontend {
    Write-Info "Building frontend..."
    
    try {
        $buildCommand = Invoke-RemoteCommand "cd $REMOTE_DIR/frontend && npm run build"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to build frontend"
            Write-Info "Error output: $buildCommand"
            return $false
        }
        
        Write-Success "Frontend built successfully"
        return $true
    } catch {
        Write-Error "Error building frontend: $($_.Exception.Message)"
        return $false
    }
}

function Start-Services {
    Write-Info "Starting services..."
    
    try {
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
    } catch {
        Write-Error "Error starting services: $($_.Exception.Message)"
        return $false
    }
}

function Verify-Services {
    Write-Info "Verifying services..."
    
    try {
        # Check backend process
        $backendProcess = Invoke-RemoteCommand "pgrep -f 'node.*backend/server.js'"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Backend process is running (PID: $backendProcess)"
        } else {
            Write-Error "Backend process is not running"
            return $false
        }
        
        # Check frontend process
        $frontendProcess = Invoke-RemoteCommand "pgrep -f 'npm.*preview'"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Frontend process is running (PID: $frontendProcess)"
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
    } catch {
        Write-Error "Error verifying services: $($_.Exception.Message)"
        return $false
    }
}

function Main {
    Write-Separator
    Write-ColorOutput "Remote Deployment Script" $COLOR_SUCCESS
    Write-Separator
    Write-ColorOutput ""
    
    Write-Info "Local Directory: $LOCAL_DIR"
    Write-Info "Remote Server: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}"
    Write-ColorOutput ""
    
    Write-Warning "This script requires SSH key authentication to be configured."
    Write-Info "If you haven't set up SSH keys, please run: setup_ssh_key.ps1"
    Write-ColorOutput ""
    
    # Step 1: Test SSH connection
    Write-Step "1" "Test SSH Connection"
    if (-not (Test-SSHConnection)) {
        Write-Error "SSH connection failed, deployment stopped"
        Write-Info "Please ensure SSH key authentication is configured"
        Write-Info "Run setup_ssh_key.ps1 to configure SSH keys"
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
            Write-Info "Please install Node.js 18 manually on the server"
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
    
    exit 0
}

# Execute main function
Main
