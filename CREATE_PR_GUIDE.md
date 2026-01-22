# 🎯 创建Pull Request - 超详细图文指南

## 📌 当前状态

✅ 已完成的工作：
- 创建了功能分支：`add-pr-demo`
- 推送分支到GitHub
- 创建了示例文件：`PR_DEMO.md`
- 提交并推送到GitHub

⏳ 待完成的工作：
- 创建Pull Request
- 审核和合并PR

---

## 🚀 创建Pull Request - 详细步骤

### 第1步：打开创建PR的页面

**直接点击这个链接：**
```
https://github.com/XieGR365/sjzx-zonghebuxian/compare/main...add-pr-demo
```

或者手动访问：
1. 打开浏览器
2. 访问：https://github.com/XieGR365/sjzx-zonghebuxian
3. 点击页面顶部的 "Pull requests" 标签
4. 点击 "New pull request" 按钮

---

### 第2步：填写PR信息

你会看到一个页面，包含以下内容：

#### 📝 标题（Title）

在 "Title" 输入框中输入：
```
docs: 添加PR演示文档
```

**说明：**
- `docs:` 表示这是文档更新
- `添加PR演示文档` 是简短的描述

#### 📋 描述（Description）

在 "Leave a comment" 或 "Description" 文本框中输入以下内容：

```markdown
## 变更说明
- 创建PR_DEMO.md演示PR工作流程
- 展示完整的PR创建过程
- 为小白用户提供参考

## 测试情况
- [x] 文档测试通过

## 相关Issue
- 无
```

**如何输入：**
1. 复制上面的内容
2. 粘贴到描述框中
3. 确保格式正确（Markdown格式）

---

### 第3步：检查PR设置

在页面左侧，你会看到：

**Base repository:** `XieGR365/sjzx-zonghebuxian`
**Base:** `main` ← 这是目标分支

**Head repository:** `XieGR365/sjzx-zonghebuxian`
**Compare:** `add-pr-demo` ← 这是你的分支

✅ **确认设置正确！**

---

### 第4步：创建PR

点击页面右下角的绿色按钮：

```
Create pull request
```

---

### 第5步：PR创建成功！

创建后，你会看到：

1. **PR页面**：显示PR的详细信息
2. **状态**：显示为 "Open"
3. **文件变更**：可以查看修改了哪些文件
4. **讨论区**：可以添加评论

---

## 📊 PR页面说明

### 顶部信息

```
#1 docs: 添加PR演示文档
by XieGR365 刚刚
想要合并 1 次提交到 main
```

### 状态检查

如果有配置CI/CD，会显示：
- ✅ All checks have passed
- ⚠️ Some checks failed

### 文件变更

点击 "Files changed" 标签，可以看到：
- PR_DEMO.md（新增文件）
- 显示文件内容差异

### 讨论区

可以：
- 添加评论
- 回复其他人的评论
- 提及其他人（@username）

---

## 🎯 合并PR

### 方法1：通过GitHub网页合并

1. 在PR页面，滚动到底部
2. 点击绿色按钮：
   ```
   Merge pull request
   ```
3. 确认合并：
   ```
   Confirm merge
   ```
4. PR状态变为 "Merged"

### 方法2：通过命令行合并（需要权限）

```bash
git checkout main
git pull origin main
git merge add-pr-demo
git push origin main
```

---

## 🧹 合并后清理

### 切换回主分支

```powershell
git checkout main
```

### 拉取最新代码

```powershell
git pull origin main
```

### 删除本地分支

```powershell
git branch -d add-pr-demo
```

### 删除远程分支

```powershell
git push origin --delete add-pr-demo
```

---

## 📚 查看所有PR

访问：https://github.com/XieGR365/sjzx-zonghebuxian/pulls

可以看到：
- 所有Open的PR
- 所有Closed的PR
- 所有Merged的PR

---

## ❓ 常见问题

### Q1：找不到 "Create pull request" 按钮？

**A:** 确保你访问的是正确的URL：
```
https://github.com/XieGR365/sjzx-zonghebuxian/compare/main...add-pr-demo
```

### Q2：PR创建失败，提示冲突？

**A:** 说明main分支有新的提交，需要先同步：

```powershell
git checkout add-pr-demo
git merge main
# 解决冲突
git push
```

### Q3：如何修改已创建的PR？

**A:** 在同一分支上继续修改并推送，PR会自动更新：

```powershell
# 修改文件
git add .
git commit -m "更新内容"
git push
```

### Q4：如何关闭PR？

**A:** 在PR页面点击 "Close pull request" 按钮。

### Q5：如何重新打开已关闭的PR？

**A:** GitHub不支持重新打开，需要创建新的PR。

---

## 🎯 下一步

### 选项1：立即创建PR

1. 点击链接：https://github.com/XieGR365/sjzx-zonghebuxian/compare/main...add-pr-demo
2. 按照上面的步骤填写信息
3. 点击 "Create pull request"

### 选项2：先查看PR指南

打开 [GITHUB_PR_GUIDE.md](GITHUB_PR_GUIDE.md) 了解更多细节。

### 选项3：回到主分支

```powershell
git checkout main
git pull origin main
```

---

## 📞 需要帮助？

如果遇到问题，可以：

1. 查看GitHub官方文档：https://docs.github.com/en/pull-requests
2. 查看项目PR指南：[GITHUB_PR_GUIDE.md](GITHUB_PR_GUIDE.md)
3. 询问技术支持

---

**准备好了吗？点击链接创建你的第一个PR吧！** 🚀

```
https://github.com/XieGR365/sjzx-zonghebuxian/compare/main...add-pr-demo
```
