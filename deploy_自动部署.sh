#!/bin/bash

################################################################################
# 综合布线记录管理系统 - 一键自动部署脚本
# 
# 功能说明：
#   - 自动检查系统环境（Docker、Docker Compose）
#   - 自动安装缺失的依赖
#   - 自动构建并启动前后端服务
#   - 自动配置数据持久化
#   - 提供健康检查和日志查看功能
#
# 使用方法：
#   chmod +x deploy_自动部署.sh
#   ./deploy_自动部署.sh
#
# 系统要求：
#   - Linux系统（Ubuntu 20.04+, CentOS 7+, Debian 10+）
#   - Root权限或sudo权限
#   - 至少2GB可用内存
#   - 至少10GB可用磁盘空间
#
# 作者：综合布线记录管理系统开发团队
# 日期：2025-01-04
################################################################################

# 颜色定义，用于输出不同级别的信息
RED='\033[0;31m'      # 红色 - 错误信息
GREEN='\033[0;32m'    # 绿色 - 成功信息
YELLOW='\033[1;33m'   # 黄色 - 警告信息
BLUE='\033[0;34m'     # 蓝色 - 信息提示
NC='\033[0m'          # 无颜色 - 重置颜色

# 项目配置变量
PROJECT_NAME="综合布线记录管理系统"
BACKEND_DIR="backend"
FRONTEND_DIR="frontend"
CONFIG_DIR="config"
BACKEND_CONTAINER="wiring-backend"
FRONTEND_CONTAINER="wiring-frontend"
NETWORK_NAME="wiring-network"

# 端口配置
BACKEND_PORT=3001
FRONTEND_PORT=80

# 数据持久化目录
DATA_DIR="./data"
UPLOADS_DIR="./uploads"

# Docker命令配置
DOCKER_CMD="docker"
if [ "$EUID" -ne 0 ]; then
    DOCKER_CMD="sudo docker"
fi

# 调试模式（设置为1启用调试输出）
DEBUG_MODE=0

################################################################################
# 函数：打印调试信息
# 参数：
#   $1 - 调试信息内容
################################################################################
print_debug() {
    if [ "$DEBUG_MODE" -eq 1 ]; then
        print_message "$YELLOW" "[DEBUG] $1"
    fi
}

################################################################################
# 函数：打印带颜色的消息
# 参数：
#   $1 - 颜色（RED/GREEN/YELLOW/BLUE）
#   $2 - 消息内容
################################################################################
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

################################################################################
# 函数：打印分隔线
# 参数：无
################################################################################
print_separator() {
    echo "================================================================================"
}

################################################################################
# 函数：打印步骤标题
# 参数：
#   $1 - 步骤编号
#   $2 - 步骤描述
################################################################################
print_step() {
    local step_num=$1
    local step_desc=$2
    print_separator
    print_message "$BLUE" "步骤 ${step_num}: ${step_desc}"
    print_separator
}

################################################################################
# 函数：检查命令是否存在
# 参数：
#   $1 - 命令名称
# 返回值：
#   0 - 命令存在
#   1 - 命令不存在
################################################################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

################################################################################
# 函数：检查是否为root用户或有sudo权限
# 参数：无
# 返回值：
#   0 - 有权限
#   1 - 无权限
################################################################################
check_root_permission() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    elif command_exists sudo; then
        if sudo -n true 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

################################################################################
# 函数：安装Docker
# 参数：无
################################################################################
install_docker() {
    print_message "$YELLOW" "正在安装Docker..."
    
    # 检测系统类型
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        print_message "$RED" "无法检测系统类型，请手动安装Docker"
        exit 1
    fi

    # 根据不同系统安装Docker
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/${OS}/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OS} \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        
        centos|rhel|fedora)
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        
        *)
            print_message "$RED" "不支持的系统类型: ${OS}"
            exit 1
            ;;
    esac

    # 启动Docker服务
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 将当前用户添加到docker组
    sudo usermod -aG docker $USER
    
    print_message "$GREEN" "Docker安装完成！"
    print_message "$YELLOW" "注意: 本脚本将使用sudo运行Docker命令"
    print_message "$YELLOW" "如需无密码使用docker，请执行: newgrp docker 或重新登录"
    
    # 等待Docker服务完全启动
    sleep 3
}

