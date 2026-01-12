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
    print_message "$YELLOW" "请重新登录以使docker组权限生效"
}

################################################################################
# 函数：检查并安装Docker
# 参数：无
################################################################################
check_docker() {
    print_step "1" "检查Docker环境"
    
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        print_message "$GREEN" "✓ Docker已安装 (版本: ${DOCKER_VERSION})"
    else
        print_message "$YELLOW" "✗ Docker未安装"
        read -p "是否自动安装Docker? (y/n): " install_choice
        if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
            install_docker
        else
            print_message "$RED" "请先安装Docker后再运行此脚本"
            exit 1
        fi
    fi
    
    # 检查Docker服务状态
    if ! sudo systemctl is-active --quiet docker; then
        print_message "$YELLOW" "Docker服务未运行，正在启动..."
        sudo systemctl start docker
    fi
    
    print_message "$GREEN" "✓ Docker服务运行正常"
}

################################################################################
# 函数：检查Docker Compose
# 参数：无
################################################################################
check_docker_compose() {
    print_step "2" "检查Docker Compose"
    
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version --short)
        print_message "$GREEN" "✓ Docker Compose已安装 (版本: ${COMPOSE_VERSION})"
    elif command_exists docker-compose; then
        COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
        print_message "$GREEN" "✓ Docker Compose已安装 (版本: ${COMPOSE_VERSION})"
    else
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
    
    # 检查后端端口
    if sudo netstat -tuln | grep -q ":${BACKEND_PORT} "; then
        print_message "$YELLOW" "⚠ 端口 ${BACKEND_PORT} 已被占用"
        read -p "是否继续? (y/n): " continue_choice
        if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
            exit 1
        fi
    else
        print_message "$GREEN" "✓ 后端端口 ${BACKEND_PORT} 可用"
    fi
    
    # 检查前端端口
    if sudo netstat -tuln | grep -q ":${FRONTEND_PORT} "; then
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
# 函数：停止并清理旧容器
# 参数：无
################################################################################
cleanup_old_containers() {
    print_step "6" "清理旧容器和镜像"
    
    # 停止并删除旧容器
    if docker ps -a | grep -q "$BACKEND_CONTAINER"; then
        print_message "$YELLOW" "停止旧的后端容器..."
        docker stop "$BACKEND_CONTAINER" 2>/dev/null
        docker rm "$BACKEND_CONTAINER" 2>/dev/null
        print_message "$GREEN" "✓ 后端容器已清理"
    fi
    
    if docker ps -a | grep -q "$FRONTEND_CONTAINER"; then
        print_message "$YELLOW" "停止旧的前端容器..."
        docker stop "$FRONTEND_CONTAINER" 2>/dev/null
        docker rm "$FRONTEND_CONTAINER" 2>/dev/null
        print_message "$GREEN" "✓ 前端容器已清理"
    fi
    
    # 清理旧网络
    if docker network ls | grep -q "$NETWORK_NAME"; then
        docker network rm "$NETWORK_NAME" 2>/dev/null
        print_message "$GREEN" "✓ 旧网络已清理"
    fi
}

################################################################################
# 函数：构建并启动服务
# 参数：无
################################################################################
build_and_start() {
    print_step "7" "构建并启动服务"
    
    # 进入配置目录
    cd "$CONFIG_DIR" || exit 1
    
    print_message "$BLUE" "开始构建Docker镜像..."
    
    # 构建并启动所有服务
    if docker compose up -d --build; then
        print_message "$GREEN" "✓ 服务构建并启动成功"
    else
        print_message "$RED" "✗ 服务构建或启动失败"
        exit 1
    fi
    
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
        exit 1
    fi
    
    print_message "$BLUE" "等待前端服务启动..."
    sleep 5
    print_message "$GREEN" "✓ 前端服务启动成功"
}

################################################################################
# 函数：检查服务健康状态
# 参数：无
################################################################################
check_health() {
    print_step "9" "检查服务健康状态"
    
    # 检查后端容器状态
    if docker ps | grep -q "$BACKEND_CONTAINER"; then
        print_message "$GREEN" "✓ 后端容器运行中"
        docker ps --filter "name=$BACKEND_CONTAINER" --format "  状态: {{.Status}}"
    else
        print_message "$RED" "✗ 后端容器未运行"
        exit 1
    fi
    
    # 检查前端容器状态
    if docker ps | grep -q "$FRONTEND_CONTAINER"; then
        print_message "$GREEN" "✓ 前端容器运行中"
        docker ps --filter "name=$FRONTEND_CONTAINER" --format "  状态: {{.Status}}"
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
    docker ps --filter "name=wiring-" --format "  {{.Names}}: {{.Status}}"
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
    echo "  $0 --help            # 显示帮助信息"
    echo ""
    echo "参数说明："
    echo "  --check-only          只检查环境，不执行部署"
    echo "  --help                显示此帮助信息"
    echo ""
    echo "示例："
    echo "  chmod +x $0"
    echo "  ./$0"
    echo ""
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
    esac
    
    # 检查是否在项目根目录
    if [ ! -f "$CONFIG_DIR/docker-compose.yml" ]; then
        print_message "$RED" "错误：请在项目根目录下运行此脚本"
        exit 1
    fi
    
    # 检查权限
    if ! check_root_permission; then
        print_message "$RED" "错误：需要root权限或sudo权限"
        print_message "$YELLOW" "请使用: sudo $0"
        exit 1
    fi
    
    # 执行部署步骤
    check_docker
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
