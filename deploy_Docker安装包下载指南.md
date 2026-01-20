# Docker 和 Docker Compose 离线安装包下载指南

本文档提供了Docker和Docker Compose的离线安装包下载链接和安装方法。

## 系统要求

- Linux系统（Ubuntu 20.04+, CentOS 7+, Debian 10+）
- 至少2GB可用内存
- 至少10GB可用磁盘空间

---

## 一、Docker 安装包

### Ubuntu/Debian 系统

#### 方法1：使用官方APT仓库（推荐，需要网络）

```bash
# 更新包索引
sudo apt-get update

# 安装依赖
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 添加Docker官方GPG密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 设置Docker仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新包索引
sudo apt-get update

# 安装Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker
```

#### 方法2：下载DEB包（离线安装）

**Ubuntu 22.04 (Jammy Jellyfish)**
```bash
# 下载Docker CE包
wget https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/containerd.io_1.6.24-1_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/jammy/pool/stable/amd64/docker-compose-plugin_2.24.6-1~ubuntu.22.04~jammy_amd64.deb

# 安装DEB包
sudo dpkg -i docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
sudo dpkg -i docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
sudo dpkg -i containerd.io_1.6.24-1_amd64.deb
sudo dpkg -i docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb
sudo dpkg -i docker-compose-plugin_2.24.6-1~ubuntu.22.04~jammy_amd64.deb

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker
```

**Ubuntu 20.04 (Focal Fossa)**
```bash
# 下载Docker CE包
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce-cli_24.0.7-1~ubuntu.20.04~focal_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce_24.0.7-1~ubuntu.20.04~focal_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/containerd.io_1.6.24-1_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-buildx-plugin_0.12.1-1~ubuntu.20.04~focal_amd64.deb
wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-compose-plugin_2.24.6-1~ubuntu.20.04~focal_amd64.deb

# 安装DEB包
sudo dpkg -i docker-ce-cli_24.0.7-1~ubuntu.20.04~focal_amd64.deb
sudo dpkg -i docker-ce_24.0.7-1~ubuntu.20.04~focal_amd64.deb
sudo dpkg -i containerd.io_1.6.24-1_amd64.deb
sudo dpkg -i docker-buildx-plugin_0.12.1-1~ubuntu.20.04~focal_amd64.deb
sudo dpkg -i docker-compose-plugin_2.24.6-1~ubuntu.20.04~focal_amd64.deb

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker
```

### CentOS/RHEL/Fedora 系统

#### 方法1：使用YUM仓库（推荐，需要网络）

```bash
# 安装yum-utils
sudo yum install -y yum-utils

# 添加Docker仓库
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安装Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker
```

#### 方法2：下载RPM包（离线安装）

**CentOS 8 / RHEL 8**
```bash
# 下载Docker CE包
wget https://download.docker.com/linux/centos/8/x86_64/stable/Packages/containerd.io-1.6.24-3.1.el8.x86_64.rpm
wget https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-ce-cli-24.0.7-1.el8.x86_64.rpm
wget https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-ce-24.0.7-1.el8.x86_64.rpm
wget https://download.docker.com/linux/centos/8/x86_64/stable/Packages/docker-compose-plugin-2.24.6-1.el8.x86_64.rpm

# 安装RPM包
sudo yum install -y containerd.io-1.6.24-3.1.el8.x86_64.rpm
sudo yum install -y docker-ce-cli-24.0.7-1.el8.x86_64.rpm
sudo yum install -y docker-ce-24.0.7-1.el8.x86_64.rpm
sudo yum install -y docker-compose-plugin-2.24.6-1.el8.x86_64.rpm

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker
```