################################################################################
# 函数：检查并安装Docker
# 参数：无
################################################################################
check_docker() {
    print_step "1" "检查Docker环境"
    
    # 确定是否需要使用sudo
    local DOCKER_CMD="docker"
    if [ "$EUID" -ne 0 ]; then
        DOCKER_CMD="sudo docker"
    fi
    
    # 检查docker命令是否存在
    local docker_found=0
    
    # 方法1: 检查docker命令是否在PATH中
    if command_exists docker; then
        docker_found=1
    fi
    
    # 方法2: 检查sudo docker是否可用
    if [ $docker_found -eq 0 ] && [ "$EUID" -ne 0 ]; then
        if sudo command -v docker >/dev/null 2>&1; then
            docker_found=1
        fi
    fi
    
    # 方法3: 检查docker进程是否在运行
    if [ $docker_found -eq 0 ]; then
        if pgrep -x "dockerd" >/dev/null 2>&1; then
            docker_found=1
        fi
    fi
    
    if [ $docker_found -eq 1 ]; then
        # 尝试获取docker版本
        DOCKER_VERSION=$($DOCKER_CMD --version 2>/dev/null | awk '{print $3}' | sed 's/,//')
        if [ -n "$DOCKER_VERSION" ]; then
            print_message "$GREEN" "✓ Docker已安装 (版本: ${DOCKER_VERSION})"
        else
            print_message "$GREEN" "✓ Docker已安装"
        fi
    else
        print_message "$YELLOW" "✗ Docker未安装"
        read -p "是否自动安装Docker? (y/n): " install_choice
        if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
            install_docker
            # 安装完成后直接返回，不再检查（避免循环）
            return 0
        else
            print_message "$RED" "请先安装Docker后再运行此脚本"
            exit 1
        fi
    fi
    
    # 检查Docker服务状态
    if ! sudo systemctl is-active --quiet docker 2>/dev/null; then
        print_message "$YELLOW" "Docker服务未运行，正在启动..."
        sudo systemctl start docker
        # 等待服务启动
        sleep 3
    fi
    
    print_message "$GREEN" "✓ Docker服务运行正常"
}

################################################################################
# 函数：配置Docker镜像加速器
# 参数：无
################################################################################
configure_docker_mirror() {
    print_step "1.5" "配置Docker镜像加速器"
    
    # 确定是否需要使用sudo
    local DOCKER_CMD="docker"
    if [ "$EUID" -ne 0 ]; then
        DOCKER_CMD="sudo docker"
    fi
    
    # 检查配置文件是否存在
    local config_file="$CONFIG_DIR/docker_mirror.conf"
    if [ -f "$config_file" ]; then
        print_message "$BLUE" "找到镜像源配置文件: $config_file"
        
        # 读取配置文件
        source "$config_file"
        
        # 根据配置类型配置镜像源
        case "$MIRROR_TYPE" in
            default)
                configure_default_mirrors
                ;;
            aliyun)
                configure_aliyun_mirrors
                ;;
            custom)
                configure_custom_mirrors
                ;;
            private)
                configure_private_registry
                ;;
            none)
                configure_dns_only
                ;;
            *)
                print_message "$YELLOW" "未知的镜像源类型: $MIRROR_TYPE，使用默认配置"
                configure_default_mirrors
                ;;
        esac
    else
        print_message "$YELLOW" "未找到镜像源配置文件，使用默认配置"
        configure_default_mirrors
    fi
}

# 配置默认镜像加速器
configure_default_mirrors() {
    print_message "$YELLOW" "正在配置Docker镜像加速器（默认）..."
    
    # 创建Docker配置目录
    sudo mkdir -p /etc/docker
    
    # 配置多个镜像加速器（提高可用性）
    sudo tee /etc/docker/daemon.json > /dev/null <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com",
    "https://dockerproxy.com"
  ],
  "dns": ["8.8.8.8", "114.114.114.114", "223.5.5.5"]
}
EOF
    
    restart_docker_service
}

# 配置阿里云镜像加速器
configure_aliyun_mirrors() {
    print_message "$YELLOW" "正在配置Docker镜像加速器（阿里云）..."
    
    # 创建Docker配置目录
    sudo mkdir -p /etc/docker
    
    # 配置阿里云镜像加速器
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
    
    restart_docker_service
}

# 配置自定义镜像源
configure_custom_mirrors() {
    print_message "$YELLOW" "正在配置Docker镜像加速器（自定义）..."
    
    # 创建Docker配置目录
    sudo mkdir -p /etc/docker
    
    # 构建镜像源JSON数组
    local mirrors_json=""
    for mirror in "${CUSTOM_MIRRORS[@]}"; do
        if [ -n "$mirrors_json" ]; then
            mirrors_json="$mirrors_json,"
        fi
        mirrors_json="$mirrors_json    \"$mirror\""
    done
    
    # 构建DNS JSON数组
    local dns_json=""
    for dns in "${DNS_SERVERS[@]}"; do
        if [ -n "$dns_json" ]; then
            dns_json="$dns_json,"
        fi
        dns_json="$dns_json    \"$dns\""
    done
    
    # 写入配置文件
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
$mirrors_json
  ],
  "dns": [
$dns_json
  ]
}
EOF
    
    restart_docker_service
}

# 配置私有Docker镜像仓库
configure_private_registry() {
    print_message "$YELLOW" "正在配置私有Docker镜像仓库: $PRIVATE_REGISTRY"
    
    # 创建Docker配置目录
    sudo mkdir -p /etc/docker
    
    # 构建配置JSON
    local insecure_json=""
    if [ "$INSECURE_REGISTRY" = "true" ]; then
        insecure_json="  \"insecure-registries\": [\"$PRIVATE_REGISTRY\"],"
    fi
    
    # 构建DNS JSON数组
    local dns_json=""
    for dns in "${DNS_SERVERS[@]}"; do
        if [ -n "$dns_json" ]; then
            dns_json="$dns_json,"
        fi
        dns_json="$dns_json    \"$dns\""
    done
    
    # 写入配置文件
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
$insecure_json
  "registry-mirrors": [],
  "dns": [
$dns_json
  ]
}
EOF
    
    restart_docker_service
    
    print_message "$BLUE" "配置完成后，可以使用以下命令拉取镜像："
    echo "  $DOCKER_CMD pull $PRIVATE_REGISTRY/node:18-alpine"
    echo "  $DOCKER_CMD pull $PRIVATE_REGISTRY/nginx:alpine"
    echo ""
    print_message "$YELLOW" "注意：如果私有仓库需要认证，请先登录："
    echo "  $DOCKER_CMD login $PRIVATE_REGISTRY"
}

