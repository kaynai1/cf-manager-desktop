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
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑账号' : '添加账号')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const IosSectionHeader('基本信息'),
          IosCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: '备注名称',
                    border: InputBorder.none,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<AuthType>(
                  initialValue: _authType,
                  decoration: const InputDecoration(
                    labelText: '认证方式',
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AuthType.token,
                      child: Text('API Token'),
                    ),
                    DropdownMenuItem(
                      value: AuthType.globalKey,
                      child: Text('Global API Key'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _authType = v ?? AuthType.token),
                ),
              ),
            ],
          ),
          const IosSectionHeader('凭证'),
          IosCard(
            children: [
              if (_authType == AuthType.token)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _token,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Token',
                      border: InputBorder.none,
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Cloudflare 邮箱',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _key,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Global API Key',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const IosSectionHeader('可选'),
          IosCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _accountId,
                  decoration: const InputDecoration(
                    labelText: 'Account ID（Workers / R2 / AI 用）',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 8, 28, 0),
            child: Text(
              '凭证仅保存在本机（系统加密存储），不会上传到任何第三方。',
              style: TextStyle(fontSize: 12, color: Ios.gray),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: IosButton(
              label: isEdit ? '验证并保存' : '验证并添加',
              icon: Icons.verified_user,
              busy: _busy,
              onPressed: _busy ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
