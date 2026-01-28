# 简单文件拷贝脚本
# 使用scp命令拷贝文件到远程服务器

$REMOTE_HOST = "192.168.19.58"
$REMOTE_USER = "yroot"
$REMOTE_DIR = "~/sjzx-zonghebuxian"
$LOCAL_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "文件拷贝到远程服务器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "本地目录: $LOCAL_DIR" -ForegroundColor Yellow
Write-Host "远程服务器: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}" -ForegroundColor Yellow
Write-Host ""

# 检查本地目录
if (-not (Test-Path "$LOCAL_DIR\backend" -PathType Container)) {
    Write-Host "错误: 后端目录不存在" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "$LOCAL_DIR\frontend" -PathType Container)) {
    Write-Host "错误: 前端目录不存在" -ForegroundColor Red
    exit 1
}

Write-Host "开始拷贝文件..." -ForegroundColor Yellow
Write-Host ""

# 拷贝后端文件
Write-Host "1. 拷贝后端文件..." -ForegroundColor Yellow
Write-Host "   这可能需要几分钟，请耐心等待..." -ForegroundColor Cyan
Write-Host ""

scp -r "$LOCAL_DIR\backend" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 后端文件拷贝失败" -ForegroundColor Red
    exit 1
}

Write-Host "   ✓ 后端文件拷贝完成" -ForegroundColor Green
Write-Host ""

# 拷贝前端文件
Write-Host "2. 拷贝前端文件..." -ForegroundColor Yellow
Write-Host "   这可能需要几分钟，请耐心等待..." -ForegroundColor Cyan
Write-Host ""

scp -r "$LOCAL_DIR\frontend" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 前端文件拷贝失败" -ForegroundColor Red
    exit 1
}

Write-Host "   ✓ 前端文件拷贝完成" -ForegroundColor Green
Write-Host ""

# 拷贝配置文件
Write-Host "3. 拷贝配置文件..." -ForegroundColor Yellow
Write-Host ""

if (Test-Path "$LOCAL_DIR\config" -PathType Container) {
    scp -r "$LOCAL_DIR\config" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "错误: 配置文件拷贝失败" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "   ✓ 配置文件拷贝完成" -ForegroundColor Green
} else {
    Write-Host "   ⚠ 配置目录不存在，跳过" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "所有文件拷贝完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "下一步: SSH连接到服务器并运行安装脚本" -ForegroundColor Yellow
Write-Host "命令: ssh ${REMOTE_USER}@${REMOTE_HOST}" -ForegroundColor Cyan
Write-Host ""
