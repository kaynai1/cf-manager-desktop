import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

/// 开发者平台：Workers / R2 / Workers AI。
class ZoneDevPage extends ConsumerWidget {
  final String? accountId;
  const ZoneDevPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (accountId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('开发者')),
        body: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              '此功能需要 Account ID。\n请在「编辑账号」里填写 Account ID。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Ios.gray, height: 1.6),
            ),
          ),
        ),
      );
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('开发者'),
          bottom: const TabBar(
            labelColor: Ios.orange,
            unselectedLabelColor: Ios.gray,
            indicatorColor: Ios.orange,
            tabs: [
              Tab(text: 'Workers'),
              Tab(text: 'R2'),
              Tab(text: 'AI'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _WorkersTab(accountId: accountId!),
            _R2Tab(accountId: accountId!),
            _AiTab(accountId: accountId!),
          ],
        ),
      ),
    );
  }
}

class _WorkersTab extends ConsumerWidget {
  final String accountId;
  const _WorkersTab({required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(workersProvider(accountId)),
      child: AsyncView<List<WorkerScript>>(
        value: ref.watch(workersProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('Workers（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无 Worker'),
                for (final w in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.bolt, color: Ios.orange),
                    title: w.id,
                    subtitle: w.modifiedOn,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _R2Tab extends ConsumerWidget {
  final String accountId;
  const _R2Tab({required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(r2Provider(accountId)),
      child: AsyncView<List<R2Bucket>>(
        value: ref.watch(r2Provider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('R2 存储桶（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无存储桶'),
                for (final b in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.inventory_2, color: Ios.teal),
                    title: b.name,
                    subtitle: b.location,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AiTab extends ConsumerWidget {
  final String accountId;
  const _AiTab({required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(aiProvider(accountId)),
      child: AsyncView<List<AiModel>>(
        value: ref.watch(aiProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('Workers AI 模型（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无模型'),
                for (final m in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.auto_awesome, color: Ios.purple),
                    title: m.id,
                    subtitle: m.task,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