# 仅配置DNS
configure_dns_only() {
    print_message "$YELLOW" "正在配置DNS服务器..."
    
    # 创建Docker配置目录
    sudo mkdir -p /etc/docker
    
    # 构建DNS JSON数组
    local dns_json=""
    for dns in "${DNS_SERVERS[@]}"; do
        if [ -n "$dns_json" ]; then
            dns_json="$dns_json,"
        fi
        dns_json="$dns_json    \"$dns\""
    done
    
    # 写入配置文件
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [],
  "dns": [
$dns_json
  ]
}
EOF
    
    restart_docker_service
}

# 重启Docker服务
restart_docker_service() {
    # 重启Docker服务以应用配置
    print_message "$YELLOW" "重启Docker服务以应用配置..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    # 等待Docker服务完全启动
    sleep 5
    
    # 验证配置是否生效
    if $DOCKER_CMD info | grep -q "Registry Mirrors\|Insecure Registries"; then
        print_message "$GREEN" "✓ Docker镜像加速器配置成功"
        print_message "$BLUE" "当前配置:"
        $DOCKER_CMD info | grep -A 10 "Registry Mirrors\|Insecure Registries" | sed 's/^/  /'
    else
        print_message "$YELLOW" "⚠ 镜像加速器配置可能未生效，但将继续尝试构建"
    fi
}

################################################################################
# 函数：检查Docker Compose
# 参数：无
################################################################################
check_docker_compose() {
    print_step "2" "检查Docker Compose"
    
    # 确定是否需要使用sudo
    local DOCKER_CMD="docker"
    if [ "$EUID" -ne 0 ]; then
        DOCKER_CMD="sudo docker"
    fi
    
    # 检查docker compose是否可用
    local compose_found=0
    local COMPOSE_CMD=""
    
    # 方法1: 检查docker compose (新版Docker Compose插件)
    if $DOCKER_CMD compose version >/dev/null 2>&1; then
        compose_found=1
        COMPOSE_CMD="$DOCKER_CMD compose"
        COMPOSE_VERSION=$($DOCKER_CMD compose version --short 2>/dev/null)
        print_message "$GREEN" "✓ Docker Compose已安装 (版本: ${COMPOSE_VERSION})"
    fi
    
    # 方法2: 检查docker-compose (独立版本)
    if [ $compose_found -eq 0 ] && command_exists docker-compose; then
        compose_found=1
        COMPOSE_CMD="docker-compose"
        if [ "$EUID" -ne 0 ]; then
            COMPOSE_CMD="sudo docker-compose"
        fi
        COMPOSE_VERSION=$(docker-compose --version 2>/dev/null | awk '{print $3}' | sed 's/,//')
        print_message "$GREEN" "✓ Docker Compose已安装 (版本: ${COMPOSE_VERSION})"
    fi
    
    # 方法3: 检查sudo docker-compose是否可用
    if [ $compose_found -eq 0 ] && [ "$EUID" -ne 0 ]; then
        if sudo command -v docker-compose >/dev/null 2>&1; then
            compose_found=1
            COMPOSE_CMD="sudo docker-compose"
            COMPOSE_VERSION=$(sudo docker-compose --version 2>/dev/null | awk '{print $3}' | sed 's/,//')
            print_message "$GREEN" "✓ Docker Compose已安装 (版本: ${COMPOSE_VERSION})"
        fi
    fi
    
    # 方法4: 检查docker-compose-plugin是否安装
    if [ $compose_found -eq 0 ]; then
        if [ -f "/usr/libexec/docker/cli-plugins/docker-compose" ] || [ -f "/usr/local/lib/docker/cli-plugins/docker-compose" ]; then
            compose_found=1
            COMPOSE_CMD="$DOCKER_CMD compose"
            COMPOSE_VERSION=$($DOCKER_CMD compose version --short 2>/dev/null)
            print_message "$GREEN" "✓ Docker Compose插件已安装 (版本: ${COMPOSE_VERSION})"
        fi
    fi
    
    # 如果都找不到，尝试安装
    if [ $compose_found -eq 0 ]; then
        print_message "$YELLOW" "✗ Docker Compose未安装"
        print_message "$YELLOW" "正在安装Docker Compose..."
        
        # 下载Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        print_message "$GREEN" "✓ Docker Compose安装完成"
    fi
}

