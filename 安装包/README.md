# Ubuntu 22.04 Docker 和 Docker Compose 离线安装包

本目录包含Ubuntu 22.04 (Jammy Jellyfish) LTS系统的Docker和Docker Compose离线安装包。

## 系统信息

- **操作系统**: Ubuntu 22.04.5 LTS (Jammy Jellyfish)
- **架构**: amd64/x86_64
- **Docker版本**: 24.0.7
- **Docker Compose版本**: 2.24.6

## 安装包列表

### Docker CE 包
1. `docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb` - Docker命令行接口
2. `docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb` - Docker引擎
3. `containerd.io_1.6.24-1_amd64.deb` - 容器运行时
4. `docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb` - Docker Buildx插件
5. `docker-compose-plugin_2.24.6-1~ubuntu.22.04~jammy_amd64.deb` - Docker Compose插件

### Docker Compose 独立版
6. `docker-compose-linux-x86_64` - Docker Compose独立二进制文件（可选）

## 安装步骤

### 方法1：使用DEB包安装（推荐）

```bash
# 进入安装包目录
cd 安装包

# 安装Docker CE包（按顺序安装）
sudo dpkg -i docker-ce-cli_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
sudo dpkg -i containerd.io_1.6.24-1_amd64.deb
sudo dpkg -i docker-ce_24.0.7-1~ubuntu.22.04~jammy_amd64.deb
sudo dpkg -i docker-buildx-plugin_0.12.1-1~ubuntu.22.04~jammy_amd64.deb
sudo dpkg -i docker-compose-plugin_2.24.6-1~ubuntu.22.04~jammy_amd64.deb

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
sudo docker --version
sudo docker compose version
```

### 方法2：使用一键安装脚本

```bash
# 进入安装包目录
cd 安装包

# 运行安装脚本
sudo bash install_docker_ubuntu2204.sh
```

## 验证安装

### 验证Docker
```bash
# 检查Docker版本
sudo docker --version

# 检查Docker服务状态
sudo systemctl status docker

# 运行测试容器
sudo docker run hello-world
```

### 验证Docker Compose
```bash
# 检查Docker Compose插件版本
sudo docker compose version

# 或检查独立版Docker Compose
docker-compose --version
```

## 配置Docker用户

### 将当前用户添加到docker组
```bash
sudo usermod -aG docker $USER

# 使组权限生效（选择一种方式）
# 方式1: 重新登录
# 方式2: 执行
newgrp docker
```

## 配置Docker镜像加速（可选，中国用户推荐）

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

## 故障排除

### 问题1：依赖错误
```bash
# 如果dpkg报告依赖错误，运行以下命令
sudo apt-get install -f
```

### 问题2：Docker服务无法启动
```bash
# 查看Docker服务状态
sudo systemctl status docker

# 查看Docker日志
sudo journalctl -u docker -n 50

# 重启Docker服务
sudo systemctl restart docker
```

### 问题3：权限被拒绝
```bash
# 将当前用户添加到docker组
sudo usermod -aG docker $USER

# 使组权限生效
newgrp docker
```

## 卸载Docker

```bash
# 停止Docker服务
sudo systemctl stop docker

# 卸载Docker包
sudo dpkg -r docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 删除配置文件
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
```

## 参考链接

- Docker官方文档: https://docs.docker.com/engine/install/ubuntu/
- Docker Hub: https://hub.docker.com/
- Ubuntu 22.04文档: https://releases.ubuntu.com/22.04/

## 注意事项

1. 安装前请确保系统已更新：`sudo apt-get update`
2. 安装过程中可能需要输入密码
3. 安装完成后建议重启系统
4. 如果使用独立版Docker Compose，需要手动设置可执行权限
5. Docker Compose插件已包含在docker-compose-plugin包中，无需单独安装独立版
