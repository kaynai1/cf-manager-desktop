import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

/// 概览仪表盘：顶部 4 张数据卡 + 域名 / Tunnel 列表
class OverviewPage extends ConsumerWidget {
  final String? accountId;
  final ValueChanged<String> onNavigate;
  const OverviewPage({super.key, required this.accountId, required this.onNavigate});

  String _count<T>(AsyncValue<List<T>> v) => v.when(
      data: (d) => '${d.length}', loading: () => '…', error: (_, __) => '—');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(zonesProvider);
    final acc = accountId;
    final tunnels = acc == null
        ? const AsyncValue<List<CftTunnel>>.data([])
        : ref.watch(tunnelsProvider(acc));
    final workers = acc == null
        ? const AsyncValue<List<WorkerScript>>.data([])
        : ref.watch(workersProvider(acc));
    final r2 = acc == null
        ? const AsyncValue<List<R2Bucket>>.data([])
        : ref.watch(r2Provider(acc));

    final zoneList = zones.valueOrNull ?? const <Zone>[];
    final activeZones = zoneList.where((z) => z.status == 'active').length;
    final tunList = tunnels.valueOrNull ?? const <CftTunnel>[];
    final tunLive = tunList.where((t) => t.deletedAt == null).toList();
    final online = tunLive.where((t) => t.healthy).length;

    void refresh() {
      ref.invalidate(zonesProvider);
      if (acc != null) {
        ref.invalidate(tunnelsProvider(acc));
        ref.invalidate(workersProvider(acc));
        ref.invalidate(r2Provider(acc));
      }
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: CfStatTile(
                  label: '域名',
                  value: _count(zones),
                  sub: zones.hasValue ? '$activeZones 个已生效' : '正在读取',
                  dot: zones.hasValue ? Ios.green : null,
                  onTap: () => onNavigate('域名'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CfStatTile(
                  label: '在线隧道',
                  value: tunnels.hasValue ? '$online' : _count(tunnels),
                  suffix: tunnels.hasValue ? '/ ${tunLive.length}' : null,
                  sub: acc == null
                      ? '需要 Account ID'
                      : (online > 0 ? '已连接' : '暂无在线'),
                  dot: online > 0 ? Ios.green : Ios.mute,
                  onTap: () => onNavigate('Tunnel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CfStatTile(
                  label: 'Workers',
                  value: _count(workers),
                  sub: '脚本数量',
                  onTap: () => onNavigate('Workers'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CfStatTile(
                  label: 'R2 存储桶',
                  value: _count(r2),
                  sub: '对象存储',
                  onTap: () => onNavigate('R2 存储'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CfCard(
            title: 'Cloudflare Tunnel',
            subtitle: '隧道连接状态 · 实时读取',
            actions: [
              Text('${tunLive.length} 个',
                  style: const TextStyle(fontSize: 12, color: Ios.gray)),
              CfButton(label: '全部', onPressed: () => onNavigate('Tunnel')),
            ],
            child: acc == null
                ? const CfEmptyState(
                    icon: Icons.badge_outlined,
                    title: '需要 Account ID',
                    hint: '在账号管理里给当前账号填写 Account ID 后即可查看隧道。')
                : AsyncView<List<CftTunnel>>(
                    value: tunnels,
                    builder: (_) => tunLive.isEmpty
                        ? CfEmptyState(
                            icon: Icons.route,
                            title: '暂无隧道',
                            hint: '在 Tunnel 页面创建隧道，或在飞牛 / Docker 里用令牌连接。',
                            action: CfButton(
                                label: '去创建',
                                onPressed: () => onNavigate('Tunnel')),
                          )
                        : Column(children: [
                            for (final t in tunLive.take(6))
                              _line(
                                context,
                                title: t.name,
                                sub: '${t.connectionsActive ?? 0} 个连接',
                                trailing: t.healthy
                                    ? const CfPill('在线', Ios.green)
                                    : const CfPill('离线', Ios.mute),
                              ),
                          ]),
                  ),
          ),
          const SizedBox(height: 12),
          CfCard(
            title: '我的域名',
            subtitle: '当前账号下的站点 · 点击进入管理',
            actions: [
              IconButton(
                tooltip: '刷新',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh),
                onPressed: refresh,
              ),
              CfButton(label: '全部', onPressed: () => onNavigate('域名')),
            ],
            child: AsyncView<List<Zone>>(
              value: zones,
              builder: (_) => zoneList.isEmpty
                  ? const CfEmptyState(
                      icon: Icons.public,
                      title: '暂无域名',
                      hint: '在 Cloudflare 添加站点后，这里会自动显示。')
                  : Column(children: [
                      for (final z in zoneList.take(8))
                        _line(
                          context,
                          title: z.name,
                          sub: z.plan,
                          trailing: z.status == 'active'
                              ? const CfPill('已生效', Ios.green)
                              : CfPill(z.status, const Color(0xFFC75A00)),
                          onTap: () => onNavigate('域名'),
                        ),
                      if (zoneList.length > 8)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(color: Ios.sepOf(context))),
                          ),
                          child: Text('共 ${zoneList.length} 个域名，仅列出前 8 个',
                              style: const TextStyle(
                                  fontSize: 12, color: Ios.gray)),
                        ),
                    ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context,
      {required String title,
      required String sub,
      required Widget trailing,
      VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Ios.sepOf(context))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 1),
                  Text(sub,
                      style: const TextStyle(fontSize: 11.5, color: Ios.mute)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
