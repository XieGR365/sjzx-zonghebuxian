# 综合布线记录管理系统 - 后端

> 基于 Node.js + TypeScript + Express + SQLite 的综合布线记录管理系统后端服务

[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue)](https://www.typescriptlang.org/)
[![Express](https://img.shields.io/badge/Express-4.x-000000)](https://expressjs.com/)

## 项目简介

后端服务提供RESTful API接口，支持Excel文件上传、数据解析、多条件查询、记录管理等核心功能。采用TypeScript全栈开发，确保类型安全和代码可维护性。

## 技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| **Node.js** | 18+ | JavaScript运行时环境 |
| **TypeScript** | 5.x | 类型安全的JavaScript超集 |
| **Express** | 4.x | 轻量级Web应用框架 |
| **better-sqlite3** | 9.x | 同步SQLite数据库驱动 |
| **Multer** | 1.x | 处理multipart/form-data的中间件 |
| **XLSX** | 0.18.x | Excel文件解析库 |
| **CORS** | 2.8.x | 跨域资源共享中间件 |
| **dotenv** | 16.x | 环境变量管理 |

## 项目结构

```
backend/
├── src/
│   ├── config/
│   │   └── database.ts          # 数据库配置和初始化
│   ├── controllers/
│   │   └── RecordController.ts  # 记录相关控制器
│   ├── models/
│   │   └── RecordModel.ts       # 记录数据模型
│   ├── routes/
│   │   └── recordRoutes.ts      # 记录相关路由
│   ├── services/
│   │   └── ExcelParser.ts       # Excel解析服务
│   ├── types/
│   │   └── index.ts             # TypeScript类型定义
│   └── server.ts                # 服务器入口
├── uploads/                     # 上传文件目录
├── data/                        # 数据库文件目录
├── package.json                  # 依赖配置
├── tsconfig.json                # TypeScript配置
└── .env                         # 环境变量配置
```

## 架构设计

### 分层架构

```
┌─────────────────────────────────┐
│         Routes Layer            │  路由层 - 定义API端点
├─────────────────────────────────┤
│      Controllers Layer         │  控制器层 - 处理请求和响应
├─────────────────────────────────┤
│       Services Layer           │  服务层 - 业务逻辑处理
├─────────────────────────────────┤
│        Models Layer            │  模型层 - 数据访问
├─────────────────────────────────┤
│       Database Layer           │  数据库层 - SQLite
└─────────────────────────────────┘
```

### 设计原则

- **单一职责**: 每个模块只负责一个功能
- **依赖注入**: 通过构造函数注入依赖
- **错误处理**: 统一的错误处理机制
- **类型安全**: 使用TypeScript确保类型安全
- **代码复用**: 提取公共逻辑到服务层

## 安装依赖

```bash
cd backend
npm install
```

## 环境配置

编辑 `.env` 文件：

```env
# 服务端口
PORT=3001

# 跨域允许的源地址
CORS_ORIGIN=http://localhost:5173

# 数据库文件路径
DB_PATH=./data/wiring.db

# 上传文件目录
UPLOAD_DIR=./uploads

# 最大文件大小（字节，默认10MB）
MAX_FILE_SIZE=10485760

# 日志级别（debug, info, warn, error）
LOG_LEVEL=info
```

## 启动开发服务器

```bash
npm run dev
```

服务将在 `http://localhost:3001` 启动。

## 构建生产版本

```bash
npm run build
npm start
```

## API 接口

### 基础信息

- **Base URL**: `http://localhost:3001`
- **Content-Type**: `application/json` (除文件上传外)
- **字符编码**: `UTF-8`

### 响应格式

#### 成功响应

```json
{
  "success": true,
  "data": { ... },
  "message": "操作成功"
}
```

#### 错误响应

```json
{
  "success": false,
  "message": "错误描述",
  "error": "详细错误信息"
}
```

### 错误码

| 错误码 | 说明 | HTTP状态码 |
|--------|------|-----------|
| 400 | 请求参数错误 | 400 |
| 404 | 资源不存在 | 404 |
| 500 | 服务器内部错误 | 500 |

### 接口列表

#### 1. 上传文件

- **接口**: `POST /api/records/upload`
- **Content-Type**: `multipart/form-data`
- **参数**: 
  - `file`: Excel文件（.xlsx, .xls）
- **请求示例**:

```bash
curl -X POST http://localhost:3001/api/records/upload \
  -F "file=@data.xlsx"
```

- **成功响应**:

```json
{
  "success": true,
  "message": "文件上传成功",
  "data": {
    "count": 100,
    "ids": [1, 2, 3, ...]
  }
}
```

- **错误响应**:

```json
{
  "success": false,
  "message": "文件格式错误"
}
```

#### 2. 查询记录

- **接口**: `GET /api/records/query`
- **参数**: 
  - `datacenter_name`: 机房名称（可选）
  - `record_number`: 登记表编号（模糊查询，可选）
  - `circuit_number`: 线路编号（模糊查询，可选）
  - `start_port`: 起始端口（模糊查询，可选）
  - `end_port`: 目标端口（模糊查询，可选）
  - `user_cabinet`: 用户机柜（模糊查询，可选）
  - `operator`: 运营商（可选）
  - `cable_type`: 线缆类型（可选）
  - `idc_requirement_number`: IDC需求编号（模糊查询，可选）
  - `yes_ticket_number`: YES工单编号（模糊查询，可选）
  - `page`: 页码（默认1）
  - `page_size`: 每页数量（默认20，最大100）

- **请求示例**:

```bash
curl "http://localhost:3001/api/records/query?datacenter_name=机房A&page=1&page_size=20"
```

- **成功响应**:

```json
{
  "success": true,
  "data": {
    "records": [
      {
        "id": 1,
        "record_number": "BL2024001",
        "datacenter_name": "机房A",
        "circuit_number": "C001",
        "start_port": "A-01-01",
        "end_port": "B-01-01",
        "created_at": "2024-01-01T00:00:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total": 100,
      "total_pages": 5
    }
  }
}
```

#### 3. 获取记录详情

- **接口**: `GET /api/records/detail/:id`
- **参数**: `id` (路径参数)

- **请求示例**:

```bash
curl http://localhost:3001/api/records/detail/1
```

- **成功响应**:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "record_number": "BL2024001",
    "datacenter_name": "机房A",
    "idc_requirement_number": "IDC001",
    "yes_ticket_number": "YES001",
    "user_unit": "用户单位",
    "cable_type": "光纤",
    "operator": "电信",
    "circuit_number": "C001",
    "contact_person": "张三/13800138000",
    "start_port": "A-01-01",
    "hop1": "A-01-02",
    "hop2": "A-01-03",
    "hop3": null,
    "hop4": null,
    "hop5": null,
    "end_port": "B-01-01",
    "user_cabinet": "CAB-001",
    "label_complete": 1,
    "cable_standard": 1,
    "remark": "备注信息",
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

#### 4. 获取机房列表

- **接口**: `GET /api/records/datacenters`

- **请求示例**:

```bash
curl http://localhost:3001/api/records/datacenters
```

- **成功响应**:

```json
{
  "success": true,
  "data": ["机房A", "机房B", "机房C"]
}
```

#### 5. 获取筛选选项

- **接口**: `GET /api/records/filter-options`

- **请求示例**:

```bash
curl http://localhost:3001/api/records/filter-options
```

- **成功响应**:

```json
{
  "success": true,
  "data": {
    "datacenters": ["机房A", "机房B", "机房C"],
    "operators": ["电信", "联通", "移动"],
    "cable_types": ["光纤", "网线", "同轴电缆"]
  }
}
```

#### 6. 清空所有数据

- **接口**: `DELETE /api/records/clear`

- **请求示例**:

```bash
curl -X DELETE http://localhost:3001/api/records/clear
```

- **成功响应**:

```json
{
  "success": true,
  "message": "数据清空成功",
  "data": {
    "count": 100
  }
}
```

#### 7. 健康检查

- **接口**: `GET /health`

- **请求示例**:

```bash
curl http://localhost:3001/health
```

- **成功响应**:

```json
{
  "status": "ok",
  "message": "综合布线记录管理系统后端服务正常运行",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## 数据库

### 数据库设计

使用SQLite数据库，数据存储在 `data/wiring.db` 文件中。

### 数据表结构

#### records 表

| 字段名 | 类型 | 说明 | 约束 |
|--------|------|------|------|
| id | INTEGER | 主键ID | PRIMARY KEY AUTOINCREMENT |
| record_number | TEXT | 登记表编号 | NOT NULL |
| datacenter_name | TEXT | 机房名称 | NOT NULL |
| idc_requirement_number | TEXT | IDC需求编号 | |
| yes_ticket_number | TEXT | YES工单编号 | |
| user_unit | TEXT | 用户单位 | |
| cable_type | TEXT | 线缆类型 | |
| operator | TEXT | 运营商 | |
| circuit_number | TEXT | 线路编号 | |
| contact_person | TEXT | 联系人/电话 | |
| start_port | TEXT | 起始端口 | NOT NULL |
| hop1 | TEXT | 跳接点1 | |
| hop2 | TEXT | 跳接点2 | |
| hop3 | TEXT | 跳接点3 | |
| hop4 | TEXT | 跳接点4 | |
| hop5 | TEXT | 跳接点5 | |
| end_port | TEXT | 目标端口 | NOT NULL |
| user_cabinet | TEXT | 用户机柜 | |
| label_complete | INTEGER | 标签是否完整 | DEFAULT 0 |
| cable_standard | INTEGER | 线缆是否规范 | DEFAULT 0 |
| remark | TEXT | 备注 | |
| created_at | TEXT | 创建时间 | DEFAULT CURRENT_TIMESTAMP |
| updated_at | TEXT | 更新时间 | DEFAULT CURRENT_TIMESTAMP |

### 索引设计

```sql
-- 机房名称索引
CREATE INDEX idx_datacenter_name ON records(datacenter_name);

-- 线路编号索引
CREATE INDEX idx_circuit_number ON records(circuit_number);

-- 起始端口索引
CREATE INDEX idx_start_port ON records(start_port);

-- 目标端口索引
CREATE INDEX idx_end_port ON records(end_port);

-- 用户机柜索引
CREATE INDEX idx_user_cabinet ON records(user_cabinet);

-- 创建时间索引
CREATE INDEX idx_created_at ON records(created_at);
```

### 数据库优化

- 使用索引加速查询
- 使用预编译语句防止SQL注入
- 定期执行 `VACUUM` 命令优化数据库
- 使用事务确保数据一致性

## 测试

### 单元测试

```bash
npm test
```

### 集成测试

```bash
npm run test:integration
```

### 测试覆盖率

```bash
npm run test:coverage
```

## 安全

### 安全措施

1. **输入验证**: 对所有输入参数进行验证
2. **SQL注入防护**: 使用参数化查询
3. **文件上传限制**: 
   - 限制文件大小（默认10MB）
   - 限制文件类型（仅允许.xlsx, .xls）
   - 验证文件内容
4. **CORS配置**: 限制允许的跨域源
5. **错误处理**: 不暴露敏感信息
6. **日志记录**: 记录关键操作和错误

### 安全建议

- 生产环境使用HTTPS
- 定期更新依赖包
- 设置适当的文件权限
- 配置防火墙规则
- 定期备份数据库

## 性能优化

### 优化策略

1. **数据库优化**
   - 创建适当的索引
   - 使用预编译语句
   - 定期执行 `VACUUM` 命令

2. **缓存策略**
   - 考虑使用Redis缓存热点数据
   - 缓存机房列表、筛选选项等静态数据

3. **查询优化**
   - 使用分页查询避免大量数据传输
   - 只查询必要的字段
   - 使用索引加速查询

4. **并发处理**
   - 使用连接池管理数据库连接
   - 考虑使用Worker Threads处理CPU密集型任务

### 性能指标

| 指标 | 目标值 |
|------|--------|
| API响应时间 | < 100ms |
| 数据库查询时间 | < 50ms |
| 文件上传处理 | 1000条/秒 |
| 并发请求数 | 100+ |

## 日志

### 日志级别

- **debug**: 调试信息
- **info**: 一般信息
- **warn**: 警告信息
- **error**: 错误信息

### 日志格式

```json
{
  "timestamp": "2024-01-01T00:00:00.000Z",
  "level": "info",
  "message": "请求处理成功",
  "method": "GET",
  "url": "/api/records/query",
  "status": 200,
  "duration": 50
}
```

## 部署

### Docker部署

创建 `Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3001

CMD ["npm", "start"]
```

构建和运行:

```bash
docker build -t wiring-backend .
docker run -p 3001:3001 -v $(pwd)/data:/app/data wiring-backend
```

### PM2部署

```bash
npm install -g pm2
pm2 start dist/server.js --name wiring-backend
pm2 save
pm2 startup
```

## 故障排查

### 常见问题

#### 1. 数据库连接失败

**症状**: 启动时报错 "Database connection failed"

**解决方案**:
- 检查 `DB_PATH` 环境变量配置
- 确保 `data` 目录存在且有写权限
- 检查SQLite文件是否损坏

#### 2. 文件上传失败

**症状**: 上传文件时报错 "File upload failed"

**解决方案**:
- 检查 `UPLOAD_DIR` 环境变量配置
- 确保 `uploads` 目录存在且有写权限
- 检查文件大小是否超过限制
- 验证文件格式是否正确

#### 3. CORS错误

**症状**: 浏览器控制台报错 "CORS policy"

**解决方案**:
- 检查 `CORS_ORIGIN` 环境变量配置
- 确保前端地址配置正确
- 检查防火墙设置

#### 4. 端口被占用

**症状**: 启动时报错 "Port already in use"

**解决方案**:
- 检查端口占用情况: `netstat -ano | findstr :3001`
- 修改 `PORT` 环境变量
- 终止占用端口的进程

### 日志查看

查看应用日志:

```bash
# 开发环境
npm run dev

# 生产环境（PM2）
pm2 logs wiring-backend

# Docker环境
docker logs <container-id>
```

## 开发指南

### 添加新的API接口

1. 在 `src/types/index.ts` 中定义类型
2. 在 `src/models/` 中创建数据模型
3. 在 `src/controllers/` 中创建控制器
4. 在 `src/routes/` 中添加路由
5. 在 `src/server.ts` 中注册路由

### 代码规范

- 使用 TypeScript 严格模式
- 遵循 ESLint 规则
- 使用 Prettier 格式化代码
- 编写单元测试
- 添加必要的注释

## 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](../../LICENSE) 文件

## 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue
- 发送邮件
- 加入讨论组

---

**综合布线记录管理系统后端** - 稳定、高效、安全

## Excel 文件格式

上传的 Excel 文件需要包含以下列（列名可以包含关键词）：

- 登记表编号（必填）
- 机房名称（必填）
- IDC需求编号
- YES工单编号
- 用户单位
- 线缆类型
- 运营商
- 线路编号
- 报障人/联系方式
- 起始端口（A端）
- 一跳
- 二跳
- 三跳
- 四跳
- 五跳
- 目标端口（Z端）
- 用户机柜
- 线路标签是否齐全（是/否）
- 线路是否规范（是/否）
- 备注
