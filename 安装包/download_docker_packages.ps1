# Ubuntu 22.04 Docker and Docker Compose Package Download Script (PowerShell Version)
# This script downloads Docker and Docker Compose offline installation packages for Ubuntu 22.04 (Jammy Jellyfish) LTS

Write-Host "==========================================" -ForegroundColor Blue
Write-Host "  Ubuntu 22.04 Docker Package Downloader" -ForegroundColor Blue
Write-Host "  (PowerShell Version)" -ForegroundColor Blue
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""

# Download URLs
$DOCKER_BASE_URL = "https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64"
$COMPOSE_URL = "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-linux-x86_64"

# Docker CE package list
$PACKAGES = @(
    "containerd.io_1.6.24-1_amd64.deb",
    "docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb",
    "docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb",
    "docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb",
    "docker-compose-plugin_2.24.6-1~ubuntu.22.04~jammy_amd64.deb"
)

# Download file function
function Download-File {
    param(
        [string]$Url,
        [string]$Filename
    )
    
    Write-Host "[INFO] Downloading: $Filename" -ForegroundColor Yellow
    
    try {
        # Check if file already exists
        if (Test-Path $Filename) {
            $existingSize = (Get-Item $Filename).Length
            $sizeMB = [math]::Round($existingSize / 1MB, 2)
            Write-Host "[SUCCESS] File exists: $Filename (Size: $sizeMB MB)" -ForegroundColor Green
            return $true
        }
        
        # Download file using WebClient
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $Filename)
        
        # Verify download
        if (Test-Path $Filename) {
            $fileSize = (Get-Item $Filename).Length
            $sizeMB = [math]::Round($fileSize / 1MB, 2)
            Write-Host "[SUCCESS] Download complete: $Filename (Size: $sizeMB MB)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERROR] Download failed: $Filename" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[ERROR] Download failed: $Filename" -ForegroundColor Red
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Download Docker CE packages
Write-Host "[INFO] Starting Docker CE package download..." -ForegroundColor Blue
Write-Host ""

$allSuccess = $true

foreach ($package in $PACKAGES) {
    $url = "$DOCKER_BASE_URL/$package"
    if (-not (Download-File -Url $url -Filename $package)) {
        $allSuccess = $false
    }
    Write-Host ""
}

# Download Docker Compose standalone
Write-Host "[INFO] Starting Docker Compose standalone download..." -ForegroundColor Blue

if (-not (Download-File -Url $COMPOSE_URL -Filename "docker-compose-linux-x86_64")) {
    $allSuccess = $false
}

Write-Host ""

# Display results
Write-Host "==========================================" -ForegroundColor Blue
if ($allSuccess) {
    Write-Host "[SUCCESS] All packages downloaded successfully!" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Some files failed to download, please check network connection and retry" -ForegroundColor Yellow
}
Write-Host "==========================================" -ForegroundColor Blue
Write-Host ""

# Display downloaded files
Write-Host "[INFO] Downloaded files:" -ForegroundColor Blue
Write-Host ""

Get-ChildItem -Filter "*.deb" -ErrorAction SilentlyContinue | ForEach-Object {
    $sizeMB = [math]::Round($_.Length / 1MB, 2)
    Write-Host "  - $($_.Name) ($sizeMB MB)" -ForegroundColor White
}

Get-ChildItem -Filter "docker-compose-linux-x86_64" -ErrorAction SilentlyContinue | ForEach-Object {
    $sizeMB = [math]::Round($_.Length / 1MB, 2)
    Write-Host "  - $($_.Name) ($sizeMB MB)" -ForegroundColor White
}

Write-Host ""
Write-Host "[INFO] Next steps:" -ForegroundColor Blue
Write-Host "  1. Upload all files in this directory to your Ubuntu 22.04 server" -ForegroundColor White
Write-Host "  2. Run on server: sudo bash install_docker_ubuntu2204.sh" -ForegroundColor White
Write-Host ""

if ($allSuccess) {
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
    Write-Host "Please check network connection and run the script again" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
