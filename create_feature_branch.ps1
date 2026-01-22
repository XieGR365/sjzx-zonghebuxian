param(
    [Parameter(Mandatory=$true)]
    [string]$BranchName
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "创建新的功能分支" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$currentDate = Get-Date -Format "yyyyMMdd"
$currentBranch = git branch --show-current

Write-Host "当前分支: $currentBranch" -ForegroundColor Yellow
Write-Host "新分支名: $BranchName" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. 拉取最新代码..." -ForegroundColor Yellow
git pull origin main

Write-Host "2. 创建新分支: $BranchName..." -ForegroundColor Yellow
git checkout -b $BranchName

Write-Host "3. 推送新分支到远程..." -ForegroundColor Yellow
git push -u origin $BranchName

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "✅ 分支创建成功！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "现在你可以在分支 '$BranchName' 上进行修改了" -ForegroundColor Cyan
Write-Host "修改完成后，运行 .\create_pr.ps1 来创建Pull Request" -ForegroundColor Cyan
Write-Host ""
