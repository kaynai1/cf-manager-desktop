import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'account_edit_page.dart';
import 'account_home_page.dart';
import 'ios.dart';

class AccountListPage extends ConsumerWidget {
  final Future<void> Function()? onLogout;
  const AccountListPage({super.key, this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountsProvider);
    final accounts = state.accounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloudflare 管理器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加账号',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountEditPage()),
            ),
          ),
          if (onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: '退出登录',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('退出登录'),
                    content: const Text('确定要退出登录吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('退出',
                            style: TextStyle(color: Ios.red)),
                      ),
                    ],
                  ),
                );
                if (ok == true) await onLogout!();
              },
            ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                if (accounts.isEmpty)
                  const _EmptyAccounts()
                else ...[
                  const IosSectionHeader('账号'),
                  IosCard(
                    children: [
                      for (final a in accounts)
                        IosRow(
                          leading: IosIconBadge(
                            icon: Icons.cloud,
                            color: a.authType == AuthType.token
                                ? Ios.orange
                                : Ios.blue,
                          ),
                          title: a.name,
                          subtitle: a.authType.label,
                          trailing: state.selected?.id == a.id
                              ? const Icon(Icons.check_circle,
                                  color: Ios.green, size: 20)
                              : null,
                          chevron: true,
                          onTap: () async {
                            await ref
                                .read(accountsProvider.notifier)
                                .select(a.id);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AccountHomePage(),
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                  const IosSectionHeader('管理'),
                  IosCard(
                    children: [
                      for (final a in accounts)
                        IosRow(
                          leading: const IosIconBadge(
                              icon: Icons.settings, color: Ios.gray),
                          title: '编辑「${a.name}」',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AccountEditPage(account: a),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Ios.red, size: 20),
                            onPressed: () => _confirmDelete(context, ref, a),
                          ),
                        ),
                    ],
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: IosButton(
                    label: '添加账号',
                    icon: Icons.add,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AccountEditPage()),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Account a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账号'),
        content: Text('确定删除「${a.name}」及其本地凭证吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Ios.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(accountsProvider.notifier).remove(a.id);
    }
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(32, 80, 32, 0),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 64, color: Ios.gray),
          SizedBox(height: 16),
          Text('还没有账号', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text(
            '添加一个 Cloudflare 账号开始管理域名、DNS、Workers、R2 与 Workers AI。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Ios.gray, height: 1.6),
          ),
        ],
      ),
    );
  }
}
