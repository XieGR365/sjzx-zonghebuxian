#!/bin/bash

# Ubuntu 22.04 Docker 和 Docker Compose 离线安装脚本
# 本脚本用于在Ubuntu 22.04 (Jammy Jellyfish) LTS系统上离线安装Docker和Docker Compose

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_step() {
    echo ""
    echo "=========================================="
    echo -e "${BLUE}$1${NC}"
    echo "=========================================="
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用root权限运行此脚本"
        print_info "使用方法: sudo $0"
        exit 1
    fi
}

# 检查系统版本
check_system() {
    print_step "步骤 1/6: 检查系统版本"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
        
        print_info "操作系统: $PRETTY_NAME"
        
        if [ "$OS" != "ubuntu" ]; then
            print_error "此脚本仅适用于Ubuntu系统"
            exit 1
        fi
        
        if [ "$VERSION" != "22.04" ]; then
            print_warning "此脚本为Ubuntu 22.04设计，当前版本: $VERSION"
            read -p "是否继续安装? (y/n): " continue_choice
            if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
                exit 1
            fi
        fi
        
        print_success "系统版本检查通过"
    else
        print_error "无法检测系统版本"
        exit 1
    fi
}

# 检查安装包是否存在
check_packages() {
    print_step "步骤 2/6: 检查安装包"
    
    local missing_packages=()
    
    # 检查Docker CE包
    for package in \
        "containerd.io_1.6.24-1_amd64.deb" \
        "docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb" \
        "docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb" \
        "docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb" \
        "docker-compose-plugin_2.24.6-1~ubuntu.22.04~jammy_amd64.deb"
    do
        if [ ! -f "$package" ]; then
            missing_packages+=("$package")
        fi
    done
    
    # 检查Docker Compose独立版
    if [ ! -f "docker-compose-linux-x86_64" ]; then
        print_warning "Docker Compose独立版不存在（可选）"
    fi
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        print_error "以下安装包不存在:"
        for pkg in "${missing_packages[@]}"; do
            echo "  - $pkg"
        done
        print_info "请确保所有DEB包都在当前目录下"
        exit 1
    fi
    
    print_success "所有必需的安装包都已找到"
}

# 安装Docker CE包
install_docker() {
    print_step "步骤 3/6: 安装Docker CE包"
    
    print_info "安装containerd.io..."
    dpkg -i containerd.io_1.6.24-1_amd64.deb
    
    print_info "安装docker-ce-cli..."
    dpkg -i docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
    
    print_info "安装docker-ce..."
    dpkg -i docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
    
    print_info "安装docker-buildx-plugin..."
    dpkg -i docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb
    
    print_info "安装docker-compose-plugin..."
    dpkg -i docker-compose-plugin_2.24.6-1~ubuntu.22.04~jammy_amd64.deb
    
    print_success "Docker CE包安装完成"
}

# 启动Docker服务
start_docker() {
    print_step "步骤 4/6: 启动Docker服务"
    
    print_info "启动Docker服务..."
    systemctl start docker
    
    print_info "设置Docker服务开机自启..."
    systemctl enable docker
    
    print_info "等待Docker服务完全启动..."
    sleep 3
    
    if systemctl is-active --quiet docker; then
        print_success "Docker服务启动成功"
    else
        print_error "Docker服务启动失败"
        print_info "查看服务状态: systemctl status docker"
        exit 1
    fi
}

# 安装Docker Compose独立版（可选）
install_docker_compose() {
    print_step "步骤 5/6: 安装Docker Compose独立版（可选）"
    
    if [ -f "docker-compose-linux-x86_64" ]; then
        print_info "安装Docker Compose独立版..."
        
        cp docker-compose-linux-x86_64 /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        
        print_success "Docker Compose独立版安装完成"
    else
        print_info "跳过Docker Compose独立版安装（文件不存在）"
        print_info "Docker Compose插件已包含在docker-compose-plugin包中"
    fi
}

# 验证安装
verify_installation() {
    print_step "步骤 6/6: 验证安装"
    
    print_info "检查Docker版本..."
    if docker --version; then
        print_success "Docker安装成功"
    else
        print_error "Docker安装失败"
        exit 1
    fi
    
    print_info "检查Docker Compose插件版本..."
    if docker compose version; then
        print_success "Docker Compose插件安装成功"
    else
        print_warning "Docker Compose插件检查失败"
    fi
    
    print_info "检查Docker Compose独立版版本..."
    if command -v docker-compose >/dev/null 2>&1; then
        if docker-compose --version; then
            print_success "Docker Compose独立版安装成功"
        else
            print_warning "Docker Compose独立版检查失败"
        fi
    else
        print_info "Docker Compose独立版未安装（可选）"
    fi
    
    print_info "运行测试容器..."
    if docker run --rm hello-world; then
        print_success "Docker运行正常"
    else
        print_warning "测试容器运行失败，但Docker可能仍然正常工作"
    fi
}

# 配置建议
configure_suggestions() {
    print_step "配置建议"
    
    print_info "1. 将当前用户添加到docker组（可选，避免每次使用sudo）"
    echo "   sudo usermod -aG docker \$USER"
    echo "   newgrp docker"
    echo ""
    
    print_info "2. 配置Docker镜像加速（可选，中国用户推荐）"
    echo "   sudo mkdir -p /etc/docker"
    echo '   sudo tee /etc/docker/daemon.json <<-'EOF
    echo '   {
    echo '     "registry-mirrors": [
    echo '       "https://docker.mirrors.ustc.edu.cn",
    echo '       "https://hub-mirror.c.163.com",
    echo '       "https://mirror.ccs.tencentyun.com"
    echo '     ]
    echo '   }'
    echo "   EOF"
    echo "   sudo systemctl daemon-reload"
    echo "   sudo systemctl restart docker"
    echo ""
    
    print_info "3. 查看Docker服务状态"
    echo "   sudo systemctl status docker"
    echo ""
    
    print_info "4. 查看Docker日志"
    echo "   sudo journalctl -u docker -n 50"
}

# 主函数
main() {
    echo "=========================================="
    echo "  Ubuntu 22.04 Docker 离线安装工具"
    echo "=========================================="
    echo ""
    
    check_root
    check_system
    check_packages
    install_docker
    start_docker
    install_docker_compose
    verify_installation
    configure_suggestions
    
    echo ""
    echo "=========================================="
    print_success "Docker和Docker Compose安装完成！"
    echo "=========================================="
    echo ""
    print_info "现在可以使用Docker了！"
    print_info "尝试运行: sudo docker run hello-world"
}

# 运行主函数
main
