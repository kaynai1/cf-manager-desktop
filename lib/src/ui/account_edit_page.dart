import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api.dart';
import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class AccountEditPage extends ConsumerStatefulWidget {
  final Account? account;
  const AccountEditPage({super.key, this.account});

  @override
  ConsumerState<AccountEditPage> createState() => _AccountEditPageState();
}

class _AccountEditPageState extends ConsumerState<AccountEditPage> {
  final _name = TextEditingController();
  final _token = TextEditingController();
  final _email = TextEditingController();
  final _key = TextEditingController();
  final _accountId = TextEditingController();

  AuthType _authType = AuthType.token;
  bool _busy = false;

  bool get isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _name.text = a.name;
      _authType = a.authType;
      _token.text = a.token ?? '';
      _email.text = a.email ?? '';
      _key.text = a.globalKey ?? '';
      _accountId.text = a.accountId ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _token.dispose();
    _email.dispose();
    _key.dispose();
    _accountId.dispose();
    super.dispose();
  }

  Account _build() {
    final id = widget.account?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    return Account(
      id: id,
      name: _name.text.trim().isEmpty ? '未命名账号' : _name.text.trim(),
      authType: _authType,
      token: _authType == AuthType.token ? _token.text.trim() : null,
      email: _authType == AuthType.globalKey ? _email.text.trim() : null,
      globalKey: _authType == AuthType.globalKey ? _key.text.trim() : null,
      accountId:
          _accountId.text.trim().isEmpty ? null : _accountId.text.trim(),
    );
  }

  Future<void> _save() async {
    final acc = _build();
    if (acc.authType == AuthType.token && (acc.token ?? '').isEmpty) {
      _toast('请填写 API Token');
      return;
    }
    if (acc.authType == AuthType.globalKey &&
        ((acc.email ?? '').isEmpty || (acc.globalKey ?? '').isEmpty)) {
      _toast('请填写邮箱和 Global API Key');
      return;
    }

    setState(() => _busy = true);
    try {
      await CfApi(acc).verify();
      final notifier = ref.read(accountsProvider.notifier);
      if (isEdit) {
        await notifier.update(acc);
      } else {
        await notifier.add(acc);
      }
      if (!mounted) return;
      _toast('验证成功，已保存');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fillColor =
        isLight ? const Color(0xFFF7F9FC) : const Color(0xFF101927);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide.none,
    );
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑账号' : '添加账号')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(28),
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
                    color:
                        Colors.black.withValues(alpha: isLight ? 0.08 : 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Ios.orange, Color(0xFFFFA63D)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cloud_outlined,
                            color: Colors.white, size: 21),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? '编辑 Cloudflare 账号' : '连接 Cloudflare 账号',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '凭证仅保存在本机加密存储，不会上传到任何第三方。',
                    style: TextStyle(fontSize: 12, color: Ios.gray),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: '备注名称',
                      filled: true,
                      fillColor: fillColor,
                      border: inputBorder,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<AuthType>(
                    initialValue: _authType,
                    decoration: InputDecoration(
                      labelText: '认证方式',
                      filled: true,
                      fillColor: fillColor,
                      border: inputBorder,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AuthType.token,
                        child: Text('API Token（推荐）'),
                      ),
                      DropdownMenuItem(
                        value: AuthType.globalKey,
                        child: Text('Global API Key（邮箱 + 密钥）'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _authType = v ?? AuthType.token),
                  ),
                  const SizedBox(height: 14),
                  if (_authType == AuthType.token)
                    TextField(
                      controller: _token,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'API Token',
                        hintText: '在 Cloudflare 控制台「My Profile → API Tokens」创建',
                        filled: true,
                        fillColor: fillColor,
                        border: inputBorder,
                      ),
                    )
                  else ...[
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Cloudflare 邮箱',
                        filled: true,
                        fillColor: fillColor,
                        border: inputBorder,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _key,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Global API Key',
                        filled: true,
                        fillColor: fillColor,
                        border: inputBorder,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: _accountId,
                    decoration: InputDecoration(
                      labelText: 'Account ID（选填）',
                      helperText: 'Workers / R2 / D1 / Tunnel 等功能需要',
                      filled: true,
                      fillColor: fillColor,
                      border: inputBorder,
                    ),
                  ),
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
                      onPressed: _busy ? null : _save,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.verified_user,
                                    size: 17),
                                const SizedBox(width: 7),
                                Text(
                                    isEdit ? '验证并保存' : '验证并连接',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
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
