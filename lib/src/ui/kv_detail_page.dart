import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class KvDetailPage extends ConsumerWidget {
  final String accountId;
  final KvNamespace ns;
  const KvDetailPage({super.key, required this.accountId, required this.ns});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (accountId, ns.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(ns.title),
        actions: [
          IosPageAction(
            label: '新建键',
            icon: Icons.add,
            onPressed: () => _edit(context, ref, null),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.invalidate(kvKeysProvider(key)),
          ),
        ],
      ),
      body: AsyncView<List<KvKey>>(
        value: ref.watch(kvKeysProvider(key)),
        builder: (keys) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('键（${keys.length}）'),
            IosCard(
              children: [
                if (keys.isEmpty) const IosRow(title: '暂无键'),
                for (final k in keys)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.label, color: Ios.blue),
                    title: k.name,
                    chevron: true,
                    onTap: () => _edit(context, ref, k.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Ios.red, size: 20),
                      onPressed: () async {
                        final api = ref.read(apiProvider);
                        if (api == null) return;
                        try {
                          await api.deleteKvKey(accountId, ns.id, k.name);
                          ref.invalidate(kvKeysProvider(key));
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

  Future<void> _edit(BuildContext context, WidgetRef ref, String? keyName) async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    final nameCtrl = TextEditingController(text: keyName ?? '');
    final valCtrl = TextEditingController();
    if (keyName != null) {
      try {
        valCtrl.text = await api.getKvValue(accountId, ns.id, keyName);
      } catch (_) {}
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(keyName == null ? '新增键值' : '编辑键值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              enabled: keyName == null,
              decoration: const InputDecoration(labelText: '键名'),
            ),
            TextField(
              controller: valCtrl,
              maxLines: 5,
              decoration: const InputDecoration(labelText: '值'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('保存')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      try {
        await api.putKvValue(
            accountId, ns.id, nameCtrl.text.trim(), valCtrl.text);
        ref.invalidate(kvKeysProvider((accountId, ns.id)));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }
}
