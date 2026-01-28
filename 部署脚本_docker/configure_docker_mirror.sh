#!/bin/bash

# Docker镜像源配置脚本
# 支持配置自定义的Docker镜像源地址

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

# 检查Docker命令
check_docker() {
    if command -v docker >/dev/null 2>&1; then
        DOCKER_CMD="docker"
    elif sudo command -v docker >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
    else
        print_error "未找到Docker命令"
        exit 1
    fi
}

# 测试网络连接
test_connection() {
    local url=$1
    local timeout=3
    
    if curl -s --connect-timeout $timeout --max-time $timeout "$url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 配置自定义镜像源
configure_custom_mirror() {
    echo "=========================================="
    echo "  Docker镜像源配置工具"
    echo "=========================================="
    echo ""
    
    print_info "请选择镜像源配置方式："
    echo ""
    echo "1. 使用默认镜像加速器（中科大、网易、腾讯云）"
    echo "2. 使用阿里云镜像加速器"
    echo "3. 使用自定义镜像源"
    echo "4. 使用内网/私有Docker镜像仓库"
    echo "5. 仅配置DNS（不使用镜像加速器）"
    echo ""
    
    read -p "请输入选项 (1-5): " choice
    
    case $choice in
        1)
            configure_default_mirrors
            ;;
        2)
            configure_aliyun_mirror
            ;;
        3)
            configure_custom_mirror_url
            ;;
        4)
            configure_private_registry
            ;;
        5)
            configure_dns_only
            ;;
        *)
            print_error "无效的选项"
            exit 1
            ;;
    esac
}

# 配置默认镜像加速器
configure_default_mirrors() {
    print_info "配置默认镜像加速器..."
    
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://dockerproxy.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ],
  "dns": ["8.8.8.8", "114.114.114.114", "223.5.5.5"]
}
EOF
    
    restart_docker
}

# 配置阿里云镜像加速器
configure_aliyun_mirror() {
    print_info "配置阿里云镜像加速器..."
    
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<-'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://registry.cn-beijing.aliyuncs.com",
    "https://registry.cn-shanghai.aliyuncs.com",
    "https://registry.cn-shenzhen.aliyuncs.com"
  ],
  "dns": ["8.8.8.8", "114.114.114.114", "223.5.5.5"]
}
EOF
    
    restart_docker
}

# 配置自定义镜像源
configure_custom_mirror_url() {
    print_info "配置自定义镜像源..."
    echo ""
    
    read -p "请输入镜像源URL (例如: https://your-registry.com): " mirror_url
    
    if [ -z "$mirror_url" ]; then
        print_error "镜像源URL不能为空"
        exit 1
    fi
    
    # 测试连接
    print_info "测试连接到 $mirror_url ..."
    if test_connection "$mirror_url"; then
        print_success "连接成功"
    else
        print_warning "连接失败，但将继续配置"
    fi
    
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    "$mirror_url"
  ],
  "dns": ["8.8.8.8", "114.114.114.114", "223.5.5.5"]
}
EOF
    
    restart_docker
}

# 配置内网/私有Docker镜像仓库
configure_private_registry() {
    print_info "配置内网/私有Docker镜像仓库..."
    echo ""
    
    read -p "请输入私有仓库地址 (例如: 192.168.19.58:5000): " registry_url
    
    if [ -z "$registry_url" ]; then
        print_error "私有仓库地址不能为空"
        exit 1
    fi
    
    # 测试连接
    print_info "测试连接到 $registry_url ..."
    if test_connection "http://$registry_url/v2/"; then
        print_success "连接成功"
    else
        print_warning "连接失败，但将继续配置"
    fi
    
    # 配置私有仓库（不安全模式，用于测试）
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "insecure-registries": ["$registry_url"],
  "registry-mirrors": [],
  "dns": ["8.8.8.8", "114.114.114.114", "223.5.5.5"]
}
EOF
    
    restart_docker
    
    print_info "配置完成后，可以使用以下命令拉取镜像："
    echo "  $DOCKER_CMD pull $registry_url/node:18-alpine"
    echo "  $DOCKER_CMD pull $registry_url/nginx:alpine"
    echo ""
    print_warning "注意：如果私有仓库需要认证，请先登录："
    echo "  $DOCKER_CMD login $registry_url"
}

# 仅配置DNS
configure_dns_only() {
    print_info "仅配置DNS..."
    
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<-'EOF'
{
  "registry-mirrors": [],
  "dns": ["8.8.8.8", "114.114.114.114", "223.5.5.5", "1.1.1.1"]
}
EOF
    
    restart_docker
}

# 重启Docker服务
restart_docker() {
    print_info "重启Docker服务以应用配置..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    # 等待Docker服务完全启动
    sleep 5
    
    # 验证配置
    if $DOCKER_CMD info | grep -q "Registry Mirrors"; then
        print_success "Docker镜像源配置成功"
        echo ""
        print_info "当前配置:"
        $DOCKER_CMD info | grep -A 10 "Registry Mirrors" | sed 's/^/  /'
        echo ""
        print_info "DNS配置:"
        $DOCKER_CMD info | grep -A 5 "DNS" | sed 's/^/  /'
    else
        print_warning "镜像源配置可能未生效"
    fi
}

# 显示当前配置
show_current_config() {
    print_info "当前Docker配置:"
    echo ""
    
    if [ -f "/etc/docker/daemon.json" ]; then
        cat /etc/docker/daemon.json | python3 -m json.tool 2>/dev/null || cat /etc/docker/daemon.json
    else
        print_warning "未找到Docker配置文件"
    fi
    
    echo ""
    print_info "Docker信息:"
    $DOCKER_CMD info | grep -E "Registry Mirrors|Insecure Registries|DNS" | sed 's/^/  /'
}

# 主函数
main() {
    # 检查Docker
    check_docker
    
    # 显示当前配置
    show_current_config
    echo ""
    
    # 配置镜像源
    configure_custom_mirror
    
    echo ""
    print_success "配置完成！"
    echo ""
    print_info "现在可以运行部署脚本: sudo bash deploy_自动部署.sh"
}

# 运行主函数
main
