import 'dart:convert';
import 'dart:io' show File, Directory, Platform;

/// 是否为桌面平台（Windows / macOS / Linux）。
/// 桌面平台使用本地文件存储，避免依赖系统安全存储插件在部分环境的挂起。
bool get isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// Windows / 桌面平台的安全存储：把数据保存到用户目录下的 JSON 文件。
/// 避免依赖 flutter_secure_storage（其在部分 Windows 环境下会挂起）。
/// 所有读写均不抛异常（内部吞掉 IO 错误），保证调用方永不被阻塞或中断。
class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  Directory? get _dir {
    try {
      final env = Platform.environment['LOCALAPPDATA'];
      final base = (env == null || env.isEmpty)
          ? Directory.systemTemp.path
          : env;
      final folder = Directory('$base${Platform.pathSeparator}CloudflareManager');
      if (!folder.existsSync()) {
        folder.createSync(recursive: true);
      }
      return folder;
    } catch (_) {
      return null;
    }
  }

  File? get _file {
    final dir = _dir;
    if (dir == null) return null;
    try {
      return File('${dir.path}${Platform.pathSeparator}storage.json');
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _cache = {};

  void _load() {
    if (_cache.isNotEmpty) return;
    final f = _file;
    if (f == null) return;
    try {
      if (f.existsSync()) {
        final raw = f.readAsStringSync();
        final data = jsonDecode(raw);
        if (data is Map) {
          _cache = data.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      }
    } catch (_) {
      _cache = {};
    }
  }

  void _persist() {
    final f = _file;
    if (f == null) return;
    try {
      f.writeAsStringSync(jsonEncode(_cache), flush: true);
    } catch (_) {
      // ignore
    }
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