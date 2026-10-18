/// 桌面（Windows / macOS / Linux）端的存储初始化 stub。
/// 桌面平台使用系统级加密存储（Credential Manager 等），无需额外初始化。
Future<void> initializePlatformStorage() async {
  // no-op
}