################################################################################
# 函数：检查项目目录结构
# 参数：无
################################################################################
check_project_structure() {
    print_step "3" "检查项目目录结构"
    
    # 检查必需的目录
    if [ ! -d "$BACKEND_DIR" ]; then
        print_message "$RED" "✗ 后端目录不存在: ${BACKEND_DIR}"
        exit 1
    fi
    print_message "$GREEN" "✓ 后端目录存在"
    
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_message "$RED" "✗ 前端目录不存在: ${FRONTEND_DIR}"
        exit 1
    fi
    print_message "$GREEN" "✓ 前端目录存在"
    
    if [ ! -d "$CONFIG_DIR" ]; then
        print_message "$RED" "✗ 配置目录不存在: ${CONFIG_DIR}"
        exit 1
    fi
    print_message "$GREEN" "✓ 配置目录存在"
    
    # 检查必需的文件
    if [ ! -f "$CONFIG_DIR/docker-compose.yml" ]; then
        print_message "$RED" "✗ Docker Compose配置文件不存在"
        exit 1
    fi
    print_message "$GREEN" "✓ Docker Compose配置文件存在"
    
    if [ ! -f "$BACKEND_DIR/Dockerfile" ]; then
        print_message "$RED" "✗ 后端Dockerfile不存在"
        exit 1
    fi
    print_message "$GREEN" "✓ 后端Dockerfile存在"
    
    if [ ! -f "$FRONTEND_DIR/Dockerfile" ]; then
        print_message "$RED" "✗ 前端Dockerfile不存在"
        exit 1
    fi
    print_message "$GREEN" "✓ 前端Dockerfile存在"
}

################################################################################
# 函数：检查端口占用情况
# 参数：无
################################################################################
check_ports() {
    print_step "4" "检查端口占用情况"
    
    # 确定是否需要使用sudo
    local NETSTAT_CMD="netstat"
    if [ "$EUID" -ne 0 ]; then
        NETSTAT_CMD="sudo netstat"
    fi
    
    # 检查后端端口
    if $NETSTAT_CMD -tuln 2>/dev/null | grep -q ":${BACKEND_PORT} "; then
        print_message "$YELLOW" "⚠ 端口 ${BACKEND_PORT} 已被占用"
        read -p "是否继续? (y/n): " continue_choice
        if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
            exit 1
        fi
    else
        print_message "$GREEN" "✓ 后端端口 ${BACKEND_PORT} 可用"
    fi
    
    # 检查前端端口
    if $NETSTAT_CMD -tuln 2>/dev/null | grep -q ":${FRONTEND_PORT} "; then
        print_message "$YELLOW" "⚠ 端口 ${FRONTEND_PORT} 已被占用"
        read -p "是否继续? (y/n): " continue_choice
        if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
            exit 1
        fi
    else
        print_message "$GREEN" "✓ 前端端口 ${FRONTEND_PORT} 可用"
    fi
}

################################################################################
# 函数：创建数据持久化目录
# 参数：无
################################################################################
create_data_dirs() {
    print_step "5" "创建数据持久化目录"
    
    # 创建后端数据目录
    if [ ! -d "$BACKEND_DIR/data" ]; then
        mkdir -p "$BACKEND_DIR/data"
        print_message "$GREEN" "✓ 创建后端数据目录: ${BACKEND_DIR}/data"
    else
        print_message "$GREEN" "✓ 后端数据目录已存在"
    fi
    
    # 创建后端上传目录
    if [ ! -d "$BACKEND_DIR/uploads" ]; then
        mkdir -p "$BACKEND_DIR/uploads"
        print_message "$GREEN" "✓ 创建后端上传目录: ${BACKEND_DIR}/uploads"
    else
        print_message "$GREEN" "✓ 后端上传目录已存在"
    fi
    
    # 设置目录权限
    chmod 755 "$BACKEND_DIR/data"
    chmod 755 "$BACKEND_DIR/uploads"
    print_message "$GREEN" "✓ 目录权限设置完成"
}

################################################################################
# 函数：清理旧容器和镜像
# 参数：无
################################################################################
cleanup_old_containers() {
    print_step "6" "清理旧容器和镜像"
    
    # 确定是否需要使用sudo
    local DOCKER_CMD="docker"
    if [ "$EUID" -ne 0 ]; then
        DOCKER_CMD="sudo docker"
    fi
    
    print_debug "开始清理旧容器和镜像..."
    
    # 停止并删除旧容器
    if $DOCKER_CMD ps -a | grep -q "$BACKEND_CONTAINER"; then
        print_message "$YELLOW" "停止旧的后端容器..."
        
        # 尝试正常停止
        if ! $DOCKER_CMD stop "$BACKEND_CONTAINER" 2>/dev/null; then
            print_message "$YELLOW" "正常停止失败，尝试强制停止..."
            $DOCKER_CMD kill "$BACKEND_CONTAINER" 2>/dev/null || true
        fi
        
        print_message "$YELLOW" "删除旧的后端容器..."
        $DOCKER_CMD rm -f "$BACKEND_CONTAINER" 2>/dev/null || true
        print_message "$GREEN" "✓ 后端容器已清理"
    else
        print_debug "后端容器不存在，跳过"
    fi
    
    if $DOCKER_CMD ps -a | grep -q "$FRONTEND_CONTAINER"; then
        print_message "$YELLOW" "停止旧的前端容器..."
        
        # 尝试正常停止
        if ! $DOCKER_CMD stop "$FRONTEND_CONTAINER" 2>/dev/null; then
            print_message "$YELLOW" "正常停止失败，尝试强制停止..."
            $DOCKER_CMD kill "$FRONTEND_CONTAINER" 2>/dev/null || true
        fi
        
        print_message "$YELLOW" "删除旧的前端容器..."
        $DOCKER_CMD rm -f "$FRONTEND_CONTAINER" 2>/dev/null || true
        print_message "$GREEN" "✓ 前端容器已清理"
    else
        print_debug "前端容器不存在，跳过"
    fi
    
    # 清理旧网络
    if $DOCKER_CMD network ls | grep -q "$NETWORK_NAME"; then
        print_message "$YELLOW" "删除旧的网络..."
        $DOCKER_CMD network rm "$NETWORK_NAME" 2>/dev/null || true
        print_message "$GREEN" "✓ 旧网络已清理"
    else
        print_debug "网络不存在，跳过"
    fi
    
    print_debug "清理完成"
}

