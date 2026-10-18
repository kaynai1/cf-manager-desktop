import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';
import 'zone_home_page.dart';

class ZoneListPage extends ConsumerWidget {
  const ZoneListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountsProvider).selected;
    return Scaffold(
      appBar: AppBar(
        title: const Text('域名'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(zonesProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(zonesProvider),
        child: AsyncView<List<Zone>>(
          value: ref.watch(zonesProvider),
          builder: (zones) {
            if (zones.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.dns_outlined, size: 64, color: Ios.gray),
                  SizedBox(height: 16),
                  Center(
                    child: Text('该账号下没有域名',
                        style: TextStyle(color: Ios.gray)),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                IosSectionHeader(
                    '账号：${account?.name ?? '-'} · ${zones.length} 个域名'),
                IosCard(
                  children: [
                    for (final z in zones)
                      IosRow(
                        leading: IosIconBadge(
                          icon: Icons.public,
                          color: z.status == 'active' ? Ios.green : Ios.gray,
                        ),
                        title: z.name,
                        subtitle: '${z.status} · ${z.plan}',
                        chevron: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ZoneHomePage(zone: z),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
