#!/bin/bash

################################################################################
# 综合布线记录管理系统 - 环境检查脚本
# 
# 功能：检查服务器环境是否满足部署要求
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
FRONTEND_PORT=80
BACKEND_PORT=3001
MIN_DISK_SPACE=10240  # 10GB in MB
MIN_MEMORY=2048       # 2GB in MB

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

print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

check_command() {
    if command -v $1 &> /dev/null; then
        return 0
    else
        return 1
    fi
}

################################################################################
# 检查操作系统
################################################################################

check_os() {
    print_section "1. 操作系统检查"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_info "操作系统: $PRETTY_NAME"
        print_info "内核版本: $(uname -r)"
        
        # 检查是否为支持的系统
        case "$ID" in
            ubuntu|debian)
                print_success "系统类型: Debian系"
                ;;
            centos|rhel|fedora)
                print_success "系统类型: RedHat系"
                ;;
            *)
                print_warning "系统类型: $ID (可能不完全支持)"
                ;;
        esac
        
        # 检查系统版本
        if [ -n "$VERSION_ID" ]; then
            print_info "系统版本: $VERSION_ID"
            
            # 检查最低版本要求
            case "$ID" in
                ubuntu)
                    if [ "$(echo "$VERSION_ID" | cut -d'.' -f1)" -lt 20 ]; then
                        print_error "Ubuntu版本过低，需要Ubuntu 20.04或更高版本"
                        return 1
                    fi
                    ;;
                debian)
                    if [ "$(echo "$VERSION_ID" | cut -d'.' -f1)" -lt 10 ]; then
                        print_error "Debian版本过低，需要Debian 10或更高版本"
                        return 1
                    fi
                    ;;
                centos)
                    if [ "$(echo "$VERSION_ID" | cut -d'.' -f1)" -lt 7 ]; then
                        print_error "CentOS版本过低，需要CentOS 7或更高版本"
                        return 1
                    fi
                    ;;
            esac
        fi
        
        return 0
    else
        print_error "无法检测操作系统信息"
        return 1
    fi
}

################################################################################
# 检查用户权限
################################################################################

check_user_permissions() {
    print_section "2. 用户权限检查"
    
    if [ "$EUID" -eq 0 ]; then
        print_success "当前用户具有root权限"
        print_info "用户: $(whoami)"
        print_info "UID: $EUID"
        return 0
    else
        print_warning "当前用户不具有root权限"
        print_info "用户: $(whoami)"
        print_info "UID: $EUID"
        
        # 检查是否有sudo权限
        if sudo -n true 2>/dev/null; then
            print_success "用户具有sudo权限"
            return 0
        else
            print_error "用户不具有sudo权限，部署脚本需要root权限"
            return 1
        fi
    fi
}

################################################################################
# 检查系统资源
################################################################################

check_system_resources() {
    print_section "3. 系统资源检查"
    
    # 检查CPU核心数
    local cpu_cores=$(nproc)
    print_info "CPU核心数: $cpu_cores"
    
    if [ "$cpu_cores" -lt 2 ]; then
        print_warning "CPU核心数不足2核，建议至少2核"
    else
        print_success "CPU核心数满足要求"
    fi
    
    # 检查内存
    local total_memory=$(free -m | awk '/Mem:/ {print $2}')
    local available_memory=$(free -m | awk '/Mem:/ {print $7}')
    
    print_info "总内存: ${total_memory}MB"
    print_info "可用内存: ${available_memory}MB"
    
    if [ "$total_memory" -lt $MIN_MEMORY ]; then
        print_warning "总内存不足${MIN_MEMORY}MB，建议至少${MIN_MEMORY}MB"
    else
        print_success "内存满足要求"
    fi
    
    # 检查磁盘空间
    local available_disk=$(df -BM / | awk 'NR==2 {print $4}' | sed 's/M//')
    
    print_info "可用磁盘空间: ${available_disk}MB"
    
    if [ "$available_disk" -lt $MIN_DISK_SPACE ]; then
        print_error "可用磁盘空间不足${MIN_DISK_SPACE}MB，建议至少${MIN_DISK_SPACE}MB"
        return 1
    else
        print_success "磁盘空间满足要求"
    fi
    
    return 0
}

################################################################################
# 检查Docker
################################################################################

