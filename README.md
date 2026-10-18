# Cloudflare 管理器 —— Windows 桌面版

> 这是一个**独立工程**，只做 **Windows 桌面应用**。Web 版 / Docker 部署在
> 另一个独立工程 `cloudflare-manager-web` 中。本目录可单独拷贝、单独构建。

一个把 **Cloudflare 免费功能**集中管理的 **Windows 桌面软件**：多账号、域名、DNS、设置、
Workers、KV、D1、R2、Pages、Queues、Workers AI、Turnstile、Email Routing、API 令牌等。
iOS 风格界面，凭证通过 **Windows 凭据管理器** 加密保存，直连 Cloudflare API。

---

## 一、环境要求

- **Flutter**（stable 3.22+，建议 3.47.x）并加入 PATH
- 开启桌面支持：`flutter config --enable-windows-desktop`
- **Visual Studio 2022**：勾选「使用 C++ 的桌面开发」工作负载

## 二、快速启动

**双击 `启动-Windows桌面版.bat`**，自动完成：补全 `windows/` 脚手架 → `pub get` →
构建 Release → 弹出应用窗口。

## 三、手动构建 / 运行

```powershell
# 构建 Release 版
./scripts/build_windows.ps1

# 构建 Debug 版
./scripts/build_windows.ps1 -Debug

# 开发调试运行（flutter run -d windows）
./scripts/run_windows.ps1
```

直接 Flutter 命令：
```bash
flutter pub get
flutter build windows --release
flutter run -d windows
```

## 四、产物与分发

- 产物：`build\windows\x64\runner\Release\cloudflare_manager.exe`
- 分发：把 `Release\` 目录**整体**拷贝到其它 Windows 电脑即可直接运行（含所需 DLL）。

## 五、功能清单

- 账号级：多账号、API Token / Global API Key、API 令牌管理、成员、Turnstile、Access
- 域名级：DNS、DNSSEC、设置引擎（56 项）、缓存清除、分析、Page Rules、安全、Email Routing
- 开发者平台：Workers、KV、D1、R2、Pages、Queues、AI Gateway、Vectorize、Durable Objects
- 启动登录门禁

## 六、安全说明（重要）

- **不要**把真实 API Token / Global API Key 写进源码（会随 exe 打包可反编译提取）。
  `lib/src/defaults.dart` 默认为空，请在 App 内手动添加账号。
- 凭证保存在 **Windows 凭据管理器**。
- 应用启动登录密码为占位示例（`admin` / `admin`），发布前请在 `lib/src/store.dart` 修改。

## 七、目录结构

```
lib/                 # Flutter 应用源码
assets/icon/         # 应用图标
scripts/             # 构建/运行脚本
启动-Windows桌面版.bat  # 一键启动
```

> `windows/` 目录首次构建时由 `flutter create --platforms=windows` 自动生成。

## 八、许可证

MIT License