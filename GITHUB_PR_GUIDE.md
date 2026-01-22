# GitHub Pull Requests 使用指南

## 📚 什么是Pull Request（PR）？

Pull Request（简称PR）是GitHub提供的代码审核和协作功能。简单来说：

**PR就像是一个"代码审核流程"：**

1. **你在新分支上修改代码** - 不影响主代码
2. **创建Pull Request** - 告诉别人你想合并代码
3. **审核和测试** - 其他人可以查看、测试你的代码
4. **合并到主分支** - 确认无误后合并

## ✅ 使用PR的好处

- ✅ **保护主代码** - 不会被破坏性修改影响
- ✅ **版本回退** - 可以随时回退到之前的版本
- ✅ **团队协作** - 方便多人协作开发
- ✅ **代码审查** - 其他人可以审查你的代码
- ✅ **完整记录** - 有完整的修改历史和讨论记录

## 🚀 快速开始

### 步骤1：创建功能分支

**Windows系统：**
```powershell
.\create_feature_branch.ps1 fix-login-bug
```

**Linux/Mac系统：**
```bash
chmod +x create_feature_branch.sh
./create_feature_branch.sh fix-login-bug
```

这个命令会：
1. 拉取最新的main分支代码
2. 创建新分支 `fix-login-bug`
3. 推送新分支到GitHub

### 步骤2：在新分支上修改代码

现在你可以在新分支上自由修改代码了，不会影响主分支。

修改完成后，提交代码：
```powershell
# Windows
.\sync.ps1

# Linux/Mac
./sync.sh
```

### 步骤3：创建Pull Request

**Windows系统：**
```powershell
.\create_pr.ps1
```

**Linux/Mac系统：**
```bash
chmod +x create_pr.sh
./create_pr.sh
```

这个命令会：
1. 检查当前分支
2. 检查是否有未提交的更改
3. 提供创建PR的链接
4. 显示PR标题和描述模板

### 步骤4：在GitHub上完成PR创建

脚本会提供一个链接，点击链接即可创建PR：
```
https://github.com/XieGR365/sjzx-zonghebuxian/compare/main...fix-login-bug
```

填写PR信息：
- **标题**：使用清晰的描述
- **描述**：说明修改内容和测试情况

点击"Create pull request"按钮。

### 步骤5：审核和合并

1. **自动检查**：GitHub会自动运行测试（如果配置了）
2. **代码审查**：你可以邀请其他人审查代码
3. **讨论**：在PR中讨论代码问题
4. **合并**：确认无误后点击"Merge pull request"

## 📝 PR标题规范

使用以下前缀让PR更清晰：

| 前缀 | 用途 | 示例 |
|--------|------|--------|
| `feat:` | 新功能 | `feat: 添加用户登录功能` |
| `fix:` | 修复bug | `fix: 修复数据导出bug` |
| `docs:` | 文档更新 | `docs: 更新部署文档` |
| `refactor:` | 代码重构 | `refactor: 优化数据库查询` |
| `test:` | 测试相关 | `test: 添加单元测试` |
| `chore:` | 构建/工具 | `chore: 更新依赖包` |
| `style:` | 代码格式 | `style: 统一代码风格` |
| `perf:` | 性能优化 | `perf: 优化查询性能` |

## 📋 PR描述模板

```markdown
## 变更说明
- 添加了用户登录功能
- 修复了数据导出时的格式问题
- 优化了数据库查询性能

## 测试情况
- [x] 功能测试通过
- [x] 回归测试通过
- [x] 代码审查通过

## 相关Issue
- 关联 #123

## 截图/演示
（如果有界面变更，可以添加截图或GIF）

## 注意事项
- 需要更新API文档
- 需要通知运维团队
```

## 🔧 常用命令

### 查看所有分支
```bash
git branch -a
```

### 切换分支
```bash
git checkout <分支名>
```

### 查看PR状态
访问：https://github.com/XieGR365/sjzx-zonghebuxian/pulls

### 合并PR后更新本地
```bash
git checkout main
git pull origin main
git branch -d <已合并的分支>
```

## ⚠️ 注意事项

1. **不要在main分支上直接修改**
   - 始终在功能分支上工作
   - 通过PR合并到main

2. **保持分支简洁**
   - 一个分支只做一个功能
   - 避免在一个PR中包含太多修改

3. **及时更新分支**
   - 如果main有更新，及时合并到你的分支
   ```bash
   git checkout <你的分支>
   git merge main
   ```

4. **写好PR描述**
   - 清晰说明变更内容
   - 列出测试情况
   - 关联相关Issue

5. **响应审查意见**
   - 及时回复审查意见
   - 根据意见修改代码
   - 修改后更新PR

## 🎯 工作流程示例

```
1. 创建分支
   ./create_feature_branch.sh add-user-profile

2. 修改代码
   (编辑文件...)

3. 提交代码
   ./sync.sh

4. 创建PR
   ./create_pr.sh

5. 在GitHub上审核
   (访问链接，填写PR信息)

6. 合并PR
   (在GitHub上点击Merge)

7. 更新本地
   git checkout main
   git pull origin main
   git branch -d add-user-profile
```

## 📚 相关资源

- [GitHub官方PR文档](https://docs.github.com/en/pull-requests)
- [PR最佳实践](https://github.com/features/project-management/#best-practices-for-pull-requests)
- [Conventional Commits](https://www.conventionalcommits.org/)

## ❓ 常见问题

### Q: PR创建失败怎么办？
A: 检查以下几点：
- 分支是否已推送到远程
- 是否有未提交的更改
- 是否在main分支上（不能在main上创建PR）

### Q: 如何修改已创建的PR？
A: 在同一分支上继续修改并推送，PR会自动更新。

### Q: 如何关闭PR？
A: 在GitHub PR页面点击"Close pull request"按钮。

### Q: PR冲突了怎么办？
A:
```bash
git checkout main
git pull origin main
git checkout <你的分支>
git merge main
# 解决冲突
git push
```

---

**现在就开始使用PR吧！** 🚀
