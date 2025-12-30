# HTTPS配置文档

## 1. HTTPS概述

### 1.1 为什么需要HTTPS
- 数据传输加密，防止中间人攻击
- 提升用户信任度
- 满足安全合规要求
- 支持现代浏览器特性

### 1.2 SSL证书选择
- **Let's Encrypt**: 免费SSL证书，自动续期
- **有效期**: 90天，可自动续期
- **适用场景**: 公网IP或域名访问

## 2. 准备工作

### 2.1 前置条件
- 公网IP或域名
- 80端口可访问（用于证书验证）
- 管理员权限

### 2.2 确认域名解析
如果有域名，确保DNS解析正确:
```powershell
# 测试域名解析
nslookup your-domain.com
```

### 2.3 确认防火墙配置
确保80和443端口已开放:
```powershell
Get-NetFirewallRule -DisplayName "HTTP"
Get-NetFirewallRule -DisplayName "HTTPS"
```

## 3. 使用Let's Encrypt获取SSL证书

### 3.1 安装Win-ACME
Win-ACME是Windows平台上的Let's Encrypt客户端。

#### 3.1.1 下载Win-ACME
访问: https://www.win-acme.com/

下载最新版本的Win-ACME (zip文件)。

#### 3.1.2 解压并安装
```powershell
# 创建目录
New-Item -ItemType Directory -Path "D:\wiring-record-system\ssl\win-acme" -Force

# 解压到该目录
# (手动解压下载的zip文件到该目录)
```

### 3.2 生成SSL证书

#### 3.2.1 运行Win-ACME
```powershell
cd D:\wiring-record-system\ssl\win-acme
.\wacs.exe
```

#### 3.2.2 按照向导操作
1. 选择 `N` - 创建新的证书
2. 选择 `1` - 单个域名
3. 输入域名（如: `your-domain.com` 或 `your-ip.duckdns.org`）
4. 选择 `2` - 使用HTTP验证
5. 选择 `1` - 自动创建IIS站点
6. 选择 `1` - 创建证书
7. 选择 `1` - 不创建计划任务（稍后手动配置）
8. 选择 `1` - 不创建FTP用户

证书生成后，会保存在 `D:\wiring-record-system\ssl\win-acme` 目录。

### 3.3 配置自动续期

#### 3.3.1 创建续期脚本
创建 `renew-certificate.ps1`:

```powershell
$wacsPath = "D:\wiring-record-system\ssl\win-acme\wacs.exe"
$logPath = "D:\wiring-record-system\ssl\logs\renew.log"

& $wacsPath --renew --baseuri "https://acme-v02.api.letsencrypt.org/" >> $logPath 2>&1

Write-Host "证书续期检查完成: $(Get-Date)" -ForegroundColor Green
```

#### 3.3.2 设置定时任务
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File D:\wiring-record-system\ssl\renew-certificate.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "03:00"
Register-ScheduledTask -TaskName "Renew SSL Certificate" -Action $action -Trigger $trigger -RunLevel Highest
```

## 4. 配置IIS使用SSL证书

### 4.1 导入证书到IIS

#### 4.1.1 打开IIS管理器
1. 按 `Win + R`，输入 `inetmgr`，回车
2. 打开IIS管理器

#### 4.1.2 导入证书
1. 点击服务器名称
2. 双击"服务器证书"
3. 点击"导入"
4. 选择证书文件（.pfx格式）
5. 输入证书密码（如果有的话）
6. 点击"确定"

### 4.2 绑定SSL证书到网站

#### 4.2.1 选择网站
1. 在IIS管理器中，选择"WiringRecordSystem"网站

#### 4.2.2 添加HTTPS绑定
1. 点击右侧"绑定"
2. 点击"添加"
3. 填写以下信息:
   - 类型: `https`
   - IP地址: `全部未分配`
   - 端口: `443`
   - SSL证书: 选择刚导入的证书
4. 点击"确定"

### 4.3 配置HTTP到HTTPS重定向

#### 4.3.1 添加HTTP重定向规则
在 `web.config` 中添加重定向规则:

```xml
<rule name="HTTP to HTTPS redirect" stopProcessing="true">
  <match url="(.*)" />
  <conditions>
    <add input="{HTTPS}" pattern="off" ignoreCase="true" />
  </conditions>
  <action type="Redirect" url="https://{HTTP_HOST}/{R:1}" redirectType="Permanent" />
