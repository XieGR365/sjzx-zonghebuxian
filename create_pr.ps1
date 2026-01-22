Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "创建Pull Request指南" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$currentBranch = git branch --show-current
$mainBranch = "main"

Write-Host "当前分支: $currentBranch" -ForegroundColor Yellow
Write-Host "目标分支: $mainBranch" -ForegroundColor Yellow
Write-Host ""

if ($currentBranch -eq $mainBranch) {
    Write-Host "❌ 错误: 不能在主分支上创建Pull Request" -ForegroundColor Red
    Write-Host "请先创建一个功能分支:" -ForegroundColor Yellow
    Write-Host "  .\create_feature_branch.ps1 <分支名称>" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "1. 检查是否有未提交的更改..." -ForegroundColor Yellow
$status = git status --porcelain
if ($status) {
    Write-Host "⚠️  警告: 有未提交的更改" -ForegroundColor Yellow
    Write-Host "请先提交更改:" -ForegroundColor Cyan
    Write-Host "  git add -A" -ForegroundColor White
    Write-Host "  git commit -m '你的提交信息'" -ForegroundColor White
    Write-Host "  git push" -ForegroundColor White
    Write-Host ""
    $continue = Read-Host "是否继续? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

Write-Host "2. 检查分支是否已推送..." -ForegroundColor Yellow
$remoteBranches = git ls-remote --heads origin $currentBranch
if (-not $remoteBranches) {
    Write-Host "⚠️  警告: 分支未推送到远程" -ForegroundColor Yellow
    Write-Host "正在推送..." -ForegroundColor Cyan
    git push -u origin $currentBranch
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "✅ 准备创建Pull Request" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "请访问以下链接创建Pull Request:" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔗 https://github.com/XieGR365/sjzx-zonghebuxian/compare/main...$currentBranch" -ForegroundColor Yellow
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Pull Request创建指南" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 PR标题示例:" -ForegroundColor Yellow
Write-Host "  - feat: 添加用户登录功能" -ForegroundColor White
Write-Host "  - fix: 修复数据导出bug" -ForegroundColor White
Write-Host "  - docs: 更新部署文档" -ForegroundColor White
Write-Host "  - refactor: 优化数据库查询" -ForegroundColor White
Write-Host ""
Write-Host "📋 PR描述模板:" -ForegroundColor Yellow
Write-Host "  ## 变更说明" -ForegroundColor White
Write-Host "  - 变更1" -ForegroundColor White
Write-Host "  - 变更2" -ForegroundColor White
Write-Host ""
Write-Host "  ## 测试情况" -ForegroundColor White
Write-Host "  - [x] 功能测试通过" -ForegroundColor White
Write-Host "  - [x] 回归测试通过" -ForegroundColor White
Write-Host ""
Write-Host "  ## 相关Issue" -ForegroundColor White
Write-Host "  - 关联 #123" -ForegroundColor White
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
