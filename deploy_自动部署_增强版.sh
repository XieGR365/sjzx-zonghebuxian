#!/bin/bash

################################################################################
# 综合布线记录管理系统 - 增强版一键自动部署脚本
# 
# 功能说明：
#   - 每步执行前检查环境是否满足要求
#   - 每步执行后验证任务是否如期完成
#   - 提供详细的反馈和错误处理
#   - 支持自动修复或手动干预
#
# 使用方法：
#   chmod +x deploy_自动部署_增强版.sh
#   ./deploy_自动部署_增强版.sh
#
# 系统要求：
#   - Linux系统（Ubuntu 20.04+, CentOS 7+, Debian 10+）
#   - Root权限或sudo权限
#   - 至少2GB可用内存
#   - 至少10GB可用磁盘空间
#
# 作者：综合布线记录管理系统开发团队
# 日期：2025-01-20
################################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

# 调试模式
DEBUG_MODE=0

# 步骤状态跟踪
STEP_STATUS_FILE="/tmp/deploy_status.log"
echo "部署开始时间: $(date)" > "$STEP_STATUS_FILE"

################################################################################
# 工具函数
################################################################################

print_debug() {
    if [ "$DEBUG_MODE" -eq 1 ]; then
        echo -e "${YELLOW}[DEBUG]${NC} $1"
    fi
}

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_separator() {
    echo "================================================================================"
}

print_step() {
    local step_num=$1
    local step_desc=$2
    print_separator
    echo -e "${BLUE}步骤 ${step_num}: ${step_desc}${NC}"
    print_separator
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}[信息]${NC} $1"
}

log_step() {
    local step_name=$1
    local status=$2
    local message=$3
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 步骤: $step_name | 状态: $status | 信息: $message" >> "$STEP_STATUS_FILE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

################################################################################
# 步骤检查和验证函数
################################################################################

# 检查前置条件
check_prerequisites() {
    local step_name=$1
    print_info "检查步骤前置条件: $step_name"
    
    case $step_name in
        "check_docker")
            check_docker_prerequisites
            ;;
        "configure_docker_mirror")
            check_docker_mirror_prerequisites
            ;;
        "check_docker_compose")
            check_docker_compose_prerequisites
            ;;
        "check_project_structure")
            check_project_structure_prerequisites
            ;;
        "check_ports")
            check_ports_prerequisites
            ;;
        "create_data_dirs")
            check_data_dirs_prerequisites
            ;;
        "cleanup_old_containers")
            check_cleanup_prerequisites
            ;;
        "build_and_start")
            check_build_prerequisites
            ;;
        "wait_for_services")
            check_services_prerequisites
            ;;
        "check_health")
            check_health_prerequisites
            ;;
        *)
            print_success "无需前置检查"
            return 0
            ;;
    esac
}

# 验证步骤结果
verify_step_result() {
    local step_name=$1
    print_info "验证步骤结果: $step_name"
    
    case $step_name in
        "check_docker")
            verify_docker_result
            ;;
        "configure_docker_mirror")
            verify_docker_mirror_result
            ;;
        "check_docker_compose")
            verify_docker_compose_result
            ;;
        "check_project_structure")
            verify_project_structure_result
            ;;
        "check_ports")
            verify_ports_result
            ;;
        "create_data_dirs")
            verify_data_dirs_result
            ;;
        "cleanup_old_containers")
            verify_cleanup_result
            ;;
        "build_and_start")
            verify_build_result
            ;;
        "wait_for_services")
            verify_services_result
            ;;
        "check_health")
            verify_health_result
            ;;
        *)
            print_success "无需验证"
            return 0
            ;;
    esac
}

# 处理步骤失败
handle_step_failure() {
    local step_name=$1
    local error_msg=$2
    
    print_error "步骤失败: $step_name"
    print_error "错误信息: $error_msg"
    log_step "$step_name" "失败" "$error_msg"
    
    echo ""
    print_warning "请选择处理方式:"
    echo "  1. 重试当前步骤"
    echo "  2. 跳过当前步骤（不推荐）"
    echo "  3. 查看详细日志"
    echo "  4. 退出部署"
    echo ""
    
    read -p "请输入选项 (1-4): " choice
    
    case $choice in
        1)
            print_info "重试当前步骤..."
            return 1
            ;;
        2)
            print_warning "跳过当前步骤"
            log_step "$step_name" "跳过" "用户选择跳过"
            return 0
            ;;
        3)
            print_info "查看详细日志:"
            cat "$STEP_STATUS_FILE"
            return 1
            ;;
        4)
            print_error "退出部署"
            exit 1
            ;;
        *)
            print_error "无效选项，退出部署"
            exit 1
            ;;
    esac
}

