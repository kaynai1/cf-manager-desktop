import 'dart:ui';

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
          // 右侧内容区：浅灰半透明面板区分层级 + 独立 Navigator
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0x59FFFFFF),
                border: Border(
                  left: BorderSide(color: Color(0x14FFFFFF), width: 1),
                ),
              ),
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


/// 深色磨砂左侧导航栏（rgba(15,23,42,0.75) + 蓝紫发光选中态）
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
    return Container(
      width: 216,
      decoration: BoxDecoration(
        color: Ios.sidebar,
        border: const Border(
          right: BorderSide(color: Ios.sidebarBorder, width: 1),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 应用标识
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Ios.orange, Color(0xFFFFA63D)],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Ios.orange.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.cloud,
                          color: Colors.white, size: 17),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Cloudflare 管理器',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Ios.sidebarText,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0x120F172A)),
              // 分组导航
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final g in groups) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
                        child: Text(
                          g.label,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      for (final it in g.items)
                        _SidebarItem(
                          item: it,
                          selected: it.label == current,
                          onTap: () => onTap(it.label),
                        ),
                    ],
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0x120F172A)),
              // 底部账号
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0x1FFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_outline,
                          size: 14, color: Ios.sidebarTextDim),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            accountName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Ios.sidebarText,
                            ),
                          ),
                          const Text(
                            '已连接',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF4ADE80),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 侧栏导航项：圆角图标 + 选中蓝紫发光边框
class _SidebarItem extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final color = AccountHomePage._groupAccent[widget.item.label] ?? Ios.blue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? Ios.blue.withValues(alpha: 0.12)
                  : _hover
                      ? const Color(0x99FFFFFF)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              // 选中：蓝色发光边框
              border: Border.all(
                color: selected
                    ? Ios.blue.withValues(alpha: 0.55)
                    : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Ios.blue.withValues(alpha: 0.28),
                        blurRadius: 12,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // 圆角图标
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color, Ios.blueLight],
                          )
                        : null,
                    color: selected ? null : const Color(0x0F0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.item.icon,
                    size: 15,
                    color: selected ? Colors.white : Ios.sidebarTextDim,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.1,
                      color: selected ? Colors.white : Ios.sidebarText,
                    ),
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
