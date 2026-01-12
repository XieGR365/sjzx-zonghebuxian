# 综合布线记录管理系统 - 部署技术细节文档

## 文档信息
- **文档版本**: v1.0.0
- **最后更新**: 2025-01-04
- **适用系统**: 综合布线记录管理系统
- **目标读者**: 系统管理员、运维工程师、开发人员

---

## 目录
1. [系统架构概述](#1-系统架构概述)
2. [Docker容器化技术细节](#2-docker容器化技术细节)
3. [网络配置详解](#3-网络配置详解)
4. [数据持久化策略](#4-数据持久化策略)
5. [安全配置](#5-安全配置)
6. [性能优化](#6-性能优化)
7. [监控与日志](#7-监控与日志)
8. [故障排查技术](#8-故障排查技术)
9. [扩展性设计](#9-扩展性设计)
10. [技术规格](#10-技术规格)

---

## 1. 系统架构概述

### 1.1 整体架构
系统采用前后端分离的微服务架构，通过Docker容器化技术实现部署的标准化和可移植性。

```
┌─────────────────────────────────────────────────────────────┐
│                        用户浏览器                             │
│                  (Chrome/Firefox/Safari)                     │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS/HTTP (Port 80/443)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Frontend Container                        │
│                   (Nginx + Vue.js SPA)                       │
│                   Port: 80 (Host) → 80 (Container)          │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP (Internal Network)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend Container                         │
│              (Node.js + Express + SQLite)                   │
│                   Port: 3001 (Host → Container)             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   Data Volume                                │
│              (SQLite Database + Uploads)                     │
│              - /app/data (Database)                          │
│              - /app/uploads (Excel Files)                    │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 技术栈
- **前端**: Vue 3 + TypeScript + Vite + Nginx
- **后端**: Node.js + Express + TypeScript + SQLite3
- **容器化**: Docker + Docker Compose
- **反向代理**: Nginx
- **数据处理**: xlsx (Excel解析)

---

## 2. Docker容器化技术细节

### 2.1 前端容器 (Frontend Container)

#### 2.1.1 Dockerfile分析
```dockerfile
# 构建阶段
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# 运行阶段
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**技术要点**:
- **多阶段构建**: 分离构建和运行环境，减小最终镜像体积
- **Alpine Linux**: 使用轻量级基础镜像，减少安全攻击面
- **生产依赖优化**: `npm ci --only=production` 仅安装生产依赖
- **Nginx配置**: 自定义配置文件优化静态资源服务

#### 2.1.2 Nginx配置详解
```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_min_length 1000;

    # SPA路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API代理到后端
    location /api/ {
        proxy_pass http://backend:3001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**配置说明**:
- **Gzip压缩**: 减少传输数据量，提升加载速度
- **SPA路由支持**: 处理Vue Router的history模式
- **静态资源缓存**: 长期缓存策略，减少重复请求
- **API代理**: 将前端API请求转发到后端容器

### 2.2 后端容器 (Backend Container)

#### 2.2.1 Dockerfile分析
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3001
CMD ["node", "dist/server.js"]
```

**技术要点**:
- **TypeScript编译**: 在容器内编译TypeScript代码
- **生产环境优化**: 仅安装生产依赖
- **健康检查**: 通过Docker Compose配置健康检查端点

#### 2.2.2 环境变量配置
```yaml
environment:
  - PORT=3001
  - CORS_ORIGIN=http://localhost
  - DB_PATH=/app/data/wiring.db
  - UPLOAD_DIR=/app/uploads
```

**变量说明**:
- `PORT`: 后端服务监听端口
- `CORS_ORIGIN`: 允许的跨域请求来源
- `DB_PATH`: SQLite数据库文件路径
- `UPLOAD_DIR`: Excel文件上传目录

---

## 3. 网络配置详解

### 3.1 Docker网络架构
```yaml
networks:
  wiring-network:
    driver: bridge
```

**网络特性**:
- **Bridge驱动**: 创建隔离的容器网络
- **服务发现**: 容器间通过服务名互相访问
- **网络隔离**: 容器网络与宿主机网络隔离

### 3.2 端口映射
```yaml
services:
  frontend:
    ports:
      - "80:80"  # 宿主机80 → 容器80
  
  backend:
    ports:
      - "3001:3001"  # 宿主机3001 → 容器3001
```

**端口说明**:
- **80端口**: 前端服务对外暴露端口
- **3001端口**: 后端服务对外暴露端口（可选，主要用于调试）

### 3.3 服务间通信
```
Frontend → Backend: http://backend:3001/
```

**通信特点**:
- **内部DNS**: Docker Compose提供内部DNS解析
- **负载均衡**: 未来可扩展为多实例负载均衡
- **安全隔离**: 后端服务不直接暴露到公网

---

## 4. 数据持久化策略

### 4.1 数据卷配置
```yaml
volumes:
  - ../backend/data:/app/data        # 数据库文件
  - ../backend/uploads:/app/uploads  # 上传文件
```

**持久化内容**:
- **数据库**: SQLite数据库文件 (`wiring.db`)
- **上传文件**: Excel文件存储目录

### 4.2 数据备份策略

#### 4.2.1 自动备份脚本
```bash
#!/bin/bash
# 数据备份脚本
BACKUP_DIR="/backup/wiring"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份数据库
docker exec wiring-backend cp /app/data/wiring.db $BACKUP_DIR/wiring_$DATE.db

# 备份上传文件
docker exec wiring-backend tar -czf /tmp/uploads_$DATE.tar.gz -C /app uploads
docker cp wiring-backend:/tmp/uploads_$DATE.tar.gz $BACKUP_DIR/

# 清理7天前的备份
find $BACKUP_DIR -name "*.db" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

#### 4.2.2 数据恢复步骤
```bash
# 1. 停止服务
docker-compose down

# 2. 恢复数据库
cp /backup/wiring/wiring_20250104_120000.db backend/data/wiring.db

# 3. 恢复上传文件
tar -xzf /backup/wiring/uploads_20250104_120000.tar.gz -C backend/

# 4. 重启服务
docker-compose up -d
```

### 4.3 数据一致性保证
- **事务处理**: SQLite支持ACID事务
- **文件锁**: SQLite使用文件锁保证并发安全
- **备份时机**: 建议在低峰期进行备份

---

## 5. 安全配置

### 5.1 容器安全
```yaml
# 使用非root用户运行
user: node

# 只读文件系统（可选）
read_only: true

# 限制特权
privileged: false
```

### 5.2 网络安全
- **防火墙配置**: 仅开放必要端口（80/443）
- **HTTPS配置**: 使用Let's Encrypt免费SSL证书
- **CORS限制**: 严格配置跨域访问策略

### 5.3 数据安全
- **文件权限**: 数据库文件权限设置为600
- **敏感信息**: 环境变量不包含敏感信息
- **日志脱敏**: 日志中不记录敏感数据

### 5.4 安全加固建议
```bash
# 1. 更新系统包
apt-get update && apt-get upgrade -y

# 2. 配置防火墙
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# 3. 限制Docker访问
usermod -aG docker $USER
```

---

## 6. 性能优化

### 6.1 前端优化
- **代码分割**: Vite自动进行代码分割
- **懒加载**: 路由级别的懒加载
- **资源压缩**: Gzip压缩静态资源
- **CDN加速**: 可配置CDN加速静态资源

### 6.2 后端优化
- **连接池**: SQLite连接池配置
- **查询优化**: 数据库索引优化
- **缓存策略**: 可添加Redis缓存层
- **异步处理**: 使用异步I/O提升并发性能

### 6.3 数据库优化
```sql
-- 创建索引
CREATE INDEX idx_user_unit ON records(user_unit);
CREATE INDEX idx_building ON records(building);
CREATE INDEX idx_floor ON records(floor);

-- 定期VACUUM
VACUUM;
```

### 6.4 容器资源限制
```yaml
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 512M
    reservations:
      cpus: '0.5'
      memory: 256M
```

---

## 7. 监控与日志

### 7.1 日志配置
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### 7.2 健康检查
```yaml
healthcheck:
  test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3001/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### 7.3 监控指标
- **容器状态**: CPU、内存、磁盘使用率
- **服务健康**: HTTP健康检查端点
- **日志监控**: 错误日志、访问日志
- **性能指标**: 响应时间、请求量

### 7.4 日志查看命令
```bash
# 查看所有日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f frontend
docker-compose logs -f backend

# 查看最近100行日志
docker-compose logs --tail=100
```

---

## 8. 故障排查技术

### 8.1 常见问题诊断

#### 8.1.1 容器启动失败
```bash
# 查看容器日志
docker-compose logs

# 检查容器状态
docker-compose ps

# 查看详细错误信息
docker inspect <container_id>
```

#### 8.1.2 网络连接问题
```bash
# 检查网络配置
docker network ls
docker network inspect wiring_wiring-network

# 测试容器间连接
docker exec wiring-frontend ping backend
```

#### 8.1.3 数据库访问问题
```bash
# 检查数据库文件权限
ls -la backend/data/

# 验证数据库完整性
docker exec wiring-backend sqlite3 /app/data/wiring.db "PRAGMA integrity_check;"
```

### 8.2 性能问题诊断
```bash
# 查看容器资源使用
docker stats

# 分析慢查询
docker exec wiring-backend sqlite3 /app/data/wiring.db ".timer on" "SELECT * FROM records;"

# 检查磁盘空间
df -h
du -sh backend/data/
```

### 8.3 日志分析技巧
```bash
# 查找错误日志
docker-compose logs | grep -i error

# 统计错误数量
docker-compose logs | grep -i error | wc -l

# 查看最近错误
docker-compose logs --tail=100 | grep -i error
```

---

## 9. 扩展性设计

### 9.1 水平扩展
```yaml
# 扩展后端服务实例
backend:
  deploy:
    replicas: 3
  # 配置负载均衡器
```

### 9.2 数据库迁移
- **SQLite → PostgreSQL**: 支持更大规模数据
- **主从复制**: 数据库读写分离
- **分库分表**: 大数据量场景

### 9.3 缓存层集成
```yaml
# 添加Redis缓存
redis:
  image: redis:alpine
  ports:
    - "6379:6379"
  volumes:
    - redis-data:/data
```

### 9.4 微服务拆分
- **认证服务**: 独立的用户认证服务
- **文件服务**: 文件上传下载服务
- **统计服务**: 数据统计分析服务

---

## 10. 技术规格

### 10.1 系统要求
- **操作系统**: Linux (Ubuntu 20.04+, CentOS 7+, Debian 10+)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **内存**: 最低2GB，推荐4GB
- **磁盘**: 最低20GB，推荐50GB
- **CPU**: 最低2核，推荐4核

### 10.2 网络要求
- **带宽**: 最低10Mbps，推荐100Mbps
- **端口**: 80 (HTTP), 443 (HTTPS)
- **延迟**: 内部网络延迟 < 10ms

### 10.3 性能指标
- **并发用户**: 支持100+并发用户
- **响应时间**: 页面加载 < 2秒
- **数据处理**: 支持10万+记录
- **文件上传**: 支持50MB+文件

### 10.4 可靠性指标
- **可用性**: 99.9%
- **数据备份**: 每日自动备份
- **故障恢复**: < 5分钟
- **数据一致性**: ACID保证

---

## 附录

### A. Docker命令速查
```bash
# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f

# 进入容器
docker exec -it <container_name> sh

# 更新镜像
docker-compose pull
docker-compose up -d
```

### B. 数据库管理命令
```bash
# 进入数据库
docker exec -it wiring-backend sqlite3 /app/data/wiring.db

# 查看表结构
.schema

# 查询数据
SELECT * FROM records LIMIT 10;

# 导出数据
.mode csv
.output records.csv
SELECT * FROM records;
.quit
```

### C. 故障恢复流程
1. **识别问题**: 查看日志和监控指标
2. **定位原因**: 分析错误信息和系统状态
3. **执行修复**: 应用相应的修复方案
4. **验证结果**: 确认问题已解决
5. **记录文档**: 更新故障处理文档

### D. 联系支持
- **技术文档**: 参考项目README和部署文档
- **问题反馈**: 提交GitHub Issue
- **紧急联系**: 系统管理员

---

**文档结束**
