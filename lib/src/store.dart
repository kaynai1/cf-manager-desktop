import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

/// 跨平台安全存储：
/// - 桌面（Windows/macOS/Linux）：系统级加密存储（Windows Credential Manager 等）
/// - Android/iOS：平台 Keystore / Keychain
/// - Web：WebCrypto 加密（配合 `main.dart` 中的 `setInitializations`）
final FlutterSecureStorage _kStorage = FlutterSecureStorage(
  // Android 使用加密 SharedPreferences
  aOptions: const AndroidOptions(),
  iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

/// 账号凭证安全存储（Windows Credential Manager / Android Keystore / WebCrypto）。
class AccountStore {
  static const _kAccounts = 'cf_accounts';
  static const _kSelected = 'cf_selected';

  static Future<List<Account>> load() async {
    final s = await _kStorage.read(key: _kAccounts);
    if (s == null || s.isEmpty) return [];
    final list = jsonDecode(s) as List;
    return list
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(List<Account> accounts) async {
    await _kStorage.write(
      key: _kAccounts,
      value: jsonEncode(accounts.map((e) => e.toJson()).toList()),
    );
  }

  static Future<String?> selected() => _kStorage.read(key: _kSelected);

  static Future<void> setSelected(String? id) async {
    if (id == null) {
      await _kStorage.delete(key: _kSelected);
    } else {
      await _kStorage.write(key: _kSelected, value: id);
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
      (await _kStorage.read(key: _k)) == 'ok';

  static Future<void> login() => _kStorage.write(key: _k, value: 'ok');

  static Future<void> logout() => _kStorage.delete(key: _k);
}
