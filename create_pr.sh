#!/bin/bash

echo "=========================================="
echo "创建Pull Request指南"
echo "=========================================="
echo ""

CURRENT_BRANCH=$(git branch --show-current)
MAIN_BRANCH="main"

echo "当前分支: $CURRENT_BRANCH"
echo "目标分支: $MAIN_BRANCH"
echo ""

if [ "$CURRENT_BRANCH" = "$MAIN_BRANCH" ]; then
    echo "❌ 错误: 不能在主分支上创建Pull Request"
    echo "请先创建一个功能分支:"
    echo "  ./create_feature_branch.sh <分支名称>"
    echo ""
    exit 1
fi

echo "1. 检查是否有未提交的更改..."
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  警告: 有未提交的更改"
    echo "请先提交更改:"
    echo "  git add -A"
    echo "  git commit -m '你的提交信息'"
    echo "  git push"
    echo ""
    read -p "是否继续? (y/n): " continue
    if [ "$continue" != "y" ]; then
        exit 1
    fi
fi

echo "2. 检查分支是否已推送..."
if ! git ls-remote --heads origin $CURRENT_BRANCH | grep -q $CURRENT_BRANCH; then
    echo "⚠️  警告: 分支未推送到远程"
    echo "正在推送..."
    git push -u origin $CURRENT_BRANCH
fi

echo ""
echo "=========================================="
echo "✅ 准备创建Pull Request"
echo "=========================================="
echo ""
echo "请访问以下链接创建Pull Request:"
echo ""
echo "🔗 https://github.com/XieGR365/sjzx-zonghebuxian/compare/main...$CURRENT_BRANCH"
echo ""
echo "或者使用以下命令（如果安装了gh CLI）:"
echo "  gh pr create --base main --head $CURRENT_BRANCH --title '你的PR标题' --body '你的PR描述'"
echo ""
echo "=========================================="
echo "Pull Request创建指南"
echo "=========================================="
echo ""
echo "📝 PR标题示例:"
echo "  - feat: 添加用户登录功能"
echo "  - fix: 修复数据导出bug"
echo "  - docs: 更新部署文档"
echo "  - refactor: 优化数据库查询"
echo ""
echo "📋 PR描述模板:"
echo "  ## 变更说明"
echo "  - 变更1"
echo "  - 变更2"
echo ""
echo "  ## 测试情况"
echo "  - [x] 功能测试通过"
echo "  - [x] 回归测试通过"
echo ""
echo "  ## 相关Issue"
echo "  - 关联 #123"
echo ""
echo "=========================================="
