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

function Test-SSHConnection {
    Write-Separator
    Write-Info "Step 1: Check SSH connection"
    Write-Separator
    
    Write-Info "Testing SSH connection to ${REMOTE_USER}@${REMOTE_HOST}..."
    $result = Invoke-SSH "echo 'Connection successful'"
    
    if ($LASTEXITCODE -eq 0 -and $result -like "*Connection successful*") {
        Write-Success "SSH connection OK"
        return $true
    } else {
        Write-Error "SSH connection failed"
        Write-Info "Please check:"
        Write-Info "  1. Remote server IP: $REMOTE_HOST"
        Write-Info "  2. SSH service running"
        Write-Info "  3. Network connection"
        Write-Info "  4. SSH key or password"
        return $false
    }
}

function Get-OSInfo {
    Write-Separator
    Write-Info "Step 2: Check OS information"
    Write-Separator
    
    Write-Info "Getting OS information..."
    $osInfo = Invoke-SSH "cat /etc/os-release"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host $osInfo
        
        $osName = Invoke-SSH "grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '""'"
        $osVersion = Invoke-SSH "grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '""'"
        
        Write-Info "OS: $osName"
        Write-Info "Version: $osVersion"
        
        return $osName
    } else {
        Write-Error "Cannot get OS information"
        return $null
    }
}

function Check-NodeJS {
    Write-Separator
    Write-Info "Step 3: Check Node.js environment"
    Write-Separator
    
    Write-Info "Checking if Node.js is installed..."
    $nodeVersion = Invoke-SSH "node --version" | Out-String
    $nodeVersion = $nodeVersion.Trim()
    
    if ([string]::IsNullOrEmpty($nodeVersion) -or $nodeVersion -like "*command not found*") {
        Write-Warning "Node.js not installed"
        Write-Info "Need to install Node.js 18 or higher"
        return $false
    } else {
        Write-Success "Node.js installed: $nodeVersion"
        
        $majorVersion = [int]($nodeVersion -replace 'v(\d+).*', '$1')
        if ($majorVersion -lt 18) {
            Write-Warning "Node.js version too low: $nodeVersion (recommend 18 or higher)"
            return $false
        }
        
        return $true
    }
}

function Install-NodeJS {
    param([string]$OSName)
    
    Write-Separator
    Write-Info "Step 4: Install Node.js"
    Write-Separator
    
    Write-Warning "Starting Node.js 18 installation..."
    Write-Warning "This may take several minutes, please wait..."
    
    if ($OSName -eq "ubuntu") {
        Write-Info "Detected Ubuntu system, using apt..."
        
        Write-Info "Updating package list..."
        $result = Invoke-SSH "apt-get update"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to update package list"
            Write-Info "Please check network and apt source"
            return $false
        }
        Write-Success "Package list updated"
        
        Write-Info "Installing required tools..."
        $result = Invoke-SSH "apt-get install -y curl gnupg"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install tools"
            return $false
        }
        Write-Success "Tools installed"
        
        Write-Info "Adding Node.js 18.x repository..."
        $result = Invoke-SSH "curl -fsSL https://deb.nodesource.com/setup_18.x | bash -"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to add Node.js repository"
            Write-Info "Please check network connection"
            return $false
        }
        Write-Success "Node.js repository added"
        
        Write-Info "Installing Node.js..."
        $result = Invoke-SSH "apt-get install -y nodejs"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install Node.js"
            return $false
        }
        Write-Success "Node.js installed"
    }
    elseif ($OSName -eq "centos") {
        Write-Info "Detected CentOS system, using yum..."
        
        Write-Info "Installing required tools..."
        $result = Invoke-SSH "yum install -y curl"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install tools"
            return $false
        }
        Write-Success "Tools installed"
        
        Write-Info "Adding Node.js 18.x repository..."
        $result = Invoke-SSH "curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to add Node.js repository"
            Write-Info "Please check network connection"
            return $false
        }
        Write-Success "Node.js repository added"
        
        Write-Info "Installing Node.js..."
        $result = Invoke-SSH "yum install -y nodejs"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install Node.js"
            return $false
        }
        Write-Success "Node.js installed"
    }
    else {
        Write-Error "Unsupported OS: $OSName"
        Write-Info "Please manually install Node.js 18 or higher"
        Write-Info "Download: https://nodejs.org/"
        return $false
    }
    
    Write-Info "Verifying Node.js installation..."
    $nodeVersion = Invoke-SSH "node --version" | Out-String
    $nodeVersion = $nodeVersion.Trim()
    
    if ([string]::IsNullOrEmpty($nodeVersion) -or $nodeVersion -like "*command not found*") {
        Write-Error "Node.js installation verification failed"
        return $false
    } else {
        Write-Success "Node.js installed successfully: $nodeVersion"
        return $true
    }
}

