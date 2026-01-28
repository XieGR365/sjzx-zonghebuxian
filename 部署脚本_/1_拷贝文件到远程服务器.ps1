################################################################################
# 综合布线记录管理系统 - SSH文件拷贝脚本
# 
# 功能说明：
#   - 将本地项目文件拷贝到远程Linux服务器
#   - 执行前检查、拷贝、验证
#   - 遇到问题立即停止并反馈
#
# 使用方法：
#   1. 确保已安装PowerShell 7+
#   2. 确保SSH客户端可用（Windows 10/11自带或安装Git Bash）
#   3. 确保已安装rsync（可通过Git或cwrsync获得）
#   4. 以管理员身份运行PowerShell
#   5. 执行脚本: .\1_拷贝文件到远程服务器.ps1
#
# 作者：综合布线记录管理系统开发团队
# 日期：2026-01-20
################################################################################

# 配置变量
$REMOTE_HOST = "192.168.19.58"
$REMOTE_USER = "yroot"
$REMOTE_DIR = "~/sjzx-zonghebuxian"
$LOCAL_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# 日志文件
$LOG_FILE = "/tmp/deploy_copy_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# 颜色定义（PowerShell控制台颜色）
$COLOR_INFO = "Cyan"
$COLOR_SUCCESS = "Green"
$COLOR_ERROR = "Red"
$COLOR_WARNING = "Yellow"

################################################################################
# 工具函数
################################################################################

function Write-Info {
    param([string]$Message)
    Write-Host "[信息] " -ForegroundColor $COLOR_INFO -NoNewline
    Write-Host $Message
    Log-Message "INFO: $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] " -ForegroundColor $COLOR_SUCCESS -NoNewline
    Write-Host $Message
    Log-Message "SUCCESS: $Message"
}

function Write-Error {
    param([string]$Message)
    Write-Host "[✗] " -ForegroundColor $COLOR_ERROR -NoNewline
    Write-Host $Message
    Log-Message "ERROR: $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[⚠] " -ForegroundColor $COLOR_WARNING -NoNewline
    Write-Host $Message
    Log-Message "WARNING: $Message"
}

function Write-Separator {
    Write-Host "================================================================================"
}

function Log-Message {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" >> $LOG_FILE
}

function Test-CommandExists {
    param([string]$Command)
    $command = Get-Command $Command -ErrorAction SilentlyContinue
    return $null -ne $command
}

