#!/bin/bash

echo "=========================================="
echo "同步代码到GitHub"
echo "=========================================="
echo ""

echo "1. 添加所有更改..."
git add -A

echo "2. 提交更改..."
read -p "请输入提交信息 (默认: Auto sync): " commit_msg
commit_msg=${commit_msg:-"Auto sync: $(date '+%Y-%m-%d %H:%M:%S')"}
git commit -m "$commit_msg"

echo "3. 推送到GitHub..."
git push

echo ""
echo "=========================================="
echo "同步完成！"
echo "=========================================="
