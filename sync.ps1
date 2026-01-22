Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "同步代码到GitHub" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. 添加所有更改..." -ForegroundColor Yellow
git add -A

Write-Host "2. 提交更改..." -ForegroundColor Yellow
$commitMsg = Read-Host "请输入提交信息 (默认: Auto sync)"
if ([string]::IsNullOrEmpty($commitMsg)) {
    $commitMsg = "Auto sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}
git commit -m $commitMsg

Write-Host "3. 推送到GitHub..." -ForegroundColor Yellow
git push

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "同步完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
