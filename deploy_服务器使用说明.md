# 综合布线记录管理系统 - 服务器部署使用说明

> 本文档提供在Linux服务器上部署和使用综合布线记录管理系统的详细说明

## 目录

- [快速开始](#快速开始)
- [系统要求](#系统要求)
- [部署前准备](#部署前准备)
- [一键部署](#一键部署)
- [验证部署](#验证部署)
- [日常使用](#日常使用)
- [数据备份](#数据备份)
- [故障排查](#故障排查)
- [性能优化](#性能优化)
- [安全配置](#安全配置)
- [常见问题](#常见问题)

---

## 快速开始

### 最简单的部署方式（推荐）

如果你已经准备好了项目文件，只需要三步即可完成部署：

```bash
# 1. 进入项目根目录
cd /path/to/sjzx-zonghebuxian

# 2. 给脚本添加执行权限
chmod +x deploy_自动部署.sh

# 3. 运行部署脚本
sudo ./deploy_自动部署.sh
```

等待几分钟，部署完成后访问 `http://服务器IP地址` 即可使用系统。

---

## 系统要求

### 硬件要求

| 配置项 | 最低配置 | 推荐配置 |
|--------|----------|----------|
| CPU | 2核 | 4核+ |
| 内存 | 2GB | 4GB+ |
| 硬盘 | 10GB | 50GB+ SSD |
| 网络 | 100Mbps | 1Gbps |

### 软件要求

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| **操作系统** | Ubuntu 20.04+, CentOS 7+, Debian 10+ | Linux系统 |
| **Docker** | 20.10+ | 容器运行时 |
| **Docker Compose** | 2.0+ | 容器编排工具 |
| **权限** | Root或Sudo | 需要管理员权限 |

### 浏览器要求

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

---

## 部署前准备

### 1. 准备项目文件

将以下三个目录上传到服务器：

```
服务器目录结构：
/path/to/sjzx-zonghebuxian/
├── backend/              # 后端源代码
│   ├── src/
│   ├── Dockerfile
│   └── package.json
├── frontend/             # 前端源代码
│   ├── src/
│   ├── Dockerfile
│   └── package.json
├── config/               # 配置文件
│   └── docker-compose.yml
├── deploy_自动部署.sh    # 自动部署脚本
├── deploy_部署技术细节.md
└── deploy_服务器使用说明.md
```

### 2. 上传文件到服务器

#### 方法一：使用SCP（推荐）

```bash
# 在本地Windows系统上，使用PowerShell或Git Bash
scp -r d:\TREA\sjzx-zonghebuxian\backend user@server-ip:/path/to/sjzx-zonghebuxian/
scp -r d:\TREA\sjzx-zonghebuxian\frontend user@server-ip:/path/to/sjzx-zonghebuxian/
scp -r d:\TREA\sjzx-zonghebuxian\config user@server-ip:/path/to/sjzx-zonghebuxian/
scp d:\TREA\sjzx-zonghebuxian\deploy_*.sh user@server-ip:/path/to/sjzx-zonghebuxian/
scp d:\TREA\sjzx-zonghebuxian\deploy_*.md user@server-ip:/path/to/sjzx-zonghebuxian/
```

#### 方法二：使用SFTP工具

使用WinSCP、FileZilla等图形化工具上传文件：
1. 连接到服务器
2. 导航到目标目录
3. 拖拽文件上传

#### 方法三：打包后上传

```bash
# 在本地打包
cd d:\TREA\sjzx-zonghebuxian
tar -czf sjzx-zonghebuxian.tar.gz backend frontend config deploy_*

# 上传压缩包
scp sjzx-zonghebuxian.tar.gz user@server-ip:/tmp/

# 在服务器上解压
ssh user@server-ip
cd /path/to/
tar -xzf /tmp/sjzx-zonghebuxian.tar.gz
```

### 3. 检查服务器环境

登录到服务器，检查基本环境：

```bash
# 检查操作系统版本
cat /etc/os-release

# 检查可用内存
free -h

# 检查磁盘空间
df -h

# 检查CPU信息
lscpu
```

---

## 一键部署

### 完整部署流程

#### 步骤1：登录服务器

```bash
ssh user@server-ip
```

#### 步骤2：进入项目目录

```bash
cd /path/to/sjzx-zonghebuxian
```

#### 步骤3：给脚本添加执行权限

```bash
chmod +x deploy_自动部署.sh
```

#### 步骤4：运行部署脚本

```bash
sudo ./deploy_自动部署.sh
```

### 部署脚本执行过程

脚本会自动执行以下步骤：

1. **检查Docker环境**
   - 检查Docker是否已安装
   - 如果未安装，自动安装Docker
   - 启动Docker服务

2. **检查Docker Compose**
   - 检查Docker Compose是否已安装
   - 如果未安装，自动安装

3. **检查项目结构**
   - 验证backend目录存在
   - 验证frontend目录存在
   - 验证config目录存在
   - 验证配置文件完整

4. **检查端口占用**
   - 检查后端端口3001是否可用
   - 检查前端端口80是否可用

5. **创建数据目录**
   - 创建backend/data目录（数据库）
   - 创建backend/uploads目录（上传文件）

6. **清理旧容器**
   - 停止并删除旧的后端容器
   - 停止并删除旧的前端容器
   - 清理旧的网络

7. **构建并启动服务**
   - 构建后端Docker镜像
   - 构建前端Docker镜像
   - 启动所有容器

8. **等待服务启动**
   - 等待后端服务就绪
   - 等待前端服务就绪

9. **健康检查**
   - 检查后端容器状态
   - 检查前端容器状态
   - 验证后端健康接口
   - 验证前端访问

10. **显示部署信息**
    - 显示访问地址
    - 显示服务端口
    - 显示容器状态
    - 显示常用命令

### 预期输出示例

```
================================================================================
综合布线记录管理系统 - 一键自动部署
================================================================================

================================================================================
步骤 1: 检查Docker环境
================================================================================
✓ Docker已安装 (版本: 24.0.7)
✓ Docker服务运行正常

================================================================================
步骤 2: 检查Docker Compose
================================================================================
✓ Docker Compose已安装 (版本: 2.21.0)

================================================================================
步骤 3: 检查项目目录结构
================================================================================
✓ 后端目录存在
✓ 前端目录存在
✓ 配置目录存在
✓ Docker Compose配置文件存在
✓ 后端Dockerfile存在
✓ 前端Dockerfile存在

================================================================================
步骤 4: 检查端口占用情况
================================================================================
✓ 后端端口 3001 可用
✓ 前端端口 80 可用

================================================================================
步骤 5: 创建数据持久化目录
================================================================================
✓ 创建后端数据目录: backend/data
✓ 创建后端上传目录: backend/uploads
✓ 目录权限设置完成

================================================================================
步骤 6: 清理旧容器和镜像
================================================================================
✓ 后端容器已清理
✓ 前端容器已清理
✓ 旧网络已清理

================================================================================
步骤 7: 构建并启动服务
================================================================================
开始构建Docker镜像...
[+] Building 45.2s (12/12) FINISHED
=> [backend internal] load build definition from Dockerfile
=> [frontend internal] load build definition from Dockerfile
...
✓ 服务构建并启动成功

================================================================================
步骤 8: 等待服务启动
================================================================================
等待后端服务启动...
✓ 后端服务启动成功
等待前端服务启动...
✓ 前端服务启动成功

================================================================================
步骤 9: 检查服务健康状态
================================================================================
✓ 后端容器运行中
  状态: Up 2 minutes
✓ 前端容器运行中
  状态: Up 2 minutes
✓ 后端健康检查通过
✓ 前端访问正常

================================================================================
步骤 10: 部署完成
================================================================================

================================================================================
🎉 综合布线记录管理系统 部署成功！
================================================================================

访问地址：
  本地访问: http://localhost
  网络访问: http://192.168.1.100

服务端口：
  前端端口: 80
  后端端口: 3001

容器状态：
  wiring-backend: Up 2 minutes
  wiring-frontend: Up 2 minutes

数据目录：
  数据库: backend/data
  上传文件: backend/uploads

常用命令：
  查看日志: docker compose -f config/docker-compose.yml logs -f
  停止服务: docker compose -f config/docker-compose.yml down
  重启服务: docker compose -f config/docker-compose.yml restart
  查看状态: docker compose -f config/docker-compose.yml ps

⚠  注意事项：
  1. 首次部署后，请访问系统并上传Excel数据
  2. 数据文件会持久化保存在 backend/data 目录
  3. 上传的文件会保存在 backend/uploads 目录
  4. 建议定期备份数据目录

================================================================================
部署完成！
```

---

## 验证部署

### 1. 检查容器状态

```bash
docker ps
```

预期输出：
```
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS                    NAMES
abc123def456   sjzx-zonghebuxian-frontend   "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes   0.0.0.0:80->80/tcp       wiring-frontend
def456ghi789   sjzx-zonghebuxian-backend    "npm start"              2 minutes ago   Up 2 minutes   0.0.0.0:3001->3001/tcp   wiring-backend
```

### 2. 检查后端健康接口

```bash
curl http://localhost:3001/health
```

预期输出：
```json
{
  "status": "ok",
  "message": "综合布线记录管理系统后端服务正常运行"
}
```

### 3. 检查前端访问

```bash
curl -I http://localhost
```

预期输出：
```
HTTP/1.1 200 OK
Server: nginx
Content-Type: text/html
...
```

### 4. 查看服务日志

```bash
# 查看所有服务日志
docker compose -f config/docker-compose.yml logs

# 查看后端日志
docker compose -f config/docker-compose.yml logs backend

# 查看前端日志
docker compose -f config/docker-compose.yml logs frontend

# 实时查看日志
docker compose -f config/docker-compose.yml logs -f
```

### 5. 浏览器访问

在浏览器中打开以下地址：

- 本地访问：`http://localhost`
- 网络访问：`http://服务器IP地址`

你应该能看到综合布线记录管理系统的登录页面。

---

## 日常使用

### 启动服务

```bash
docker compose -f config/docker-compose.yml up -d
```

### 停止服务

```bash
docker compose -f config/docker-compose.yml down
```

### 重启服务

```bash
# 重启所有服务
docker compose -f config/docker-compose.yml restart

# 重启后端服务
docker compose -f config/docker-compose.yml restart backend

# 重启前端服务
docker compose -f config/docker-compose.yml restart frontend
```

### 查看服务状态

```bash
docker compose -f config/docker-compose.yml ps
```

### 查看日志

```bash
# 查看所有日志
docker compose -f config/docker-compose.yml logs

# 实时查看日志
docker compose -f config/docker-compose.yml logs -f

# 查看最近100行日志
docker compose -f config/docker-compose.yml logs --tail=100

# 查看特定服务的日志
docker compose -f config/docker-compose.yml logs backend
```

### 进入容器

```bash
# 进入后端容器
docker exec -it wiring-backend sh

# 进入前端容器
docker exec -it wiring-frontend sh
```

### 更新服务

```bash
# 1. 停止服务
docker compose -f config/docker-compose.yml down

# 2. 重新构建并启动
docker compose -f config/docker-compose.yml up -d --build
```

### 清理资源

```bash
# 停止并删除容器
docker compose -f config/docker-compose.yml down

# 停止并删除容器、网络、镜像
docker compose -f config/docker-compose.yml down --rmi all

# 停止并删除容器、网络、镜像、数据卷
docker compose -f config/docker-compose.yml down -v
```

---

## 数据备份

### 备份数据库

```bash
# 创建备份目录
mkdir -p backups

# 备份数据库文件
cp backend/data/wiring.db backups/wiring_backup_$(date +%Y%m%d_%H%M%S).db

# 压缩备份
tar -czf backups/wiring_backup_$(date +%Y%m%d_%H%M%S).tar.gz backend/data backend/uploads
```

### 自动备份脚本

创建自动备份脚本 `backup.sh`：

```bash
#!/bin/bash

# 备份目录
BACKUP_DIR="/path/to/sjzx-zonghebuxian/backups"
DATA_DIR="/path/to/sjzx-zonghebuxian/backend/data"
UPLOADS_DIR="/path/to/sjzx-zonghebuxian/backend/uploads"

# 日期格式
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份数据
tar -czf $BACKUP_DIR/wiring_backup_$DATE.tar.gz $DATA_DIR $UPLOADS_DIR

# 删除7天前的备份
find $BACKUP_DIR -name "wiring_backup_*.tar.gz" -mtime +7 -delete

echo "备份完成: wiring_backup_$DATE.tar.gz"
```

设置定时任务：

```bash
# 编辑crontab
crontab -e

# 添加定时任务（每天凌晨2点备份）
0 2 * * * /path/to/sjzx-zonghebuxian/backup.sh >> /var/log/wiring-backup.log 2>&1
```

### 恢复数据

```bash
# 停止服务
docker compose -f config/docker-compose.yml down

# 解压备份文件
tar -xzf backups/wiring_backup_20240101_020000.tar.gz -C /

# 启动服务
docker compose -f config/docker-compose.yml up -d
```

---

## 故障排查

### 问题1：容器无法启动

**症状**：`docker ps` 看不到容器

**排查步骤**：

```bash
# 1. 查看容器状态
docker ps -a

# 2. 查看容器日志
docker logs wiring-backend
docker logs wiring-frontend

# 3. 检查端口占用
sudo netstat -tuln | grep -E ":(80|3001)"

# 4. 检查磁盘空间
df -h
```

**解决方案**：

```bash
# 如果端口被占用，停止占用进程
sudo lsof -ti:80 | xargs kill -9
sudo lsof -ti:3001 | xargs kill -9

# 如果磁盘空间不足，清理Docker资源
docker system prune -a

# 重新启动服务
docker compose -f config/docker-compose.yml up -d
```

### 问题2：无法访问前端

**症状**：浏览器无法打开 `http://服务器IP`

**排查步骤**：

```bash
# 1. 检查前端容器状态
docker ps | grep wiring-frontend

# 2. 检查前端日志
docker logs wiring-frontend

# 3. 检查防火墙
sudo ufw status
sudo firewall-cmd --list-all

# 4. 检查Nginx配置
docker exec wiring-frontend cat /etc/nginx/conf.d/default.conf
```

**解决方案**：

```bash
# 如果防火墙阻止，开放端口
sudo ufw allow 80
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --reload

# 重启前端容器
docker restart wiring-frontend
```

### 问题3：后端API无法访问

**症状**：前端显示"上传失败"或"API错误"

**排查步骤**：

```bash
# 1. 检查后端容器状态
docker ps | grep wiring-backend

# 2. 检查后端日志
docker logs wiring-backend

# 3. 测试健康接口
curl http://localhost:3001/health

# 4. 进入容器检查
docker exec -it wiring-backend sh
ls -la /app/data
```

**解决方案**：

```bash
# 重启后端容器
docker restart wiring-backend

# 如果数据库文件不存在，创建空数据库
docker exec wiring-backend touch /app/data/wiring.db

# 检查容器网络
docker network inspect wiring-network
```

### 问题4：上传文件失败

**症状**：上传Excel文件时提示"上传失败"

**排查步骤**：

```bash
# 1. 检查uploads目录权限
ls -la backend/uploads

# 2. 检查磁盘空间
df -h

# 3. 查看后端日志
docker logs wiring-backend | tail -50
```

**解决方案**：

```bash
# 修改目录权限
chmod 755 backend/uploads
chown -R $USER:$USER backend/uploads

# 清理磁盘空间
docker system prune -a

# 重启后端服务
docker restart wiring-backend
```

### 问题5：数据丢失

**症状**：重启容器后数据不见了

**原因**：数据卷未正确挂载

**解决方案**：

```bash
# 1. 停止服务
docker compose -f config/docker-compose.yml down

# 2. 检查数据目录
ls -la backend/data
ls -la backend/uploads

# 3. 重新启动服务
docker compose -f config/docker-compose.yml up -d

# 4. 验证数据卷挂载
docker inspect wiring-backend | grep -A 10 Mounts
```

---

## 性能优化

### 1. 限制容器资源使用

编辑 `config/docker-compose.yml`：

```yaml
services:
  backend:
    # ... 其他配置
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G

  frontend:
    # ... 其他配置
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

### 2. 启用日志轮转

编辑 `config/docker-compose.yml`：

```yaml
services:
  backend:
    # ... 其他配置
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  frontend:
    # ... 其他配置
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 3. 优化Nginx配置

编辑 `frontend/nginx.conf`：

```nginx
server {
    listen 80;
    server_name localhost;
    
    # 启用Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    
    # 启用缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # ... 其他配置
}
```

### 4. 使用反向代理

如果需要使用域名和HTTPS，可以配置Nginx反向代理：

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

---

## 安全配置

### 1. 修改默认端口

编辑 `config/docker-compose.yml`：

```yaml
services:
  backend:
    ports:
      - "8301:3001"  # 修改为8301

  frontend:
    ports:
      - "8080:80"  # 修改为8080
```

### 2. 配置防火墙

```bash
# Ubuntu/Debian
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 8301
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=8301/tcp
sudo firewall-cmd --reload
```

### 3. 使用HTTPS

```bash
# 安装Certbot
sudo apt-get install certbot

# 获取SSL证书
sudo certbot certonly --standalone -d your-domain.com

# 配置Nginx使用SSL
# （参考上面的反向代理配置）
```

### 4. 限制文件上传大小

编辑 `backend/src/server.ts`，添加文件大小限制：

```typescript
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
```

### 5. 定期更新

```bash
# 更新Docker镜像
docker compose -f config/docker-compose.yml pull
docker compose -f config/docker-compose.yml up -d --build

# 更新系统
sudo apt-get update && sudo apt-get upgrade
```

---

## 常见问题

### Q1: 部署脚本需要多长时间？

**A**: 通常需要5-10分钟，具体取决于服务器性能和网络速度。首次部署需要下载Docker镜像，时间会稍长一些。

### Q2: 可以在Windows服务器上部署吗？

**A**: 可以，但需要安装Docker Desktop for Windows。建议使用Linux服务器以获得更好的性能和稳定性。

### Q3: 如何修改端口？

**A**: 编辑 `config/docker-compose.yml` 文件，修改 `ports` 配置，然后重启服务。

### Q4: 数据会丢失吗？

**A**: 不会。数据通过Docker卷持久化保存在 `backend/data` 和 `backend/uploads` 目录。即使删除容器，数据也会保留。

### Q5: 如何查看数据库内容？

**A**: 可以使用SQLite工具查看：

```bash
# 安装sqlite3
sudo apt-get install sqlite3

# 查看数据库
sqlite3 backend/data/wiring.db
.tables
SELECT * FROM records LIMIT 10;
```

### Q6: 可以部署多个实例吗？

**A**: 可以，但需要修改端口和容器名称，避免冲突。建议使用负载均衡器管理多个实例。

### Q7: 如何升级到新版本？

**A**: 备份数据后，重新运行部署脚本：

```bash
# 备份数据
tar -czf backups/backup_$(date +%Y%m%d).tar.gz backend/data backend/uploads

# 更新代码
git pull

# 重新部署
sudo ./deploy_自动部署.sh
```

### Q8: 如何监控系统性能？

**A**: 使用以下命令监控：

```bash
# 查看容器资源使用
docker stats

# 查看系统资源
htop

# 查看磁盘IO
iostat -x 1
```

---

## 技术支持

如遇到其他问题，请参考：

- [部署技术细节](./deploy_部署技术细节.md)
- [项目主文档](./README.md)
- [后端开发文档](./backend/README.md)
- [前端开发文档](./frontend/README.md)

---

**综合布线记录管理系统** - 让布线管理更简单、更高效
