import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'src/ui/ios.dart';
import 'src/ui/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web 端：flutter_secure_storage v9 需要在启动时生成并持久化加密密钥。
  // 桌面 / 移动平台不调用，交给系统级加密存储（Credential Manager / Keystore）。
  if (kIsWeb) {
    await const FlutterSecureStorage().setInitializations(
      resetOnError: false,
      usePrefs: true,
    );
  }

  runApp(const ProviderScope(child: CfManagerApp()));
}

class CfManagerApp extends StatelessWidget {
  const CfManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloudflare 管理器',
      debugShowCheckedModeBanner: false,
      theme: IosTheme.light(),
      darkTheme: IosTheme.dark(),
      themeMode: ThemeMode.system,
      home: const LoginGate(),
    );
  }
}
