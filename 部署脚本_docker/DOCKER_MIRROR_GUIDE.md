# Docker镜像源配置指南

## 问题描述

服务器192.168.19.58无法访问外网的Docker Hub，导致部署失败：

```
failed to solve: node:18-alpine: failed to do request: Head "https://docker.mirrors.ustc.edu.cn/v2/library/node/manifests/18-alpine?ns=docker.io": dial tcp: lookup docker.mirrors.ustc.edu.cn on 127.0.0.53:53: i/o timeout
```

## 解决方案

根据您的网络环境，有以下几种解决方案：

### 方案1：使用内网私有Docker镜像仓库（推荐）

如果您在192.168.19.58或内网其他服务器上搭建了私有Docker镜像仓库：

#### 步骤1：配置Docker镜像源

编辑 `config/docker_mirror.conf` 文件：

```bash
# 设置为私有仓库模式
MIRROR_TYPE=private

# 配置私有仓库地址
PRIVATE_REGISTRY=192.168.19.58:5000

# 如果仓库使用HTTP（非HTTPS），设置为true
INSECURE_REGISTRY=true
```

#### 步骤2：配置Docker镜像地址

编辑 `config/.env` 文件：

```bash
# 使用私有仓库的镜像
NODE_IMAGE=192.168.19.58:5000/library/node:18-alpine
NGINX_IMAGE=192.168.19.58:5000/library/nginx:alpine
```

#### 步骤3：运行部署脚本

```bash
sudo bash deploy_自动部署.sh
```

### 方案2：使用自定义镜像源

如果您有其他可访问的Docker镜像源：

#### 步骤1：配置Docker镜像源

编辑 `config/docker_mirror.conf` 文件：

```bash
# 设置为自定义模式
MIRROR_TYPE=custom

# 配置自定义镜像源列表
CUSTOM_MIRRORS=(
    "http://your-mirror-1.com"
    "http://your-mirror-2.com"
)
```

#### 步骤2：配置Docker镜像地址

编辑 `config/.env` 文件：

```bash
# 使用自定义镜像源的镜像
NODE_IMAGE=your-mirror-1.com/library/node:18-alpine
NGINX_IMAGE=your-mirror-1.com/library/nginx:alpine
```

#### 步骤3：运行部署脚本

```bash
sudo bash deploy_自动部署.sh
```

### 方案3：仅配置DNS（尝试直接连接Docker Hub）

如果您的网络可以访问Docker Hub但DNS解析有问题：

#### 步骤1：配置Docker镜像源

编辑 `config/docker_mirror.conf` 文件：

```bash
# 仅配置DNS
MIRROR_TYPE=none

# 配置DNS服务器
DNS_SERVERS=(
    "8.8.8.8"
    "114.114.114.114"
    "223.5.5.5"
)
```

#### 步骤2：运行部署脚本

```bash
sudo bash deploy_自动部署.sh
```

### 方案4：使用交互式配置工具

使用提供的交互式配置工具：

```bash
sudo bash configure_docker_mirror.sh
```

按照提示选择配置方式。

## 搭建私有Docker镜像仓库

如果您需要搭建私有Docker镜像仓库，可以使用以下方法：

### 方法1：使用Docker Registry

```bash
# 启动Docker Registry
docker run -d \
  -p 5000:5000 \
  --name registry \
  -v /data/registry:/var/lib/registry \
  registry:2
```

### 方法2：使用Harbor（企业级）

Harbor是一个企业级Docker镜像仓库，提供更多功能：

1. 下载Harbor安装包
2. 配置harbor.yml
3. 运行install.sh

### 推送镜像到私有仓库

```bash
# 1. 拉取官方镜像
docker pull node:18-alpine
docker pull nginx:alpine

# 2. 重新打标签
docker tag node:18-alpine 192.168.19.58:5000/library/node:18-alpine
docker tag nginx:alpine 192.168.19.58:5000/library/nginx:alpine

# 3. 推送到私有仓库
docker push 192.168.19.58:5000/library/node:18-alpine
docker push 192.168.19.58:5000/library/nginx:alpine
```

