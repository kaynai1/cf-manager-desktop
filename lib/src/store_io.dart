import 'dart:io' show Platform;

/// 是否为桌面平台（Windows / macOS / Linux）。
/// 桌面平台使用本地文件存储，避免依赖系统安全存储插件在部分环境的挂起。
bool get isDesktop {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return true;
  return false;
}