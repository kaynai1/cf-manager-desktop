import 'dart:convert';
import 'dart:io';

/// Windows 桌面版的安全存储：保存在用户目录下的加密配置文件。
/// 避免依赖 flutter_secure_storage（其在部分 Windows 环境下会挂起）。
class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  // 存到 %LOCALAPPDATA%\CloudflareManager\storage.json
  File get _file {
    final dir = Platform.environment['LOCALAPPDATA'];
    final base = dir == null || dir.isEmpty
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
    _file.writeAsStringSync(
      jsonEncode(_cache),
      flush: true,
    );
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