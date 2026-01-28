#!/bin/bash

# Docker镜像预拉取脚本
# 用于在部署前预先拉取所需的Docker镜像
# 解决中国用户访问Docker Hub缓慢的问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 需要拉取的镜像列表
IMAGES=(
    "node:18-alpine"
    "nginx:alpine"
    "node:18"
    "nginx:latest"
)

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
    
    print_success "找到Docker命令: $DOCKER_CMD"
}

# 配置镜像加速器
configure_mirror() {
    print_info "配置Docker镜像加速器..."
    
    if [ -f "/etc/docker/daemon.json" ] && grep -q "registry-mirrors" "/etc/docker/daemon.json"; then
        print_success "镜像加速器已配置"
        return 0
    fi
    
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://dockerproxy.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ],
  "dns": ["8.8.8.8", "114.114.114.114"]
}
EOF
    
    print_info "重启Docker服务..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sleep 3
    
    print_success "镜像加速器配置完成"
}

# 拉取镜像
pull_images() {
    print_info "开始拉取Docker镜像..."
    echo ""
    
    local success_count=0
    local fail_count=0
    
    for image in "${IMAGES[@]}"; do
        print_info "正在拉取: $image"
        
        if $DOCKER_CMD pull "$image"; then
            print_success "✓ 拉取成功: $image"
            ((success_count++))
        else
            print_error "✗ 拉取失败: $image"
            ((fail_count++))
        fi
        
        echo ""
    done
    
    echo "=========================================="
    print_info "拉取结果统计:"
    print_success "成功: $success_count 个镜像"
    if [ $fail_count -gt 0 ]; then
        print_error "失败: $fail_count 个镜像"
    fi
    echo "=========================================="
}

# 显示已拉取的镜像
show_images() {
    print_info "已拉取的镜像列表:"
    echo ""
    $DOCKER_CMD images | grep -E "REPOSITORY|node|nginx"
}

# 主函数
main() {
    echo "=========================================="
    echo "  Docker镜像预拉取工具"
    echo "=========================================="
    echo ""
    
    check_docker
    configure_mirror
    pull_images
    show_images
    
    echo ""
    print_success "镜像预拉取完成！"
    echo ""
    print_info "现在可以运行部署脚本: sudo bash deploy_自动部署.sh"
}

# 运行主函数
main
