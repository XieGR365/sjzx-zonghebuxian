@echo off
chcp 65001 >nul
cls
echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                                                                ║
echo ║     综合布线记录管理系统 - 远程部署助手（小白专用版）        ║
echo ║                                                                ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo 服务器信息:
echo   地址: 192.168.19.58
echo   用户名: yroot
echo   密码: Yovole@2026
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
echo 本脚本将引导你完成以下步骤:
echo.
echo   步骤1: 创建远程目录
echo   步骤2: 上传项目文件
echo   步骤3: 设置执行权限
echo   步骤4: 执行自动部署
echo   步骤5: 验证部署结果
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
echo 注意事项:
echo   - 每次执行SSH或SCP命令时，都需要输入密码
echo   - 密码是: Yovole@2026
echo   - 输入密码时屏幕上不会显示任何字符（这是正常的）
echo   - 输入完密码后按回车键
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
pause

cls
echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                    步骤1: 创建远程目录                      ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo 正在执行命令: ssh yroot@192.168.19.58 "mkdir -p /opt/sjzx-zonghebuxian"
echo.
echo 请输入密码: Yovole@2026
echo.
ssh yroot@192.168.19.58 "mkdir -p /opt/sjzx-zonghebuxian"
echo.
if %errorlevel% equ 0 (
    echo ✓ 远程目录创建成功！
) else (
    echo ✗ 远程目录创建失败，请检查密码是否正确
    pause
    exit /b 1
)
echo.
pause

cls
echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                    步骤2: 上传项目文件                      ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo 共需要上传6个文件/目录，每次都需要输入密码
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

echo [1/6] 正在上传 backend/ 目录...
echo.
echo 请输入密码: Yovole@2026
echo.
scp -r "D:\TREA\sjzx-zonghebuxian\backend" yroot@192.168.19.58:/opt/sjzx-zonghebuxian/
if %errorlevel% equ 0 (
    echo ✓ backend/ 上传成功！
) else (
    echo ✗ backend/ 上传失败
    pause
    exit /b 1
)
echo.
pause

echo [2/6] 正在上传 frontend/ 目录...
echo.
echo 请输入密码: Yovole@2026
echo.
scp -r "D:\TREA\sjzx-zonghebuxian\frontend" yroot@192.168.19.58:/opt/sjzx-zonghebuxian/
if %errorlevel% equ 0 (
    echo ✓ frontend/ 上传成功！
) else (
    echo ✗ frontend/ 上传失败
    pause
    exit /b 1
)
echo.
pause

echo [3/6] 正在上传 config/ 目录...
echo.
echo 请输入密码: Yovole@2026
echo.
scp -r "D:\TREA\sjzx-zonghebuxian\config" yroot@192.168.19.58:/opt/sjzx-zonghebuxian/
if %errorlevel% equ 0 (
    echo ✓ config/ 上传成功！
) else (
    echo ✗ config/ 上传失败
    pause
    exit /b 1
)
echo.
pause

echo [4/6] 正在上传 deploy_自动部署.sh...
echo.
echo 请输入密码: Yovole@2026
echo.
scp "D:\TREA\sjzx-zonghebuxian\deploy_自动部署.sh" yroot@192.168.19.58:/opt/sjzx-zonghebuxian/
if %errorlevel% equ 0 (
    echo ✓ deploy_自动部署.sh 上传成功！
) else (
    echo ✗ deploy_自动部署.sh 上传失败
    pause
    exit /b 1
)
echo.
pause

echo [5/6] 正在上传 deploy_服务器使用说明.md...
echo.
echo 请输入密码: Yovole@2026
echo.
scp "D:\TREA\sjzx-zonghebuxian\deploy_服务器使用说明.md" yroot@192.168.19.58:/opt/sjzx-zonghebuxian/
if %errorlevel% equ 0 (
    echo ✓ deploy_服务器使用说明.md 上传成功！
) else (
    echo ✗ deploy_服务器使用说明.md 上传失败
    pause
    exit /b 1
)
echo.
pause

echo [6/6] 正在上传 deploy_部署技术细节.md...
echo.
echo 请输入密码: Yovole@2026
echo.
scp "D:\TREA\sjzx-zonghebuxian\deploy_部署技术细节.md" yroot@192.168.19.58:/opt/sjzx-zonghebuxian/
if %errorlevel% equ 0 (
    echo ✓ deploy_部署技术细节.md 上传成功！
) else (
    echo ✗ deploy_部署技术细节.md 上传失败
    pause
    exit /b 1
)
echo.
pause

