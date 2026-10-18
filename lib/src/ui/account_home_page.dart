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
  const _NavItem(this.icon, this.label);
}

/// 侧栏分组
class _NavGroup {
  final String label;
  final List<_NavItem> items;
  const _NavGroup(this.label, this.items);
}

/// 当前选中的功能 id（用 label 作为 id）
final _navIdProvider = StateProvider<String>((ref) => '域名');

class AccountHomePage extends ConsumerWidget {
  const AccountHomePage({super.key});

  static const _groups = <_NavGroup>[
    _NavGroup('常用', [
      _NavItem(Icons.public, '域名'),
      _NavItem(Icons.bolt, 'Workers'),
      _NavItem(Icons.key, 'Workers KV'),
      _NavItem(Icons.storage, 'D1 数据库'),
      _NavItem(Icons.inventory_2, 'R2 存储'),
      _NavItem(Icons.web, 'Pages'),
    ]),
    _NavGroup('网络与安全', [
      _NavItem(Icons.route, 'Tunnel'),
      _NavItem(Icons.verified, 'Turnstile'),
      _NavItem(Icons.lock, 'Zero Trust'),
    ]),
    _NavGroup('AI 与数据', [
      _NavItem(Icons.auto_awesome, 'AI 网关'),
      _NavItem(Icons.scatter_plot, 'Vectorize'),
      _NavItem(Icons.list, 'Queues'),
      _NavItem(Icons.memory, 'Durable Objects'),
    ]),
    _NavGroup('账户', [
      _NavItem(Icons.badge, '账号信息'),
      _NavItem(Icons.people, '成员'),
      _NavItem(Icons.vpn_key, 'API 令牌'),
    ]),
  ];

  static const _groupAccent = <String, Color>{
    '域名': Ios.blue,
    'Workers': Ios.orange,
    'Workers KV': Ios.purple,
    'D1 数据库': Ios.blue,
    'R2 存储': Ios.teal,
    'Pages': Ios.orange,
    'Tunnel': Ios.teal,
    'Turnstile': Ios.orange,
    'Zero Trust': Ios.green,
    'AI 网关': Ios.purple,
    'Vectorize': Ios.teal,
    'Queues': Ios.green,
    'Durable Objects': Ios.gray,
    '账号信息': Ios.blue,
    '成员': Ios.purple,
    'API 令牌': Ios.orange,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountsProvider).selected;
    final accountId = account?.accountId;
    final navId = ref.watch(_navIdProvider);

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            accountName: account?.name ?? '未命名账号',
            groups: _groups,
            current: navId,
            onTap: (id) => ref.read(_navIdProvider.notifier).state = id,
          ),
          // 右侧内容区：独立 Navigator，切换/下钻都只发生在这里
          Expanded(
            child: Navigator(
              key: ValueKey('content-nav-$navId'),
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => _pageFor(
                  navId,
                  accountId,
                  onGoHome: () =>
                      ref.read(_navIdProvider.notifier).state = '域名',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageFor(String id, String? accountId,
      {required VoidCallback onGoHome}) {
    if (id == '域名') return const ZoneListPage();
    if (id == 'API 令牌') return const ApiTokensPage();
    if (accountId == null) return _NoAccountIdView(onGoHome: onGoHome);
    return switch (id) {
      'Workers' => WorkersPage(accountId: accountId),
      'Workers KV' => KvPage(accountId: accountId),
      'D1 数据库' => D1Page(accountId: accountId),
      'R2 存储' => R2Page(accountId: accountId),
      'Pages' => PagesPage(accountId: accountId),
      'Tunnel' => TunnelsPage(accountId: accountId),
      'Turnstile' => TurnstilePage(accountId: accountId),
      'Zero Trust' => AccessPage(accountId: accountId),
      'AI 网关' => AiGatewayPage(accountId: accountId),
      'Vectorize' => VectorizePage(accountId: accountId),
      'Queues' => QueuesPage(accountId: accountId),
      'Durable Objects' => DoPage(accountId: accountId),
      '账号信息' => AccountInfoPage(accountId: accountId),
      '成员' => MembersPage(accountId: accountId),
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

/// 停靠式左侧导航栏（桌面软件形态：贴边、紧凑、分组、单行条目）
class _Sidebar extends StatelessWidget {
  final String accountName;
  final List<_NavGroup> groups;
  final String current;
  final ValueChanged<String> onTap;
  const _Sidebar({
    required this.accountName,
    required this.groups,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surface = isLight ? const Color(0xFFEFF4FB) : const Color(0xFF0F1829);
    final borderColor = isLight ? const Color(0x14000000) : const Color(0x1FFFFFFF);

    Widget buildItem(_NavItem item) {
      final selected = item.label == current;
      final color = AccountHomePage._groupAccent[item.label] ?? Ios.blue;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(item.label),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? (isLight
                        ? Colors.white
                        : const Color(0xFF243049))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: selected && isLight
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 17,
                    color: selected ? color : (isLight ? Ios.gray : Ios.grayDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? (isLight ? const Color(0xFF16233A) : Colors.white)
                            : (isLight
                                ? const Color(0xFF445060)
                                : Ios.grayDark),
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
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

    return Container(
      width: 212,
      decoration: BoxDecoration(
        color: surface,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 应用标识（紧凑，像软件标题栏的延续）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Ios.orange, Color(0xFFFFA63D)],
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.cloud, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Cloudflare 管理器',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          // 分组导航
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                for (final g in groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 16, 4),
                    child: Text(
                      g.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isLight ? Ios.gray : Ios.grayDark,
                      ),
                    ),
                  ),
                  for (final it in g.items) buildItem(it),
                ],
              ],
            ),
          ),
          // 底部：当前账号（像软件的状态栏）
          Divider(height: 1, color: borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                Icon(Icons.cloud_circle_outlined,
                    size: 16, color: isLight ? Ios.gray : Ios.grayDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    accountName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLight
                          ? const Color(0xFF37475C)
                          : Colors.white70,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 14, color: isLight ? Ios.gray : Ios.grayDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
