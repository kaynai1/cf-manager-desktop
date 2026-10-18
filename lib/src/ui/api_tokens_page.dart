import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class ApiTokensPage extends ConsumerWidget {
  const ApiTokensPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 令牌'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(apiTokensProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Ios.orange,
        foregroundColor: Colors.white,
        onPressed: () => _create(context, ref),
        child: const Icon(Icons.add),
      ),
      body: AsyncView<List<ApiToken>>(
        value: ref.watch(apiTokensProvider),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            IosSectionHeader('令牌（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无令牌'),
                for (final t in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.vpn_key, color: Ios.orange),
                    title: t.name,
                    subtitle: t.createdOn,
                    value: t.status,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Ios.blue, size: 20),
                          tooltip: '滚动更新',
                          onPressed: () async {
                            final api = ref.read(apiProvider);
                            if (api == null) return;
                            try {
                              await api.rollApiToken(t.id);
                              ref.invalidate(apiTokensProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')));
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Ios.red, size: 20),
                          onPressed: () async {
                            final api = ref.read(apiProvider);
                            if (api == null) return;
                            try {
                              await api.deleteApiToken(t.id);
                              ref.invalidate(apiTokensProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final groups = await ref.read(permissionGroupsProvider.future);
    if (!context.mounted) return;
    final name = TextEditingController();
    String? groupId = groups.isNotEmpty ? groups.first.id : null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('创建 API 令牌'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: groupId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '权限组'),
                items: [
                  for (final g in groups)
                    DropdownMenuItem(value: g.id, child: Text(g.name)),
                ],
                onChanged: (v) => setSt(() => groupId = v),
              ),
            ],
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
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && groupId != null) {
      final api = ref.read(apiProvider);
      if (api == null) return;
      try {
        await api.createApiToken(name.text.trim(), groupId!);
        ref.invalidate(apiTokensProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }
}