**CentOS 7 / RHEL 7**
```bash
# 下载Docker CE包
wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.6.24-3.1.el7.x86_64.rpm
wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-cli-24.0.7-1.el7.x86_64.rpm
wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-24.0.7-1.el7.x86_64.rpm
wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-compose-plugin-2.24.6-1.el7.x86_64.rpm

# 安装RPM包
sudo yum install -y containerd.io-1.6.24-3.1.el7.x86_64.rpm
sudo yum install -y docker-ce-cli-24.0.7-1.el7.x86_64.rpm
sudo yum install -y docker-ce-24.0.7-1.el7.x86_64.rpm
sudo yum install -y docker-compose-plugin-2.24.6-1.el7.x86_64.rpm

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker
```

---

## 二、Docker Compose 安装包

### 方法1：Docker Compose 插件（推荐）

Docker Compose现在作为Docker的插件提供，无需单独安装。

如果使用Docker 20.10+版本，`docker compose` 命令已经内置。

检查是否已安装：
```bash
sudo docker compose version
```

### 方法2：独立版Docker Compose（适用于旧版Docker）

**下载独立版Docker Compose（适用于所有Linux发行版）**

```bash
# 下载最新版本的Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 设置可执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker-compose --version
```

**手动下载链接（选择适合你系统的版本）**

Linux x86_64:
```
https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64
```

Linux aarch64 (ARM64):
```
https://github.com/docker/compose/releases/latest/download/docker-compose-linux-aarch64
```

**特定版本下载链接**

Docker Compose v2.24.6 (最新稳定版):
- Linux x86_64: https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-linux-x86_64
- Linux aarch64: https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-linux-aarch64

---

## 三、快速安装脚本

### Ubuntu/Debian 一键安装脚本

```bash
#!/bin/bash
# 更新系统
sudo apt-get update

# 安装依赖
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 添加Docker GPG密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 设置仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新并安装
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动服务
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到docker组
sudo usermod -aG docker $USER

echo "Docker安装完成！"
echo "请执行: newgrp docker 或重新登录"
```

### CentOS/RHEL 一键安装脚本

```bash
#!/bin/bash
# 安装yum-utils
sudo yum install -y yum-utils

# 添加Docker仓库
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安装Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动服务
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到docker组
sudo usermod -aG docker $USER

echo "Docker安装完成！"
echo "请执行: newgrp docker 或重新登录"
```

---

## 四、验证安装

### 验证Docker安装

```bash
# 检查Docker版本
sudo docker --version

# 检查Docker服务状态
sudo systemctl status docker

# 运行测试容器
sudo docker run hello-world
```

### 验证Docker Compose安装

```bash
# 检查Docker Compose插件版本
sudo docker compose version

# 或检查独立版Docker Compose
docker-compose --version
```

---

## 五、常用Docker镜像加速（中国用户）

如果下载镜像速度慢，可以配置镜像加速器：

```bash
# 创建Docker配置目录
sudo mkdir -p /etc/docker

# 配置镜像加速器
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com"
  ]
}
EOF

# 重启Docker服务
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## 六、故障排除

### 问题1：Docker服务无法启动

```bash
# 查看Docker服务状态
sudo systemctl status docker

# 查看Docker日志
sudo journalctl -u docker -n 50

# 重启Docker服务
sudo systemctl restart docker
```

### 问题2：权限被拒绝

```bash
# 将当前用户添加到docker组
sudo usermod -aG docker $USER

# 使组权限生效（选择一种方式）
# 方式1: 重新登录
# 方式2: 执行
newgrp docker
```

### 问题3：端口被占用

```bash
# 查看端口占用
sudo netstat -tuln | grep -E ':(80|3001) '

# 停止占用端口的进程
sudo kill -9 <PID>
```

---

## 七、卸载Docker

### Ubuntu/Debian

```bash
# 卸载Docker
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 删除配置文件
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
```

### CentOS/RHEL

```bash
# 卸载Docker
sudo yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 删除配置文件
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
```

---

## 八、参考链接

- Docker官方文档: https://docs.docker.com/engine/install/
- Docker Compose文档: https://docs.docker.com/compose/install/
- Docker Hub: https://hub.docker.com/
- Docker GitHub: https://github.com/docker/docker-ce

---

**注意**: 请根据你的Linux发行版选择合适的安装方法。如果服务器无法访问外网，建议使用离线安装包的方法。