## 配置文件说明

### config/docker_mirror.conf

Docker镜像加速器配置文件：

| 配置项 | 说明 | 可选值 |
|--------|------|--------|
| MIRROR_TYPE | 镜像源类型 | default, aliyun, custom, private, none |
| CUSTOM_MIRRORS | 自定义镜像源列表 | URL数组 |
| PRIVATE_REGISTRY | 私有仓库地址 | IP:端口 或 域名:端口 |
| INSECURE_REGISTRY | 是否允许HTTP连接 | true, false |
| DNS_SERVERS | DNS服务器列表 | IP地址数组 |

### config/.env

Docker镜像地址配置文件：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| NODE_IMAGE | Node.js镜像地址 | node:18-alpine 或 192.168.19.58:5000/library/node:18-alpine |
| NGINX_IMAGE | Nginx镜像地址 | nginx:alpine 或 192.168.19.58:5000/library/nginx:alpine |

## 验证配置

### 检查Docker配置

```bash
# 查看Docker信息
sudo docker info | grep -A 10 "Registry Mirrors\|Insecure Registries"

# 查看daemon.json配置
cat /etc/docker/daemon.json
```

### 测试镜像拉取

```bash
# 测试拉取Node.js镜像
sudo docker pull $NODE_IMAGE

# 测试拉取Nginx镜像
sudo docker pull $NGINX_IMAGE
```

### 查看已拉取的镜像

```bash
sudo docker images
```

## 常见问题

### Q1: 配置后仍然无法连接

**A**: 检查以下几点：

1. 确认私有仓库地址正确
2. 确认私有仓库服务正在运行
3. 检查防火墙规则
4. 查看Docker日志：`sudo journalctl -u docker -n 50`

### Q2: 提示"insecure registry"

**A**: 在 `/etc/docker/daemon.json` 中添加：

```json
{
  "insecure-registries": ["192.168.19.58:5000"]
}
```

然后重启Docker：

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Q3: 如何回滚到默认配置？

**A**: 删除配置文件或修改为默认值：

```bash
# 编辑 config/docker_mirror.conf
MIRROR_TYPE=default

# 或删除配置文件，让脚本使用默认配置
rm config/docker_mirror.conf
```

### Q4: 镜像拉取速度慢

**A**: 尝试以下方法：

1. 使用多个镜像源（提高可用性）
2. 使用离线安装包
3. 预先拉取镜像：`sudo bash pull_docker_images.sh`

## 快速配置示例

### 示例1：使用192.168.19.58:5000私有仓库

```bash
# 编辑 config/docker_mirror.conf
cat > config/docker_mirror.conf << 'EOF'
MIRROR_TYPE=private
PRIVATE_REGISTRY=192.168.19.58:5000
INSECURE_REGISTRY=true
DNS_SERVERS=("8.8.8.8" "114.114.114.114")
EOF

# 编辑 config/.env
cat > config/.env << 'EOF'
NODE_IMAGE=192.168.19.58:5000/library/node:18-alpine
NGINX_IMAGE=192.168.19.58:5000/library/nginx:alpine
EOF

# 运行部署
sudo bash deploy_自动部署.sh
```

### 示例2：使用阿里云镜像加速器

```bash
# 编辑 config/docker_mirror.conf
cat > config/docker_mirror.conf << 'EOF'
MIRROR_TYPE=aliyun
DNS_SERVERS=("8.8.8.8" "114.114.114.114")
EOF

# 运行部署
sudo bash deploy_自动部署.sh
```

## 联系支持

如果以上方案都无法解决问题，请联系技术支持并提供以下信息：

1. 服务器IP：192.168.19.58
2. 网络环境描述
3. Docker版本：`docker --version`
4. 错误日志：`sudo journalctl -u docker -n 50`