################################################################################
# 步骤1: 检查Docker环境
################################################################################

check_docker_prerequisites() {
    print_info "检查系统权限..."
    if [ "$EUID" -eq 0 ]; then
        print_success "以root用户运行"
    elif command_exists sudo && sudo -n true 2>/dev/null; then
        print_success "有sudo权限"
    else
        print_error "需要root权限或sudo权限"
        return 1
    fi
    
    print_info "检查系统类型..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_success "系统: $PRETTY_NAME"
    else
        print_error "无法检测系统类型"
        return 1
    fi
    
    print_info "检查内存..."
    local mem_mb=$(free -m | awk '/^Mem:/{print $2}')
    if [ $mem_mb -ge 2048 ]; then
        print_success "内存: ${mem_mb}MB (满足要求: ≥2GB)"
    else
        print_warning "内存: ${mem_mb}MB (建议: ≥2GB)"
    fi
    
    print_info "检查磁盘空间..."
    local disk_gb=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $disk_gb -ge 10 ]; then
        print_success "磁盘空间: ${disk_gb}GB (满足要求: ≥10GB)"
    else
        print_error "磁盘空间: ${disk_gb}GB (不满足要求: ≥10GB)"
        return 1
    fi
    
    return 0
}

verify_docker_result() {
    print_info "验证Docker安装..."
    
    if command_exists docker; then
        print_success "Docker命令存在"
        local version=$(docker --version 2>/dev/null)
        print_info "版本: $version"
    else
        print_error "Docker命令不存在"
        return 1
    fi
    
    if pgrep -x "dockerd" >/dev/null 2>&1; then
        print_success "Docker守护进程运行中"
    else
        print_error "Docker守护进程未运行"
        return 1
    fi
    
    if sudo systemctl is-active --quiet docker 2>/dev/null; then
        print_success "Docker服务运行中"
    else
        print_error "Docker服务未运行"
        return 1
    fi
    
    log_step "check_docker" "成功" "Docker环境检查完成"
    return 0
}

check_docker() {
    print_step "1" "检查Docker环境"
    
    if ! check_prerequisites "check_docker"; then
        handle_step_failure "check_docker" "前置条件检查失败"
        return 1
    fi
    
    if command_exists docker; then
        print_success "Docker已安装"
    else
        print_warning "Docker未安装"
        read -p "是否自动安装Docker? (y/n): " install_choice
        if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
            install_docker
        else
            print_error "请先安装Docker后再运行此脚本"
            exit 1
        fi
    fi
    
    if ! sudo systemctl is-active --quiet docker 2>/dev/null; then
        print_warning "Docker服务未运行，正在启动..."
        sudo systemctl start docker
        sleep 3
    fi
    
    if ! verify_step_result "check_docker"; then
        handle_step_failure "check_docker" "Docker环境验证失败"
        return 1
    fi
    
    print_success "步骤1完成: Docker环境检查"
    echo ""
}

install_docker() {
    print_info "正在安装Docker..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        print_error "无法检测系统类型"
        exit 1
    fi

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
            print_error "不支持的系统类型: ${OS}"
            exit 1
            ;;
    esac

    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    
    print_success "Docker安装完成"
    sleep 3
}

################################################################################
# 步骤1.5: 配置Docker镜像加速器
################################################################################

check_docker_mirror_prerequisites() {
    print_info "检查Docker配置目录..."
    if [ -d "/etc/docker" ]; then
        print_success "Docker配置目录存在"
    else
        print_info "Docker配置目录不存在，将创建"
    fi
    
    print_info "检查配置文件..."
    local config_file="$CONFIG_DIR/docker_mirror.conf"
    if [ -f "$config_file" ]; then
        print_success "找到配置文件: $config_file"
    else
        print_warning "未找到配置文件，将使用默认配置"
    fi
    
    return 0
}

verify_docker_mirror_result() {
    print_info "验证Docker镜像加速器配置..."
    
    if [ -f "/etc/docker/daemon.json" ]; then
        print_success "Docker配置文件存在"
        
        if $DOCKER_CMD info | grep -q "Registry Mirrors\|Insecure Registries"; then
            print_success "镜像加速器配置已生效"
            $DOCKER_CMD info | grep -A 10 "Registry Mirrors\|Insecure Registries" | sed 's/^/  /'
        else
            print_warning "镜像加速器配置可能未生效"
        fi
        
        if $DOCKER_CMD info | grep -q "DNS"; then
            print_success "DNS配置已生效"
        fi
    else
        print_error "Docker配置文件不存在"
        return 1
    fi
    
    log_step "configure_docker_mirror" "成功" "Docker镜像加速器配置完成"
    return 0
}

