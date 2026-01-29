#!/bin/bash

################################################################################
# 综合布线记录管理系统 - 自动部署脚本
# 
# 功能：自动部署综合布线记录管理系统到Linux服务器
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
FRONTEND_PORT=80
BACKEND_PORT=3001
BACKEND_INTERNAL_PORT=3001
FRONTEND_INTERNAL_PORT=80

# Docker镜像配置
DOCKER_REGISTRY="docker.m.daocloud.io"
NODE_IMAGE="${DOCKER_REGISTRY}/node:18-alpine"
NGINX_IMAGE="${DOCKER_REGISTRY}/nginx:alpine"

# 数据库配置
DB_DIR="${PROJECT_DIR}/backend/data"
UPLOAD_DIR="${PROJECT_DIR}/backend/uploads"

# 日志配置
LOG_DIR="${PROJECT_DIR}/logs"
BACKUP_DIR="${PROJECT_DIR}/backup"

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

print_step() {
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
# 步骤1：环境检查
################################################################################

step1_check_environment() {
    print_step "步骤 1/8：环境检查"
    
    local errors=0
    
    # 检查操作系统
    print_info "检查操作系统..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_info "操作系统: $PRETTY_NAME"
    else
        print_error "无法检测操作系统"
        ((errors++))
    fi
    
    # 检查root权限
    print_info "检查用户权限..."
    if [ "$EUID" -ne 0 ]; then
        print_error "此脚本需要root权限，请使用 sudo 运行"
        ((errors++))
    else
        print_success "当前用户具有root权限"
    fi
    
    # 检查Docker
    print_info "检查Docker..."
    if check_command docker; then
        DOCKER_VERSION=$(docker --version | head -n1 | cut -d' ' -f2)
        print_success "Docker已安装: $DOCKER_VERSION"
    else
        print_error "Docker未安装"
        ((errors++))
    fi
    
    # 检查Docker Compose
    print_info "检查Docker Compose..."
    if check_command docker-compose; then
        COMPOSE_VERSION=$(docker-compose --version | head -n1)
        print_success "Docker Compose已安装: $COMPOSE_VERSION"
    else
        print_error "Docker Compose未安装"
        ((errors++))
    fi
    
    # 检查网络连接
    print_info "检查网络连接..."
    if ping -c 1 -W 2 mirrors.aliyun.com &> /dev/null 2>&1; then
        print_success "网络连接正常"
    else
        print_warning "网络连接可能存在问题"
        ((errors++))
    fi
    
    # 检查端口占用
    print_info "检查端口占用..."
    if netstat -tuln 2>/dev/null | grep -q ":${FRONTEND_PORT} "; then
        print_warning "端口 $FRONTEND_PORT 已被占用"
        ((errors++))
    else
        print_success "端口 $FRONTEND_PORT 可用"
    fi
    
    if netstat -tuln 2>/dev/null | grep -q ":${BACKEND_PORT} "; then
        print_warning "端口 $BACKEND_PORT 已被占用"
        ((errors++))
    else
        print_success "端口 $BACKEND_PORT 可用"
    fi
    
    # 检查磁盘空间
    print_info "检查磁盘空间..."
    local available_space=$(df -BG / | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 10240 ]; then
        print_warning "可用磁盘空间不足10GB，当前可用: $((available_space/1024))MB"
        ((errors++))
    else
        print_success "磁盘空间充足: $((available_space/1024))MB"
    fi
    
    if [ $errors -gt 0 ]; then
        print_error "环境检查发现 $errors 个问题，部署已停止"
        exit 1
    else
        print_success "环境检查通过"
    fi
}

################################################################################
# 步骤2：安装Docker和Docker Compose
################################################################################

step2_install_docker() {
    print_step "步骤 2/8：安装Docker和Docker Compose"
    
    # 如果Docker已安装，跳过
    if check_command docker && check_command docker-compose; then
        print_info "Docker和Docker Compose已安装，跳过安装步骤"
        return 0
    fi
    
    print_info "更新软件包列表..."
    if [ -f /etc/debian_version ]; then
        apt-get update -y
    elif [ -f /etc/redhat-release ]; then
        yum update -y
    fi
    
    # 安装Docker
    print_info "安装Docker..."
    if [ -f /etc/debian_version ]; then
        # Ubuntu/Debian - 使用阿里云镜像
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/docker-ce.list -o /etc/apt/sources.list.d/docker.list
        apt-get install -y docker-ce docker-ce-cli containerd.io
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL - 使用阿里云镜像
        yum install -y yum-utils
        yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io
    fi
    
    # 启动Docker服务
    print_info "启动Docker服务..."
    systemctl start docker
    systemctl enable docker
    
    # 安装Docker Compose
    print_info "安装Docker Compose..."
    if [ -f /etc/debian_version ]; then
        curl -L "https://mirrors.aliyun.com/docker/compose/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    elif [ -f /etc/redhat-release ]; then
        curl -L "https://mirrors.aliyun.com/docker/compose/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    fi
    
    chmod +x /usr/local/bin/docker-compose
    
    # 验证安装
    if check_command docker; then
        print_success "Docker安装成功"
        docker --version
    else
        print_error "Docker安装失败"
        exit 1
    fi
    
    if check_command docker-compose; then
        print_success "Docker Compose安装成功"
        docker-compose --version
    else
        print_error "Docker Compose安装失败"
        exit 1
    fi
}

################################################################################
# 步骤3：创建项目目录
################################################################################

step3_create_directories() {
    print_step "步骤 3/8：创建项目目录"
    
    # 创建主项目目录
    if [ ! -d "$PROJECT_DIR" ]; then
        print_info "创建项目目录: $PROJECT_DIR"
        mkdir -p "$PROJECT_DIR"
        print_success "项目目录创建成功"
    else
        print_info "项目目录已存在: $PROJECT_DIR"
    fi
    
    # 创建数据目录
    mkdir -p "$DB_DIR"
    mkdir -p "$UPLOAD_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$BACKUP_DIR"
    
    print_success "所有必要目录创建完成"
}

################################################################################
# 步骤4：创建Docker Compose配置文件
################################################################################

step4_create_docker_compose() {
    print_step "步骤 4/8：创建Docker Compose配置"
    
    local compose_file="${PROJECT_DIR}/docker-compose.yml"
    
    print_info "创建Docker Compose配置文件: $compose_file"
    
    cat > "$compose_file" << 'EOF'
version: '3.8'

services:
  # 后端服务
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: wiring-backend
    ports:
      - "${BACKEND_PORT}:${BACKEND_INTERNAL_PORT}"
    volumes:
      - ${DB_DIR}:/app/data
      - ${UPLOAD_DIR}:/app/uploads
      - ${LOG_DIR}:/app/logs
    environment:
      - NODE_ENV=production
      - PORT=${BACKEND_INTERNAL_PORT}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:${BACKEND_INTERNAL_PORT}/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - wiring-network

  # 前端服务
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: wiring-frontend
    ports:
      - "${FRONTEND_PORT}:${FRONTEND_INTERNAL_PORT}"
    depends_on:
      - backend
    environment:
      - VITE_API_BASE_URL=http://backend:${BACKEND_INTERNAL_PORT}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:${FRONTEND_INTERNAL_PORT}/"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - wiring-network

networks:
  wiring-network:
    driver: bridge

volumes:
  wiring-data:
    driver: local
  wiring-uploads:
    driver: local
  wiring-logs:
    driver: local
EOF
    
    print_success "Docker Compose配置文件创建成功"
}

################################################################################
# 步骤5：创建后端Dockerfile
################################################################################

step5_create_backend_dockerfile() {
    print_step "步骤 5/8：创建后端Dockerfile"
    
    local dockerfile="${PROJECT_DIR}/backend/Dockerfile"
    
    # 创建backend目录
    mkdir -p "${PROJECT_DIR}/backend"
    
    print_info "创建后端Dockerfile: $dockerfile"
    
    cat > "$dockerfile" << 'EOF'
FROM ${NODE_IMAGE}

WORKDIR /app

# 安装依赖
COPY package*.json ./
RUN npm ci --only=production

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 暴露端口
EXPOSE ${BACKEND_INTERNAL_PORT}

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:${BACKEND_INTERNAL_PORT}/health || exit 1

# 启动应用
CMD ["node", "dist/server.js"]
EOF
    
    print_success "后端Dockerfile创建成功"
}

################################################################################
# 步骤6：创建前端Dockerfile
################################################################################

step6_create_frontend_dockerfile() {
    print_step "步骤 6/8：创建前端Dockerfile"
    
    local dockerfile="${PROJECT_DIR}/frontend/Dockerfile"
    
    # 创建frontend目录
    mkdir -p "${PROJECT_DIR}/frontend"
    
    print_info "创建前端Dockerfile: $dockerfile"
    
    cat > "$dockerfile" << 'EOF'
# 构建阶段
FROM ${NODE_IMAGE} as builder

WORKDIR /app

# 安装依赖
COPY package*.json ./
RUN npm ci

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 生产阶段
FROM ${NGINX_IMAGE}

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制nginx配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE ${FRONTEND_INTERNAL_PORT}

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]
EOF
    
    print_success "前端Dockerfile创建成功"
}

