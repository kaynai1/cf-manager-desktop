import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class ZoneAnalyticsPage extends ConsumerWidget {
  final Zone zone;
  const ZoneAnalyticsPage({super.key, required this.zone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析（近 24 小时）'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(zoneAnalyticsProvider(zone.id)),
          ),
        ],
      ),
      body: AsyncView<Map<String, dynamic>>(
        value: ref.watch(zoneAnalyticsProvider(zone.id)),
        builder: (data) {
          final totals = (data['totals'] as Map?) ?? const {};
          int all(String key) {
            final v = totals[key];
            if (v is Map) return (v['all'] as num?)?.toInt() ?? 0;
            return 0;
          }

          final requests = all('requests');
          final bandwidth = all('bandwidth');
          final threats = all('threats');
          final pageviews = all('pageviews');
          final uniques = all('uniques');

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              const IosSectionHeader('总览'),
              IosCard(
                children: [
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.bar_chart, color: Ios.blue),
                    title: '请求数',
                    value: _fmt(requests),
                  ),
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.swap_vert, color: Ios.teal),
                    title: '带宽',
                    value: _bytes(bandwidth),
                  ),
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.shield, color: Ios.red),
                    title: '威胁',
                    value: _fmt(threats),
                  ),
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.description, color: Ios.purple),
                    title: '页面浏览',
                    value: _fmt(pageviews),
                  ),
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.people, color: Ios.orange),
                    title: '独立访客',
                    value: _fmt(uniques),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );

  static String _bytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1024 * 1024 * 1024) {
      return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}
