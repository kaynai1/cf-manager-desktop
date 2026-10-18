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
      appBar: AppBar(
        title: const Text('Workers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(workersProvider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<WorkerScript>>(
        value: ref.watch(workersProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('脚本（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无 Worker'),
                for (final w in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.bolt, color: Ios.orange),
                    title: w.id,
                    subtitle: w.modifiedOn,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Ios.red, size: 20),
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
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
