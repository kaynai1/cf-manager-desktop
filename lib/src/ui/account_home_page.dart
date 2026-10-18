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

/// 当前选中的功能索引
final _navIndexProvider = StateProvider<int>((ref) => 0);

class AccountHomePage extends ConsumerWidget {
  const AccountHomePage({super.key});

  static const _items = <_NavItem>[
    _NavItem(Icons.public, '域名', 'DNS · 设置 · 安全 · 分析', Ios.blue),
    _NavItem(Icons.bolt, 'Workers', '脚本与部署', Ios.orange),
    _NavItem(Icons.key, 'Workers KV', '键值存储', Ios.purple),
    _NavItem(Icons.storage, 'D1 数据库', 'SQL 数据库', Ios.blue),
    _NavItem(Icons.inventory_2, 'R2 存储', '对象存储桶', Ios.teal),
    _NavItem(Icons.web, 'Pages', '静态站点', Ios.orange),
    _NavItem(Icons.list, 'Queues', '消息队列', Ios.green),
    _NavItem(Icons.auto_awesome, 'AI 网关', 'AI Gateway', Ios.purple),
    _NavItem(Icons.scatter_plot, 'Vectorize', '向量索引', Ios.teal),
    _NavItem(Icons.memory, 'Durable Objects', '持久化对象', Ios.gray),
    _NavItem(Icons.verified, 'Turnstile', '人机验证', Ios.orange),
    _NavItem(Icons.route, 'Tunnel', '本地服务映射', Ios.teal),
    _NavItem(Icons.lock, 'Zero Trust', 'Access 访问控制', Ios.green),
    _NavItem(Icons.badge, '账号信息', '账户详情', Ios.blue),
    _NavItem(Icons.people, '成员', '成员管理', Ios.purple),
    _NavItem(Icons.vpn_key, 'API 令牌', 'Token 管理', Ios.orange),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountsProvider).selected;
    final accountId = account?.accountId;
    final navIndex = ref.watch(_navIndexProvider);
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              accountName: account?.name ?? '未命名账号',
              items: _items,
              current: navIndex,
              onTap: (i) => ref.read(_navIndexProvider.notifier).state = i,
            ),
            // 右侧内容区：独立 Navigator，页面切换/跳转都发生在这一区域，
            // 左侧导航栏永驻，呈现桌面软件的多面板体验。
            Expanded(
              child: Navigator(
                key: ValueKey('content-nav-$navIndex'),
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (_) => _pageFor(
                    navIndex,
                    accountId,
                    onGoHome: () =>
                        ref.read(_navIndexProvider.notifier).state = 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageFor(int index, String? accountId,
      {required VoidCallback onGoHome}) {
    // 域名、API 令牌不需要 Account ID
    if (index == 0) return const ZoneListPage();
    if (index == 15) return const ApiTokensPage();
    if (accountId == null) return _NoAccountIdView(onGoHome: onGoHome);
    return switch (index) {
      1 => WorkersPage(accountId: accountId),
      2 => KvPage(accountId: accountId),
      3 => D1Page(accountId: accountId),
      4 => R2Page(accountId: accountId),
      5 => PagesPage(accountId: accountId),
      6 => QueuesPage(accountId: accountId),
      7 => AiGatewayPage(accountId: accountId),
      8 => VectorizePage(accountId: accountId),
      9 => DoPage(accountId: accountId),
      10 => TurnstilePage(accountId: accountId),
      11 => TunnelsPage(accountId: accountId),
      12 => AccessPage(accountId: accountId),
      13 => AccountInfoPage(accountId: accountId),
      14 => MembersPage(accountId: accountId),
      _ => const ZoneListPage(),
    };
  }
}

/// 没填 Account ID 的提示页
class _NoAccountIdView extends StatelessWidget {
  final VoidCallback onGoHome;
  const _NoAccountIdView({required this.onGoHome});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.badge_outlined, size: 64, color: Ios.gray),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            '需要 Account ID',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            '此功能需要 Account ID。请回到「账号管理」编辑账号并填写 Account ID。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Ios.gray, fontSize: 14, height: 1.6),
          ),
        ),
        const SizedBox(height: 60),
        Center(
          child: SizedBox(
            width: 200,
            child: IosButton(
              label: '返回域名页',
              icon: Icons.arrow_back,
              onPressed: onGoHome,
            ),
          ),
        ),
      ],
    );
  }
}

/// 左侧玻璃导航栏
class _Sidebar extends StatelessWidget {
  final String accountName;
  final List<_NavItem> items;
  final int current;
  final ValueChanged<int> onTap;
  const _Sidebar({
    required this.accountName,
    required this.items,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: 230,
      margin: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      decoration: BoxDecoration(
        color: isLight ? Ios.card : Ios.cardDark,
        borderRadius: BorderRadius.circular(Ios.radius),
        border: Border.all(
            color: isLight ? Ios.cardBorder : Ios.cardBorderDark),
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
            // 顶部 logo + 应用名
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Ios.orange, Color(0xFFFFA63D)],
                      ),
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: Ios.orange.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.cloud,
                        color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cloudflare 管理器',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          accountName,
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
            Divider(height: 1, indent: 18, endIndent: 18, color: isLight ? Ios.sep : Ios.sepDark),
            // 导航项
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (var i = 0; i < items.length; i++)
                    _NavTile(
                      item: items[i],
                      selected: i == current,
                      onTap: () => onTap(i),
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

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? Ios.blue.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Ios.blue.withValues(alpha: 0.25)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        selected
                            ? item.color
                            : item.color.withValues(alpha: 0.75),
                        Color.lerp(item.color, Colors.white, 0.2)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: item.color.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected
                              ? Ios.blue
                              : (isLight
                                  ? Colors.black87
                                  : Colors.white),
                        ),
                      ),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isLight ? Ios.gray : Ios.grayDark,
                        ),
                      ),
                    ],
                  ),
                ),
                // 选中指示条
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected ? Ios.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
