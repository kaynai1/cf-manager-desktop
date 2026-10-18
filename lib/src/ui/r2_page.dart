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
              final ok = await showCfDialog<bool>(
                context,
                title: '新建存储桶',
                subtitle: 'R2 对象存储桶（名称需全局唯一）',
                confirmLabel: '创建',
                confirmValue: true,
                child: TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '桶名称',
                    hintText: '例如 my-bucket',
                  ),
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
            CfPageHeader(
              title: 'R2 存储桶',
              subtitle: '共 ${list.length} 个桶 · 点击行查看对象',
            ),
            CfTable(
              columns: const ['存储桶', '位置', '创建时间', ''],
              emptyState: const CfEmptyState(
                icon: Icons.inventory_2_outlined,
                title: '还没有存储桶',
                hint: '点击右上角「新建存储桶」创建第一个 R2 桶。',
              ),
              rows: [
                for (final b in list)
                  [
                    CfTable.cellOf(InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => R2ObjectsPage(
                              accountId: accountId, bucket: b.name),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Ios.teal, Color(0xFF5AC8C8)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.inventory_2,
                                color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              b.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Ios.blue),
                            ),
                          ),
                        ],
                      ),
                    )),
                    CfTable.cellOf(Text(b.location ?? '—',
                        style:
                            const TextStyle(fontSize: 12, color: Ios.gray))),
                    CfTable.cellOf(Text(b.creationDate ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: Ios.gray))),
                    CfTable.cellOf(Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 17, color: Ios.red),
                        tooltip: '删除',
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
                    )),
                  ],
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
