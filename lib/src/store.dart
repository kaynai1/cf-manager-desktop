import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';
import 'store_io.dart';

/// 跨平台安全存储接口。
abstract class KVStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Windows 桌面后端：使用本地文件存储（避免 flutter_secure_storage 在桌面挂起）。
class _FileStorage implements KVStorage {
  final SecureStore _impl = SecureStore.instance;
  @override
  Future<String?> read(String key) => _impl.read(key);
  @override
  Future<void> write(String key, String value) => _impl.write(key, value);
  @override
  Future<void> delete(String key) => _impl.delete(key);
}

/// 其它平台后端：系统级安全存储。
class _SecureStorageBackend implements KVStorage {
  final FlutterSecureStorage _s = FlutterSecureStorage(
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  @override
  Future<String?> read(String key) => _s.read(key: key);
  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

/// 选择后端：桌面（非 Web 且非移动）用文件存储，其它用系统安全存储。
final KVStorage _kStorage =
    (!kIsWeb && isDesktop) ? _FileStorage() : _SecureStorageBackend();

/// 账号凭证安全存储（Windows 文件 / Android Keystore / WebCrypto）。
class AccountStore {
  static const _kAccounts = 'cf_accounts';
  static const _kSelected = 'cf_selected';

  static Future<List<Account>> load() async {
    final s = await _kStorage.read(_kAccounts);
    if (s == null || s.isEmpty) return [];
    final list = jsonDecode(s) as List;
    return list
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(List<Account> accounts) async {
    await _kStorage.write(
      _kAccounts,
      jsonEncode(accounts.map((e) => e.toJson()).toList()),
    );
  }

  static Future<String?> selected() => _kStorage.read(_kSelected);

  static Future<void> setSelected(String? id) async {
    if (id == null) {
      await _kStorage.delete(_kSelected);
    } else {
      await _kStorage.write(_kSelected, id);
    }
  }
}

/// 应用登录状态。
class AuthStore {
  static const _k = 'cf_logged_in';

  // 应用登录账号（占位示例，请在发布前自行修改）
  static const username = 'admin';
  static const password = 'admin';

  static Future<bool> isLoggedIn() async =>
      (await _kStorage.read(_k)) == 'ok';

  static Future<void> login() => _kStorage.write(_k, 'ok');

  static Future<void> logout() => _kStorage.delete(_k);
}