function Invoke-SSH {
    param(
        [string]$Command,
        [int]$Timeout = 10
    )
    $fullCommand = "ssh -o ConnectTimeout=$Timeout -o BatchMode=yes ${REMOTE_USER}@${REMOTE_HOST} `"$Command`""
    $output = Invoke-Expression $fullCommand 2>&1
    return $output
}

################################################################################
# 检查函数
################################################################################

function Test-LocalFiles {
    Write-Info "检查本地文件..."
    
    $allOk = $true
    
    # 检查后端目录
    if (-not (Test-Path "$LOCAL_DIR\backend" -PathType Container)) {
        Write-Error "后端目录不存在: $LOCAL_DIR\backend"
        $allOk = $false
    } else {
        Write-Success "后端目录存在"
    }
    
    # 检查前端目录
    if (-not (Test-Path "$LOCAL_DIR\frontend" -PathType Container)) {
        Write-Error "前端目录不存在: $LOCAL_DIR\frontend"
        $allOk = $false
    } else {
        Write-Success "前端目录存在"
    }
    
    # 检查配置目录
    if (-not (Test-Path "$LOCAL_DIR\config" -PathType Container)) {
        Write-Error "配置目录不存在: $LOCAL_DIR\config"
        $allOk = $false
    } else {
        Write-Success "配置目录存在"
    }
    
    # 检查后端package.json
    if (-not (Test-Path "$LOCAL_DIR\backend\package.json" -PathType Leaf)) {
        Write-Error "后端package.json不存在"
        $allOk = $false
    }
    
    # 检查前端package.json
    if (-not (Test-Path "$LOCAL_DIR\frontend\package.json" -PathType Leaf)) {
        Write-Error "前端package.json不存在"
        $allOk = $false
    }
    
    if (-not $allOk) {
        Log-Message "本地文件检查失败"
        return $false
    }
    
    Log-Message "本地文件检查通过"
    return $true
}

function Test-SSHConnection {
    Write-Info "检查SSH连接..."
    
    # 检查ssh命令
    if (-not (Test-CommandExists "ssh")) {
        Write-Error "SSH命令不可用"
        Write-Info "请安装SSH客户端或Git Bash"
        Log-Message "SSH命令不可用"
        return $false
    }
    
    # 检查rsync命令
    if (-not (Test-CommandExists "rsync")) {
        Write-Error "rsync命令不可用"
        Write-Info "请安装rsync（可通过Git或cwrsync获得）"
        Log-Message "rsync命令不可用"
        return $false
    }
    
    Write-Info "尝试连接到远程服务器 $REMOTE_HOST..."
    $result = Invoke-SSH "echo 'SSH连接成功'"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "无法连接到远程服务器 $REMOTE_HOST"
        Write-Info "请检查:"
        Write-Info "  1. 网络连接"
        Write-Info "  2. 远程服务器地址: $REMOTE_HOST"
        Write-Info "  3. SSH密钥配置（建议使用SSH密钥认证）"
        Log-Message "SSH连接失败: $REMOTE_HOST"
        return $false
    }
    
    Write-Success "SSH连接正常"
    Log-Message "SSH连接检查通过: $REMOTE_HOST"
    return $true
}

function Test-RemoteDiskSpace {
    Write-Info "检查远程服务器磁盘空间..."
    
    $remoteSpace = Invoke-SSH "df -h ~ | awk 'NR==2 {print \$4}'" | Out-String
    $remoteSpace = $remoteSpace.Trim()
    
    if ([string]::IsNullOrEmpty($remoteSpace)) {
        Write-Warning "无法获取远程服务器磁盘空间信息"
        Log-Message "无法获取远程磁盘空间"
        return $true
    }
    
    Write-Info "远程服务器可用空间: $remoteSpace"
    Log-Message "远程磁盘空间: $remoteSpace"
    return $true
}

################################################################################
# 拷贝函数
################################################################################

function Copy-BackendFiles {
    Write-Info "拷贝后端文件..."
    
    if (-not (Test-Path "$LOCAL_DIR\backend" -PathType Container)) {
        Write-Error "后端目录不存在"
        return $false
    }
    
    Write-Info "创建远程后端目录..."
    $result = Invoke-SSH "mkdir -p $REMOTE_DIR/backend"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "创建远程目录失败"
        Log-Message "创建远程目录失败: $REMOTE_DIR/backend"
        return $false
    }
    
    Write-Info "开始拷贝后端文件..."
    Write-Warning "这可能需要几分钟，请耐心等待..."
    
    # 构建rsync命令
    $rsyncCmd = "rsync -avz --progress"
    $rsyncCmd += " --exclude='node_modules/'"
    $rsyncCmd += " --exclude='dist/'"
    $rsyncCmd += " --exclude='*.log'"
    $rsyncCmd += " --exclude='test_*.js'"
    $rsyncCmd += " --exclude='check_*.js'"
    $rsyncCmd += " --exclude='create-test-excel.js'"
    $rsyncCmd += " --exclude='.env'"
    $rsyncCmd += " `"$LOCAL_DIR/backend/`""
    $rsyncCmd += " ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/backend/"
    
    Invoke-Expression $rsyncCmd 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "后端文件拷贝完成"
        Log-Message "后端文件拷贝成功"
        return $true
    } else {
        Write-Error "后端文件拷贝失败"
        Log-Message "后端文件拷贝失败"
        return $false
    }
}

