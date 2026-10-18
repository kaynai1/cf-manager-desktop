import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Web 端专用的 secure storage 初始化。
/// 仅当代码运行在 Flutter Web 上才会被编译进产物。
Future<void> initializePlatformStorage() async {
  await const FlutterSecureStorage().setInitializations(
    resetOnError: false,
    usePrefs: true,
  );
}