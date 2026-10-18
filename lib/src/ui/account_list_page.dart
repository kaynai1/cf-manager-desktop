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
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(title: const Text('Cloudflare 管理器')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Ios.orange, Color(0xFFFFA63D)],
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.cloud,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '选择要管理的账号',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: '添加账号',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AccountEditPage()),
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
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('退出',
                                            style:
                                                TextStyle(color: Ios.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) await onLogout!();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        accounts.isEmpty
                            ? '添加一个 Cloudflare 账号开始管理域名、DNS、Workers、R2 与 Workers AI。'
                            : '共 ${accounts.length} 个账号 · 点击行进入管理 · 右侧按钮编辑或删除',
                        style:
                            const TextStyle(fontSize: 13, color: Ios.gray),
                      ),
                      const SizedBox(height: 18),
                      if (accounts.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 44, horizontal: 24),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.white
                                : const Color(0xFF16202F),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isLight
                                  ? const Color(0x14000000)
                                  : const Color(0x14FFFFFF),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.cloud_off,
                                  size: 44, color: Ios.gray),
                              SizedBox(height: 14),
                              Text('还没有账号',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 6),
                              Text(
                                '点击右上角「+」添加你的第一个 Cloudflare 账号',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Ios.gray,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.white
                                : const Color(0xFF16202F),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isLight
                                  ? const Color(0x14000000)
                                  : const Color(0x14FFFFFF),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isLight ? 0.06 : 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Column(
                              children: [
                                for (var i = 0; i < accounts.length; i++) ...[
                                  if (i > 0)
                                    Divider(
                                        height: 1,
                                        color: isLight
                                            ? const Color(0x14000000)
                                            : const Color(0x14FFFFFF)),
                                  _AccountTile(
                                    account: accounts[i],
                                    selected:
                                        state.selected?.id == accounts[i].id,
                                    onTap: () async {
                                      await ref
                                          .read(accountsProvider.notifier)
                                          .select(accounts[i].id);
                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const AccountHomePage(),
                                          ),
                                        );
                                      }
                                    },
                                    onEdit: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AccountEditPage(
                                            account: accounts[i]),
                                      ),
                                    ),
                                    onDelete: () => _confirmDelete(
                                        context, ref, accounts[i]),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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

/// 账号行：图标 + 名称/类型 + 编辑/删除按钮
class _AccountTile extends StatelessWidget {
  final Account account;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AccountTile({
    required this.account,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: account.authType == AuthType.token
                      ? [Ios.orange, const Color(0xFFFFA63D)]
                      : [Ios.blue, const Color(0xFF5B8DEF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cloud, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle,
                            size: 15, color: Ios.green),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.authType.label,
                    style: TextStyle(
                        fontSize: 12,
                        color: isLight ? Ios.gray : Ios.grayDark),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 17, color: Ios.gray),
              tooltip: '编辑',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 17, color: Ios.red),
              tooltip: '删除',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
