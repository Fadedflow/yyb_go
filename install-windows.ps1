<#
YYB Go 一键安装（Windows，需管理员 PowerShell）。
安装二进制与资源目录到 %ProgramData%\yyb-go，注册开机自启的计划任务并立即启动。

用法（在解压目录内，右键“以管理员身份运行 PowerShell”后）：
  powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 [-ListenHost 0.0.0.0] [-Port 8000]
#>
param(
	[string]$ListenHost = "0.0.0.0",
	[int]$Port = 8000
)

$ErrorActionPreference = "Stop"

# 需要管理员权限
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	Write-Error "请以管理员身份运行 PowerShell 后再执行本脚本。"
	exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppDir = Join-Path $env:ProgramData "yyb-go"
$TaskName = "yyb-go"

# 定位二进制
$bin = Get-ChildItem -Path $ScriptDir -Filter "yyb-go*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $bin) {
	$named = Join-Path $ScriptDir "yyb-go.exe"
	if (Test-Path $named) { $bin = Get-Item $named }
}
if (-not $bin) {
	Write-Error "找不到二进制文件（yyb-go.exe 或 yyb-go-windows-*.exe）"
	exit 1
}

# 定位资源目录
$res = $null
foreach ($cand in @((Join-Path $ScriptDir "resource"), (Join-Path (Split-Path $ScriptDir -Parent) "resource"))) {
	if (Test-Path $cand -PathType Container) { $res = $cand; break }
}
if (-not $res) {
	Write-Error "找不到 resource 目录"
	exit 1
}

Write-Host ">> 安装到 $AppDir"
New-Item -ItemType Directory -Force -Path $AppDir | Out-Null
Copy-Item -Path $bin.FullName -Destination (Join-Path $AppDir "yyb-go.exe") -Force

$AppRes = Join-Path $AppDir "resource"
if (-not (Test-Path $AppRes)) {
	Copy-Item -Path $res -Destination $AppRes -Recurse -Force
} else {
	Write-Host ">> $AppRes 已存在，跳过（保留现有数据）"
}

Write-Host ">> 注册计划任务 $TaskName（host=$ListenHost port=$Port）"
$exe = Join-Path $AppDir "yyb-go.exe"
$cmdArgs = "--host $ListenHost --port $Port --resource-root `"$AppRes`""
$action = New-ScheduledTaskAction -Execute $exe -Argument $cmdArgs -WorkingDirectory $AppDir
$trigger = New-ScheduledTaskTrigger -AtStartup
$principalCfg = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principalCfg -Settings $settings | Out-Null
Start-ScheduledTask -TaskName $TaskName

Write-Host ">> 完成。服务地址：http://${ListenHost}:$Port"
Write-Host "查看状态：Get-ScheduledTask -TaskName $TaskName"
Write-Host "卸载：    powershell -ExecutionPolicy Bypass -File .\uninstall-windows.ps1"
