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
    final active = zone.status == 'active';
    final isLight = Theme.of(context).brightness == Brightness.light;

    void go(Widget page) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(zone.name),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (active ? Ios.green : Ios.orange)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle,
                        size: 8,
                        color: active ? Ios.green : Ios.orange),
                    const SizedBox(width: 6),
                    Text(
                      active ? '运行中' : zone.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? Ios.green : Ios.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ---- 概览横幅（官网式：域名名 + 套餐 + 关键指标）----
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? [const Color(0xFFE8F0FD), const Color(0xFFF3F7FF)]
                    : [const Color(0xFF16243E), const Color(0xFF101A2E)],
              ),
              borderRadius: BorderRadius.circular(Ios.radius),
              border: Border.all(
                color: Ios.blue.withValues(alpha: isLight ? 0.15 : 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Ios.orange, Color(0xFFFFA63D)],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child:
                      const Icon(Icons.public, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${zone.plan} · 创建于 Cloudflare 的托管域名',
                        style: TextStyle(
                          fontSize: 12,
                          color: isLight ? Ios.gray : Ios.grayDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---- 快捷操作（官网式功能入口网格）----
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              '快捷操作',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Ios.gray,
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickTile(
                icon: Icons.dns,
                color: Ios.blue,
                label: 'DNS 记录',
                desc: '管理解析记录',
                onTap: () => go(DnsPage(zone: zone)),
              ),
              _QuickTile(
                icon: Icons.bar_chart,
                color: Ios.teal,
                label: '流量分析',
                desc: '请求量 · 带宽',
                onTap: () => go(ZoneAnalyticsPage(zone: zone)),
              ),
              _QuickTile(
                icon: Icons.tune,
                color: Ios.orange,
                label: '域名设置',
                desc: 'SSL · 速度 · 网络',
                onTap: () => go(ZoneSettingsPage(zone: zone)),
              ),
              _QuickTile(
                icon: Icons.delete_sweep,
                color: Ios.red,
                label: '缓存清除',
                desc: '清理边缘缓存',
                onTap: () => go(ZoneCachePage(zone: zone)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---- 设置与安全 ----
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              '设置与安全',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Ios.gray,
              ),
            ),
          ),
          IosCard(
            children: [
              IosRow(
                leading:
                    const IosIconBadge(icon: Icons.rule, color: Ios.purple),
                title: 'Page Rules',
                subtitle: '页面级跳转/缓存规则',
                chevron: true,
                onTap: () => go(PageRulesPage(zone: zone)),
              ),
              IosRow(
                leading:
                    const IosIconBadge(icon: Icons.shield, color: Ios.red),
                title: '安全',
                subtitle: '访问规则 · 速率限制 · 事件',
                chevron: true,
                onTap: () =>
                    go(SecurityPage(zone: zone, accountId: accountId)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.verified_user, color: Ios.green),
                title: 'DNSSEC',
                subtitle: '域名签名保护',
                chevron: true,
                onTap: () => go(DnssecPage(zone: zone)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.forward_to_inbox, color: Ios.orange),
                title: 'Email Routing',
                subtitle: '邮件路由转发',
                chevron: true,
                onTap: () => go(ZoneEmailRoutingPage(zone: zone)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---- 开发者平台 ----
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              '开发者平台',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Ios.gray,
              ),
            ),
          ),
          IosCard(
            children: [
              IosRow(
                leading:
                    const IosIconBadge(icon: Icons.code, color: Ios.orange),
                title: 'Workers · R2 · Workers AI',
                subtitle: '脚本 · 对象存储 · AI 模型',
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

/// 快捷操作网格块（官网式卡片按钮）
class _QuickTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String desc;
  final VoidCallback onTap;
  const _QuickTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Ios.radius),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLight ? Ios.card : Ios.cardDark,
          borderRadius: BorderRadius.circular(Ios.radius),
          border: Border.all(
              color: isLight ? Ios.cardBorder : Ios.cardBorderDark),
          boxShadow: [
            BoxShadow(
              color: Ios.cardShadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, Color.lerp(color, Colors.white, 0.25)!],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: isLight ? Ios.gray : Ios.grayDark),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: isLight ? Ios.gray : Ios.grayDark),
          ],
        ),
      ),
    );
  }
}