</rule>
```

#### 4.3.2 完整的web.config
更新 `D:\wiring-record-system\frontend\web.config`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="HTTP to HTTPS redirect" stopProcessing="true">
          <match url="(.*)" />
          <conditions>
            <add input="{HTTPS}" pattern="off" ignoreCase="true" />
          </conditions>
          <action type="Redirect" url="https://{HTTP_HOST}/{R:1}" redirectType="Permanent" />
        </rule>
        <rule name="Handle History Mode and custom 404/500" stopProcessing="true">
          <match url="(.*)" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
          </conditions>
          <action type="Rewrite" url="/" />
        </rule>
        <rule name="ReverseProxyInboundRule1" stopProcessing="true">
          <match url="^api/(.*)" />
          <action type="Rewrite" url="http://localhost:3001/api/{R:1}" />
        </rule>
      </rules>
    </rewrite>
    <httpProtocol>
      <customHeaders>
        <add name="Strict-Transport-Security" value="max-age=31536000; includeSubDomains" />
        <add name="X-Content-Type-Options" value="nosniff" />
        <add name="X-Frame-Options" value="DENY" />
        <add name="X-XSS-Protection" value="1; mode=block" />
      </customHeaders>
    </httpProtocol>
    <staticContent>
      <clientCache cacheControlMode="UseMaxAge" cacheControlMaxAge="365.00:00:00" />
      <mimeMap fileExtension=".json" mimeType="application/json" />
      <mimeMap fileExtension=".woff" mimeType="application/font-woff" />
      <mimeMap fileExtension=".woff2" mimeType="application/font-woff2" />
    </staticContent>
  </system.webServer>
</configuration>
```

## 5. 配置SSL安全设置

### 5.1 启用HSTS
HSTS (HTTP Strict Transport Security) 强制浏览器使用HTTPS。

在 `web.config` 中已添加:
```xml
<add name="Strict-Transport-Security" value="max-age=31536000; includeSubDomains" />
```

### 5.2 配置SSL协议
1. 打开IIS管理器
2. 选择服务器名称
3. 双击"SSL设置"
4. 勾选"要求SSL"
5. 选择"客户端证书": 忽略
6. 点击"应用"

### 5.3 配置加密套件
使用PowerShell配置安全的加密套件:

```powershell
# 设置TLS 1.2为默认
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 配置加密套件
$ciphers = @(
    'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
    'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
    'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384',
    'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256'
)

Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers' -Name $ciphers -Value 0xFFFFFFFF -Type DWord
```

## 6. 验证HTTPS配置

### 6.1 测试HTTPS访问
在浏览器中访问:
```
https://your-domain.com
```
或
```
https://your-public-ip
```

### 6.2 检查SSL证书
1. 点击浏览器地址栏的锁图标
2. 查看证书信息
3. 确认证书有效

### 6.3 使用SSL Labs测试
访问: https://www.ssllabs.com/ssltest/

输入域名，测试SSL配置安全性。

### 6.4 检查HTTP重定向
访问:
```
http://your-domain.com
```

应该自动重定向到:
```
https://your-domain.com
```

## 7. 使用自签名证书（内网环境）

如果在内网环境，没有公网域名，可以使用自签名证书。

### 7.1 生成自签名证书
```powershell
# 创建证书
$cert = New-SelfSignedCertificate -DnsName "localhost","your-server-name" -CertStoreLocation "cert:\LocalMachine\My"

# 导出证书
$password = ConvertTo-SecureString -String "your-password" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "D:\wiring-record-system\ssl\self-signed.pfx" -Password $password

# 导出公钥证书
Export-Certificate -Cert $cert -FilePath "D:\wiring-record-system\ssl\self-signed.cer"
```

