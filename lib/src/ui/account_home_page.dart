import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'account_info_page.dart';
import 'access_page.dart';
import 'ai_gateway_page.dart';
import 'api_tokens_page.dart';
import 'd1_page.dart';
import 'do_page.dart';
import 'ios.dart';
import 'kv_page.dart';
import 'members_page.dart';
import 'pages_page.dart';
import 'queues_page.dart';
import 'r2_page.dart';
import 'turnstile_page.dart';
import 'tunnels_page.dart';
import 'vectorize_page.dart';
import 'workers_page.dart';
import 'zone_list_page.dart';

/// 功能项定义
class _NavItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _NavItem(this.icon, this.label, this.subtitle, this.color);
}

class AccountHomePage extends ConsumerWidget {
  const AccountHomePage({super.key});

  static const _items = <_NavItem>[
    _NavItem(Icons.public, '域名 Zones', 'DNS · 设置 · 规则 · 安全 · 分析',
        Ios.blue),
    _NavItem(Icons.bolt, 'Workers', '脚本与部署', Ios.orange),
    _NavItem(Icons.key, 'Workers KV', '键值存储', Ios.purple),
    _NavItem(Icons.storage, 'D1 数据库', 'SQL 数据库', Ios.blue),
    _NavItem(Icons.inventory_2, 'R2 对象存储', '对象存储桶', Ios.teal),
    _NavItem(Icons.web, 'Pages', '静态站点', Ios.orange),
    _NavItem(Icons.list, 'Queues', '消息队列', Ios.green),
    _NavItem(Icons.auto_awesome, 'AI Gateway', 'AI 网关', Ios.purple),
    _NavItem(Icons.scatter_plot, 'Vectorize', '向量索引', Ios.teal),
    _NavItem(Icons.memory, 'Durable Objects', '持久化对象', Ios.gray),
    _NavItem(Icons.verified, 'Turnstile', '人机验证', Ios.orange),
    _NavItem(Icons.route, 'Tunnel', '本地服务安全暴露', Ios.teal),
    _NavItem(Icons.lock, 'Zero Trust', 'Access 访问', Ios.green),
    _NavItem(Icons.badge, '账号信息', '账户详情', Ios.blue),
    _NavItem(Icons.people, '成员', '成员管理', Ios.purple),
    _NavItem(Icons.vpn_key, 'API 令牌', 'Token 管理', Ios.orange),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountsProvider).selected;
    final accountId = account?.accountId;

    void go(Widget page) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );

    void goBuilder(_NavItem item) {
      if (item.label == '域名 Zones') return go(const ZoneListPage());
      if (item.label == 'API 令牌') return go(const ApiTokensPage());
      if (accountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先在「编辑账号」里填写 Account ID')),
        );
        return;
      }
      final page = switch (item.label) {
        'Workers' => WorkersPage(accountId: accountId),
        'Workers KV' => KvPage(accountId: accountId),
        'D1 数据库' => D1Page(accountId: accountId),
        'R2 对象存储' => R2Page(accountId: accountId),
        'Pages' => PagesPage(accountId: accountId),
        'Queues' => QueuesPage(accountId: accountId),
        'AI Gateway' => AiGatewayPage(accountId: accountId),
        'Vectorize' => VectorizePage(accountId: accountId),
        'Durable Objects' => DoPage(accountId: accountId),
        'Turnstile' => TurnstilePage(accountId: accountId),
        'Tunnel' => TunnelsPage(accountId: accountId),
        'Zero Trust' => AccessPage(accountId: accountId),
        '账号信息' => AccountInfoPage(accountId: accountId),
        '成员' => MembersPage(accountId: accountId),
        _ => ZoneListPage(),
      };
      go(page);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Cloudflare 管理器')),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              accountName: account?.name ?? '未命名账号',
              items: _items,
              onTap: goBuilder,
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(28, 12, 28, 40),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '你好，${account?.name ?? 'Cloudflare'}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    '从左侧选择要管理的 Cloudflare 服务，或从下方快速开始。',
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Ios.gray
                            : Ios.grayDark),
                  ),
                  const SizedBox(height: 24),
                  _QuickStart(items: _items, onTap: goBuilder),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 左侧玻璃导航栏
class _Sidebar extends StatelessWidget {
  final String accountName;
  final List<_NavItem> items;
  final ValueChanged<_NavItem> onTap;
  const _Sidebar({
    required this.accountName,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Ios.card
            : Ios.cardDark,
        borderRadius: BorderRadius.circular(Ios.radius),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.light
              ? Ios.cardBorder
              : Ios.cardBorderDark,
        ),
        boxShadow: [
          BoxShadow(
            color: Ios.cardShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Ios.radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Ios.orange, Color(0xFFFFA63D)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cloudflare',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          accountName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.light
                                ? Ios.gray
                                : Ios.grayDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final it in items)
                    _NavTile(item: it, onTap: () => onTap(it)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final VoidCallback onTap;
  const _NavTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [item.color, Color.lerp(item.color, Colors.white, 0.2)!],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isLight ? Ios.gray : Ios.grayDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStart extends StatelessWidget {
  final List<_NavItem> items;
  final ValueChanged<_NavItem> onTap;
  const _QuickStart({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final grouped = items.toList();
    final half = (grouped.length / 2).ceil();
    final left = grouped.take(half).toList();
    final right = grouped.skip(half).toList();

    Widget tile(_NavItem it) => InkWell(
          onTap: () => onTap(it),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? Ios.card
                  : Ios.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.light
                    ? Ios.cardBorder
                    : Ios.cardBorderDark,
              ),
              boxShadow: [
                BoxShadow(
                  color: Ios.cardShadow,
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _IconBox(it.color, it.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        it.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Ios.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Ios.gray),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '快速开始',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Column(
                    children: [for (final it in left) ...[tile(it), const SizedBox(height: 10)]])),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    children: [for (final it in right) ...[tile(it), const SizedBox(height: 10)]])),
          ],
        ),
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _IconBox(this.color, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.white, 0.2)!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}