function Check-NPM {
    Write-Separator
    Write-Info "Step 5: Check NPM environment"
    Write-Separator
    
    Write-Info "Checking if NPM is installed..."
    $npmVersion = Invoke-SSH "npm --version" | Out-String
    $npmVersion = $npmVersion.Trim()
    
    if ([string]::IsNullOrEmpty($npmVersion) -or $npmVersion -like "*command not found*") {
        Write-Warning "NPM not installed"
        Write-Info "NPM usually comes with Node.js"
        return $false
    } else {
        Write-Success "NPM installed: $npmVersion"
        return $true
    }
}

function Install-NPM {
    Write-Separator
    Write-Info "Step 6: Install NPM"
    Write-Separator
    
    Write-Warning "Starting NPM installation..."
    
    Write-Info "Installing npm using npm..."
    $result = Invoke-SSH "npm install -g npm"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install NPM"
        Write-Info "Trying to install using package manager..."
        
        $osName = Invoke-SSH "grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '""'"
        
        if ($osName -eq "ubuntu") {
            $result = Invoke-SSH "apt-get install -y npm"
        }
        elseif ($osName -eq "centos") {
            $result = Invoke-SSH "yum install -y npm"
        }
        else {
            Write-Error "Unsupported OS"
            return $false
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install NPM"
            return $false
        }
    }
    
    Write-Success "NPM installation completed"
    
    Write-Info "Verifying NPM installation..."
    $npmVersion = Invoke-SSH "npm --version" | Out-String
    $npmVersion = $npmVersion.Trim()
    
    if ([string]::IsNullOrEmpty($npmVersion) -or $npmVersion -like "*command not found*") {
        Write-Error "NPM installation verification failed"
        return $false
    } else {
        Write-Success "NPM installed successfully: $npmVersion"
        return $true
    }
}

function Check-DiskSpace {
    Write-Separator
    Write-Info "Step 7: Check disk space"
    Write-Separator
    
    Write-Info "Checking disk space..."
    $diskInfo = Invoke-SSH "df -h /"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host $diskInfo
        
        $diskLines = Invoke-SSH "df -h /" | Out-String
        $lines = $diskLines -split "`n"
        $dataLine = $lines[1]
        $parts = $dataLine -split "\s+"
        $availableSpace = $parts[3]
        
        Write-Info "Available disk space: $availableSpace"
        
        $availableGB = [double]($availableSpace -replace "G", "").Trim()
        if ($availableGB -lt 2) {
            Write-Warning "Disk space insufficient: $availableSpace (recommend at least 2GB)"
            Write-Info "Please clean up disk space"
            return $false
        } else {
            Write-Success "Disk space sufficient"
            return $true
        }
    } else {
        Write-Error "Cannot get disk information"
        return $false
    }
}

function Check-Ports {
    Write-Separator
    Write-Info "Step 8: Check port usage"
    Write-Separator
    
    $BACKEND_PORT = 3001
    $FRONTEND_PORT = 80
    
    Write-Info "Checking port usage..."
    
    $backendResult = Invoke-SSH "netstat -tuln 2>/dev/null | grep `":3001 `"" | Out-String
    $backendResult = $backendResult.Trim()
    
    if ([string]::IsNullOrEmpty($backendResult)) {
        Write-Success "Backend port $BACKEND_PORT available"
    } else {
        Write-Warning "Backend port $BACKEND_PORT is in use"
        $process = Invoke-SSH "lsof -i :$BACKEND_PORT 2>/dev/null"
        if ($LASTEXITCODE -ne 0) {
            $process = Invoke-SSH "netstat -tulpn 2>/dev/null | grep :$BACKEND_PORT"
        }
        Write-Info "Process using port:"
        Write-Host $process
    }
    
    $frontendResult = Invoke-SSH "netstat -tuln 2>/dev/null | grep `":80 `"" | Out-String
    $frontendResult = $frontendResult.Trim()
    
    if ([string]::IsNullOrEmpty($frontendResult)) {
        Write-Success "Frontend port $FRONTEND_PORT available"
    } else {
        Write-Warning "Frontend port $FRONTEND_PORT is in use"
        $process = Invoke-SSH "lsof -i :$FRONTEND_PORT 2>/dev/null"
        if ($LASTEXITCODE -ne 0) {
            $process = Invoke-SSH "netstat -tulpn 2>/dev/null | grep :$FRONTEND_PORT"
        }
        Write-Info "Process using port:"
        Write-Host $process
    }
    
    return $true
}

