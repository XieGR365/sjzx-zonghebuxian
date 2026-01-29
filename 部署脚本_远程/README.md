# 综合布线记录管理系统 - 远程自动部署脚本

## 📋 目录

- [系统概述](#系统概述)
- [功能特性](#功能特性)
- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [详细说明](#详细说明)
  - [步骤1：环境检查](#步骤1环境检查)
  - [步骤2：安装Docker和Docker Compose](#步骤2安装docker和docker-compose)
  - [步骤3：创建项目目录](#步骤3创建项目目录)
  - [步骤4：创建Docker Compose配置](#步骤4创建docker-compose配置)
  - [步骤5：创建后端Dockerfile](#步骤5创建后端dockerfile)
  - [步骤6：创建前端Dockerfile](#步骤6创建前端dockerfile)
  - [步骤7：创建Nginx配置](#步骤7创建nginx配置)
  - [步骤8：构建和启动服务](#步骤8构建和启动服务)
- [部署验证](#部署验证)
- [服务管理](#服务管理)
- [常见问题](#常见问题)
- [技术支持](#技术支持)

---

## 系统概述

本部署脚本用于将综合布线记录管理系统自动部署到Linux服务器。脚本采用"步步为营"的原则，逻辑清晰、步骤明确，每一步都有详细的检查和错误处理机制。

### 核心特性

- ✅ **自动化部署**：一键完成所有部署步骤
- ✅ **环境检查**：自动检查系统环境和依赖
- ✅ **国内镜像源**：使用DaoCloud国内镜像，确保下载速度
- ✅ **错误处理**：每步都有错误检查和友好提示
- ✅ **健康检查**：自动验证服务运行状态
- ✅ **日志记录**：详细的日志输出，便于排查问题
- ✅ **数据持久化**：使用Docker卷挂载，数据不丢失

---

## 功能特性

### 1. 环境检查
- 操作系统检测（Ubuntu/Debian/CentOS）
- Docker和Docker Compose检测
- 网络连接检查
- 端口占用检查
- 磁盘空间检查

### 2. 自动安装
- 自动安装Docker（如未安装）
- 自动安装Docker Compose（如未安装）
- 使用国内镜像源加速下载

### 3. 项目部署
- 自动创建项目目录结构
- 自动生成Docker Compose配置
- 自动生成Dockerfile
- 自动生成Nginx配置

### 4. 服务管理
- 一键启动所有服务
- 健康检查
- 日志查看
- 服务重启/停止

---

## 系统要求

### 硬件要求

| 配置项 | 最低要求 | 推荐配置 |
|---------|----------|----------|
| CPU | 2核 | 4核及以上 |
| 内存 | 2GB | 4GB及以上 |
| 硬盘 | 20GB | 50GB及以上 |
| 网络 | 10Mbps | 100Mbps及以上 |

### 软件要求

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| 操作系统 | Linux (Ubuntu 20.04+, CentOS 7+, Debian 10+) | 推荐Ubuntu 20.04 LTS |
| Docker | 20.10+ | 脚本会自动安装 |
| Docker Compose | 2.0+ | 脚本会自动安装 |
| Shell | Bash 4.0+ | 大多数Linux系统默认支持 |

### 网络要求

- **开放端口**: 80 (HTTP), 443 (HTTPS, 可选)
- **网络延迟**: 内部网络延迟 < 10ms
- **带宽**: 最低10Mbps，推荐100Mbps

---

## 快速开始

### 前提条件

1. 服务器已安装Linux操作系统
2. 服务器具有root权限或sudo权限
3. 服务器可以访问互联网
4. 服务器防火墙已开放相应端口

### 一键部署

```bash
# 1. 上传部署脚本到服务器
scp 自动部署.sh user@server:/tmp/

# 2. 登录服务器
ssh user@server

# 3. 进入临时目录
cd /tmp

# 4. 给脚本添加执行权限
chmod +x 自动部署.sh

# 5. 执行部署脚本
sudo ./自动部署.sh
```

### 预期结果

部署脚本将自动完成以下操作：

1. ✅ 检查系统环境
2. ✅ 安装Docker和Docker Compose（如需要）
3. ✅ 创建项目目录 `/opt/sjzx-zonghebuxian`
4. ✅ 生成Docker Compose配置文件
5. ✅ 生成后端Dockerfile
6. ✅ 生成前端Dockerfile
7. ✅ 生成Nginx配置文件
8. ✅ 构建Docker镜像
9. ✅ 启动所有服务
10. ✅ 验证服务健康状态

---

## 详细说明

### 步骤1：环境检查

#### 检查内容

1. **操作系统检测**
   - 检测Linux发行版和版本
   - 支持Ubuntu、Debian、CentOS等主流发行版

2. **用户权限检查**
   - 验证当前用户是否具有root权限
   - 如无root权限，提示使用sudo运行脚本

3. **Docker检测**
   - 检查Docker是否已安装
   - 检查Docker Compose是否已安装
   - 显示版本信息

4. **网络连接检查**
   - 测试与国内镜像源的连接
   - 确保网络正常

5. **端口占用检查**
   - 检查前端端口（80）是否被占用
   - 检查后端端口（3001）是否被占用

6. **磁盘空间检查**
   - 检查可用磁盘空间是否充足（至少10GB）

#### 错误处理

- ❌ **操作系统不支持**：脚本将停止并提示支持的系统版本
- ❌ **权限不足**：提示使用sudo运行脚本
- ❌ **网络异常**：提示检查网络连接
- ❌ **端口占用**：提示修改端口配置或停止占用端口的进程
- ❌ **磁盘不足**：提示清理磁盘空间或扩容

---

### 步骤2：安装Docker和Docker Compose

#### 安装内容

1. **Docker安装**
   - 使用阿里云镜像源加速下载
   - 自动配置Docker仓库
   - 启动并启用Docker服务

2. **Docker Compose安装**
   - 从GitHub下载最新版本
   - 配置执行权限
   - 验证安装结果

#### 国内镜像源

脚本使用以下国内镜像源：

- **Docker镜像**: `docker.m.daocloud.io`
- **Node.js镜像**: `docker.m.daocloud.io/node:18-alpine`
- **Nginx镜像**: `docker.m.daocloud.io/nginx:alpine`

这些镜像源位于国内，下载速度快且稳定。

#### 错误处理

- ❌ **下载失败**：提示检查网络连接或手动下载
- ❌ **安装失败**：显示详细错误信息，建议手动安装

---

### 步骤3：创建项目目录

#### 目录结构

```
/opt/sjzx-zonghebuxian/
├── backend/              # 后端服务
│   ├── data/            # 数据库文件
│   └── uploads/         # 上传文件
├── frontend/             # 前端应用
├── logs/                # 日志文件
├── backup/              # 备份文件
└── docker-compose.yml    # Docker编排配置
```

#### 错误处理

- ❌ **目录创建失败**：提示检查磁盘权限
- ❌ **权限设置失败**：提示检查用户权限

---

### 步骤4：创建Docker Compose配置

#### 配置内容

Docker Compose配置包含以下服务：

1. **backend服务**
   - 基于Node.js 18 Alpine镜像
   - 暴露端口：3001
   - 挂载数据卷：数据库、上传文件、日志

2. **frontend服务**
   - 基于Nginx Alpine镜像
   - 暴露端口：80
   - 依赖backend服务
   - 配置API反向代理

3. **network网络**
   - 使用bridge网络模式
   - 服务间通过内部网络通信

4. **volumes卷**
   - 数据持久化存储
   - 上传文件持久化存储
   - 日志文件持久化存储

#### 错误处理

- ❌ **配置文件创建失败**：提示检查磁盘空间和权限

---

### 步骤5：创建后端Dockerfile

#### Dockerfile内容

- 基础镜像：Node.js 18 Alpine
- 工作目录：/app
- 安装依赖：使用npm ci
- 复制源代码：COPY指令
- 构建应用：npm run build
- 暴露端口：3001
- 健康检查：定期检查服务状态

#### 错误处理

- ❌ **Dockerfile创建失败**：提示检查磁盘空间

---

### 步骤6：创建前端Dockerfile

#### Dockerfile内容

- 构建阶段：Node.js 18 Alpine
- 生产阶段：Nginx Alpine
- 复制构建产物：从构建阶段复制dist目录
- 复制Nginx配置：自定义nginx.conf
- 暴露端口：80
- 启动命令：nginx -g daemon off

#### 错误处理

- ❌ **Dockerfile创建失败**：提示检查磁盘空间

---

### 步骤7：创建Nginx配置

#### 配置内容

- 监听端口：80
- 根目录：/usr/share/nginx/html
- Gzip压缩：启用，提高传输效率
- 静态资源缓存：配置缓存策略
- API代理：将/api请求代理到后端3001端口
- 前端路由：支持Vue Router的history模式

#### 错误处理

- ❌ **配置文件创建失败**：提示检查磁盘空间

---

### 步骤8：构建和启动服务

#### 执行流程

1. **构建Docker镜像**
   - 执行`docker-compose build`
   - 显示构建进度
   - 处理构建错误

2. **启动服务**
   - 执行`docker-compose up -d`
   - 后台运行服务
   - 显示启动状态

3. **等待服务启动**
   - 等待30秒让服务完全启动
   - 显示等待进度

4. **验证服务状态**
   - 检查backend容器状态
   - 检查frontend容器状态
   - 显示容器日志（如有错误）

#### 错误处理

- ❌ **镜像构建失败**：显示详细错误信息，建议检查Dockerfile
- ❌ **服务启动失败**：显示容器日志，建议检查配置
- ❌ **健康检查失败**：显示服务状态，建议查看日志

---

## 部署验证

### 自动验证

脚本会自动执行以下验证：

1. **后端健康检查**
   ```bash
   curl -f http://localhost:3001/health
   ```
   - 最多尝试10次，每次间隔5秒
   - 成功则继续，失败则显示错误

2. **前端服务检查**
   ```bash
   curl -f http://localhost:80
   ```
   - 检查前端页面是否可访问

3. **容器状态检查**
   ```bash
   docker-compose ps
   ```
   - 显示所有容器运行状态

### 验证成功标志

- ✅ 后端容器状态：Up (healthy)
- ✅ 前端容器状态：Up
- ✅ 后端健康检查：通过
- ✅ 前端访问：正常

### 访问地址

部署成功后，可以通过以下地址访问系统：

- **前端地址**: `http://服务器IP地址`
- **后端API**: `http://服务器IP地址:3001`

---

## 服务管理

### 查看服务状态

```bash
cd /opt/sjzx-zonghebuxian
docker-compose ps
```

### 查看服务日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看后端日志
docker-compose logs -f backend

# 查看前端日志
docker-compose logs -f frontend
```

### 重启服务

```bash
cd /opt/sjzx-zonghebuxian
docker-compose restart
```

### 停止服务

```bash
cd /opt/sjzx-zonghebuxian
docker-compose down
```

### 重新构建并启动

```bash
cd /opt/sjzx-zonghebuxian
docker-compose down
docker-compose build
docker-compose up -d
```

### 进入容器

```bash
# 进入后端容器
docker-compose exec backend sh

# 进入前端容器
docker-compose exec frontend sh
```

---

## 常见问题

### Q1：部署脚本执行权限错误

**问题**: `bash: ./自动部署.sh: Permission denied`

**解决方案**:
```bash
chmod +x 自动部署.sh
sudo ./自动部署.sh
```

---

### Q2：Docker安装失败

**问题**: Docker或Docker Compose安装失败

**解决方案**:

1. 手动安装Docker：
   ```bash
   # Ubuntu/Debian
   curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/docker-ce.list -o /etc/apt/sources.list.d/docker.list
   apt-get install -y docker-ce docker-ce-cli containerd.io
   
   # CentOS/RHEL
   yum install -y yum-utils
   yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
   yum install -y docker-ce docker-ce-cli containerd.io
   ```

2. 手动安装Docker Compose：
   ```bash
   sudo curl -L "https://mirrors.aliyun.com/docker/compose/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

---

### Q3：端口被占用

**问题**: 端口80或3001已被其他服务占用

**解决方案**:

1. 查找占用端口的进程：
   ```bash
   sudo netstat -tulnp | grep :80
   sudo netstat -tulnp | grep :3001
   ```

2. 停止占用端口的进程：
   ```bash
   sudo kill -9 <PID>
   ```

3. 或修改部署脚本中的端口配置：
   ```bash
   # 编辑自动部署.sh
   FRONTEND_PORT=8080  # 修改为其他端口
   BACKEND_PORT=8081
   ```

---

### Q4：容器启动失败

**问题**: Docker容器启动失败或反复重启

**解决方案**:

1. 查看容器日志：
   ```bash
   cd /opt/sjzx-zonghebuxian
   docker-compose logs backend
   docker-compose logs frontend
   ```

2. 检查磁盘空间：
   ```bash
   df -h
   ```

3. 检查Docker资源：
   ```bash
   docker stats
   ```

4. 清理Docker资源：
   ```bash
   docker system prune -a
   ```

---

### Q5：无法访问前端页面

**问题**: 浏览器无法访问前端页面

**解决方案**:

1. 检查容器状态：
   ```bash
   docker-compose ps
   ```

2. 检查防火墙：
   ```bash
   # Ubuntu/Debian
   sudo ufw status
   sudo ufw allow 80/tcp
   
   # CentOS/RHEL
   sudo firewall-cmd --list-all
   sudo firewall-cmd --permanent --add-port=80/tcp
   sudo firewall-cmd --reload
   ```

3. 检查Nginx配置：
   ```bash
   docker-compose exec frontend cat /etc/nginx/conf.d/default.conf
   ```

---

### Q6：后端API无法访问

**问题**: 前端无法连接后端API

**解决方案**:

1. 检查后端健康状态：
   ```bash
   curl http://localhost:3001/health
   ```

2. 检查网络连接：
   ```bash
   docker-compose exec backend ping frontend
   ```

3. 查看后端日志：
   ```bash
   docker-compose logs backend
   ```

---

### Q7：数据库文件丢失

**问题**: 重启容器后数据库数据丢失

**解决方案**:

数据已通过Docker卷挂载持久化存储，不会丢失。如确实丢失：

1. 检查卷挂载：
   ```bash
   docker volume ls
   ```

2. 检查数据目录：
   ```bash
   ls -lh /opt/sjzx-zonghebuxian/backend/data
   ```

3. 恢复备份：
   ```bash
   ls -lh /opt/sjzx-zonghebuxian/backup
   ```

---

### Q8：上传文件失败

**问题**: 上传Excel文件时失败

**解决方案**:

1. 检查上传目录权限：
   ```bash
   docker-compose exec backend ls -lh /app/uploads
   ```

2. 检查磁盘空间：
   ```bash
   df -h
   ```

3. 查看后端日志：
   ```bash
   docker-compose logs backend
   ```

4. 检查文件大小限制：
   - 默认限制：50MB
   - 可在后端配置中修改

---

## 技术支持

### 日志位置

- **Docker日志**: `/opt/sjzx-zonghebuxian/logs/`
- **应用日志**: `/opt/sjzx-zonghebuxian/backend/data/`
- **容器日志**: `docker-compose logs`

### 数据备份

- **备份目录**: `/opt/sjzx-zonghebuxian/backup/`
- **备份频率**: 建议每日备份
- **备份保留**: 建议保留7天

### 监控建议

1. **定期检查服务状态**
   ```bash
   # 添加到crontab
   0 */5 * * * * cd /opt/sjzx-zonghebuxian && docker-compose ps >> /var/log/sjzx-status.log
   ```

2. **定期备份数据库**
   ```bash
   # 添加到crontab
   0 2 * * * cd /opt/sjzx-zonghebuxian/backend && cp data/wiring.db backup/wiring_$(date +\%Y\%m\%d).db
   ```

3. **监控磁盘空间**
   ```bash
   df -h
   ```

---

## 配置自定义

### 修改端口配置

编辑 `自动部署.sh` 文件：

```bash
# 修改前端端口
FRONTEND_PORT=8080

# 修改后端端口
BACKEND_PORT=8081
```

### 修改项目目录

编辑 `自动部署.sh` 文件：

```bash
# 修改项目目录
PROJECT_DIR="/custom/path/to/project"
```

### 修改Docker镜像源

编辑 `自动部署.sh` 文件：

```bash
# 修改Docker镜像源
DOCKER_REGISTRY="your-custom-registry"
NODE_IMAGE="${DOCKER_REGISTRY}/node:18-alpine"
NGINX_IMAGE="${DOCKER_REGISTRY}/nginx:alpine"
```

---

## 安全建议

### 1. 使用HTTPS

建议配置SSL证书，启用HTTPS访问：

1. 获取SSL证书（Let's Encrypt免费证书）
2. 修改Nginx配置，添加SSL配置
3. 开放443端口

### 2. 限制访问IP

配置防火墙，只允许特定IP访问：

```bash
# Ubuntu/Debian
sudo ufw allow from 192.168.1.0/24 to any port 80

# CentOS/RHEL
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port protocol="tcp" port="80" accept'
sudo firewall-cmd --reload
```

### 3. 定期更新

定期更新系统和Docker：

```bash
# 更新系统
sudo apt-get update && sudo apt-get upgrade -y

# 更新Docker
docker pull
docker-compose pull
docker-compose up -d
```

### 4. 监控日志

定期查看日志，发现异常：

```bash
# 查看错误日志
docker-compose logs | grep -i error

# 查看警告日志
docker-compose logs | grep -i warning
```

---

## 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0.0 | 2025-01-29 | 初始版本，支持一键部署 |

---

## 附录

### A. Docker命令参考

```bash
# 查看所有容器
docker ps -a

# 查看所有镜像
docker images -a

# 查看所有卷
docker volume ls

# 查看所有网络
docker network ls

# 清理未使用的资源
docker system prune -a

# 查看容器资源使用
docker stats
```

### B. 系统服务命令

```bash
# 启动Docker服务
sudo systemctl start docker

# 停止Docker服务
sudo systemctl stop docker

# 重启Docker服务
sudo systemctl restart docker

# 查看Docker服务状态
sudo systemctl status docker

# 查看Docker服务日志
sudo journalctl -u docker -f
```

---

## 联系方式

如有问题，请联系技术支持团队。

---

**祝您部署顺利！** 🚀
