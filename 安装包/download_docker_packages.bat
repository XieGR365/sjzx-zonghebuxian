@echo off
REM Ubuntu 22.04 Docker 和 Docker Compose 安装包下载脚本 (Windows版本)
REM 本脚本用于下载Ubuntu 22.04 (Jammy Jellyfish) LTS系统的Docker和Docker Compose离线安装包

setlocal enabledelayedexpansion

echo ==========================================
echo   Ubuntu 22.04 Docker 安装包下载工具
echo   (Windows版本)
echo ==========================================
echo.

REM 检查curl是否可用
where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到curl命令
    echo 请确保curl已安装并添加到PATH环境变量
    pause
    exit /b 1
)

echo [信息] 找到下载工具: curl
echo.

REM 下载URL
set DOCKER_BASE_URL=https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64
set COMPOSE_URL=https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-linux-x86_64

REM Docker CE包列表
set PACKAGES[0]=containerd.io_1.6.24-1_amd64.deb
set PACKAGES[1]=docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
set PACKAGES[2]=docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
set PACKAGES[3]=docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb
set PACKAGES[4]=docker-compose-plugin_2.24.6-1~ubuntu.22.04~jammy_amd64.deb

REM 下载Docker CE包
echo [信息] 开始下载Docker CE包...
echo.

for /l %%i in (0,1,4) do (
    set "PACKAGE=!PACKAGES[%%i]!"
    if exist "!PACKAGE!" (
        echo [成功] 文件已存在: !PACKAGE!
    ) else (
        echo [信息] 正在下载: !PACKAGE!
        curl -L -C - -o "!PACKAGE!" "%DOCKER_BASE_URL%/!PACKAGE!"
        if !errorlevel! equ 0 (
            echo [成功] 下载完成: !PACKAGE!
        ) else (
            echo [错误] 下载失败: !PACKAGE!
            pause
            exit /b 1
        )
    )
)

echo.
REM 下载Docker Compose独立版
echo [信息] 开始下载Docker Compose独立版...
if exist docker-compose-linux-x86_64 (
    echo [成功] 文件已存在: docker-compose-linux-x86_64
) else (
    echo [信息] 正在下载: docker-compose-linux-x86_64
    curl -L -C - -o docker-compose-linux-x86_64 "%COMPOSE_URL%"
    if %errorlevel% equ 0 (
        echo [成功] 下载完成: docker-compose-linux-x86_64
    ) else (
        echo [错误] 下载失败: docker-compose-linux-x86_64
        pause
        exit /b 1
    )
)

echo.
echo ==========================================
echo [成功] 所有安装包下载完成！
echo ==========================================
echo.
echo [信息] 已下载的文件:
echo.
dir /b *.deb docker-compose-linux-x86_64 2>nul
echo.
echo [信息] 下一步:
echo   1. 将此目录下的所有文件上传到Ubuntu 22.04服务器
echo   2. 在服务器上运行: sudo bash install_docker_ubuntu2204.sh
echo.

pause
