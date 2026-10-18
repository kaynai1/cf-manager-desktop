import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class QueuesPage extends ConsumerWidget {
  final String accountId;
  const QueuesPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(queuesProvider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<QueueInfo>>(
        value: ref.watch(queuesProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('队列（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无队列'),
                for (final q in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.list, color: Ios.green),
                    title: q.name,
                    subtitle: q.id,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