### 7.2 安装自签名证书
1. 双击 `self-signed.cer` 文件
2. 点击"安装证书"
3. 选择"受信任的根证书颁发机构"
4. 点击"确定"

### 7.3 在IIS中导入证书
参考4.1节的步骤，导入自签名证书。

### 7.4 配置客户端信任证书
在每台客户端机器上:
1. 将 `self-signed.cer` 复制到客户端
2. 双击安装到"受信任的根证书颁发机构"

## 8. 故障排查

### 8.1 证书验证失败
**问题**: 浏览器提示证书无效

**解决方案**:
1. 检查证书是否过期
2. 检查域名是否匹配
3. 检查证书链是否完整
4. 对于自签名证书，确保已安装到受信任的根证书颁发机构

### 8.2 HTTPS无法访问
**问题**: 无法通过HTTPS访问网站

**解决方案**:
1. 检查443端口是否开放
2. 检查IIS HTTPS绑定是否正确
3. 检查防火墙规则
4. 检查证书是否正确导入

### 8.3 HTTP不重定向到HTTPS
**问题**: 访问HTTP不会自动重定向到HTTPS

**解决方案**:
1. 检查web.config中的重定向规则
2. 检查URL重写模块是否安装
3. 检查IIS URL重写规则配置

### 8.4 混合内容警告
**问题**: 浏览器提示混合内容

**解决方案**:
1. 检查前端代码中是否有HTTP资源引用
2. 将所有资源引用改为HTTPS
3. 使用相对路径代替绝对路径

## 9. 证书管理

### 9.1 查看证书信息
```powershell
# 查看所有证书
Get-ChildItem -Path "Cert:\LocalMachine\My"

# 查看特定证书
$cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*your-domain*" }
$cert | Format-List *
```

### 9.2 删除旧证书
```powershell
# 删除旧证书
$oldCert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.NotAfter -lt (Get-Date).AddDays(-30) }
$oldCert | Remove-Item
```

### 9.3 备份证书
```powershell
# 备份证书
$cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*your-domain*" }
$password = ConvertTo-SecureString -String "backup-password" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "D:\wiring-record-system\ssl\backup.pfx" -Password $password
```

## 10. 安全最佳实践

### 10.1 定期更新证书
- Let's Encrypt证书每90天需要续期
- 配置自动续期任务
- 定期检查证书有效期

### 10.2 使用强加密
- 禁用弱加密套件
- 启用TLS 1.2和TLS 1.3
- 禁用SSLv2、SSLv3、TLS 1.0、TLS 1.1

### 10.3 监控证书状态
创建证书监控脚本 `check-certificate.ps1`:

```powershell
$cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*your-domain*" }
$daysLeft = ($cert.NotAfter - (Get-Date)).Days

if ($daysLeft -lt 30) {
    Write-Host "警告: 证书将在 $daysLeft 天后过期" -ForegroundColor Red
    
    # 发送告警邮件
    Send-MailMessage -From "monitoring@company.com" -To "admin@company.com" -Subject "SSL证书即将过期" -Body "SSL证书将在 $daysLeft 天后过期，请及时续期" -SmtpServer "smtp.company.com"
} else {
    Write-Host "证书状态正常，剩余 $daysLeft 天" -ForegroundColor Green
}
```

### 10.4 配置证书告警
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File D:\wiring-record-system\ssl\check-certificate.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "09:00"
Register-ScheduledTask -TaskName "Check SSL Certificate" -Action $action -Trigger $trigger -RunLevel Highest
```

## 11. 下一步

HTTPS配置完成后，请继续阅读:
- [05-数据备份方案文档.md](./05-数据备份方案文档.md)
- [06-监控方案文档.md](./06-监控方案文档.md)

---

**文档版本**: v1.0
**创建日期**: 2025-12-30
**最后更新**: 2025-12-30
**维护人员**: 综合布线记录管理系统团队