################################################################################
# 函数：构建并启动服务
# 参数：无
################################################################################
build_and_start() {
    print_step "7" "构建并启动服务"
    
    # 确定是否需要使用sudo
    local DOCKER_CMD="docker"
    if [ "$EUID" -ne 0 ]; then
        DOCKER_CMD="sudo docker"
    fi
    
    # 确定Docker Compose命令
    local COMPOSE_CMD=""
    if $DOCKER_CMD compose version >/dev/null 2>&1; then
        COMPOSE_CMD="$DOCKER_CMD compose"
    elif command_exists docker-compose; then
        COMPOSE_CMD="docker-compose"
        if [ "$EUID" -ne 0 ]; then
            COMPOSE_CMD="sudo docker-compose"
        fi
    else
        print_message "$RED" "✗ Docker Compose未找到"
        exit 1
    fi
    
    # 进入配置目录
    print_message "$BLUE" "当前目录: $(pwd)"
    cd "$CONFIG_DIR" || exit 1
    print_message "$BLUE" "切换到配置目录: $(pwd)"
    
    # 检查docker-compose.yml是否存在
    if [ ! -f "docker-compose.yml" ]; then
        print_message "$RED" "✗ docker-compose.yml文件不存在"
        print_message "$YELLOW" "当前目录内容:"
        ls -la
        exit 1
    fi
    
    print_message "$BLUE" "开始构建Docker镜像..."
    print_message "$BLUE" "使用命令: ${COMPOSE_CMD}"
    print_message "$BLUE" "配置文件: $(pwd)/docker-compose.yml"
    print_message "$YELLOW" "提示: 构建过程可能需要几分钟，请耐心等待..."
    echo ""
    
    # 检查网络连接
    print_message "$BLUE" "检查网络连接..."
    if ping -c 1 -W 2 registry-1.docker.io >/dev/null 2>&1; then
        print_message "$GREEN" "✓ 可以连接到Docker Hub"
    else
        print_message "$YELLOW" "⚠ 无法连接到Docker Hub"
        print_message "$YELLOW" "将使用镜像加速器下载镜像"
    fi
    echo ""
    
    # 构建并启动所有服务
    print_message "$BLUE" "执行命令: ${COMPOSE_CMD} up -d --build"
    
    # 使用后台任务监控构建进度
    local build_log="/tmp/docker-compose-build.log"
    local build_pid=""
    
    # 启动构建并记录日志
    $COMPOSE_CMD up -d --build > "$build_log" 2>&1 &
    build_pid=$!
    
    print_message "$BLUE" "构建进程已启动 (PID: ${build_pid})"
    print_message "$YELLOW" "正在构建中..."
    
    # 监控构建进度
    local timeout=600  # 10分钟超时
    local elapsed=0
    local interval=10
    
    while kill -0 $build_pid 2>/dev/null; do
        sleep $interval
        elapsed=$((elapsed + interval))
        
        # 显示进度
        local progress=$((elapsed / 10))
        echo -ne "\r${YELLOW}构建中... ${progress}秒 elapsed${NC}"
        
        # 检查超时
        if [ $elapsed -ge $timeout ]; then
            echo ""
            print_message "$RED" "✗ 构建超时 (${timeout}秒)"
            print_message "$YELLOW" "尝试终止构建进程..."
            kill $build_pid 2>/dev/null || true
            wait $build_pid 2>/dev/null || true
            
            print_message "$YELLOW" "查看构建日志:"
            tail -n 50 "$build_log"
            
            read -p "是否继续尝试启动已构建的服务? (y/n): " continue_choice
            if [ "$continue_choice" = "y" ] || [ "$continue_choice" = "Y" ]; then
                print_message "$BLUE" "尝试启动服务..."
                $COMPOSE_CMD up -d
            fi
            exit 1
        fi
    done
    
    echo ""
    
    # 等待构建完成
    wait $build_pid
    local build_exit_code=$?
    
    # 显示构建结果
    if [ $build_exit_code -eq 0 ]; then
        print_message "$GREEN" "✓ 服务构建并启动成功"
        
        # 显示构建日志的最后几行
        if [ -f "$build_log" ]; then
            print_debug "构建日志最后10行:"
            tail -n 10 "$build_log" | while read line; do
                print_debug "$line"
            done
        fi
    else
        print_message "$RED" "✗ 服务构建或启动失败 (退出码: ${build_exit_code})"
        print_message "$YELLOW" "查看详细构建日志:"
        
        if [ -f "$build_log" ]; then
            tail -n 100 "$build_log"
        fi
        
        # 提供故障排除建议
        echo ""
        print_message "$YELLOW" "故障排除建议:"
        echo "  1. 检查网络连接是否正常"
        echo "  2. 检查Docker是否有足够的磁盘空间"
        echo "  3. 检查Docker服务是否正常运行: ${DOCKER_CMD} ps"
        echo "  4. 尝试手动清理Docker缓存: ${DOCKER_CMD} system prune -a"
        echo "  5. 查看完整日志: cat $build_log"
        echo ""
        print_message "$YELLOW" "如果遇到DNS解析问题，请尝试以下方法:"
        echo "  方法1: 配置Docker镜像加速器"
        echo "    sudo mkdir -p /etc/docker"
        echo '    sudo tee /etc/docker/daemon.json <<-'EOF
        echo '    {'
        echo '      "registry-mirrors": ['
        echo '        "https://docker.mirrors.ustc.edu.cn",'
        echo '        "https://hub-mirror.c.163.com",'
        echo '        "https://mirror.ccs.tencentyun.com"'
        echo '      ],'
        echo '      "dns": ["8.8.8.8", "114.114.114.114"]'
        echo '    }'
        echo "    EOF"
        echo "    sudo systemctl daemon-reload"
        echo "    sudo systemctl restart docker"
        echo ""
        echo "  方法2: 使用离线安装包（推荐中国用户）"
        echo "    1. 下载Ubuntu 22.04 Docker安装包"
        echo "    2. 上传到服务器并运行: sudo bash 安装包/install_docker_ubuntu2204.sh"
        echo ""
        echo "  方法3: 手动拉取镜像"
        echo "    ${DOCKER_CMD} pull node:18-alpine"
        echo "    ${DOCKER_CMD} pull nginx:alpine"
        
        read -p "是否尝试仅启动已构建的服务? (y/n): " start_choice
        if [ "$start_choice" = "y" ] || [ "$start_choice" = "Y" ]; then
            print_message "$BLUE" "尝试启动服务..."
            $COMPOSE_CMD up -d
            if [ $? -eq 0 ]; then
                print_message "$GREEN" "✓ 服务启动成功"
            else
                exit 1
            fi
        else
            exit 1
        fi
    fi
    
    # 清理临时日志文件
    rm -f "$build_log" 2>/dev/null || true
    
    # 返回根目录
    cd ..
}

