#!/bin/bash

# Ubuntu 22.04 Docker 和 Docker Compose 安装包下载脚本
# 本脚本用于下载Ubuntu 22.04 (Jammy Jellyfish) LTS系统的Docker和Docker Compose离线安装包

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 下载URL
DOCKER_BASE_URL="https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64"

# Docker CE包列表
PACKAGES=(
    "containerd.io_1.6.24-1_amd64.deb"
    "docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb"
    "docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb"
    "docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb"
    "docker-compose-plugin_2.24.6-1~ubuntu.22.04~jammy_amd64.deb"
)

# Docker Compose独立版
COMPOSE_URL="https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-linux-x86_64"

# 打印信息函数
print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

# 检查wget或curl
check_download_tool() {
    if command -v wget >/dev/null 2>&1; then
        DOWNLOAD_CMD="wget"
        print_success "找到下载工具: wget"
    elif command -v curl >/dev/null 2>&1; then
        DOWNLOAD_CMD="curl"
        print_success "找到下载工具: curl"
    else
        print_error "未找到wget或curl，请先安装其中一个"
        exit 1
    fi
}

# 下载文件函数
download_file() {
    local url=$1
    local filename=$2
    
    print_info "正在下载: $filename"
    
    if [ "$DOWNLOAD_CMD" = "wget" ]; then
        wget -c --progress=bar:force "$url" -O "$filename"
    else
        curl -L -C - --progress-bar "$url" -o "$filename"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "下载完成: $filename"
    else
        print_error "下载失败: $filename"
        exit 1
    fi
}

# 验证文件
verify_file() {
    local filename=$1
    
    if [ -f "$filename" ]; then
        local size=$(du -h "$filename" | cut -f1)
        print_success "文件已存在: $filename (大小: $size)"
        return 0
    else
        return 1
    fi
}

# 主函数
main() {
    echo "=========================================="
    echo "  Ubuntu 22.04 Docker 安装包下载工具"
    echo "=========================================="
    echo ""
    
    # 检查下载工具
    check_download_tool
    echo ""
    
    # 下载Docker CE包
    print_info "开始下载Docker CE包..."
    echo ""
    
    for package in "${PACKAGES[@]}"; do
        if ! verify_file "$package"; then
            download_file "$DOCKER_BASE_URL/$package" "$package"
        fi
    done
    
    echo ""
    
    # 下载Docker Compose独立版
    print_info "开始下载Docker Compose独立版..."
    if ! verify_file "docker-compose-linux-x86_64"; then
        download_file "$COMPOSE_URL" "docker-compose-linux-x86_64"
        
        # 设置可执行权限
        chmod +x docker-compose-linux-x86_64
        print_success "已设置可执行权限"
    fi
    
    echo ""
    echo "=========================================="
    print_success "所有安装包下载完成！"
    echo "=========================================="
    echo ""
    print_info "已下载的文件:"
    echo ""
    ls -lh *.deb docker-compose-linux-x86_64 2>/dev/null || true
    echo ""
    print_info "下一步: 运行 install_docker_ubuntu2204.sh 进行安装"
}

# 运行主函数
main
