import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Web 端使用 web_init.dart（含 secure storage 初始化），桌面端使用 stub（空实现）。
import 'src/web_init_stub.dart'
    if (dart.library.html) 'src/web_init.dart';

import 'src/ui/ios.dart';
import 'src/ui/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web 端：flutter_secure_storage v9 需在启动时生成并持久化加密密钥。
  // 桌面 / 移动平台走系统级加密存储（Credential Manager / Keystore），无需初始化。
  await initializePlatformStorage();

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