################################################################################
# 函数：等待服务启动
# 参数：无
################################################################################
wait_for_services() {
    print_step "8" "等待服务启动"
    
    print_message "$BLUE" "等待后端服务启动..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:${BACKEND_PORT}/health >/dev/null 2>&1; then
            print_message "$GREEN" "✓ 后端服务启动成功"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        print_message "$RED" "✗ 后端服务启动超时"
        print_message "$YELLOW" "故障排除建议:"
        echo "  1. 检查后端容器日志: ${DOCKER_CMD} logs wiring-backend"
        echo "  2. 检查端口是否被占用: netstat -tuln | grep ${BACKEND_PORT}"
        echo "  3. 检查容器状态: ${DOCKER_CMD} ps -a"
        echo "  4. 重启后端服务: ${DOCKER_CMD} restart wiring-backend"
        
        read -p "是否继续检查前端服务? (y/n): " continue_choice
        if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
            exit 1
        fi
    fi
    
    print_message "$BLUE" "等待前端服务启动..."
    sleep 5
    
    # 检查前端服务
    local frontend_attempts=10
    local frontend_attempt=0
    
    while [ $frontend_attempt -lt $frontend_attempts ]; do
        if curl -s http://localhost:${FRONTEND_PORT} >/dev/null 2>&1; then
            print_message "$GREEN" "✓ 前端服务启动成功"
            break
        fi
        frontend_attempt=$((frontend_attempt + 1))
        echo -n "."
        sleep 2
    done
    
    if [ $frontend_attempt -eq $frontend_attempts ]; then
        print_message "$YELLOW" "⚠ 前端服务可能还在启动中"
        print_message "$YELLOW" "请稍后手动检查: http://localhost:${FRONTEND_PORT}"
    fi
}

