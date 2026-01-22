#!/bin/bash

echo "=========================================="
echo "创建新的功能分支"
echo "=========================================="
echo ""

if [ -z "$1" ]; then
    echo "用法: ./create_feature_branch.sh <分支名称>"
    echo "示例: ./create_feature_branch.sh fix-login-bug"
    echo ""
    exit 1
fi

BRANCH_NAME=$1
CURRENT_DATE=$(date +%Y%m%d)

echo "当前分支: $(git branch --show-current)"
echo "新分支名: $BRANCH_NAME"
echo ""

echo "1. 拉取最新代码..."
git pull origin main

echo "2. 创建新分支: $BRANCH_NAME..."
git checkout -b $BRANCH_NAME

echo "3. 推送新分支到远程..."
git push -u origin $BRANCH_NAME

echo ""
echo "=========================================="
echo "✅ 分支创建成功！"
echo "=========================================="
echo ""
echo "现在你可以在分支 '$BRANCH_NAME' 上进行修改了"
echo "修改完成后，运行 ./create_pr.sh 来创建Pull Request"
echo ""