function Copy-FrontendFiles {
    Write-Info "拷贝前端文件..."
    
    if (-not (Test-Path "$LOCAL_DIR\frontend" -PathType Container)) {
        Write-Error "前端目录不存在"
        return $false
    }
    
    Write-Info "创建远程前端目录..."
    $result = Invoke-SSH "mkdir -p $REMOTE_DIR/frontend"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "创建远程目录失败"
        Log-Message "创建远程目录失败: $REMOTE_DIR/frontend"
        return $false
    }
    
    Write-Info "开始拷贝前端文件..."
    Write-Warning "这可能需要几分钟，请耐心等待..."
    
    # 构建rsync命令
    $rsyncCmd = "rsync -avz --progress"
    $rsyncCmd += " --exclude='node_modules/'"
    $rsyncCmd += " --exclude='dist/'"
    $rsyncCmd += " --exclude='.cache/'"
    $rsyncCmd += " --exclude='*.log'"
    $rsyncCmd += " --exclude='.env'"
    $rsyncCmd += " `"$LOCAL_DIR/frontend/`""
    $rsyncCmd += " ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/frontend/"
    
    Invoke-Expression $rsyncCmd 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "前端文件拷贝完成"
        Log-Message "前端文件拷贝成功"
        return $true
    } else {
        Write-Error "前端文件拷贝失败"
        Log-Message "前端文件拷贝失败"
        return $false
    }
}

function Copy-ConfigFiles {
    Write-Info "拷贝配置文件..."
    
    if (-not (Test-Path "$LOCAL_DIR\config" -PathType Container)) {
        Write-Error "配置目录不存在"
        return $false
    }
    
    Write-Info "创建远程配置目录..."
    $result = Invoke-SSH "mkdir -p $REMOTE_DIR/config"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "创建远程目录失败"
        Log-Message "创建远程目录失败: $REMOTE_DIR/config"
        return $false
    }
    
    Write-Info "开始拷贝配置文件..."
    
    # 构建rsync命令
    $rsyncCmd = "rsync -avz --progress"
    $rsyncCmd += " --exclude='*.log'"
    $rsyncCmd += " `"$LOCAL_DIR/config/`""
    $rsyncCmd += " ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/config/"
    
    Invoke-Expression $rsyncCmd 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "配置文件拷贝完成"
        Log-Message "配置文件拷贝成功"
        return $true
    } else {
        Write-Error "配置文件拷贝失败"
        Log-Message "配置文件拷贝失败"
        return $false
    }
}

function Copy-DocFiles {
    Write-Info "拷贝文档文件..."
    
    # 检查说明文档目录
    if (-not (Test-Path "$LOCAL_DIR\06-说明文档" -PathType Container)) {
        Write-Warning "说明文档目录不存在，跳过"
        return $true
    }
    
    Write-Info "创建远程文档目录..."
    Invoke-SSH "mkdir -p $REMOTE_DIR/06-说明文档"
    
    Write-Info "拷贝说明文档..."
    
    $rsyncCmd = "rsync -avz --progress"
    $rsyncCmd += " `"$LOCAL_DIR/06-说明文档/`""
    $rsyncCmd += " ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/06-说明文档/"
    
    Invoke-Expression $rsyncCmd 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
    
    # 检查部署文档目录
    if (Test-Path "$LOCAL_DIR\07-部署文档" -PathType Container) {
        Invoke-SSH "mkdir -p $REMOTE_DIR/07-部署文档"
        Write-Info "拷贝部署文档..."
        
        $rsyncCmd = "rsync -avz --progress"
        $rsyncCmd += " `"$LOCAL_DIR/07-部署文档/`""
        $rsyncCmd += " ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/07-部署文档/"
        
        Invoke-Expression $rsyncCmd 2>&1 | Tee-Object -FilePath $LOG_FILE -Append
    }
    
    Write-Success "文档文件拷贝完成"
    Log-Message "文档文件拷贝成功"
    return $true
}

################################################################################
# 验证函数
################################################################################