cls
echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                  步骤3: 设置执行权限                      ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo 正在执行命令: ssh yroot@192.168.19.58 "chmod +x /opt/sjzx-zonghebuxian/deploy_自动部署.sh"
echo.
echo 请输入密码: Yovole@2026
echo.
ssh yroot@192.168.19.58 "chmod +x /opt/sjzx-zonghebuxian/deploy_自动部署.sh"
echo.
if %errorlevel% equ 0 (
    echo ✓ 执行权限设置成功！
) else (
    echo ✗ 执行权限设置失败
    pause
    exit /b 1
)
echo.
pause

cls
echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                  步骤4: 执行自动部署                        ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo 现在需要SSH登录到服务器，然后执行自动部署脚本
echo.
echo 请按照以下步骤操作:
echo.
echo   1. 输入以下命令登录服务器:
echo      ssh yroot@192.168.19.58
echo.
echo   2. 输入密码: Yovole@2026
echo.
echo   3. 进入项目目录:
echo      cd /opt/sjzx-zonghebuxian
echo.
echo   4. 执行自动部署脚本:
echo      ./deploy_自动部署.sh
echo.
echo   5. 等待部署完成（可能需要10-20分钟）
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
echo 现在是否要自动执行这些命令？
echo.
echo   [Y] 是，自动执行
echo   [N] 否，我自己手动执行
echo.
set /p choice="请选择 (Y/N): "
if /i "%choice%"=="Y" (
    echo.
    echo 正在自动执行...
    echo.
    echo 请输入密码: Yovole@2026
    echo.
    ssh yroot@192.168.19.58 "cd /opt/sjzx-zonghebuxian && ./deploy_自动部署.sh"
) else (
    echo.
    echo 好的，请手动执行上述命令
    echo.
    pause
    exit /b 0
)
echo.
pause

cls
echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                  步骤5: 验证部署结果                        ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo 部署完成！现在需要验证部署结果
echo.
echo 请按照以下步骤操作:
echo.
echo   1. 检查容器状态:
echo      docker ps
echo.
echo   2. 查看服务日志:
echo      docker logs wiring-backend
echo      docker logs wiring-frontend
echo.
echo   3. 测试后端API:
echo      curl http://localhost:3001/health
echo.
echo   4. 在浏览器中访问:
echo      http://192.168.19.58
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
echo 是否要自动执行验证命令？
echo.
echo   [Y] 是，自动执行
echo   [N] 否，我自己手动验证
echo.
set /p choice="请选择 (Y/N): "
if /i "%choice%"=="Y" (
    echo.
    echo 正在自动验证...
    echo.
    echo 请输入密码: Yovole@2026
    echo.
    ssh yroot@192.168.19.58 "docker ps && echo '' && echo 后端日志: && docker logs --tail 20 wiring-backend && echo '' && echo 前端日志: && docker logs --tail 20 wiring-frontend && echo '' && echo 测试后端API: && curl http://localhost:3001/health"
) else (
    echo.
    echo 好的，请手动执行上述验证命令
)
echo.
pause

cls
echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                    部署完成！                                  ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
echo 🎉 恭喜！部署已完成！
echo.
echo 现在你可以通过浏览器访问系统:
echo.
echo   http://192.168.19.58
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
echo 常用命令:
echo.
echo   查看服务状态:
echo     ssh yroot@192.168.19.58 "cd /opt/sjzx-zonghebuxian && docker-compose ps"
echo.
echo   重启服务:
echo     ssh yroot@192.168.19.58 "cd /opt/sjzx-zonghebuxian && docker-compose restart"
echo.
echo   停止服务:
echo     ssh yroot@192.168.19.58 "cd /opt/sjzx-zonghebuxian && docker-compose down"
echo.
echo   查看日志:
echo     ssh yroot@192.168.19.58 "cd /opt/sjzx-zonghebuxian && docker-compose logs -f"
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
echo 相关文档:
echo.
echo   - deploy_远程部署完整指南.md
echo   - deploy_服务器使用说明.md
echo   - deploy_部署技术细节.md
echo   - 04-实施/实施文档.md
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
echo 如果遇到问题，请查看相关文档或联系技术支持
echo.
pause
