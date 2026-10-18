import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'dns_page.dart';
import 'dnssec_page.dart';
import 'ios.dart';
import 'page_rules_page.dart';
import 'security_page.dart';
import 'zone_analytics_page.dart';
import 'zone_cache_page.dart';
import 'zone_dev_page.dart';
import 'zone_email_routing_page.dart';
import 'zone_settings_page.dart';

class ZoneHomePage extends ConsumerWidget {
  final Zone zone;
  const ZoneHomePage({super.key, required this.zone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountsProvider).selected;
    final accountId = zone.accountId ?? account?.accountId;

    void go(Widget page) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );

    return Scaffold(
      appBar: AppBar(title: Text(zone.name)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const IosSectionHeader('域名'),
          IosCard(
            children: [
              IosRow(
                leading: IosIconBadge(
                  icon: Icons.public,
                  color: zone.status == 'active' ? Ios.green : Ios.gray,
                ),
                title: zone.name,
                subtitle: '${zone.status} · ${zone.plan}',
              ),
              IosRow(
                leading:
                    const IosIconBadge(icon: Icons.dns, color: Ios.blue),
                title: 'DNS 记录',
                chevron: true,
                onTap: () => go(DnsPage(zone: zone)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.bar_chart, color: Ios.teal),
                title: '分析',
                chevron: true,
                onTap: () => go(ZoneAnalyticsPage(zone: zone)),
              ),
            ],
          ),
          const IosSectionHeader('设置与安全'),
          IosCard(
            children: [
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.tune, color: Ios.orange),
                title: '设置（SSL/TLS · 速度 · 缓存 · 网络 · 安全）',
                chevron: true,
                onTap: () => go(ZoneSettingsPage(zone: zone)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.delete_sweep, color: Ios.red),
                title: '缓存清除',
                chevron: true,
                onTap: () => go(ZoneCachePage(zone: zone)),
              ),
              IosRow(
                leading:
                    const IosIconBadge(icon: Icons.rule, color: Ios.purple),
                title: 'Page Rules',
                chevron: true,
                onTap: () => go(PageRulesPage(zone: zone)),
              ),
              IosRow(
                leading:
                    const IosIconBadge(icon: Icons.shield, color: Ios.red),
                title: '安全（访问规则 · 速率限制 · 事件）',
                chevron: true,
                onTap: () => go(SecurityPage(zone: zone, accountId: accountId)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.verified_user, color: Ios.green),
                title: 'DNSSEC',
                chevron: true,
                onTap: () => go(DnssecPage(zone: zone)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.forward_to_inbox, color: Ios.orange),
                title: 'Email Routing',
                chevron: true,
                onTap: () => go(ZoneEmailRoutingPage(zone: zone)),
              ),
            ],
          ),
          const IosSectionHeader('开发者平台'),
          IosCard(
            children: [
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.code, color: Ios.orange),
                title: 'Workers · R2 · Workers AI',
                chevron: true,
                onTap: () => go(ZoneDevPage(accountId: accountId)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