function Test-CopyResult {
    Write-Info "验证文件拷贝结果..."
    
    $allOk = $true
    
    # 验证后端文件
    $backendCheck = Invoke-SSH "test -d $REMOTE_DIR/backend ; test -f $REMOTE_DIR/backend/package.json"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "后端文件验证失败"
        $allOk = $false
    } else {
        Write-Success "后端文件验证通过"
    }
    
    # 验证前端文件
    $frontendCheck = Invoke-SSH "test -d $REMOTE_DIR/frontend ; test -f $REMOTE_DIR/frontend/package.json"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "前端文件验证失败"
        $allOk = $false
    } else {
        Write-Success "前端文件验证通过"
    }
    
    # 验证配置文件
    $configCheck = Invoke-SSH "[ -d $REMOTE_DIR/config ]"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "配置文件验证失败"
        $allOk = $false
    } else {
        Write-Success "配置文件验证通过"
    }
    
    if (-not $allOk) {
        Log-Message "文件验证失败"
        return $false
    }
    
    Log-Message "文件验证通过"
    return $true
}

################################################################################
# 主函数
################################################################################

function Main {
    Write-Separator
    Write-Host "综合布线记录管理系统 - SSH文件拷贝脚本" -ForegroundColor $COLOR_SUCCESS
    Write-Separator
    Write-Host ""
    
    Write-Info "开始时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Info "本地目录: $LOCAL_DIR"
    Write-Info "远程服务器: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}"
    Write-Host ""
    
    Write-Info "日志文件: $LOG_FILE"
    Write-Host ""
    
    # 步骤1: 检查本地文件
    Write-Separator
    Write-Info "步骤1: 检查本地文件"
    Write-Separator
    if (-not (Test-LocalFiles)) {
        Write-Error "本地文件检查失败，停止执行"
        Write-Info "请检查本地项目结构"
        exit 1
    }
    Write-Host ""
    
    # 步骤2: 检查SSH连接
    Write-Separator
    Write-Info "步骤2: 检查SSH连接"
    Write-Separator
    if (-not (Test-SSHConnection)) {
        Write-Error "SSH连接检查失败，停止执行"
        Write-Info "请检查SSH配置"
        exit 1
    }
    Write-Host ""
    
    # 步骤3: 检查远程磁盘空间
    Write-Separator
    Write-Info "步骤3: 检查远程磁盘空间"
    Write-Separator
    if (-not (Test-RemoteDiskSpace)) {
        Write-Warning "磁盘空间检查失败，但继续执行"
    }
    Write-Host ""
    
    # 步骤4: 拷贝后端文件
    Write-Separator
    Write-Info "步骤4: 拷贝后端文件"
    Write-Separator
    if (-not (Copy-BackendFiles)) {
        Write-Error "后端文件拷贝失败，停止执行"
        Write-Info "请查看日志: $LOG_FILE"
        exit 1
    }
    Write-Host ""
    
    # 步骤5: 拷贝前端文件
    Write-Separator
    Write-Info "步骤5: 拷贝前端文件"
    Write-Separator
    if (-not (Copy-FrontendFiles)) {
        Write-Error "前端文件拷贝失败，停止执行"
        Write-Info "请查看日志: $LOG_FILE"
        exit 1
    }
    Write-Host ""
    
    # 步骤6: 拷贝配置文件
    Write-Separator
    Write-Info "步骤6: 拷贝配置文件"
    Write-Separator
    if (-not (Copy-ConfigFiles)) {
        Write-Error "配置文件拷贝失败，停止执行"
        Write-Info "请查看日志: $LOG_FILE"
        exit 1
    }
    Write-Host ""
    
    # 步骤7: 拷贝文档文件
    Write-Separator
    Write-Info "步骤7: 拷贝文档文件"
    Write-Separator
    if (-not (Copy-DocFiles)) {
        Write-Warning "文档文件拷贝失败，但继续执行"
    }
    Write-Host ""
    
    # 步骤8: 验证拷贝结果
    Write-Separator
    Write-Info "步骤8: 验证拷贝结果"
    Write-Separator
    if (-not (Test-CopyResult)) {
        Write-Error "文件验证失败，停止执行"
        Write-Info "请查看日志: $LOG_FILE"
        exit 1
    }
    Write-Host ""
    
    # 完成
    Write-Separator
    Write-Success "所有文件拷贝完成！"
    Write-Separator
    Write-Host ""
    Write-Info "完成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Info "日志文件: $LOG_FILE"
    Write-Host ""
    Write-Info "下一步: 运行 2_启动服务.ps1 启动前端和后端服务"
    Write-Host ""
}

# 执行主函数
Main
