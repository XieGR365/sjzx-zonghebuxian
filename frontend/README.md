# 综合布线记录管理系统 - 前端

> 基于 Vue 3 + TypeScript + Element Plus 的综合布线记录管理系统前端应用

[![Vue Version](https://img.shields.io/badge/Vue-3.x-42b883)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue)](https://www.typescriptlang.org/)
[![Element Plus](https://img.shields.io/badge/Element%20Plus-2.x-409eff)](https://element-plus.org/)
[![Vite](https://img.shields.io/badge/Vite-5.x-646cff)](https://vitejs.dev/)

## 项目简介

前端应用提供现代化的用户界面，支持Excel文件上传、多条件查询、记录详情查看等核心功能。采用Vue 3 Composition API开发，配合TypeScript确保类型安全，使用Element Plus提供丰富的UI组件。

## 技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| **Vue** | 3.x | 渐进式JavaScript框架，采用Composition API |
| **TypeScript** | 5.x | 类型安全的JavaScript超集 |
| **Element Plus** | 2.x | 基于Vue 3的组件库，提供丰富的UI组件 |
| **Vue Router** | 4.x | 官方路由管理器 |
| **Axios** | 1.x | HTTP客户端，用于API请求 |
| **Vite** | 5.x | 下一代前端构建工具，提供快速的开发体验 |
| **Pinia** | 2.x | 状态管理库（可选） |

## 项目结构

```
frontend/
├── src/
│   ├── assets/               # 静态资源（图片、样式等）
│   ├── components/           # 可复用组件
│   │   ├── Header.vue        # 头部组件
│   │   ├── Footer.vue        # 底部组件
│   │   └── ...
│   ├── router/               # 路由配置
│   │   └── index.ts          # 路由定义和导航守卫
│   ├── services/             # API服务
│   │   └── api.ts            # API封装和请求拦截器
│   ├── stores/                # 状态管理（可选）
│   │   └── index.ts          # 全局状态
│   ├── types/                # TypeScript类型定义
│   │   └── index.ts          # 共享类型定义
│   ├── utils/                # 工具函数
│   │   ├── request.ts        # 请求工具
│   │   └── format.ts         # 格式化工具
│   ├── views/                # 页面组件
│   │   ├── UploadView.vue        # 上传页面
│   │   ├── RecordsView.vue       # 记录列表页面
│   │   └── RecordDetailView.vue  # 记录详情页面
│   ├── App.vue               # 根组件
│   └── main.ts               # 应用入口
├── public/                   # 公共静态资源
├── index.html                # HTML入口
├── package.json              # 依赖配置
├── tsconfig.json             # TypeScript配置
├── vite.config.ts            # Vite构建配置
└── .env                      # 环境变量配置
```

## 架构设计

### 组件架构

```
┌─────────────────────────────────┐
│           App.vue               │  根组件
├─────────────────────────────────┤
│         Views Layer             │  页面层 - 业务页面
├─────────────────────────────────┤
│       Components Layer          │  组件层 - 可复用组件
├─────────────────────────────────┤
│        Services Layer           │  服务层 - API调用
├─────────────────────────────────┤
│         Utils Layer             │  工具层 - 工具函数
└─────────────────────────────────┘
```

### 设计原则

- **组件化**: 将UI拆分为可复用的组件
- **单向数据流**: 数据从父组件流向子组件
- **响应式**: 利用Vue 3的响应式系统
- **类型安全**: 使用TypeScript确保类型安全
- **性能优化**: 按需加载、懒加载、虚拟滚动

## 环境要求

- **Node.js**: 18.0.0 或更高版本
- **npm**: 9.0.0 或更高版本（随Node.js安装）
- **浏览器**: Chrome 90+ / Firefox 88+ / Safari 14+ / Edge 90+

## 安装依赖

```bash
cd frontend
npm install
```

## 环境配置

编辑 `.env` 文件：

```env
# API基础URL
VITE_API_BASE_URL=http://localhost:3001

# 应用标题
VITE_APP_TITLE=综合布线记录管理系统

# 上传文件大小限制（MB）
VITE_MAX_FILE_SIZE=10
```

## 启动开发服务器

```bash
npm run dev
```

应用将在 `http://localhost:5173` 启动。

## 构建生产版本

```bash
npm run build
```

构建产物将输出到 `dist` 目录。

## 预览生产版本

```bash
npm run preview
```

## 功能特性

### 1. 上传页面 (UploadView)

**功能描述**: 支持拖拽上传Excel文件，自动解析并导入数据

**主要功能**:
- 拖拽上传 Excel 文件
- 支持 .xlsx 和 .xls 格式
- 文件大小限制 10MB
- 实时显示上传进度
- 上传成功后显示导入记录数
- 错误提示和友好反馈

**技术实现**:
- 使用 Element Plus 的 Upload 组件
- Axios 拦截器处理请求和响应
- 进度条显示上传进度

### 2. 布线记录列表页面 (RecordsView)

**功能描述**: 提供多条件组合查询，支持分页显示和记录详情查看

**主要功能**:
- 多条件组合查询
  - 机房名称（下拉选择）
  - 登记表编号（模糊查询）
  - 线路编号（模糊查询）
  - 起始端口（模糊查询）
  - 目标端口（模糊查询）
  - 用户机柜（模糊查询）
  - 运营商（下拉选择）
  - 线缆类型（下拉选择）
  - IDC需求编号（模糊查询）
  - YES工单编号（模糊查询）
- 分页显示（支持自定义每页数量）
- 点击行查看详情
- 清空所有数据功能（需二次确认）
- 加载状态提示
- 空状态提示

**技术实现**:
- 使用 Element Plus 的 Table 组件
- 响应式查询参数管理
- 防抖处理搜索请求
- 虚拟滚动优化大数据量

### 3. 记录详情页面 (RecordDetailView)

**功能描述**: 展示完整的布线记录信息，包括端口路径可视化

**主要功能**:
- 完整的记录信息展示
- 端口路径可视化（起始端口 → 跳接点 → 目标端口）
- 标签齐全、线路规范状态显示（带颜色标识）
- 时间信息展示（创建时间、更新时间）
- 返回列表功能

**技术实现**:
- 使用 Element Plus 的 Descriptions 组件
- 动态渲染端口路径
- 状态标签使用不同颜色

## 路由配置

| 路径 | 组件 | 说明 | 权限 |
|------|------|------|------|
| `/` | - | 重定向到 /upload | 公开 |
| `/upload` | UploadView | 上传文件页面 | 公开 |
| `/records` | RecordsView | 布线记录列表页面 | 公开 |
| `/records/:id` | RecordDetailView | 记录详情页面 | 公开 |

### 路由守卫

- 全局前置守卫：检查用户权限（如需要）
- 全局后置守卫：记录页面访问日志

## API 服务

### API 基础配置

```typescript
// src/services/api.ts
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})
```

### 请求拦截器

```typescript
api.interceptors.request.use(
  config => {
    // 添加请求头
    config.headers['Authorization'] = `Bearer ${token}`
    return config
  },
  error => {
    return Promise.reject(error)
  }
)
```

### 响应拦截器

```typescript
api.interceptors.response.use(
  response => {
    const { data } = response
    if (data.success) {
      return data
    } else {
      ElMessage.error(data.message || '请求失败')
      return Promise.reject(new Error(data.message))
    }
  },
  error => {
    ElMessage.error(error.message || '网络错误')
    return Promise.reject(error)
  }
)
```

### API 方法

| 方法 | 说明 | 参数 | 返回值 |
|------|------|------|--------|
| `uploadFile(file)` | 上传Excel文件 | File | Promise<UploadResult> |
| `queryRecords(params)` | 查询记录列表 | QueryParams | Promise<QueryResult> |
| `getRecordDetail(id)` | 获取记录详情 | number | Promise<Record> |
| `getDatacenters()` | 获取机房列表 | - | Promise<string[]> |
| `getFilterOptions()` | 获取筛选选项 | - | Promise<FilterOptions> |
| `clearAllData()` | 清空所有数据 | - | Promise<ClearResult> |

## 组件说明

### 公共组件

#### Header.vue
- 应用标题显示
- 导航菜单
- 用户信息（如需要）

#### Footer.vue
- 版权信息
- 联系方式
- 友情链接

### 页面组件

#### UploadView.vue
- 文件上传区域
- 上传进度显示
- 上传结果提示

#### RecordsView.vue
- 查询表单
- 记录列表表格
- 分页组件
- 操作按钮

#### RecordDetailView.vue
- 记录详情展示
- 端口路径可视化
- 返回按钮

## 设计特点

### UI设计

- **现代化界面**: 采用渐变色背景、卡片式布局，提供优秀的视觉体验
- **响应式设计**: 适配不同屏幕尺寸，支持桌面端和移动端
- **丰富的交互**: 悬停效果、过渡动画，提升用户体验
- **清晰的视觉层次**: 信息分层展示，重要信息一目了然
- **用户友好**: 直观的操作流程，降低学习成本

### 性能优化

- **按需加载**: 路由懒加载，减少首屏加载时间
- **组件懒加载**: 使用 `defineAsyncComponent` 按需加载组件
- **虚拟滚动**: 大数据量表格使用虚拟滚动
- **防抖节流**: 搜索输入使用防抖，减少不必要的请求
- **缓存策略**: 合理使用缓存，减少重复请求

### 代码质量

- **TypeScript**: 全面的类型定义，减少运行时错误
- **ESLint**: 代码检查，确保代码质量
- **Prettier**: 代码格式化，保持代码风格一致
- **组件封装**: 可复用的组件封装，提高代码复用率

## 状态管理

### 状态结构

```typescript
interface AppState {
  user: User | null
  loading: boolean
  datacenters: string[]
  filterOptions: FilterOptions
}
```

### 状态管理方案

- 使用 Pinia 进行全局状态管理
- 模块化状态，按功能划分
- 持久化关键状态（如用户信息）

## 样式方案

### CSS架构

- **CSS Modules**: 组件级样式隔离
- **SCSS**: 预处理器，支持嵌套、变量、混合等
- **主题定制**: 通过 CSS 变量实现主题切换

### 样式规范

- 使用 BEM 命名规范
- 统一的颜色、字体、间距变量
- 响应式断点统一管理

## 测试

### 单元测试

```bash
npm run test:unit
```

### 组件测试

```bash
npm run test:component
```

### E2E测试

```bash
npm run test:e2e
```

## 部署

### 静态部署

将 `dist` 目录部署到 Web 服务器（如 Nginx、Apache 等）。

### Nginx配置示例

```nginx
server {
  listen 80;
  server_name example.com;

  root /var/www/wiring-frontend/dist;
  index index.html;

  location / {
    try_files $uri $uri/ /index.html;
  }

  location /api {
    proxy_pass http://localhost:3001;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

### Docker部署

创建 `Dockerfile`:

```dockerfile
FROM node:18-alpine as builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

构建和运行:

```bash
docker build -t wiring-frontend .
docker run -p 80:80 wiring-frontend
```

## 开发指南

### 添加新页面

1. 在 `src/views/` 中创建页面组件
2. 在 `src/router/index.ts` 中添加路由配置
3. 在导航菜单中添加入口

### 添加新组件

1. 在 `src/components/` 中创建组件
2. 编写组件的 TypeScript 类型
3. 编写组件的样式
4. 在需要的页面中引入使用

### 添加新的API方法

1. 在 `src/types/index.ts` 中定义类型
2. 在 `src/services/api.ts` 中添加API方法
3. 在页面中调用API方法

### 代码规范

- 使用 TypeScript 严格模式
- 遵循 ESLint 规则
- 使用 Prettier 格式化代码
- 组件命名采用 PascalCase
- 文件命名采用 kebab-case
- 编写必要的注释

## 常见问题

### 1. 跨域问题

**症状**: 开发环境下请求API时报错跨域

**解决方案**:
- 检查 `vite.config.ts` 中的代理配置
- 确保后端服务已启动
- 检查后端 CORS 配置

### 2. 样式不生效

**症状**: 修改样式后没有生效

**解决方案**:
- 检查样式文件是否正确引入
- 清除浏览器缓存
- 检查 CSS Modules 的类名是否正确
- 检查样式优先级

### 3. 类型错误

**症状**: TypeScript 报类型错误

**解决方案**:
- 检查类型定义是否正确
- 使用 `as` 类型断言（谨慎使用）
- 检查类型导入是否正确
- 运行 `npm run type-check` 检查类型

### 4. 构建失败

**症状**: 运行 `npm run build` 失败

**解决方案**:
- 检查依赖是否完整安装
- 检查 TypeScript 配置
- 检查代码语法错误
- 查看详细的错误信息

## 性能指标

| 指标 | 目标值 |
|------|--------|
| 首屏加载时间 | < 2s |
| 页面切换时间 | < 500ms |
| API响应时间 | < 100ms |
| 构建时间 | < 30s |
| 包大小 | < 500KB (gzip) |

## 浏览器兼容性

| 浏览器 | 版本 |
|--------|------|
| Chrome | 90+ |
| Firefox | 88+ |
| Safari | 14+ |
| Edge | 90+ |

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

**综合布线记录管理系统前端** - 现代化、高性能、易维护