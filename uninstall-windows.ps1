<#
YYB Go 卸载（Windows，需管理员 PowerShell）。
默认保留数据（resource），加 -Purge 一并删除。

用法：
  powershell -ExecutionPolicy Bypass -File .\uninstall-windows.ps1 [-Purge]
#>
param(
	[switch]$Purge
)

$ErrorActionPreference = "Stop"

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	Write-Error "请以管理员身份运行 PowerShell 后再执行本脚本。"
	exit 1
}

$AppDir = Join-Path $env:ProgramData "yyb-go"
$TaskName = "yyb-go"

Write-Host ">> 停止并移除计划任务"
Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

if ($Purge) {
	Write-Host ">> 删除 $AppDir（含数据）"
	Remove-Item -Path $AppDir -Recurse -Force -ErrorAction SilentlyContinue
} else {
	Write-Host ">> 删除二进制，保留数据目录 $AppDir\resource"
	Remove-Item -Path (Join-Path $AppDir "yyb-go.exe") -Force -ErrorAction SilentlyContinue
}

Write-Host ">> 完成"
