import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class MembersPage extends ConsumerWidget {
  final String accountId;
  const MembersPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('成员'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(membersProvider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<Member>>(
        value: ref.watch(membersProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('成员（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无成员'),
                for (final m in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.person, color: Ios.purple),
                    title: m.email ?? m.id,
                    value: m.status,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
