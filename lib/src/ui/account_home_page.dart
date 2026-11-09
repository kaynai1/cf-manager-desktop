import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity.dart';
import '../models.dart';
import '../providers.dart';
import 'account_edit_page.dart';
import 'account_info_page.dart';
import 'access_page.dart';
import 'ai_gateway_page.dart';
import 'api_tokens_page.dart';
import 'd1_page.dart';
import 'do_page.dart';
import 'ios.dart';
import 'kv_page.dart';
import 'members_page.dart';
import 'overview_page.dart';
import 'pages_page.dart';
import 'queues_page.dart';
import 'r2_page.dart';
import 'speedtest_page.dart';
import 'turnstile_page.dart';
import 'tunnels_page.dart';
import 'vectorize_page.dart';
import 'workers_page.dart';
import 'zone_list_page.dart';

const kAppVersion = '1.1.0';

class _NavItem {
  final IconData icon;
  final String label;
  final String? tag;
  const _NavItem(this.icon, this.label, {this.tag});
}

class _NavGroup {
  final String label;
  final List<_NavItem> items;
  const _NavGroup(this.label, this.items);
}

final _navIdProvider = StateProvider<String>((ref) => '概览');

/// 主界面：顶栏 + 左侧导航 + 内容 + 右侧面板 + 状态栏
class AccountHomePage extends ConsumerWidget {
  const AccountHomePage({super.key});

  static const _groups = <_NavGroup>[
    _NavGroup('总览', [
      _NavItem(Icons.grid_view_rounded, '概览'),
      _NavItem(Icons.public, '域名'),
    ]),
    _NavGroup('开发者平台', [
      _NavItem(Icons.bolt, 'Workers'),
      _NavItem(Icons.key_outlined, 'Workers KV'),
      _NavItem(Icons.storage_outlined, 'D1 数据库'),
      _NavItem(Icons.inventory_2_outlined, 'R2 存储'),
      _NavItem(Icons.web_outlined, 'Pages'),
    ]),
    _NavGroup('网络与安全', [
      _NavItem(Icons.route_outlined, 'Tunnel'),
      _NavItem(Icons.speed, '优选 IP', tag: 'NEW'),
      _NavItem(Icons.verified_outlined, 'Turnstile'),
      _NavItem(Icons.lock_outline, 'Zero Trust'),
    ]),
    _NavGroup('AI 与数据', [
      _NavItem(Icons.auto_awesome_outlined, 'AI 网关'),
      _NavItem(Icons.scatter_plot_outlined, 'Vectorize'),
      _NavItem(Icons.list_alt, 'Queues'),
      _NavItem(Icons.memory, 'Durable Objects'),
    ]),
    _NavGroup('账户', [
      _NavItem(Icons.badge_outlined, '账号信息'),
      _NavItem(Icons.people_outline, '成员'),
      _NavItem(Icons.vpn_key_outlined, 'API 令牌'),
    ]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountsProvider);
    final account = state.selected;
    final accountId = account?.accountId;
    final navId = ref.watch(_navIdProvider);
    final zones = ref.watch(zonesProvider);
    void go(String id) => ref.read(_navIdProvider.notifier).state = id;

    void refreshAll() {
      ref.invalidate(zonesProvider);
      if (accountId != null) {
        ref.invalidate(tunnelsProvider(accountId));
        ref.invalidate(workersProvider(accountId));
        ref.invalidate(r2Provider(accountId));
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已刷新')));
    }

    final zoneCount = zones.valueOrNull?.length;

    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            account: account,
            accounts: state.accounts,
            onSwitch: (id) async {
              await ref.read(accountsProvider.notifier).select(id);
              ActivityLog.instance.add('切换到账号「${state.accounts.firstWhere((a) => a.id == id).name}」', kind: 'info');
            },
            onRefresh: refreshAll,
            onManage: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final showRight = c.maxWidth >= 1180;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Sidebar(
                      groups: _groups,
                      current: navId,
                      counts: {if (zoneCount != null) '域名': '$zoneCount'},
                      accountId: accountId,
                      onTap: go,
                    ),
                    Expanded(
                      child: Navigator(
                        key: ValueKey('content-$navId-${account?.id}'),
                        onGenerateRoute: (_) => PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              _pageFor(navId, accountId, go),
                          transitionDuration: Duration.zero,
                        ),
                      ),
                    ),
                    if (showRight)
                      _RightPanel(
                        accounts: state.accounts,
                        current: account,
                        onSwitch: (id) async {
                          await ref.read(accountsProvider.notifier).select(id);
                          ActivityLog.instance.add(
                              '切换到账号「${state.accounts.firstWhere((a) => a.id == id).name}」',
                              kind: 'info');
                        },
                        onAdd: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AccountEditPage()),
                        ),
                        onSpeedTest: () => go('优选 IP'),
                      ),
                  ],
                );
              },
            ),
          ),
          _StatusBar(
            left: account == null
                ? '未选择账号'
                : '当前账号 ${account.name}${zoneCount == null ? '' : ' · 域名 $zoneCount 个'}',
          ),
        ],
      ),
    );
  }

  Widget _pageFor(String id, String? accountId, ValueChanged<String> go) {
    if (id == '概览') return OverviewPage(accountId: accountId, onNavigate: go);
    if (id == '域名') return const ZoneListPage();
    if (id == 'API 令牌') return const ApiTokensPage();
    if (id == '优选 IP') return const SpeedTestPage();
    if (accountId == null) return _NoAccountIdView(onGoHome: () => go('概览'));
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
      _ => OverviewPage(accountId: accountId, onNavigate: go),
    };
  }
}

