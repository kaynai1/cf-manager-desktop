import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class AccessPage extends ConsumerWidget {
  final String accountId;
  const AccessPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zero Trust · Access'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(accessAppsProvider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<AccessApp>>(
        value: ref.watch(accessAppsProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('Access 应用（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无 Access 应用'),
                for (final a in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.lock, color: Ios.green),
                    title: a.name,
                    subtitle: a.domain,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