function Show-Summary {
    Write-Separator
    Write-Info "Environment check summary"
    Write-Separator
    
    Write-Info "Remote server: ${REMOTE_USER}@${REMOTE_HOST}"
    
    $nodeVersion = Invoke-SSH "node --version" | Out-String
    $nodeVersion = $nodeVersion.Trim()
    if ([string]::IsNullOrEmpty($nodeVersion) -or $nodeVersion -like "*command not found*") {
        Write-Error "Node.js: Not installed"
    } else {
        Write-Success "Node.js: $nodeVersion"
    }
    
    $npmVersion = Invoke-SSH "npm --version" | Out-String
    $npmVersion = $npmVersion.Trim()
    if ([string]::IsNullOrEmpty($npmVersion) -or $npmVersion -like "*command not found*") {
        Write-Error "NPM: Not installed"
    } else {
        Write-Success "NPM: $npmVersion"
    }
    
    $diskLines = Invoke-SSH "df -h /" | Out-String
    $lines = $diskLines -split "`n"
    $dataLine = $lines[1]
    $parts = $dataLine -split "\s+"
    $availableSpace = $parts[3]
    Write-Info "Disk space: $availableSpace available"
    
    Write-Separator
}

function Main {
    Write-Separator
    Write-Host "Cable Management System - Server Installation Script" -ForegroundColor $COLOR_SUCCESS
    Write-Separator
    Write-Host ""
    
    $startTime = Get-Date
    Write-Info "Start time: $startTime"
    Write-Host ""
    
    if (-not (Test-SSHConnection)) {
        Write-Error "SSH connection failed, stopping execution"
        return
    }
    Write-Host ""
    
    $osName = Get-OSInfo
    if ([string]::IsNullOrEmpty($osName)) {
        Write-Error "Cannot get OS information, stopping execution"
        return
    }
    Write-Host ""
    
    $nodeOk = Check-NodeJS
    Write-Host ""
    
    if (-not $nodeOk) {
        Write-Warning "Node.js not installed or version too low, need to install"
        $install = Read-Host "Continue to install Node.js? (y/n)"
        if ($install -ne "y" -and $install -ne "Y") {
            Write-Error "User cancelled installation, stopping execution"
            return
        }
        
        if (-not (Install-NodeJS -OSName $osName)) {
            Write-Error "Node.js installation failed, stopping execution"
            return
        }
        Write-Host ""
    }
    
    $npmOk = Check-NPM
    Write-Host ""
    
    if (-not $npmOk) {
        Write-Warning "NPM not installed, need to install"
        $install = Read-Host "Continue to install NPM? (y/n)"
        if ($install -ne "y" -and $install -ne "Y") {
            Write-Error "User cancelled installation, stopping execution"
            return
        }
        
        if (-not (Install-NPM)) {
            Write-Error "NPM installation failed, stopping execution"
            return
        }
        Write-Host ""
    }
    
    if (-not (Check-DiskSpace)) {
        Write-Error "Disk space insufficient, stopping execution"
        return
    }
    Write-Host ""
    
    Check-Ports
    Write-Host ""
    
    Show-Summary
    
    Write-Separator
    Write-Success "Environment check and installation completed!"
    Write-Separator
    Write-Host ""
    
    $endTime = Get-Date
    Write-Info "End time: $endTime"
    Write-Host ""
    Write-Info "Next steps:"
    Write-Info "  1. Run 1_拷贝文件到远程服务器.ps1 to copy project files"
    Write-Info "  2. Run 服务器启动.ps1 to start services"
    Write-Host ""
}

Main
