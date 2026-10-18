import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class DnssecPage extends ConsumerWidget {
  final Zone zone;
  const DnssecPage({super.key, required this.zone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DNSSEC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dnssecProvider(zone.id)),
          ),
        ],
      ),
      body: AsyncView<Map<String, dynamic>>(
        value: ref.watch(dnssecProvider(zone.id)),
        builder: (d) {
          final status = '${d['status'] ?? 'disabled'}';
          final active = status == 'active';
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              const IosSectionHeader('状态'),
              IosCard(
                children: [
                  SwitchListTile(
                    value: active,
                    activeTrackColor: Ios.orange,
                    title: const Text('启用 DNSSEC'),
                    subtitle: Text(status),
                    onChanged: (v) async {
                      final api = ref.read(apiProvider);
                      if (api == null) return;
                      try {
                        await api.editDnssec(
                            zone.id, v ? 'active' : 'disabled');
                        ref.invalidate(dnssecProvider(zone.id));
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              if (d['ds'] != null) ...[
                const IosSectionHeader('DS 记录（到域名注册商处填写）'),
                IosCard(
                  children: [
                    IosRow(title: 'Key Tag', value: '${d['key_tag']}'),
                    IosRow(title: 'Algorithm', value: '${d['algorithm']}'),
                    IosRow(title: 'Digest Type', value: '${d['digest_type']}'),
                    IosRow(title: 'Digest', value: '${d['digest']}'),
                    IosRow(title: 'DS', value: '${d['ds']}'),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
