import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'dns_edit_page.dart';
import 'ios.dart';

class DnsPage extends ConsumerWidget {
  final Zone zone;
  const DnsPage({super.key, required this.zone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DNS 记录 · ${zone.name}'),
        actions: [
          IosPageAction(
            label: '添加记录',
            icon: Icons.add,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DnsEditPage(zone: zone)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.invalidate(dnsProvider(zone.id)),
          ),
        ],
      ),
      body: AsyncView<List<DnsRecord>>(
        value: ref.watch(dnsProvider(zone.id)),
        builder: (records) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('记录（${records.length}）'),
            IosCard(
              children: [
                if (records.isEmpty) const IosRow(title: '暂无 DNS 记录'),
                for (final r in records)
                  IosRow(
                    leading: IosIconBadge(
                      icon: _iconFor(r.type),
                      color: _colorFor(r.type),
                    ),
                    title: '${r.type}  ${r.name}',
                    subtitle: r.proxied ? '${r.content} · 已代理' : r.content,
                    chevron: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DnsEditPage(zone: zone, record: r),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'A':
      case 'AAAA':
        return Icons.language;
      case 'CNAME':
        return Icons.alt_route;
      case 'MX':
        return Icons.email;
      case 'TXT':
        return Icons.text_fields;
      case 'NS':
        return Icons.dns;
      default:
        return Icons.tag;
    }
  }

  static Color _colorFor(String type) {
    switch (type) {
      case 'A':
      case 'AAAA':
        return Ios.blue;
      case 'CNAME':
        return Ios.purple;
      case 'MX':
        return Ios.teal;
      case 'TXT':
        return Ios.gray;
      default:
        return Ios.orange;
    }
  }
}
