#!/bin/bash

################################################################################
# 综合布线记录管理系统 - 服务管理脚本
# 
# 功能：管理综合布线记录管理系统的各项服务
# 适用系统：Ubuntu 20.04+, CentOS 7+, Debian 10+
# 作者：系统自动生成
# 版本：v1.0.0
################################################################################

set -e

################################################################################
# 颜色定义
################################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# 配置变量
################################################################################

PROJECT_NAME="综合布线记录管理系统"
PROJECT_DIR="/opt/sjzx-zonghebuxian"
BACKUP_DIR="${PROJECT_DIR}/backup"
LOG_DIR="${PROJECT_DIR}/logs"
DB_DIR="${PROJECT_DIR}/backend/data"
UPLOAD_DIR="${PROJECT_DIR}/backend/uploads"

################################################################################
# 辅助函数
################################################################################

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_menu() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}$PROJECT_NAME 服务管理${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "1. 启动服务"
    echo "2. 停止服务"
    echo "3. 重启服务"
    echo "4. 查看服务状态"
    echo "5. 查看服务日志"
    echo "6. 备份数据"
    echo "7. 清理资源"
    echo "8. 更新服务"
    echo "9. 查看系统信息"
    echo "0. 退出"
    echo -e "${BLUE}========================================${NC}"
}

check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose未安装"
        return 1
    fi
    
    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "项目目录不存在: $PROJECT_DIR"
        return 1
    fi
    
    if [ ! -f "${PROJECT_DIR}/docker-compose.yml" ]; then
        print_error "Docker Compose配置文件不存在"
        return 1
    fi
    
    return 0
}

################################################################################
# 启动服务
################################################################################

start_services() {
    print_info "启动服务..."
    
    if ! check_docker_compose; then
        return 1
    fi
    
    cd "$PROJECT_DIR"
    
    print_info "检查Docker Compose配置..."
    if docker-compose config &> /dev/null; then
        print_success "Docker Compose配置检查通过"
    else
        print_error "Docker Compose配置检查失败"
        return 1
    fi
    
    print_info "启动服务..."
    if docker-compose up -d; then
        print_success "服务启动成功"
        
        print_info "等待服务启动（30秒）..."
        sleep 30
        
        print_info "检查服务状态..."
        docker-compose ps
        
        return 0
    else
        print_error "服务启动失败"
        return 1
    fi
}

################################################################################
# 停止服务
################################################################################

stop_services() {
    print_info "停止服务..."
    
    if ! check_docker_compose; then
        return 1
    fi
    
    cd "$PROJECT_DIR"
    
    print_info "停止服务..."
    if docker-compose down; then
        print_success "服务停止成功"
        return 0
    else
        print_error "服务停止失败"
        return 1
    fi
}

################################################################################
# 重启服务
################################################################################

restart_services() {
    print_info "重启服务..."
    
    if ! check_docker_compose; then
        return 1
    fi
    
    cd "$PROJECT_DIR"
    
    print_info "重启服务..."
    if docker-compose restart; then
        print_success "服务重启成功"
        
        print_info "等待服务启动（30秒）..."
        sleep 30
        
        print_info "检查服务状态..."
        docker-compose ps
        
        return 0
    else
        print_error "服务重启失败"
        return 1
    fi
}

################################################################################
# 查看服务状态
################################################################################

show_status() {
    print_info "查看服务状态..."
    
    if ! check_docker_compose; then
        return 1
    fi
    
    cd "$PROJECT_DIR"
    
    print_info "容器状态:"
    docker-compose ps
    
    print_info ""
    print_info "容器资源使用:"
    docker stats --no-stream
    
    print_info ""
    print_info "Docker磁盘使用:"
    docker system df
    
    return 0
}

################################################################################
# 查看服务日志
################################################################################

show_logs() {
    print_info "查看服务日志..."
    
    if ! check_docker_compose; then
        return 1
    fi
    
    cd "$PROJECT_DIR"
    
    echo ""
    echo "选择要查看日志的服务:"
    echo "1. 所有服务"
    echo "2. 后端服务"
    echo "3. 前端服务"
    echo "0. 返回"
    read -p "请选择 [0-3]: " log_choice
    
    case "$log_choice" in
        1)
            print_info "查看所有服务日志..."
            docker-compose logs -f --tail=100
            ;;
        2)
            print_info "查看后端服务日志..."
            docker-compose logs -f --tail=100 backend
            ;;
        3)
            print_info "查看前端服务日志..."
            docker-compose logs -f --tail=100 frontend
            ;;
        0)
            return 0
            ;;
        *)
            print_error "无效选择"
            return 1
            ;;
    esac
    
    return 0
}

################################################################################
# 备份数据
################################################################################

backup_data() {
    print_info "备份数据..."
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 生成备份文件名
    local date=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/backup_${date}.tar.gz"
    
    print_info "备份文件: $backup_file"
    
    # 备份数据
    cd "$PROJECT_DIR"
    
    print_info "备份数据库..."
    if [ -f "${DB_DIR}/wiring.db" ]; then
        cp "${DB_DIR}/wiring.db" "${BACKUP_DIR}/wiring_${date}.db"
        print_success "数据库备份完成"
    else
        print_warning "数据库文件不存在"
    fi
    
    print_info "备份上传文件..."
    if [ -d "$UPLOAD_DIR" ] && [ "$(ls -A $UPLOAD_DIR 2>/dev/null)" ]; then
        tar -czf "${BACKUP_DIR}/uploads_${date}.tar.gz" -C "$UPLOAD_DIR" .
        print_success "上传文件备份完成"
    else
        print_warning "上传文件目录为空"
    fi
    
    print_info "备份配置文件..."
    if [ -f "${PROJECT_DIR}/docker-compose.yml" ]; then
        cp "${PROJECT_DIR}/docker-compose.yml" "${BACKUP_DIR}/docker-compose_${date}.yml"
        print_success "配置文件备份完成"
    fi
    
    # 清理旧备份（保留7天）
    print_info "清理旧备份..."
    find "$BACKUP_DIR" -name "*.db" -mtime +7 -delete
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
    find "$BACKUP_DIR" -name "*.yml" -mtime +7 -delete
    
    print_success "备份完成"
    
    # 显示备份列表
    print_info "备份文件列表:"
    ls -lh "$BACKUP_DIR"
    
    return 0
}

