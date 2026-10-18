import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class DoPage extends ConsumerWidget {
  final String accountId;
  const DoPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Durable Objects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(doNamespacesProvider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<DoNamespace>>(
        value: ref.watch(doNamespacesProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('命名空间（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无命名空间'),
                for (final n in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.memory, color: Ios.gray),
                    title: n.name ?? n.id,
                    subtitle: n.id,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
