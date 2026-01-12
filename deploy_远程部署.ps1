# 综合布线记录管理系统 - 远程服务器部署脚本
# 服务器信息
$SERVER = "192.168.19.58"
$USERNAME = "yroot"
$PASSWORD = "Yovole@2026"
$REMOTE_DIR = "/opt/sjzx-zonghebuxian"
$LOCAL_DIR = "D:\TREA\sjzx-zonghebuxian"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  综合布线记录管理系统 - 远程部署脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 步骤1：检查本地文件
Write-Host "步骤1: 检查本地文件..." -ForegroundColor Yellow
$requiredDirs = @("backend", "frontend", "config")
$requiredFiles = @("deploy_自动部署.sh", "deploy_服务器使用说明.md", "deploy_部署技术细节.md")

foreach ($dir in $requiredDirs) {
    $path = Join-Path $LOCAL_DIR $dir
    if (Test-Path $path) {
        Write-Host "  ✓ 找到目录: $dir" -ForegroundColor Green
    } else {
        Write-Host "  ✗ 未找到目录: $dir" -ForegroundColor Red
        exit 1
    }
}

foreach ($file in $requiredFiles) {
    $path = Join-Path $LOCAL_DIR $file
    if (Test-Path $path) {
        Write-Host "  ✓ 找到文件: $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ 未找到文件: $file" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# 步骤2：创建远程目录
Write-Host "步骤2: 创建远程目录..." -ForegroundColor Yellow
$sshCommand = "ssh $USERNAME@$SERVER `"mkdir -p $REMOTE_DIR`""
Write-Host "执行命令: $sshCommand" -ForegroundColor Gray
Invoke-Expression $sshCommand
Write-Host "  ✓ 远程目录创建完成" -ForegroundColor Green
Write-Host ""

# 步骤3：上传文件
Write-Host "步骤3: 上传文件到服务器..." -ForegroundColor Yellow
Write-Host "注意: 每次上传都需要输入密码" -ForegroundColor Yellow
Write-Host ""

# 上传backend目录
Write-Host "正在上传 backend/ 目录..." -ForegroundColor Cyan
$scpCommand = "scp -r `"$LOCAL_DIR\backend`" ${USERNAME}@${SERVER}:${REMOTE_DIR}/"
Write-Host "执行命令: $scpCommand" -ForegroundColor Gray
Invoke-Expression $scpCommand
Write-Host "  ✓ backend/ 上传完成" -ForegroundColor Green
Write-Host ""

# 上传frontend目录
Write-Host "正在上传 frontend/ 目录..." -ForegroundColor Cyan
$scpCommand = "scp -r `"$LOCAL_DIR\frontend`" ${USERNAME}@${SERVER}:${REMOTE_DIR}/"
Write-Host "执行命令: $scpCommand" -ForegroundColor Gray
Invoke-Expression $scpCommand
Write-Host "  ✓ frontend/ 上传完成" -ForegroundColor Green
Write-Host ""

# 上传config目录
Write-Host "正在上传 config/ 目录..." -ForegroundColor Cyan
$scpCommand = "scp -r `"$LOCAL_DIR\config`" ${USERNAME}@${SERVER}:${REMOTE_DIR}/"
Write-Host "执行命令: $scpCommand" -ForegroundColor Gray
Invoke-Expression $scpCommand
Write-Host "  ✓ config/ 上传完成" -ForegroundColor Green
Write-Host ""

# 上传部署脚本
Write-Host "正在上传部署脚本..." -ForegroundColor Cyan
$scpCommand = "scp `"$LOCAL_DIR\deploy_自动部署.sh`" ${USERNAME}@${SERVER}:${REMOTE_DIR}/"
Write-Host "执行命令: $scpCommand" -ForegroundColor Gray
Invoke-Expression $scpCommand
Write-Host "  ✓ deploy_自动部署.sh 上传完成" -ForegroundColor Green
Write-Host ""

# 上传文档
Write-Host "正在上传文档..." -ForegroundColor Cyan
$scpCommand = "scp `"$LOCAL_DIR\deploy_服务器使用说明.md`" ${USERNAME}@${SERVER}:${REMOTE_DIR}/"
Write-Host "执行命令: $scpCommand" -ForegroundColor Gray
Invoke-Expression $scpCommand
Write-Host "  ✓ deploy_服务器使用说明.md 上传完成" -ForegroundColor Green

$scpCommand = "scp `"$LOCAL_DIR\deploy_部署技术细节.md`" ${USERNAME}@${SERVER}:${REMOTE_DIR}/"
Write-Host "执行命令: $scpCommand" -ForegroundColor Gray
Invoke-Expression $scpCommand
Write-Host "  ✓ deploy_部署技术细节.md 上传完成" -ForegroundColor Green
Write-Host ""

# 步骤4：设置脚本执行权限
Write-Host "步骤4: 设置脚本执行权限..." -ForegroundColor Yellow
$sshCommand = "ssh $USERNAME@$SERVER `"chmod +x $REMOTE_DIR/deploy_自动部署.sh`""
Write-Host "执行命令: $sshCommand" -ForegroundColor Gray
Invoke-Expression $sshCommand
Write-Host "  ✓ 执行权限设置完成" -ForegroundColor Green
Write-Host ""

# 完成
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  文件上传完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步操作:" -ForegroundColor Yellow
Write-Host "1. SSH登录服务器:" -ForegroundColor White
Write-Host "   ssh $USERNAME@$SERVER" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 进入项目目录:" -ForegroundColor White
Write-Host "   cd $REMOTE_DIR" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 执行自动部署脚本:" -ForegroundColor White
Write-Host "   ./deploy_自动部署.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "4. 部署完成后，在浏览器中访问:" -ForegroundColor White
Write-Host "   http://$SERVER" -ForegroundColor Cyan
Write-Host ""
Write-Host "详细部署指南请查看: deploy_远程部署完整指南.md" -ForegroundColor Gray
Write-Host ""
