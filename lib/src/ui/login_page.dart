import 'package:flutter/material.dart';

import '../store.dart';
import 'account_list_page.dart';
import 'ios.dart';

/// 登录门禁：未登录显示登录页，登录后进入主界面。
class LoginGate extends StatefulWidget {
  const LoginGate({super.key});

  @override
  State<LoginGate> createState() => _LoginGateState();
}

class _LoginGateState extends State<LoginGate> {
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    AuthStore.isLoggedIn().then((v) {
      if (mounted) setState(() => _loggedIn = v);
    });
  }

  void _onSuccess() => setState(() => _loggedIn = true);

  Future<void> _logout() async {
    await AuthStore.logout();
    if (mounted) setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _loggedIn;
    if (loggedIn == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return loggedIn
        ? AccountListPage(onLogout: _logout)
        : LoginPage(onSuccess: _onSuccess);
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onSuccess;
  const LoginPage({super.key, required this.onSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = _user.text.trim() == AuthStore.username &&
        _pass.text == AuthStore.password;
    if (!ok) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '账号或密码错误';
        });
      }
      return;
    }
    // 先让 UI 表现"登录已成功"再持久化标记，避免存储调用偶发挂起时卡在转圈。
    widget.onSuccess();
    try {
      await AuthStore.login().timeout(const Duration(seconds: 2));
    } catch (_) {
      // 即便登录标记写入失败也允许进入主界面。
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF16202F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLight
                      ? const Color(0x14000000)
                      : const Color(0x14FFFFFF),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部标识
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Ios.orange, Color(0xFFFFA63D)],
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.cloud,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Cloudflare 管理器',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      '登录以继续',
                      style: TextStyle(fontSize: 13, color: Ios.gray),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // 账号
                  TextField(
                    controller: _user,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '账号',
                      filled: true,
                      fillColor: isLight
                          ? const Color(0xFFF7F9FC)
                          : const Color(0xFF101927),
                      prefixIcon:
                          const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 密码
                  TextField(
                    controller: _pass,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: '密码',
                      filled: true,
                      fillColor: isLight
                          ? const Color(0xFFF7F9FC)
                          : const Color(0xFF101927),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(
                            fontSize: 13, color: Ios.red)),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 46,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Ios.blue,
                        disabledBackgroundColor:
                            Ios.blue.withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      onPressed: _busy ? null : _login,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('登录',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      '默认账号 admin · 密码 admin',
                      style: TextStyle(fontSize: 12, color: Ios.gray),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
