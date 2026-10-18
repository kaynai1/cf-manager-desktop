import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class PagesPage extends ConsumerWidget {
  final String accountId;
  const PagesPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pagesProvider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<PagesProject>>(
        value: ref.watch(pagesProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('项目（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无 Pages 项目'),
                for (final p in list)
                  IosRow(
                    leading:
                        const IosIconBadge(icon: Icons.web, color: Ios.orange),
                    title: p.name,
                    subtitle: p.subdomain,
                    chevron: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PagesDeploymentsPage(accountId: accountId, project: p.name),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Ios.red, size: 20),
                      onPressed: () async {
                        final api = ref.read(apiProvider);
                        if (api == null) return;
                        try {
                          await api.deletePages(accountId, p.name);
                          ref.invalidate(pagesProvider(accountId));
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

class PagesDeploymentsPage extends ConsumerWidget {
  final String accountId;
  final String project;
  const PagesDeploymentsPage(
      {super.key, required this.accountId, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(project)),
      body: AsyncView<List<PagesDeployment>>(
        value: ref.watch(pagesDeploymentsProvider((accountId, project))),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('部署（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无部署'),
                for (final d in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.rocket_launch, color: Ios.green),
                    title: d.environment ?? d.id,
                    subtitle: d.url,
                    value: d.createdOn,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