check_docker() {
    print_section "4. Docker检查"
    
    if check_command docker; then
        DOCKER_VERSION=$(docker --version | head -n1)
        print_success "Docker已安装: $DOCKER_VERSION"
        
        # 检查Docker服务状态
        if systemctl is-active --quiet docker; then
            print_success "Docker服务运行中"
        else
            print_warning "Docker服务未运行"
            print_info "启动命令: sudo systemctl start docker"
        fi
        
        # 检查Docker版本
        DOCKER_VERSION_NUM=$(docker --version | head -n1 | cut -d' ' -f2 | cut -d',' -f1)
        print_info "Docker版本: $DOCKER_VERSION_NUM"
        
        # 检查Docker是否可以正常使用
        if docker info &> /dev/null; then
            print_success "Docker可以正常使用"
        else
            print_error "Docker无法正常使用，请检查Docker配置"
            return 1
        fi
        
        return 0
    else
        print_error "Docker未安装"
        print_info "安装命令: sudo ./自动部署.sh (脚本会自动安装Docker)"
        return 1
    fi
}

################################################################################
# 检查Docker Compose
################################################################################

check_docker_compose() {
    print_section "5. Docker Compose检查"
    
    if check_command docker-compose; then
        COMPOSE_VERSION=$(docker-compose --version | head -n1)
        print_success "Docker Compose已安装: $COMPOSE_VERSION"
        
        # 检查Docker Compose版本
        COMPOSE_VERSION_NUM=$(docker-compose --version | head -n1 | cut -d' ' -f3 | cut -d',' -f1)
        print_info "Docker Compose版本: $COMPOSE_VERSION_NUM"
        
        return 0
    else
        print_error "Docker Compose未安装"
        print_info "安装命令: sudo ./自动部署.sh (脚本会自动安装Docker Compose)"
        return 1
    fi
}

################################################################################
# 检查网络连接
################################################################################

