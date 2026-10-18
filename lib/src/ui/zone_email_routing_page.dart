import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class ZoneEmailRoutingPage extends ConsumerWidget {
  final Zone zone;
  const ZoneEmailRoutingPage({super.key, required this.zone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Routing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(emailRoutingProvider(zone.id));
              ref.invalidate(emailRulesProvider(zone.id));
              ref.invalidate(emailAddressesProvider(zone.id));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const IosSectionHeader('状态'),
          AsyncView<Map<String, dynamic>>(
            value: ref.watch(emailRoutingProvider(zone.id)),
            builder: (d) {
              final enabled = (d['enabled'] ?? false) as bool;
              final status = '${d['status'] ?? ''}';
              return IosCard(
                children: [
                  SwitchListTile(
                    value: enabled,
                    activeTrackColor: Ios.orange,
                    title: const Text('启用 Email Routing'),
                    subtitle: Text(status),
                    onChanged: enabled
                        ? null
                        : (v) async {
                            final api = ref.read(apiProvider);
                            if (api == null) return;
                            try {
                              await api.enableEmailRouting(zone.id);
                              ref.invalidate(emailRoutingProvider(zone.id));
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')));
                              }
                            }
                          },
                  ),
                ],
              );
            },
          ),
          const IosSectionHeader('路由规则'),
          AsyncView<List<EmailRule>>(
            value: ref.watch(emailRulesProvider(zone.id)),
            builder: (list) => IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无规则'),
                for (final r in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.forward_to_inbox, color: Ios.orange),
                    title: r.to ?? r.id,
                    value: r.enabled ? '启用' : '停用',
                  ),
              ],
            ),
          ),
          const IosSectionHeader('目标地址'),
          AsyncView<List<EmailAddress>>(
            value: ref.watch(emailAddressesProvider(zone.id)),
            builder: (list) => IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无地址'),
                for (final a in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.alternate_email, color: Ios.teal),
                    title: a.email,
                    value: a.verified ? '已验证' : '未验证',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
