# 综合布线记录管理系统

## 项目简介

综合布线记录管理系统是一个用于管理网络布线记录的系统，支持布线记录的增删改查、跳纤统计、数据导入导出等功能。

## 系统要求

- Linux系统（Ubuntu 20.04+, CentOS 7+, Debian 10+）
- Root权限或sudo权限
- 至少2GB可用内存
- 至少10GB可用磁盘空间
- Docker和Docker Compose

## 快速开始

### 方法1：自动部署（推荐）

```bash
# 1. 克隆项目
git clone <repository-url>
cd sjzx-zonghebuxian

# 2. 运行自动部署脚本
sudo bash deploy_自动部署.sh
```

### 方法2：手动部署

```bash
# 1. 安装Docker和Docker Compose
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# CentOS/RHEL
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 2. 配置Docker镜像加速器（中国用户推荐）
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com"
  ],
  "dns": ["8.8.8.8", "114.114.114.114"]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker

# 3. 预拉取Docker镜像（可选，加速部署）
sudo bash pull_docker_images.sh

# 4. 构建并启动服务
cd config
sudo docker compose up -d --build
```

## 部署脚本说明

### deploy_自动部署.sh

一键自动部署脚本，自动完成以下操作：

1. 检查Docker环境
2. 配置Docker镜像加速器
3. 检查Docker Compose
4. 检查项目目录结构
5. 检查端口占用情况
6. 创建数据持久化目录
7. 清理旧容器和镜像
8. 构建并启动服务
9. 等待服务启动
10. 健康检查
11. 显示部署信息

#### 使用方法

```bash
# 标准部署
sudo bash deploy_自动部署.sh

# 仅检查环境
sudo bash deploy_自动部署.sh --check-only

# 诊断模式
sudo bash deploy_自动部署.sh --diagnose

# 调试模式
sudo bash deploy_自动部署.sh --debug

# 查看帮助
sudo bash deploy_自动部署.sh --help
```

### pull_docker_images.sh

Docker镜像预拉取脚本，用于在部署前预先拉取所需的Docker镜像。

#### 使用方法

```bash
sudo bash pull_docker_images.sh
```

## 故障排除

### 问题1：Docker Hub连接失败

**错误信息**：
```
failed to do request: Head "https://registry-1.docker.io/v2/library/node/manifests/18-alpine": dial tcp: lookup registry-1.docker.io on 127.0.0.53:53: i/o timeout
```

**解决方案**：

1. **配置Docker镜像加速器**（推荐）

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com",
    "https://dockerproxy.com"
  ],
  "dns": ["8.8.8.8", "114.114.114.114"]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
```

2. **使用离线安装包**（推荐中国用户）

```bash
# 下载Ubuntu 22.04 Docker安装包
cd 安装包

# 运行安装脚本
sudo bash install_docker_ubuntu2204.sh
```

3. **手动拉取镜像**

```bash
sudo docker pull node:18-alpine
sudo docker pull nginx:alpine
```

### 问题2：Docker服务未运行

**错误信息**：
```
Docker service is not running
```

**解决方案**：

```bash
# 启动Docker服务
sudo systemctl start docker

# 设置开机自启
sudo systemctl enable docker

# 检查服务状态
sudo systemctl status docker
```

### 问题3：端口被占用

**错误信息**：
```
Port 3001 is already in use
Port 80 is already in use
```

**解决方案**：

```bash
# 查看端口占用情况
sudo netstat -tuln | grep -E ":(3001|80) "

# 停止占用端口的服务
sudo systemctl stop <service-name>

# 或者修改端口配置
# 编辑 config/docker-compose.yml
# 修改 BACKEND_PORT 和 FRONTEND_PORT
```

### 问题4：磁盘空间不足

**错误信息**：
```
no space left on device
```

**解决方案**：

```bash
# 清理Docker未使用的资源
sudo docker system prune -a

# 清理Docker构建缓存
sudo docker builder prune -a

# 查看磁盘使用情况
df -h
```

### 问题5：构建超时

**错误信息**：
```
Build timeout (600 seconds)
```

**解决方案**：

1. **预拉取镜像**

```bash
sudo bash pull_docker_images.sh
```

2. **使用镜像加速器**

```bash
# 配置镜像加速器（参考问题1的解决方案）
```

3. **手动构建**

```bash
cd config
sudo docker compose build --no-cache
sudo docker compose up -d
```

## 系统架构

```
综合布线记录管理系统
├── backend/              # 后端服务
│   ├── src/             # 源代码
│   ├── Dockerfile       # Docker镜像构建文件
│   └── package.json     # 依赖配置
├── frontend/            # 前端服务
│   ├── src/             # 源代码
│   ├── Dockerfile       # Docker镜像构建文件
│   └── package.json     # 依赖配置
├── config/              # 配置文件
│   └── docker-compose.yml # Docker Compose配置
├── 安装包/              # Docker离线安装包
│   ├── README.md        # 安装说明
│   ├── install_docker_ubuntu2204.sh # 安装脚本
│   └── *.deb            # Docker安装包
├── deploy_自动部署.sh   # 自动部署脚本
├── pull_docker_images.sh # 镜像预拉取脚本
└── README.md           # 项目说明文档
```

## 服务访问

部署完成后，可以通过以下地址访问服务：

- **前端服务**: http://localhost 或 http://服务器IP
- **后端API**: http://localhost:3001 或 http://服务器IP:3001

## 健康检查

```bash
# 检查后端服务
curl http://localhost:3001/health

# 检查前端服务
curl http://localhost/

# 查看容器状态
sudo docker ps

# 查看容器日志
sudo docker logs wiring-backend
sudo docker logs wiring-frontend
```

## 停止服务

```bash
cd config
sudo docker compose down
```

## 重启服务

```bash
cd config
sudo docker compose restart
```

## 更新服务

```bash
# 1. 拉取最新代码
git pull

# 2. 重新构建并启动
cd config
sudo docker compose up -d --build

# 3. 查看日志
sudo docker compose logs -f
```

## 数据备份

```bash
# 备份数据库
sudo docker exec wiring-backend pg_dump -U postgres wiring_db > backup.sql

# 备份上传文件
tar -czf uploads_backup.tar.gz backend/uploads/
```

## 数据恢复

```bash
# 恢复数据库
cat backup.sql | sudo docker exec -i wiring-backend psql -U postgres wiring_db

# 恢复上传文件
tar -xzf uploads_backup.tar.gz
```

## 技术栈

- **后端**: Node.js + Express + PostgreSQL
- **前端**: Vue.js + Element Plus + Vite
- **容器化**: Docker + Docker Compose
- **数据库**: PostgreSQL
- **反向代理**: Nginx

## 开发文档

详细的开发文档请参考：

- [需求文档](02-需求/)
- [设计文档](03-设计/)
- [实施文档](04-实施/)
- [后端文档](backend/README.md)
- [前端文档](frontend/README.md)

## 联系方式

如有问题，请联系开发团队。

## 许可证

[许可证信息]