// ============================================================
// 顶栏
// ============================================================
class _TopBar extends StatelessWidget {
  final Account? account;
  final List<Account> accounts;
  final ValueChanged<String> onSwitch;
  final VoidCallback onRefresh;
  final VoidCallback onManage;
  const _TopBar({
    required this.account,
    required this.accounts,
    required this.onSwitch,
    required this.onRefresh,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Ios.cardOf(context),
        border: Border(bottom: BorderSide(color: Ios.borderOf(context))),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset('assets/icon/app_icon.png',
                width: 26,
                height: 26,
                errorBuilder: (_, __, ___) => Container(
                      width: 26,
                      height: 26,
                      color: Ios.orange,
                      child: const Icon(Icons.cloud,
                          size: 16, color: Colors.white),
                    )),
          ),
          const SizedBox(width: 10),
          const Text('Cloudflare 管理器',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          const Text(kAppVersion,
              style: TextStyle(fontSize: 11.5, color: Ios.mute)),
          const Spacer(),
          if (account != null)
            PopupMenuButton<String>(
              tooltip: '切换账号',
              offset: const Offset(0, 40),
              onSelected: onSwitch,
              itemBuilder: (_) => [
                for (final a in accounts)
                  PopupMenuItem(
                    value: a.id,
                    height: 40,
                    child: Row(
                      children: [
                        _Avatar(a.name, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(a.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13))),
                        if (a.id == account!.id)
                          const Icon(Icons.check, size: 16, color: Ios.blue),
                      ],
                    ),
                  ),
              ],
              child: Container(
                height: 34,
                padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
                decoration: BoxDecoration(
                  border: Border.all(color: Ios.borderOf(context)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    _Avatar(account!.name, size: 26),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(account!.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    const CfDot(Color(0xFF13A10E)),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 10),
          _TopIcon(icon: Icons.refresh, tip: '刷新数据', onTap: onRefresh),
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider);
              final dark = mode == ThemeMode.dark;
              return _TopIcon(
                icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                tip: dark ? '切换到浅色' : '切换到深色',
                onTap: () => ref.read(themeModeProvider.notifier).state =
                    dark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          _TopIcon(
              icon: Icons.manage_accounts_outlined,
              tip: '账号管理',
              onTap: onManage),
        ],
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  const _TopIcon({required this.icon, required this.tip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tip,
      iconSize: 18,
      color: Ios.isLight(context) ? const Color(0xFF444444) : Colors.white70,
      icon: Icon(icon),
      onPressed: onTap,
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar(this.name, {this.size = 30});

  static const _colors = [
    Color(0xFFF6821F),
    Color(0xFF0067C0),
    Color(0xFF0F7B0F),
    Color(0xFF6B5BD2),
    Color(0xFFC239B3),
    Color(0xFF038387),
  ];

  @override
  Widget build(BuildContext context) {
    final t = name.trim();
    final ch = t.isEmpty ? '?' : t.characters.first.toUpperCase();
    final color = _colors[t.hashCode.abs() % _colors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(ch,
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.45)),
    );
  }
}

// ============================================================
// 左侧导航
// ============================================================
class _Sidebar extends StatelessWidget {
  final List<_NavGroup> groups;
  final String current;
  final Map<String, String> counts;
  final String? accountId;
  final ValueChanged<String> onTap;
  const _Sidebar({
    required this.groups,
    required this.current,
    required this.counts,
    required this.accountId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Ios.isLight(context);
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: isLight ? Ios.sidebar : const Color(0xFF272727),
        border: Border(right: BorderSide(color: Ios.borderOf(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              children: [
                for (final g in groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 5),
                    child: Text(g.label,
                        style: const TextStyle(
                            fontSize: 11.5, color: Ios.mute)),
                  ),
                  for (final it in g.items)
                    _SidebarItem(
                      item: it,
                      selected: it.label == current,
                      count: counts[it.label],
                      onTap: () => onTap(it.label),
                    ),
                ],
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 1,
            color: Ios.borderOf(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Account ID',
                    style: TextStyle(fontSize: 11, color: Ios.mute)),
                const SizedBox(height: 2),
                Text(
                  accountId == null || accountId!.isEmpty
                      ? '未填写'
                      : '${accountId!.substring(0, accountId!.length > 8 ? 8 : accountId!.length)}…',
                  style: Ios.mono.copyWith(
                      fontSize: 11.5,
                      color: isLight ? const Color(0xFF555555) : Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final String? count;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final isLight = Ios.isLight(context);
    final fg = sel
        ? Ios.blue
        : (isLight ? const Color(0xFF333333) : Colors.white70);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: sel
                ? (isLight ? Colors.white : const Color(0xFF333333))
                : _hover
                    ? (isLight
                        ? const Color(0x0A000000)
                        : const Color(0x0FFFFFFF))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: sel ? Ios.borderOf(context) : Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: sel ? Ios.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 9),
              Icon(widget.item.icon, size: 16, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: fg,
                  ),
                ),
              ),
              if (widget.count != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(widget.count!,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Ios.blue)),
                ),
              if (widget.item.tag != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CfPill(widget.item.tag!, Ios.green),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 右侧面板：账号快切 + 快捷工具 + 最近操作
// ============================================================
class _RightPanel extends ConsumerWidget {
  final List<Account> accounts;
  final Account? current;
  final ValueChanged<String> onSwitch;
  final VoidCallback onAdd;
  final VoidCallback onSpeedTest;
  const _RightPanel({
    required this.accounts,
    required this.current,
    required this.onSwitch,
    required this.onAdd,
    required this.onSpeedTest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(activityProvider).items;
    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Ios.borderOf(context))),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          CfCard(
            title: '账号快切',
            actions: [
              Text('${accounts.length} 个',
                  style: const TextStyle(fontSize: 12, color: Ios.gray)),
            ],
            child: Column(
              children: [
                for (final a in accounts)
                  _AccountLine(
                    account: a,
                    selected: a.id == current?.id,
                    onTap: () => onSwitch(a.id),
                  ),
                InkWell(
                  onTap: onAdd,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: Ios.sepOf(context))),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 15, color: Ios.blue),
                        SizedBox(width: 6),
                        Text('添加账号',
                            style: TextStyle(fontSize: 12.5, color: Ios.blue)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CfCard(
            title: '快捷工具',
            child: Column(
              children: [
                _ToolLine(
                  icon: Icons.speed,
                  title: '优选 IP 测速',
                  sub: '找出你网络下最快的 Cloudflare 节点',
                  onTap: onSpeedTest,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CfCard(
            title: '最近操作',
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: Ios.borderOf(context)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${log.length} 条',
                    style: const TextStyle(fontSize: 11.5, color: Ios.gray)),
              ),
            ],
            child: log.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(14, 6, 14, 18),
                    child: Text('还没有操作。新增、修改、删除都会记在这里。',
                        style: TextStyle(fontSize: 12, color: Ios.mute)),
                  )
                : Column(
                    children: [
                      for (final e in log.take(12))
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(color: Ios.sepOf(context))),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13)),
                                    Text(_hms(e.time),
                                        style: Ios.mono.copyWith(
                                            fontSize: 11, color: Ios.mute)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _kindPill(e.kind),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _kindPill(String kind) {
    if (kind == 'fail') return const CfPill('失败', Ios.red);
    if (kind == 'info') return const CfPill('记录', Ios.blue);
    return const CfPill('完成', Ios.green);
  }

  static String _hms(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}

class _AccountLine extends StatelessWidget {
  final Account account;
  final bool selected;
  final VoidCallback onTap;
  const _AccountLine(
      {required this.account, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLight = Ios.isLight(context);
    return InkWell(
      onTap: selected ? null : onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? (isLight ? Ios.blueBg : const Color(0x220067C0))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? const Color(0xFFBBD6F2) : Colors.transparent),
        ),
        child: Row(
          children: [
            _Avatar(account.name, size: 30),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        const CfPill('当前', Ios.blue),
                      ],
                    ],
                  ),
                  Text(account.authType.label,
                      style: const TextStyle(fontSize: 11, color: Ios.mute)),
                ],
              ),
            ),
            CfDot(selected ? const Color(0xFF13A10E) : Ios.mute),
            const SizedBox(width: 4),
            Text(selected ? '在线' : '切换',
                style: TextStyle(
                    fontSize: 11,
                    color: selected ? Ios.green : Ios.mute)),
          ],
        ),
      ),
    );
  }
}

class _ToolLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _ToolLine(
      {required this.icon,
      required this.title,
      required this.sub,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Ios.sepOf(context))),
        ),
        child: Row(
          children: [
            IosIconBadge(icon: icon, color: Ios.blue, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Ios.mute)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Ios.mute),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 状态栏
// ============================================================
class _StatusBar extends StatelessWidget {
  final String left;
  const _StatusBar({required this.left});

  @override
  Widget build(BuildContext context) {
    final isLight = Ios.isLight(context);
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isLight ? Ios.sidebar : const Color(0xFF272727),
        border: Border(top: BorderSide(color: Ios.borderOf(context))),
      ),
      child: Row(
        children: [
          Text(left, style: const TextStyle(fontSize: 11.5, color: Ios.gray)),
          const Spacer(),
          const Text('win32 · 凭据已加密保存 · 直连 Cloudflare API',
              style: TextStyle(fontSize: 11.5, color: Ios.gray)),
        ],
      ),
    );
  }
}

/// 没填 Account ID 的提示页
class _NoAccountIdView extends StatelessWidget {
  final VoidCallback onGoHome;
  const _NoAccountIdView({required this.onGoHome});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassPanel(
          child: CfEmptyState(
            icon: Icons.badge_outlined,
            title: '需要 Account ID',
            hint: '这个功能需要 Account ID。请在「账号管理」里编辑当前账号并填写。',
            action: CfButton(
                label: '返回概览', primary: true, onPressed: onGoHome),
          ),
        ),
      ),
    );
  }
}
