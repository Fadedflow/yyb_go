# YYB Go 部署包

每个平台压缩包内含：二进制、`resource/`（模板等资源）、一键安装/卸载脚本、服务配置。

首次安装会复制 `resource`；重复安装会保留已有 `resource`（不覆盖数据库）。

## Linux（systemd，需 root）

```bash
tar -xzf yyb-go-linux-amd64.tar.gz && cd yyb-go-linux-amd64
sudo ./install.sh                 # 默认 0.0.0.0:8000
sudo ./install.sh --host 127.0.0.1 --port 9000
sudo ./uninstall.sh               # 保留数据
sudo ./uninstall.sh --purge       # 连数据一起删
```

安装目录 `/opt/yyb-go`，日志 `journalctl -u yyb-go -f`。

## macOS（launchd，需 sudo）

```bash
tar -xzf yyb-go-darwin-arm64.tar.gz && cd yyb-go-darwin-arm64
sudo ./install-macos.sh [--host 0.0.0.0] [--port 8000]
sudo ./uninstall-macos.sh [--purge]
```

安装目录 `/usr/local/yyb-go`，日志 `/tmp/com.yyb.go.log`。

## Windows（计划任务，需管理员 PowerShell）

解压后在目录内以管理员身份运行 PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 [-ListenHost 0.0.0.0] [-Port 8000]
powershell -ExecutionPolicy Bypass -File .\uninstall-windows.ps1 [-Purge]
```

安装目录 `%ProgramData%\yyb-go`，以 SYSTEM 计划任务开机自启。

## 手动运行（不装服务）

```bash
./yyb-go --host 0.0.0.0 --port 8000 --resource-root ./resource
```