################################################################################
# 步骤7：创建前端Nginx配置
################################################################################

step7_create_nginx_config() {
    print_step "步骤 7/8：创建Nginx配置"
    
    local nginx_conf="${PROJECT_DIR}/frontend/nginx.conf"
    
    print_info "创建Nginx配置文件: $nginx_conf"
    
    cat > "$nginx_conf" << 'EOF'
server {
    listen ${FRONTEND_INTERNAL_PORT};
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss text/json application/javascript application/xml+rss;

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API代理
    location /api/ {
        proxy_pass http://backend:${BACKEND_INTERNAL_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 前端路由
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
    
    print_success "Nginx配置文件创建成功"
}

################################################################################
# 步骤8：构建和启动服务
################################################################################

step8_build_and_start() {
    print_step "步骤 8/8：构建和启动服务"
    
    cd "$PROJECT_DIR"
    
    # 构建Docker镜像
    print_info "构建Docker镜像（这可能需要几分钟）..."
    if docker-compose build; then
        print_success "Docker镜像构建成功"
    else
        print_error "Docker镜像构建失败"
        exit 1
    fi
    
    # 启动服务
    print_info "启动服务..."
    if docker-compose up -d; then
        print_success "服务启动成功"
    else
        print_error "服务启动失败"
        exit 1
    fi
    
    # 等待服务启动
    print_info "等待服务启动（30秒）..."
    sleep 30
    
    # 检查服务状态
    print_info "检查服务状态..."
    local backend_status=$(docker-compose ps -q backend)
    local frontend_status=$(docker-compose ps -q frontend)
    
    if [ "$backend_status" = "Up" ]; then
        print_success "后端服务运行中"
    else
        print_error "后端服务未运行"
        docker-compose logs backend
        exit 1
    fi
    
    if [ "$frontend_status" = "Up" ]; then
        print_success "前端服务运行中"
    else
        print_error "前端服务未运行"
        docker-compose logs frontend
        exit 1
    fi
}

################################################################################
# 部署验证
################################################################################

verify_deployment() {
    print_step "部署验证"
    
    # 检查后端健康状态
    print_info "检查后端健康状态..."
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:${BACKEND_PORT}/health &> /dev/null 2>&1; then
            print_success "后端服务健康检查通过"
            break
        else
            print_info "等待后端服务启动... ($attempt/$max_attempts)"
            sleep 5
        fi
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "后端服务健康检查超时"
        docker-compose logs backend
        exit 1
    fi
    
    # 检查前端服务
    print_info "检查前端服务..."
    if curl -f http://localhost:${FRONTEND_PORT} &> /dev/null 2>&1; then
        print_success "前端服务访问正常"
    else
        print_error "前端服务访问异常"
        docker-compose logs frontend
        exit 1
    fi
    
    # 显示访问信息
    print_info "========================================"
    print_info "部署完成！"
    print_info "========================================"
    print_success "前端访问地址: http://$(hostname -I | cut -d' ' -f1):${FRONTEND_PORT}"
    print_success "后端API地址: http://$(hostname -I | cut -d' ' -f1):${BACKEND_PORT}"
    print_info "========================================"
    print_info "查看服务日志: cd $PROJECT_DIR && docker-compose logs -f"
    print_info "停止服务: cd $PROJECT_DIR && docker-compose down"
    print_info "重启服务: cd $PROJECT_DIR && docker-compose restart"
    print_info "========================================"
}

################################################################################
# 主函数
################################################################################

main() {
    print_info "========================================"
    print_info "$PROJECT_NAME 自动部署脚本"
    print_info "版本: v1.0.0"
    print_info "========================================"
    
    # 检查是否为root用户
    if [ "$EUID" -ne 0 ]; then
        print_error "此脚本需要root权限，请使用 sudo 运行"
        exit 1
    fi
    
    # 执行部署步骤
    step1_check_environment
    step2_install_docker
    step3_create_directories
    step4_create_docker_compose
    step5_create_backend_dockerfile
    step6_create_frontend_dockerfile
    step7_create_nginx_config
    step8_build_and_start
    
    # 验证部署
    verify_deployment
    
    print_success "========================================"
    print_success "部署成功完成！"
    print_success "========================================"
}

################################################################################
# 执行主函数
################################################################################

main "$@"
