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
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final ok = _user.text.trim() == AuthStore.username &&
        _pass.text == AuthStore.password;
    if (ok) {
      await AuthStore.login();
      widget.onSuccess();
    } else {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '账号或密码错误';
        });
      }
      return;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Ios.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.cloud, color: Colors.white, size: 46),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'Cloudflare 管理器',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('请登录后使用', style: TextStyle(color: Ios.gray)),
            ),
            const SizedBox(height: 36),
            IosCard(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _user,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '账号',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _pass,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: '密码',
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(_error!, style: const TextStyle(color: Ios.red)),
                ),
              ),
            const SizedBox(height: 24),
            IosButton(
              label: '登录',
              busy: _busy,
              onPressed: _busy ? null : _login,
            ),
          ],
        ),
      ),
    );
  }
}