################################################################################
# 函数：检查服务健康状态
# 参数：无
################################################################################
check_health() {
    print_step "9" "检查服务健康状态"
    
    # 确定是否需要使用sudo
    local DOCKER_CMD="docker"
    if [ "$EUID" -ne 0 ]; then
        DOCKER_CMD="sudo docker"
    fi
    
    # 检查后端容器状态
    if $DOCKER_CMD ps | grep -q "$BACKEND_CONTAINER"; then
        print_message "$GREEN" "✓ 后端容器运行中"
        $DOCKER_CMD ps --filter "name=$BACKEND_CONTAINER" --format "  状态: {{.Status}}"
    else
        print_message "$RED" "✗ 后端容器未运行"
        exit 1
    fi
    
    # 检查前端容器状态
    if $DOCKER_CMD ps | grep -q "$FRONTEND_CONTAINER"; then
        print_message "$GREEN" "✓ 前端容器运行中"
        $DOCKER_CMD ps --filter "name=$FRONTEND_CONTAINER" --format "  状态: {{.Status}}"
    else
        print_message "$RED" "✗ 前端容器未运行"
        exit 1
    fi
    
    # 检查后端健康接口
    if curl -s http://localhost:${BACKEND_PORT}/health >/dev/null 2>&1; then
        print_message "$GREEN" "✓ 后端健康检查通过"
    else
        print_message "$RED" "✗ 后端健康检查失败"
        exit 1
    fi
    
    # 检查前端访问
    if curl -s http://localhost:${FRONTEND_PORT} >/dev/null 2>&1; then
        print_message "$GREEN" "✓ 前端访问正常"
    else
        print_message "$RED" "✗ 前端访问失败"
        exit 1
    fi
}

################################################################################
# 函数：显示部署信息
# 参数：无
################################################################################
show_deployment_info() {
    print_step "10" "部署完成"
    
    # 确定是否需要使用sudo
    local DOCKER_CMD="docker"
    if [ "$EUID" -ne 0 ]; then
        DOCKER_CMD="sudo docker"
    fi
    
    # 获取服务器IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    print_separator
    print_message "$GREEN" "🎉 ${PROJECT_NAME} 部署成功！"
    print_separator
    
    echo ""
    print_message "$BLUE" "访问地址："
    echo "  本地访问: http://localhost"
    echo "  网络访问: http://${SERVER_IP}"
    echo ""
    
    print_message "$BLUE" "服务端口："
    echo "  前端端口: ${FRONTEND_PORT}"
    echo "  后端端口: ${BACKEND_PORT}"
    echo ""
    
    print_message "$BLUE" "容器状态："
    $DOCKER_CMD ps --filter "name=wiring-" --format "  {{.Names}}: {{.Status}}"
    echo ""
    
    print_message "$BLUE" "数据目录："
    echo "  数据库: ${BACKEND_DIR}/data"
    echo "  上传文件: ${BACKEND_DIR}/uploads"
    echo ""
    
    print_message "$BLUE" "常用命令："
    echo "  查看日志: docker compose -f ${CONFIG_DIR}/docker-compose.yml logs -f"
    echo "  停止服务: docker compose -f ${CONFIG_DIR}/docker-compose.yml down"
    echo "  重启服务: docker compose -f ${CONFIG_DIR}/docker-compose.yml restart"
    echo "  查看状态: docker compose -f ${CONFIG_DIR}/docker-compose.yml ps"
    echo ""
    
    print_message "$YELLOW" "⚠  注意事项："
    echo "  1. 首次部署后，请访问系统并上传Excel数据"
    echo "  2. 数据文件会持久化保存在 ${BACKEND_DIR}/data 目录"
    echo "  3. 上传的文件会保存在 ${BACKEND_DIR}/uploads 目录"
    echo "  4. 建议定期备份数据目录"
    echo ""
    
    print_separator
}

################################################################################
# 函数：显示使用帮助
# 参数：无
################################################################################
show_help() {
    echo "综合布线记录管理系统 - 一键部署脚本"
    echo ""
    echo "使用方法："
    echo "  $0                    # 完整部署（推荐）"
    echo "  $0 --check-only       # 仅检查环境"
    echo "  $0 --debug           # 启用调试模式"
    echo "  $0 --diagnose        # 运行诊断检查"
    echo "  $0 --help            # 显示帮助信息"
    echo ""
    echo "参数说明："
    echo "  --check-only          只检查环境，不执行部署"
    echo "  --debug               启用调试模式，输出详细日志"
    echo "  --diagnose           运行诊断检查，帮助定位问题"
    echo "  --help                显示此帮助信息"
    echo ""
    echo "示例："
    echo "  chmod +x $0"
    echo "  ./$0"
    echo "  ./$0 --debug"
    echo "  ./$0 --diagnose"
    echo ""
}