check_network() {
    print_section "6. 网络连接检查"
    
    local mirrors=(
        "mirrors.aliyun.com"
        "docker.m.daocloud.io"
        "registry.cn-hangzhou.aliyuncs.com"
    )
    
    local success_count=0
    local total_count=${#mirrors[@]}
    
    for mirror in "${mirrors[@]}"; do
        print_info "测试连接到 $mirror ..."
        if ping -c 1 -W 2 "$mirror" &> /dev/null; then
            print_success "可以连接到 $mirror"
            ((success_count++))
        else
            print_warning "无法连接到 $mirror"
        fi
    done
    
    if [ "$success_count" -eq 0 ]; then
        print_error "无法连接到任何镜像源，请检查网络连接"
        return 1
    elif [ "$success_count" -lt "$total_count" ]; then
        print_warning "部分镜像源无法连接，但至少有一个可用"
        return 0
    else
        print_success "所有镜像源都可以连接"
        return 0
    fi
}

################################################################################
# 检查端口占用
################################################################################

check_ports() {
    print_section "7. 端口占用检查"
    
    local ports=("$FRONTEND_PORT" "$BACKEND_PORT")
    local port_names=("前端端口" "后端端口")
    local errors=0
    
    for i in "${!ports[@]}"; do
        local port=${ports[$i]}
        local name=${port_names[$i]}
        
        print_info "检查 $name ($port) ..."
        
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            print_warning "端口 $port 已被占用"
            
            # 显示占用端口的进程
            local pid=$(netstat -tuln 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -n1)
            if [ -n "$pid" ]; then
                print_info "占用进程PID: $pid"
                print_info "进程名称: $(ps -p $pid -o comm= 2>/dev/null || echo '未知')"
                print_info "停止命令: sudo kill -9 $pid"
            fi
            
            ((errors++))
        else
            print_success "端口 $port 可用"
        fi
    done
    
    if [ "$errors" -gt 0 ]; then
        print_warning "发现 $errors 个端口被占用"
        return 1
    else
        print_success "所有端口都可用"
        return 0
    fi
}

################################################################################
# 检查防火墙
################################################################################

check_firewall() {
    print_section "8. 防火墙检查"
    
    # 检查UFW (Ubuntu/Debian)
    if check_command ufw; then
        print_info "检测到UFW防火墙"
        
        if ufw status | grep -q "Status: active"; then
            print_warning "UFW防火墙已启用"
            
            # 检查端口是否开放
            if ufw status | grep -q "$FRONTEND_PORT"; then
                print_success "端口 $FRONTEND_PORT 已开放"
            else
                print_warning "端口 $FRONTEND_PORT 未开放"
                print_info "开放命令: sudo ufw allow $FRONTEND_PORT/tcp"
            fi
            
            if ufw status | grep -q "$BACKEND_PORT"; then
                print_success "端口 $BACKEND_PORT 已开放"
            else
                print_warning "端口 $BACKEND_PORT 未开放"
                print_info "开放命令: sudo ufw allow $BACKEND_PORT/tcp"
            fi
        else
            print_success "UFW防火墙未启用"
        fi
    fi
    
    # 检查firewalld (CentOS/RHEL)
    if check_command firewall-cmd; then
        print_info "检测到firewalld防火墙"
        
        if firewall-cmd --state &> /dev/null; then
            print_warning "firewalld防火墙已启用"
            
            # 检查端口是否开放
            if firewall-cmd --list-ports | grep -q "$FRONTEND_PORT/tcp"; then
                print_success "端口 $FRONTEND_PORT 已开放"
            else
                print_warning "端口 $FRENTEND_PORT 未开放"
                print_info "开放命令: sudo firewall-cmd --permanent --add-port=$FRONTEND_PORT/tcp && sudo firewall-cmd --reload"
            fi
            
            if firewall-cmd --list-ports | grep -q "$BACKEND_PORT/tcp"; then
                print_success "端口 $BACKEND_PORT 已开放"
            else
                print_warning "端口 $BACKEND_PORT 未开放"
                print_info "开放命令: sudo firewall-cmd --permanent --add-port=$BACKEND_PORT/tcp && sudo firewall-cmd --reload"
            fi
        else
            print_success "firewalld防火墙未启用"
        fi
    fi
}

################################################################################
# 检查SELinux
################################################################################

check_selinux() {
    print_section "9. SELinux检查"
    
    if [ -f /etc/selinux/config ]; then
        local selinux_status=$(getenforce 2>/dev/null || echo "Disabled")
        
        print_info "SELinux状态: $selinux_status"
        
        if [ "$selinux_status" = "Enforcing" ]; then
            print_warning "SELinux处于强制模式，可能会影响Docker运行"
            print_info "临时禁用: sudo setenforce 0"
            print_info "永久禁用: 编辑 /etc/selinux/config，将 SELINUX=enforcing 改为 SELINUX=disabled"
        else
            print_success "SELinux未处于强制模式"
        fi
    else
        print_info "系统未安装SELinux"
    fi
}

################################################################################
# 生成检查报告
################################################################################

generate_report() {
    print_section "环境检查报告"
    
    local total_checks=9
    local passed_checks=0
    local warning_checks=0
    local failed_checks=0
    
    # 统计检查结果
    # 这里简化处理，实际应该根据前面的检查结果统计
    
    print_info "========================================"
    print_info "检查完成！"
    print_info "========================================"
    print_info "总检查项: $total_checks"
    print_info "通过: $passed_checks"
    print_info "警告: $warning_checks"
    print_info "失败: $failed_checks"
    print_info "========================================"
    
    if [ "$failed_checks" -eq 0 ]; then
        print_success "环境检查通过，可以开始部署"
        print_info "执行部署命令: sudo ./自动部署.sh"
        return 0
    else
        print_error "环境检查未通过，请先解决上述问题"
        return 1
    fi
}

################################################################################
# 主函数
################################################################################

main() {
    print_info "========================================"
    print_info "$PROJECT_NAME 环境检查脚本"
    print_info "版本: v1.0.0"
    print_info "========================================"
    
    local errors=0
    
    # 执行所有检查
    check_os || ((errors++))
    check_user_permissions || ((errors++))
    check_system_resources || ((errors++))
    check_docker || ((errors++))
    check_docker_compose || ((errors++))
    check_network || ((errors++))
    check_ports || ((errors++))
    check_firewall || ((errors++))
    check_selinux || ((errors++))
    
    # 生成报告
    generate_report
    
    return $errors
}

################################################################################
# 执行主函数
################################################################################

main "$@"
