fnOS Cloudflare 令牌助手 v1.3.0（C# / .NET Framework 4.8 重写版）

用途
  打开 Cloudflare 官方网页登录，在你自己的账号里自动创建名为「fnOS」的 API 令牌
  （账户·Cloudflare Tunnel 编辑 + 区域·DNS 编辑），并显示账户 ID，可保存到桌面。

使用
  解压整个文件夹后运行 fnOS-CF-TokenHelper.exe。
  不要单独拿出 exe，同目录的 Microsoft.Web.WebView2.*.dll 和 WebView2Loader.dll 是微软官方签名组件，必须放在一起。
  需要 Windows 10/11（自带 .NET Framework 4.8 和 Edge WebView2）。

与 1.2.x 的区别
  旧版用 Go 编写，会把 WebView2 加载器藏在 exe 里、在内存中加载，容易被杀毒软件误报。
  新版改用 C# + 微软官方 WebView2 SDK，不再内存加载 DLL，不调用 rundll32。功能和数据文件不变。

隐私
  只访问 dash.cloudflare.com 和 api.cloudflare.com，不向任何其他地址发送数据。
  记录保存在 %APPDATA%\fnOS-CFTokenHelper。

若仍被拦截
  SmartScreen：点「更多信息」→「仍要运行」。
  Defender 误报：到 https://www.microsoft.com/en-us/wdsi/filesubmission 提交 exe，选 Incorrectly detected as malware。
  各文件 SHA256 见 SHA256.txt。

MIT License, Copyright (c) 2026 Kay