################################################################################
# 函数：运行诊断检查
# 参数：无
################################################################################
run_diagnose() {
    print_separator
    print_message "$BLUE" "系统诊断检查"
    print_separator
    echo ""
    
    # 检查系统信息
    print_message "$BLUE" "=== 系统信息 ==="
    echo "操作系统: $(uname -s) $(uname -r)"
    echo "架构: $(uname -m)"
    echo "用户: $(whoami)"
    echo "用户ID: $EUID"
    echo "当前目录: $(pwd)"
    echo ""
    
    # 检查Docker
    print_message "$BLUE" "=== Docker 检查 ==="
    if command_exists docker; then
        print_message "$GREEN" "✓ Docker命令存在"
        docker --version
    else
        print_message "$RED" "✗ Docker命令不存在"
    fi
    
    if pgrep -x "dockerd" >/dev/null 2>&1; then
        print_message "$GREEN" "✓ Docker守护进程运行中"
    else
        print_message "$RED" "✗ Docker守护进程未运行"
    fi
    
    if sudo systemctl is-active --quiet docker 2>/dev/null; then
        print_message "$GREEN" "✓ Docker服务运行中"
    else
        print_message "$RED" "✗ Docker服务未运行"
    fi
    
    echo ""
    
    # 检查Docker Compose
    print_message "$BLUE" "=== Docker Compose 检查 ==="
    if command_exists docker-compose; then
        print_message "$GREEN" "✓ docker-compose命令存在"
        docker-compose --version
    else
        print_message "$RED" "✗ docker-compose命令不存在"
    fi
    
    if sudo docker compose version >/dev/null 2>&1; then
        print_message "$GREEN" "✓ docker compose插件可用"
        sudo docker compose version --short
    else
        print_message "$RED" "✗ docker compose插件不可用"
    fi
    
    echo ""
    
    # 检查端口
    print_message "$BLUE" "=== 端口检查 ==="
    if netstat -tuln 2>/dev/null | grep -q ":${BACKEND_PORT} "; then
        print_message "$YELLOW" "⚠ 端口 ${BACKEND_PORT} 已被占用"
    else
        print_message "$GREEN" "✓ 端口 ${BACKEND_PORT} 可用"
    fi
    
    if netstat -tuln 2>/dev/null | grep -q ":${FRONTEND_PORT} "; then
        print_message "$YELLOW" "⚠ 端口 ${FRONTEND_PORT} 已被占用"
    else
        print_message "$GREEN" "✓ 端口 ${FRONTEND_PORT} 可用"
    fi
    
    echo ""
    
    # 检查磁盘空间
    print_message "$BLUE" "=== 磁盘空间检查 ==="
    df -h | grep -E "Filesystem|/$"
    echo ""
    
    # 检查Docker容器
    print_message "$BLUE" "=== Docker容器检查 ==="
    if sudo docker ps -a 2>/dev/null | grep -q "wiring-"; then
        print_message "$YELLOW" "发现旧的wiring容器:"
        sudo docker ps -a | grep "wiring-"
    else
        print_message "$GREEN" "✓ 没有旧的wiring容器"
    fi
    
    echo ""
    
    # 检查Docker镜像
    print_message "$BLUE" "=== Docker镜像检查 ==="
    local image_count=$(sudo docker images 2>/dev/null | wc -l)
    print_message "$BLUE" "Docker镜像数量: $((image_count - 1))"
    echo ""
    
    # 检查网络连接
    print_message "$BLUE" "=== 网络连接检查 ==="
    if ping -c 1 -W 2 registry-1.docker.io >/dev/null 2>&1; then
        print_message "$GREEN" "✓ 可以连接到Docker Hub"
    else
        print_message "$YELLOW" "⚠ 无法连接到Docker Hub (可能影响镜像下载)"
    fi
    
    echo ""
    print_separator
    print_message "$GREEN" "诊断完成"
    print_separator
}

################################################################################
# 函数：仅检查环境
# 参数：无
################################################################################
check_only() {
    print_message "$BLUE" "仅检查环境模式"
    check_docker
    check_docker_compose
    check_project_structure
    check_ports
    print_message "$GREEN" "✓ 环境检查完成"
}

################################################################################
# 主函数
# 参数：
#   $1 - 命令行参数
################################################################################
main() {
    # 打印欢迎信息
    print_separator
    print_message "$GREEN" "综合布线记录管理系统 - 一键自动部署"
    print_separator
    echo ""
    
    # 处理命令行参数
    case "$1" in
        --help)
            show_help
            exit 0
            ;;
        --check-only)
            check_only
            exit 0
            ;;
        --diagnose)
            run_diagnose
            exit 0
            ;;
        --debug)
            DEBUG_MODE=1
            print_message "$YELLOW" "调试模式已启用"
            ;;
    esac
    
    # 检查是否在项目根目录
    if [ ! -f "$CONFIG_DIR/docker-compose.yml" ]; then
        print_message "$RED" "错误：请在项目根目录下运行此脚本"
        print_message "$YELLOW" "当前目录: $(pwd)"
        print_message "$YELLOW" "查找文件: $CONFIG_DIR/docker-compose.yml"
        exit 1
    fi
    
    # 检查权限
    if ! check_root_permission; then
        print_message "$RED" "错误：需要root权限或sudo权限"
        print_message "$YELLOW" "请使用: sudo $0"
        exit 1
    fi
    
    # 更新Docker命令配置（在确定权限后）
    if [ "$EUID" -ne 0 ]; then
        DOCKER_CMD="sudo docker"
    else
        DOCKER_CMD="docker"
    fi
    
    print_debug "Docker命令: $DOCKER_CMD"
    print_debug "当前用户ID: $EUID"
    
    # 执行部署步骤
    check_docker
    configure_docker_mirror
    check_docker_compose
    check_project_structure
    check_ports
    create_data_dirs
    cleanup_old_containers
    build_and_start
    wait_for_services
    check_health
    show_deployment_info
    
    print_message "$GREEN" "部署完成！"
}

################################################################################
# 脚本入口点
################################################################################
main "$@"
