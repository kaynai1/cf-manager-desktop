import 'dart:convert';
import 'dart:io' show File, Directory, Platform;

/// 是否为桌面平台（Windows / macOS / Linux）。
/// 桌面平台使用本地文件存储，避免依赖系统安全存储插件在部分环境的挂起。
bool get isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// Windows / 桌面平台的安全存储：把数据保存到用户目录下的 JSON 文件。
/// 避免依赖 flutter_secure_storage（其在部分 Windows 环境下会挂起）。
class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  File get _file {
    final dir = Platform.environment['LOCALAPPDATA'];
    final base = (dir == null || dir.isEmpty)
        ? Directory.systemTemp.path
        : dir;
    final folder = Directory('$base\\CloudflareManager');
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    return File('${folder.path}\\storage.json');
  }

  Map<String, String> _cache = {};

  void _load() {
    if (_cache.isNotEmpty) return;
    try {
      if (_file.existsSync()) {
        final raw = _file.readAsStringSync();
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _cache = data.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {
      _cache = {};
    }
  }

  void _persist() {
    _file.writeAsStringSync(jsonEncode(_cache), flush: true);
  }

  Future<String?> read(String key) async {
    _load();
    return _cache[key];
  }

  Future<void> write(String key, String value) async {
    _load();
    _cache[key] = value;
    _persist();
  }

  Future<void> delete(String key) async {
    _load();
    _cache.remove(key);
    _persist();
  }
}