################################################################################
# 清理资源
################################################################################

cleanup_resources() {
    print_info "清理资源..."
    
    echo ""
    echo "选择要清理的资源:"
    echo "1. 清理停止的容器"
    echo "2. 清理未使用的镜像"
    echo "3. 清理未使用的卷"
    echo "4. 清理未使用的网络"
    echo "5. 清理所有未使用的资源"
    echo "0. 返回"
    read -p "请选择 [0-5]: " cleanup_choice
    
    case "$cleanup_choice" in
        1)
            print_info "清理停止的容器..."
            docker container prune -f
            print_success "清理完成"
            ;;
        2)
            print_info "清理未使用的镜像..."
            docker image prune -a -f
            print_success "清理完成"
            ;;
        3)
            print_info "清理未使用的卷..."
            docker volume prune -f
            print_success "清理完成"
            ;;
        4)
            print_info "清理未使用的网络..."
            docker network prune -f
            print_success "清理完成"
            ;;
        5)
            print_info "清理所有未使用的资源..."
            docker system prune -a -f
            print_success "清理完成"
            ;;
        0)
            return 0
            ;;
        *)
            print_error "无效选择"
            return 1
            ;;
    esac
    
    return 0
}

################################################################################
# 更新服务
################################################################################

update_services() {
    print_info "更新服务..."
    
    if ! check_docker_compose; then
        return 1
    fi
    
    cd "$PROJECT_DIR"
    
    # 备份数据
    print_info "更新前备份数据..."
    backup_data
    
    # 停止服务
    print_info "停止服务..."
    docker-compose down
    
    # 拉取最新代码
    print_info "拉取最新代码..."
    if [ -d "${PROJECT_DIR}/.git" ]; then
        git pull
    else
        print_warning "不是Git仓库，跳过代码更新"
    fi
    
    # 重新构建镜像
    print_info "重新构建镜像..."
    if docker-compose build; then
        print_success "镜像构建成功"
    else
        print_error "镜像构建失败"
        return 1
    fi
    
    # 启动服务
    print_info "启动服务..."
    if docker-compose up -d; then
        print_success "服务启动成功"
        
        print_info "等待服务启动（30秒）..."
        sleep 30
        
        print_info "检查服务状态..."
        docker-compose ps
        
        return 0
    else
        print_error "服务启动失败"
        return 1
    fi
}

################################################################################
# 查看系统信息
################################################################################

show_system_info() {
    print_info "查看系统信息..."
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}系统信息${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # 操作系统信息
    print_info "操作系统:"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "  名称: $PRETTY_NAME"
        echo "  内核: $(uname -r)"
    fi
    
    # 硬件信息
    print_info "硬件信息:"
    echo "  CPU: $(nproc) 核"
    echo "  内存: $(free -h | awk '/Mem:/ {print $2}')"
    echo "  磁盘: $(df -h / | awk 'NR==2 {print $2}')"
    
    # Docker信息
    print_info "Docker信息:"
    if command -v docker &> /dev/null; then
        echo "  版本: $(docker --version | head -n1)"
        echo "  运行中容器: $(docker ps -q | wc -l)"
        echo "  总容器数: $(docker ps -aq | wc -l)"
    else
        echo "  Docker未安装"
    fi
    
    # Docker Compose信息
    print_info "Docker Compose信息:"
    if command -v docker-compose &> /dev/null; then
        echo "  版本: $(docker-compose --version | head -n1)"
    else
        echo "  Docker Compose未安装"
    fi
    
    # 网络信息
    print_info "网络信息:"
    echo "  IP地址: $(hostname -I | cut -d' ' -f1)"
    echo "  主机名: $(hostname)"
    
    # 磁盘使用
    print_info "磁盘使用:"
    df -h
    
    # 内存使用
    print_info "内存使用:"
    free -h
    
    echo -e "${BLUE}========================================${NC}"
    
    return 0
}

################################################################################
# 主函数
################################################################################

main() {
    print_info "========================================"
    print_info "$PROJECT_NAME 服务管理脚本"
    print_info "版本: v1.0.0"
    print_info "========================================"
    
    while true; do
        print_menu
        read -p "请选择 [0-9]: " choice
        
        case "$choice" in
            1)
                start_services
                ;;
            2)
                stop_services
                ;;
            3)
                restart_services
                ;;
            4)
                show_status
                ;;
            5)
                show_logs
                ;;
            6)
                backup_data
                ;;
            7)
                cleanup_resources
                ;;
            8)
                update_services
                ;;
            9)
                show_system_info
                ;;
            0)
                print_info "退出服务管理脚本"
                exit 0
                ;;
            *)
                print_error "无效选择，请重新输入"
                ;;
        esac
        
        echo ""
        read -p "按Enter键继续..."
    done
}

################################################################################
# 执行主函数
################################################################################

main "$@"
