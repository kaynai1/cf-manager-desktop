import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class WorkersPage extends ConsumerWidget {
  final String accountId;
  const WorkersPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AsyncView<List<WorkerScript>>(
        value: ref.watch(workersProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            CfPageHeader(
              title: 'Workers 脚本',
              subtitle: '共 ${list.length} 个脚本 · 用量模型与绑定摘要如下',
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                  onPressed: () =>
                      ref.invalidate(workersProvider(accountId)),
                ),
              ],
            ),
            CfTable(
              columns: const ['脚本', '用量模型 / 绑定', '更新时间', ''],
              emptyState: const CfEmptyState(
                icon: Icons.bolt_outlined,
                title: '还没有部署 Worker',
                hint: '在 Cloudflare 官网或用 Wrangler CLI 部署后，这里会自动列出。',
              ),
              rows: [
                for (final w in list)
                  [
                    CfTable.cellOf(Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Ios.orange, Color(0xFFFFA63D)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.bolt,
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            w.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    )),
                    CfTable.cellOf(Text(
                      w.subLine.isEmpty ? '—' : w.subLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Ios.gray),
                    )),
                    CfTable.cellOf(Text(
                      w.modifiedOn ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Ios.gray),
                    )),
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
                            await api.deleteWorker(accountId, w.id);
                            ref.invalidate(workersProvider(accountId));
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$e')));
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
