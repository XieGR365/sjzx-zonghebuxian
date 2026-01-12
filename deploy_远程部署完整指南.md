# 综合布线记录管理系统 - 远程服务器部署完整指南

## 服务器信息
- **服务器地址**: 192.168.19.58
- **用户名**: yroot
- **密码**: Yovole@2026

## 部署前准备

### 步骤1：准备本地部署包

在本地电脑上，我们需要准备以下文件：

#### 1.1 创建部署目录
```bash
# 在项目根目录下创建部署包目录
mkdir deploy_package
cd deploy_package
```

#### 1.2 复制必要文件
需要复制的文件包括：
- `backend/` - 后端服务代码
- `frontend/` - 前端服务代码
- `config/` - 配置文件
- `deploy_自动部署.sh` - 自动部署脚本
- `deploy_服务器使用说明.md` - 服务器使用说明
- `deploy_部署技术细节.md` - 部署技术细节

#### 1.3 创建部署脚本
创建 `deploy_远程部署.bat` 文件（Windows批处理脚本）

### 步骤2：上传文件到服务器

#### 2.1 使用SCP上传文件
```bash
# 在Windows上使用PowerShell或CMD执行以下命令：

# 创建远程目录（需要手动输入密码）
ssh yroot@192.168.19.58 "mkdir -p /opt/sjzx-zonghebuxian"

# 上传backend目录
scp -r backend yroot@192.168.19.58:/opt/sjzx-zonghebuxian/

# 上传frontend目录
scp -r frontend yroot@192.168.19.58:/opt/sjzx-zonghebuxian/

# 上传config目录
scp -r config yroot@192.168.19.58:/opt/sjzx-zonghebuxian/

# 上传部署脚本
scp deploy_自动部署.sh yroot@192.168.19.58:/opt/sjzx-zonghebuxian/

# 上传文档
scp deploy_服务器使用说明.md yroot@192.168.19.58:/opt/sjzx-zonghebuxian/
scp deploy_部署技术细节.md yroot@192.168.19.58:/opt/sjzx-zonghebuxian/
```

**注意**：每次执行scp命令时，系统会提示输入密码 `Yovole@2026`

#### 2.2 使用SFTP工具上传（推荐）
使用FileZilla、WinSCP等SFTP工具：
1. 服务器：192.168.19.58
2. 端口：22
3. 用户名：yroot
4. 密码：Yovole@2026
5. 上传目录：/opt/sjzx-zonghebuxian

### 步骤3：登录服务器并执行部署

#### 3.1 SSH登录服务器
```bash
ssh yroot@192.168.19.58
# 输入密码：Yovole@2026
```

#### 3.2 进入项目目录
```bash
cd /opt/sjzx-zonghebuxian
```

#### 3.3 查看文件是否上传成功
```bash
ls -la
```

应该看到以下文件和目录：
```
backend/
frontend/
config/
deploy_自动部署.sh
deploy_服务器使用说明.md
deploy_部署技术细节.md
```

#### 3.4 给部署脚本添加执行权限
```bash
chmod +x deploy_自动部署.sh
```

#### 3.5 执行自动部署脚本
```bash
./deploy_自动部署.sh
```

脚本会自动执行以下操作：
1. 检查系统环境
2. 安装Docker和Docker Compose（如果未安装）
3. 构建Docker镜像
4. 启动前后端服务
5. 配置数据持久化
6. 显示部署结果

### 步骤4：验证部署

#### 4.1 检查容器状态
```bash
docker ps
```

应该看到两个容器在运行：
- `wiring-backend` - 后端服务
- `wiring-frontend` - 前端服务

#### 4.2 查看服务日志
```bash
# 查看后端日志
docker logs wiring-backend

# 查看前端日志
docker logs wiring-frontend
```

#### 4.3 测试后端API
```bash
curl http://localhost:3001/health
```

应该返回：
```json
{"status":"ok","message":"Backend service is running"}
```

#### 4.4 访问前端界面
在浏览器中打开：
```
http://192.168.19.58
```

应该看到综合布线记录管理系统的登录界面

### 步骤5：测试功能

#### 5.1 测试文件上传
1. 点击"上传文件"菜单
2. 选择一个Excel文件
3. 点击"上传"按钮
4. 查看上传结果

#### 5.2 测试查询功能
1. 点击"布线记录"菜单
2. 输入查询条件
3. 点击"查询"按钮
4. 查看查询结果

#### 5.3 测试导出功能
1. 在查询结果页面
2. 点击"导出"按钮
3. 下载Excel文件

#### 5.4 测试跳纤统计
1. 点击"跳纤统计"菜单
2. 查看各机房的统计数据
3. 点击"查看详情"查看详细记录

## 常见问题处理

### 问题1：Docker安装失败
**解决方案**：
```bash
# 手动安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo systemctl start docker
sudo systemctl enable docker
```

### 问题2：端口被占用
**解决方案**：
```bash
# 查看端口占用
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :3001

# 停止占用端口的进程
sudo kill -9 <PID>
```

### 问题3：容器启动失败
**解决方案**：
```bash
# 查看容器日志
docker logs wiring-backend
docker logs wiring-frontend

# 重新构建镜像
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 问题4：无法访问前端
**解决方案**：
```bash
# 检查防火墙设置
sudo firewall-cmd --list-ports
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload

# 或者使用iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables-save
```

## 部署后维护

### 查看服务状态
```bash
cd /opt/sjzx-zonghebuxian
docker-compose ps
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

### 查看日志
```bash
cd /opt/sjzx-zonghebuxian
docker-compose logs -f
```

### 备份数据
```bash
# 备份数据库
cd /opt/sjzx-zonghebuxian
cp data/wiring.db data/wiring.db.backup.$(date +%Y%m%d)

# 备份上传文件
tar -czf uploads_backup_$(date +%Y%m%d).tar.gz uploads/
```

### 更新系统
```bash
cd /opt/sjzx-zonghebuxian
docker-compose down
git pull  # 如果使用Git管理
docker-compose build --no-cache
docker-compose up -d
```

## 联系支持

如果遇到问题，请查看：
- [deploy_服务器使用说明.md](file:///d:\TREA\sjzx-zonghebuxian\deploy_服务器使用说明.md)
- [deploy_部署技术细节.md](file:///d:\TREA\sjzx-zonghebuxian\deploy_部署技术细节.md)
- [04-实施/实施文档.md](file:///d:\TREA\sjzx-zonghebuxian\04-实施\实施文档.md)

---

**部署完成！** 🎉

现在你可以通过浏览器访问 http://192.168.19.58 来使用综合布线记录管理系统了。
