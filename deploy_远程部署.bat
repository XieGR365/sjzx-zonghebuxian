@echo off
chcp 65001 >nul
echo ========================================
echo   综合布线记录管理系统 - 远程部署脚本
echo ========================================
echo.
echo 服务器信息:
echo   地址: 192.168.19.58
echo   用户名: yroot
echo   密码: Yovole@2026
echo.
echo ========================================
echo.

set SERVER=192.168.19.58
set USERNAME=yroot
set REMOTE_DIR=/opt/sjzx-zonghebuxian
set LOCAL_DIR=D:\TREA\sjzx-zonghebuxian

echo 步骤1: 创建远程目录...
echo 请输入密码: Yovole@2026
ssh %USERNAME%@%SERVER% "mkdir -p %REMOTE_DIR%"
echo.
echo ✓ 远程目录创建完成
echo.
pause

echo ========================================
echo 步骤2: 上传文件到服务器...
echo ========================================
echo 注意: 每次上传都需要输入密码
echo.

echo [1/6] 正在上传 backend/ 目录...
scp -r "%LOCAL_DIR%\backend" %USERNAME%@%SERVER%:%REMOTE_DIR%/
echo.

echo [2/6] 正在上传 frontend/ 目录...
scp -r "%LOCAL_DIR%\frontend" %USERNAME%@%SERVER%:%REMOTE_DIR%/
echo.

echo [3/6] 正在上传 config/ 目录...
scp -r "%LOCAL_DIR%\config" %USERNAME%@%SERVER%:%REMOTE_DIR%/
echo.

echo [4/6] 正在上传 deploy_自动部署.sh...
scp "%LOCAL_DIR%\deploy_自动部署.sh" %USERNAME%@%SERVER%:%REMOTE_DIR%/
echo.

echo [5/6] 正在上传 deploy_服务器使用说明.md...
scp "%LOCAL_DIR%\deploy_服务器使用说明.md" %USERNAME%@%SERVER%:%REMOTE_DIR%/
echo.

echo [6/6] 正在上传 deploy_部署技术细节.md...
scp "%LOCAL_DIR%\deploy_部署技术细节.md" %USERNAME%@%SERVER%:%REMOTE_DIR%/
echo.

echo ========================================
echo 步骤3: 设置脚本执行权限...
echo ========================================
ssh %USERNAME%@%SERVER% "chmod +x %REMOTE_DIR%/deploy_自动部署.sh"
echo.
echo ✓ 执行权限设置完成
echo.

echo ========================================
echo   文件上传完成！
echo ========================================
echo.
echo 下一步操作:
echo.
echo 1. SSH登录服务器:
echo    ssh %USERNAME%@%SERVER%
echo.
echo 2. 进入项目目录:
echo    cd %REMOTE_DIR%
echo.
echo 3. 执行自动部署脚本:
echo    ./deploy_自动部署.sh
echo.
echo 4. 部署完成后，在浏览器中访问:
echo    http://%SERVER%
echo.
echo 详细部署指南请查看: deploy_远程部署完整指南.md
echo.
pause
