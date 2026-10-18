import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class R2Page extends ConsumerWidget {
  final String accountId;
  const R2Page({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('R2 对象存储'),
        actions: [
          IosPageAction(
            label: '新建存储桶',
            icon: Icons.add,
            onPressed: () async {
              final name = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('新建存储桶'),
                  content: TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '桶名'),
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
              if (ok == true && name.text.trim().isNotEmpty) {
                final api = ref.read(apiProvider);
                if (api == null) return;
                try {
                  await api.createR2Bucket(accountId, name.text.trim());
                  ref.invalidate(r2Provider(accountId));
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
            onPressed: () => ref.invalidate(r2Provider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<R2Bucket>>(
        value: ref.watch(r2Provider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('存储桶（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无存储桶'),
                for (final b in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.inventory_2, color: Ios.teal),
                    title: b.name,
                    subtitle: b.location,
                    chevron: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            R2ObjectsPage(accountId: accountId, bucket: b.name),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Ios.red, size: 20),
                      onPressed: () async {
                        final api = ref.read(apiProvider);
                        if (api == null) return;
                        try {
                          await api.deleteR2Bucket(accountId, b.name);
                          ref.invalidate(r2Provider(accountId));
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

class R2ObjectsPage extends ConsumerWidget {
  final String accountId;
  final String bucket;
  const R2ObjectsPage({super.key, required this.accountId, required this.bucket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(bucket)),
      body: AsyncView<List<Map<String, dynamic>>>(
        value: ref.watch(r2ObjectsProvider((accountId, bucket))),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('对象（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无对象'),
                for (final o in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.insert_drive_file, color: Ios.gray),
                    title: '${o['key']}',
                    subtitle: '${o['size'] ?? ''}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
