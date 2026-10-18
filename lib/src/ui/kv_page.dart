import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';
import 'kv_detail_page.dart';

class KvPage extends ConsumerWidget {
  final String accountId;
  const KvPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers KV'),
        actions: [
          IosPageAction(
            label: '新建命名空间',
            icon: Icons.add,
            onPressed: () async {
              final title = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('新建命名空间'),
                  content: TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: '标题'),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('创建')),
                  ],
                ),
              );
              if (ok == true && title.text.trim().isNotEmpty) {
                final api = ref.read(apiProvider);
                if (api == null) return;
                try {
                  await api.createKvNamespace(accountId, title.text.trim());
                  ref.invalidate(kvNamespacesProvider(accountId));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.invalidate(kvNamespacesProvider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<KvNamespace>>(
        value: ref.watch(kvNamespacesProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('命名空间（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无命名空间'),
                for (final ns in list)
                  IosRow(
                    leading:
                        const IosIconBadge(icon: Icons.key, color: Ios.purple),
                    title: ns.title,
                    subtitle: ns.id,
                    chevron: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            KvDetailPage(accountId: accountId, ns: ns),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Ios.red, size: 20),
                      onPressed: () async {
                        final api = ref.read(apiProvider);
                        if (api == null) return;
                        try {
                          await api.deleteKvNamespace(accountId, ns.id);
                          ref.invalidate(kvNamespacesProvider(accountId));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('$e')));
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