configure_docker_mirror() {
    print_step "1.5" "配置Docker镜像加速器"
    
    if ! check_prerequisites "configure_docker_mirror"; then
        handle_step_failure "configure_docker_mirror" "前置条件检查失败"
        return 1
    fi
    
    local config_file="$CONFIG_DIR/docker_mirror.conf"
    if [ -f "$config_file" ]; then
        print_info "找到镜像源配置文件: $config_file"
        source "$config_file"
        
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
                print_warning "未知的镜像源类型: $MIRROR_TYPE，使用默认配置"
                configure_default_mirrors
                ;;
        esac
    else
        print_warning "未找到镜像源配置文件，使用默认配置"
        configure_default_mirrors
    fi
    
    if ! verify_step_result "configure_docker_mirror"; then
        handle_step_failure "configure_docker_mirror" "镜像加速器配置验证失败"
        return 1
    fi
    
    print_success "步骤1.5完成: Docker镜像加速器配置"
    echo ""
}

configure_default_mirrors() {
    print_info "配置默认镜像加速器..."
    sudo mkdir -p /etc/docker
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

configure_aliyun_mirrors() {
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
    restart_docker_service
}

configure_custom_mirrors() {
    print_info "配置自定义镜像加速器..."
    sudo mkdir -p /etc/docker
    
    local mirrors_json=""
    for mirror in "${CUSTOM_MIRRORS[@]}"; do
        if [ -n "$mirrors_json" ]; then
            mirrors_json="$mirrors_json,"
        fi
        mirrors_json="$mirrors_json    \"$mirror\""
    done
    
    local dns_json=""
    for dns in "${DNS_SERVERS[@]}"; do
        if [ -n "$dns_json" ]; then
            dns_json="$dns_json,"
        fi
        dns_json="$dns_json    \"$dns\""
    done
    
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

configure_private_registry() {
    print_info "配置私有Docker镜像仓库: $PRIVATE_REGISTRY"
    sudo mkdir -p /etc/docker
    
    local insecure_json=""
    if [ "$INSECURE_REGISTRY" = "true" ]; then
        insecure_json="  \"insecure-registries\": [\"$PRIVATE_REGISTRY\"],"
    fi
    
    local dns_json=""
    for dns in "${DNS_SERVERS[@]}"; do
        if [ -n "$dns_json" ]; then
            dns_json="$dns_json,"
        fi
        dns_json="$dns_json    \"$dns\""
    done
    
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
    
    print_info "配置完成后，可以使用以下命令拉取镜像："
    echo "  $DOCKER_CMD pull $PRIVATE_REGISTRY/node:18-alpine"
    echo "  $DOCKER_CMD pull $PRIVATE_REGISTRY/nginx:alpine"
}

configure_dns_only() {
    print_info "仅配置DNS服务器..."
    sudo mkdir -p /etc/docker
    
    local dns_json=""
    for dns in "${DNS_SERVERS[@]}"; do
        if [ -n "$dns_json" ]; then
            dns_json="$dns_json,"
        fi
        dns_json="$dns_json    \"$dns\""
    done
    
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

restart_docker_service() {
    print_info "重启Docker服务以应用配置..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    sleep 5
    
    if $DOCKER_CMD info | grep -q "Registry Mirrors\|Insecure Registries"; then
        print_success "Docker镜像加速器配置成功"
    else
        print_warning "镜像加速器配置可能未生效"
    fi
}

################################################################################
# 步骤2: 检查Docker Compose
################################################################################

check_docker_compose_prerequisites() {
    print_info "检查Docker安装状态..."
    if command_exists docker; then
        print_success "Docker已安装"
    else
        print_error "Docker未安装"
        return 1
    fi
    
    return 0
}

verify_docker_compose_result() {
    print_info "验证Docker Compose..."
    
    local compose_found=0
    local compose_cmd=""
    
    if $DOCKER_CMD compose version >/dev/null 2>&1; then
        compose_found=1
        compose_cmd="$DOCKER_CMD compose"
        print_success "Docker Compose插件可用"
        local version=$($DOCKER_CMD compose version --short 2>/dev/null)
        print_info "版本: $version"
    fi
    
    if [ $compose_found -eq 0 ] && command_exists docker-compose; then
        compose_found=1
        compose_cmd="docker-compose"
        print_success "Docker Compose独立版可用"
        local version=$(docker-compose --version 2>/dev/null | awk '{print $3}' | sed 's/,//')
        print_info "版本: $version"
    fi
    
    if [ $compose_found -eq 0 ]; then
        print_error "Docker Compose不可用"
        return 1
    fi
    
    log_step "check_docker_compose" "成功" "Docker Compose检查完成"
    return 0
}

check_docker_compose() {
    print_step "2" "检查Docker Compose"
    
    if ! check_prerequisites "check_docker_compose"; then
        handle_step_failure "check_docker_compose" "前置条件检查失败"
        return 1
    fi
    
    local compose_found=0
    local COMPOSE_CMD=""
    
    if $DOCKER_CMD compose version >/dev/null 2>&1; then
        compose_found=1
        COMPOSE_CMD="$DOCKER_CMD compose"
        print_success "Docker Compose已安装"
    fi
    
    if [ $compose_found -eq 0 ] && command_exists docker-compose; then
        compose_found=1
        COMPOSE_CMD="docker-compose"
        print_success "Docker Compose已安装"
    fi
    
    if [ $compose_found -eq 0 ]; then
        print_warning "Docker Compose未安装"
        print_info "正在安装Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        print_success "Docker Compose安装完成"
    fi
    
    if ! verify_step_result "check_docker_compose"; then
        handle_step_failure "check_docker_compose" "Docker Compose验证失败"
        return 1
    fi
    
    print_success "步骤2完成: Docker Compose检查"
    echo ""
}

################################################################################
# 步骤3: 检查项目目录结构
################################################################################

check_project_structure_prerequisites() {
    print_info "检查当前目录..."
    print_info "当前目录: $(pwd)"
    
    if [ -f "$CONFIG_DIR/docker-compose.yml" ]; then
        print_success "找到docker-compose.yml"
    else
        print_error "未找到docker-compose.yml"
        return 1
    fi
    
    return 0
}

verify_project_structure_result() {
    print_info "验证项目目录结构..."
    
    local all_ok=true
    
    if [ -d "$BACKEND_DIR" ]; then
        print_success "后端目录存在"
    else
        print_error "后端目录不存在"
        all_ok=false
    fi
    
    if [ -d "$FRONTEND_DIR" ]; then
        print_success "前端目录存在"
    else
        print_error "前端目录不存在"
        all_ok=false
    fi
    
    if [ -d "$CONFIG_DIR" ]; then
        print_success "配置目录存在"
    else
        print_error "配置目录不存在"
        all_ok=false
    fi
    
    if [ -f "$CONFIG_DIR/docker-compose.yml" ]; then
        print_success "Docker Compose配置文件存在"
    else
        print_error "Docker Compose配置文件不存在"
        all_ok=false
    fi
    
    if [ -f "$BACKEND_DIR/Dockerfile" ]; then
        print_success "后端Dockerfile存在"
    else
        print_error "后端Dockerfile不存在"
        all_ok=false
    fi
    
    if [ -f "$FRONTEND_DIR/Dockerfile" ]; then
        print_success "前端Dockerfile存在"
    else
        print_error "前端Dockerfile不存在"
        all_ok=false
    fi
    
    if [ "$all_ok" = "false" ]; then
        return 1
    fi
    
    log_step "check_project_structure" "成功" "项目目录结构检查完成"
    return 0
}

check_project_structure() {
    print_step "3" "检查项目目录结构"
    
    if ! check_prerequisites "check_project_structure"; then
        handle_step_failure "check_project_structure" "前置条件检查失败"
        return 1
    fi
    
    if ! verify_step_result "check_project_structure"; then
        handle_step_failure "check_project_structure" "项目目录结构验证失败"
        return 1
    fi
    
    print_success "步骤3完成: 项目目录结构检查"
    echo ""
}

################################################################################
# 步骤4: 检查端口占用情况
################################################################################

check_ports_prerequisites() {
    print_info "检查网络工具..."
    if command_exists netstat; then
        print_success "netstat命令可用"
    elif command_exists ss; then
        print_success "ss命令可用"
    else
        print_warning "网络检查工具不可用"
    fi
    
    return 0
}

verify_ports_result() {
    print_info "验证端口占用情况..."
    
    local netstat_cmd="netstat"
    if ! command_exists netstat && command_exists ss; then
        netstat_cmd="ss"
    fi
    
    local backend_ok=true
    local frontend_ok=true
    
    if $netstat_cmd -tuln 2>/dev/null | grep -q ":${BACKEND_PORT} "; then
        print_warning "后端端口 ${BACKEND_PORT} 已被占用"
        backend_ok=false
    else
        print_success "后端端口 ${BACKEND_PORT} 可用"
    fi
    
    if $netstat_cmd -tuln 2>/dev/null | grep -q ":${FRONTEND_PORT} "; then
        print_warning "前端端口 ${FRONTEND_PORT} 已被占用"
        frontend_ok=false
    else
        print_success "前端端口 ${FRONTEND_PORT} 可用"
    fi
    
    if [ "$backend_ok" = "false" ] || [ "$frontend_ok" = "false" ]; then
        print_warning "部分端口被占用，请确认是否继续"
        read -p "是否继续? (y/n): " continue_choice
        if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
            return 1
        fi
    fi
    
    log_step "check_ports" "成功" "端口检查完成"
    return 0
}

check_ports() {
    print_step "4" "检查端口占用情况"
    
    if ! check_prerequisites "check_ports"; then
        handle_step_failure "check_ports" "前置条件检查失败"
        return 1
    fi
    
    if ! verify_step_result "check_ports"; then
        handle_step_failure "check_ports" "端口验证失败"
        return 1
    fi
    
    print_success "步骤4完成: 端口占用情况检查"
    echo ""
}

################################################################################
# 步骤5: 创建数据持久化目录
################################################################################

check_data_dirs_prerequisites() {
    print_info "检查磁盘权限..."
    if [ -w "." ]; then
        print_success "当前目录可写"
    else
        print_error "当前目录不可写"
        return 1
    fi
    
    return 0
}

verify_data_dirs_result() {
    print_info "验证数据目录..."
    
    local all_ok=true
    
    if [ -d "$BACKEND_DIR/data" ]; then
        print_success "后端数据目录存在"
    else
        print_error "后端数据目录不存在"
        all_ok=false
    fi
    
    if [ -d "$BACKEND_DIR/uploads" ]; then
        print_success "后端上传目录存在"
    else
        print_error "后端上传目录不存在"
        all_ok=false
    fi
    
    if [ "$all_ok" = "false" ]; then
        return 1
    fi
    
    log_step "create_data_dirs" "成功" "数据目录创建完成"
    return 0
}

create_data_dirs() {
    print_step "5" "创建数据持久化目录"
    
    if ! check_prerequisites "create_data_dirs"; then
        handle_step_failure "create_data_dirs" "前置条件检查失败"
        return 1
    fi
    
    if [ ! -d "$BACKEND_DIR/data" ]; then
        mkdir -p "$BACKEND_DIR/data"
        print_success "创建后端数据目录"
    else
        print_success "后端数据目录已存在"
    fi
    
    if [ ! -d "$BACKEND_DIR/uploads" ]; then
        mkdir -p "$BACKEND_DIR/uploads"
        print_success "创建后端上传目录"
    else
        print_success "后端上传目录已存在"
    fi
    
    chmod 755 "$BACKEND_DIR/data"
    chmod 755 "$BACKEND_DIR/uploads"
    print_success "目录权限设置完成"
    
    if ! verify_step_result "create_data_dirs"; then
        handle_step_failure "create_data_dirs" "数据目录验证失败"
        return 1
    fi
    
    print_success "步骤5完成: 数据持久化目录创建"
    echo ""
}

################################################################################
# 步骤6: 清理旧容器和镜像
################################################################################

check_cleanup_prerequisites() {
    print_info "检查Docker服务状态..."
    if sudo systemctl is-active --quiet docker 2>/dev/null; then
        print_success "Docker服务运行中"
    else
        print_error "Docker服务未运行"
        return 1
    fi
    
    return 0
}

verify_cleanup_result() {
    print_info "验证清理结果..."
    
    local cleanup_ok=true
    
    if $DOCKER_CMD ps -a | grep -q "$BACKEND_CONTAINER"; then
        print_warning "后端容器仍然存在"
        cleanup_ok=false
    else
        print_success "后端容器已清理"
    fi
    
    if $DOCKER_CMD ps -a | grep -q "$FRONTEND_CONTAINER"; then
        print_warning "前端容器仍然存在"
        cleanup_ok=false
    else
        print_success "前端容器已清理"
    fi
    
    if $DOCKER_CMD network ls | grep -q "$NETWORK_NAME"; then
        print_warning "网络仍然存在"
        cleanup_ok=false
    else
        print_success "网络已清理"
    fi
    
    if [ "$cleanup_ok" = "false" ]; then
        print_warning "部分资源未清理，但将继续部署"
    fi
    
    log_step "cleanup_old_containers" "成功" "旧容器和镜像清理完成"
    return 0
}

cleanup_old_containers() {
    print_step "6" "清理旧容器和镜像"
    
    if ! check_prerequisites "cleanup_old_containers"; then
        handle_step_failure "cleanup_old_containers" "前置条件检查失败"
        return 1
    fi
    
    if $DOCKER_CMD ps -a | grep -q "$BACKEND_CONTAINER"; then
        print_info "停止旧的后端容器..."
        if ! $DOCKER_CMD stop "$BACKEND_CONTAINER" 2>/dev/null; then
            print_warning "正常停止失败，尝试强制停止..."
            $DOCKER_CMD kill "$BACKEND_CONTAINER" 2>/dev/null || true
        fi
        
        print_info "删除旧的后端容器..."
        $DOCKER_CMD rm -f "$BACKEND_CONTAINER" 2>/dev/null || true
        print_success "后端容器已清理"
    else
        print_success "后端容器不存在，跳过"
    fi
    
    if $DOCKER_CMD ps -a | grep -q "$FRONTEND_CONTAINER"; then
        print_info "停止旧的前端容器..."
        if ! $DOCKER_CMD stop "$FRONTEND_CONTAINER" 2>/dev/null; then
            print_warning "正常停止失败，尝试强制停止..."
            $DOCKER_CMD kill "$FRONTEND_CONTAINER" 2>/dev/null || true
        fi
        
        print_info "删除旧的前端容器..."
        $DOCKER_CMD rm -f "$FRONTEND_CONTAINER" 2>/dev/null || true
        print_success "前端容器已清理"
    else
        print_success "前端容器不存在，跳过"
    fi
    
    if $DOCKER_CMD network ls | grep -q "$NETWORK_NAME"; then
        print_info "删除旧的网络..."
        $DOCKER_CMD network rm "$NETWORK_NAME" 2>/dev/null || true
        print_success "网络已清理"
    else
        print_success "网络不存在，跳过"
    fi
    
    if ! verify_step_result "cleanup_old_containers"; then
        handle_step_failure "cleanup_old_containers" "清理验证失败"
        return 1
    fi
    
    print_success "步骤6完成: 旧容器和镜像清理"
    echo ""
}

################################################################################
# 步骤7: 构建并启动服务
################################################################################

check_build_prerequisites() {
    print_info "检查Docker Compose配置..."
    if [ -f "$CONFIG_DIR/docker-compose.yml" ]; then
        print_success "Docker Compose配置文件存在"
    else
        print_error "Docker Compose配置文件不存在"
        return 1
    fi
    
    print_info "检查网络连接..."
    if ping -c 1 -W 2 registry-1.docker.io >/dev/null 2>&1; then
        print_success "可以连接到Docker Hub"
    else
        print_warning "无法连接到Docker Hub"
        print_info "将使用镜像加速器下载镜像"
    fi
    
    return 0
}

verify_build_result() {
    print_info "验证服务构建结果..."
    
    local backend_running=false
    local frontend_running=false
    
    if $DOCKER_CMD ps | grep -q "$BACKEND_CONTAINER"; then
        print_success "后端容器运行中"
        backend_running=true
    else
        print_error "后端容器未运行"
    fi
    
    if $DOCKER_CMD ps | grep -q "$FRONTEND_CONTAINER"; then
        print_success "前端容器运行中"
        frontend_running=true
    else
        print_error "前端容器未运行"
    fi
    
    if [ "$backend_running" = "false" ] || [ "$frontend_running" = "false" ]; then
        return 1
    fi
    
    log_step "build_and_start" "成功" "服务构建并启动完成"
    return 0
}

build_and_start() {
    print_step "7" "构建并启动服务"
    
    if ! check_prerequisites "build_and_start"; then
        handle_step_failure "build_and_start" "前置条件检查失败"
        return 1
    fi
    
    print_info "当前目录: $(pwd)"
    cd "$CONFIG_DIR" || exit 1
    print_info "切换到配置目录: $(pwd)"
    
    local COMPOSE_CMD=""
    if $DOCKER_CMD compose version >/dev/null 2>&1; then
        COMPOSE_CMD="$DOCKER_CMD compose"
    elif command_exists docker-compose; then
        COMPOSE_CMD="docker-compose"
        if [ "$EUID" -ne 0 ]; then
            COMPOSE_CMD="sudo docker-compose"
        fi
    else
        print_error "Docker Compose未找到"
        exit 1
    fi
    
    print_info "开始构建Docker镜像..."
    print_info "使用命令: ${COMPOSE_CMD}"
    print_warning "构建过程可能需要几分钟，请耐心等待..."
    echo ""
    
    local build_log="/tmp/docker-compose-build.log"
    $COMPOSE_CMD up -d --build > "$build_log" 2>&1 &
    local build_pid=$!
    
    print_info "构建进程已启动 (PID: ${build_pid})"
    
    local timeout=600
    local elapsed=0
    local interval=10
    
    while kill -0 $build_pid 2>/dev/null; do
        sleep $interval
        elapsed=$((elapsed + interval))
        
        local progress=$((elapsed / 10))
        echo -ne "\r${YELLOW}构建中... ${progress}秒 elapsed${NC}"
        
        if [ $elapsed -ge $timeout ]; then
            echo ""
            print_error "构建超时 (${timeout}秒)"
            kill $build_pid 2>/dev/null || true
            wait $build_pid 2>/dev/null || true
            
            print_info "查看构建日志:"
            tail -n 50 "$build_log"
            
            read -p "是否继续尝试启动已构建的服务? (y/n): " continue_choice
            if [ "$continue_choice" = "y" ] || [ "$continue_choice" = "Y" ]; then
                $COMPOSE_CMD up -d
            fi
            exit 1
        fi
    done
    
    echo ""
    
    wait $build_pid
    local build_exit_code=$?
    
    if [ $build_exit_code -eq 0 ]; then
        print_success "服务构建并启动成功"
    else
        print_error "服务构建或启动失败 (退出码: ${build_exit_code})"
        print_info "查看详细构建日志:"
        tail -n 100 "$build_log"
        
        read -p "是否尝试仅启动已构建的服务? (y/n): " start_choice
        if [ "$start_choice" = "y" ] || [ "$start_choice" = "Y" ]; then
            print_info "尝试启动服务..."
            $COMPOSE_CMD up -d
            if [ $? -eq 0 ]; then
                print_success "服务启动成功"
            else
                exit 1
            fi
        fi
    fi
    
    if ! verify_step_result "build_and_start"; then
        handle_step_failure "build_and_start" "服务构建验证失败"
        return 1
    fi
    
    print_success "步骤7完成: 服务构建并启动"
    echo ""
}

################################################################################
# 步骤8: 等待服务启动
################################################################################

check_services_prerequisites() {
    print_info "检查容器状态..."
    
    if $DOCKER_CMD ps | grep -q "$BACKEND_CONTAINER"; then
        print_success "后端容器存在"
    else
        print_error "后端容器不存在"
        return 1
    fi
    
    if $DOCKER_CMD ps | grep -q "$FRONTEND_CONTAINER"; then
        print_success "前端容器存在"
    else
        print_error "前端容器不存在"
        return 1
    fi
    
    return 0
}

verify_services_result() {
    print_info "验证服务启动状态..."
    
    local backend_ready=false
    local frontend_ready=false
    
    if curl -s http://localhost:${BACKEND_PORT}/health >/dev/null 2>&1; then
        print_success "后端服务响应正常"
        backend_ready=true
    else
        print_error "后端服务无响应"
    fi
    
    if curl -s http://localhost:${FRONTEND_PORT} >/dev/null 2>&1; then
        print_success "前端服务响应正常"
        frontend_ready=true
    else
        print_error "前端服务无响应"
    fi
    
    if [ "$backend_ready" = "false" ] || [ "$frontend_ready" = "false" ]; then
        return 1
    fi
    
    log_step "wait_for_services" "成功" "服务启动完成"
    return 0
}

wait_for_services() {
    print_step "8" "等待服务启动"
    
    if ! check_prerequisites "wait_for_services"; then
        handle_step_failure "wait_for_services" "前置条件检查失败"
        return 1
    fi
    
    print_info "等待后端服务启动..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:${BACKEND_PORT}/health >/dev/null 2>&1; then
            print_success "后端服务启动成功"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    echo ""
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "后端服务启动超时"
        print_info "查看后端日志: $DOCKER_CMD logs $BACKEND_CONTAINER"
        return 1
    fi
    
    print_info "等待前端服务启动..."
    attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:${FRONTEND_PORT} >/dev/null 2>&1; then
            print_success "前端服务启动成功"
            break
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    echo ""
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "前端服务启动超时"
        print_info "查看前端日志: $DOCKER_CMD logs $FRONTEND_CONTAINER"
        return 1
    fi
    
    if ! verify_step_result "wait_for_services"; then
        handle_step_failure "wait_for_services" "服务启动验证失败"
        return 1
    fi
    
    print_success "步骤8完成: 服务启动"
    echo ""
}

################################################################################
# 步骤9: 健康检查
################################################################################

check_health_prerequisites() {
    print_info "检查服务可用性..."
    
    if curl -s http://localhost:${BACKEND_PORT}/health >/dev/null 2>&1; then
        print_success "后端服务可访问"
    else
        print_error "后端服务不可访问"
        return 1
    fi
    
    return 0
}

verify_health_result() {
    print_info "验证健康检查结果..."
    
    local health_ok=true
    
    if curl -s http://localhost:${BACKEND_PORT}/health >/dev/null 2>&1; then
        print_success "后端健康检查通过"
    else
        print_error "后端健康检查失败"
        health_ok=false
    fi
    
    if curl -s http://localhost:${FRONTEND_PORT} >/dev/null 2>&1; then
        print_success "前端健康检查通过"
    else
        print_error "前端健康检查失败"
        health_ok=false
    fi
    
    if [ "$health_ok" = "false" ]; then
        return 1
    fi
    
    log_step "check_health" "成功" "健康检查完成"
    return 0
}

check_health() {
    print_step "9" "健康检查"
    
    if ! check_prerequisites "check_health"; then
        handle_step_failure "check_health" "前置条件检查失败"
        return 1
    fi
    
    print_info "检查后端服务健康状态..."
    local backend_health=$(curl -s http://localhost:${BACKEND_PORT}/health 2>/dev/null)
    if [ $? -eq 0 ]; then
        print_success "后端服务健康"
        print_info "响应: $backend_health"
    else
        print_error "后端服务不健康"
    fi
    
    print_info "检查前端服务健康状态..."
    if curl -s http://localhost:${FRONTEND_PORT} >/dev/null 2>&1; then
        print_success "前端服务健康"
    else
        print_error "前端服务不健康"
    fi
    
    if ! verify_step_result "check_health"; then
        handle_step_failure "check_health" "健康检查验证失败"
        return 1
    fi
    
    print_success "步骤9完成: 健康检查"
    echo ""
}

################################################################################
# 步骤10: 显示部署信息
################################################################################

show_deployment_info() {
    print_step "10" "显示部署信息"
    
    print_separator
    print_message "$GREEN" "部署完成！"
    print_separator
    echo ""
    
    print_info "服务访问地址:"
    echo "  前端服务: http://localhost:${FRONTEND_PORT}"
    echo "  后端API: http://localhost:${BACKEND_PORT}"
    echo ""
    
    print_info "容器状态:"
    $DOCKER_CMD ps --filter "name=wiring-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    print_info "查看日志:"
    echo "  后端日志: $DOCKER_CMD logs -f $BACKEND_CONTAINER"
    echo "  前端日志: $DOCKER_CMD logs -f $FRONTEND_CONTAINER"
    echo ""
    
    print_info "管理命令:"
    echo "  停止服务: cd $CONFIG_DIR && $DOCKER_CMD compose down"
    echo "  重启服务: cd $CONFIG_DIR && $DOCKER_CMD compose restart"
    echo "  查看状态: $DOCKER_CMD ps"
    echo ""
    
    print_info "部署日志: $STEP_STATUS_FILE"
    echo ""
    
    log_step "show_deployment_info" "成功" "部署信息显示完成"
}

################################################################################
# 主函数
################################################################################

main() {
    print_separator
    print_message "$GREEN" "综合布线记录管理系统 - 增强版一键自动部署"
    print_separator
    echo ""
    
    print_info "部署开始时间: $(date)"
    echo ""
    
    if [ ! -f "$CONFIG_DIR/docker-compose.yml" ]; then
        print_error "错误：请在项目根目录下运行此脚本"
        print_info "当前目录: $(pwd)"
        exit 1
    fi
    
    if ! check_root_permission; then
        print_error "错误：需要root权限或sudo权限"
        print_info "请使用: sudo $0"
        exit 1
    fi
    
    local retry_count=0
    local max_retries=3
    
    while [ $retry_count -lt $max_retries ]; do
        print_info "开始部署 (尝试 $((retry_count + 1))/$max_retries)..."
        echo ""
        
        check_docker || return 1
        configure_docker_mirror || return 1
        check_docker_compose || return 1
        check_project_structure || return 1
        check_ports || return 1
        create_data_dirs || return 1
        cleanup_old_containers || return 1
        build_and_start || return 1
        wait_for_services || return 1
        check_health || return 1
        show_deployment_info
        
        print_separator
        print_message "$GREEN" "所有步骤完成！"
        print_separator
        echo ""
        print_info "部署完成时间: $(date)"
        print_info "部署日志: $STEP_STATUS_FILE"
        echo ""
        
        return 0
    done
    
    print_error "部署失败，已达到最大重试次数"
    exit 1
}

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

main "$@"
