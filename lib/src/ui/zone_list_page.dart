import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';
import 'zone_home_page.dart';

class ZoneListPage extends ConsumerWidget {
  const ZoneListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountsProvider).selected;
    return Scaffold(
      appBar: AppBar(
        title: const Text('域名'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(zonesProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(zonesProvider),
        child: AsyncView<List<Zone>>(
          value: ref.watch(zonesProvider),
          builder: (zones) {
            if (zones.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.dns_outlined, size: 64, color: Ios.gray),
                  SizedBox(height: 16),
                  Center(
                    child: Text('该账号下没有域名',
                        style: TextStyle(color: Ios.gray)),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                  child: Text(
                    '账号：${account?.name ?? '-'} · ${zones.length} 个域名',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Ios.gray,
                    ),
                  ),
                ),
                for (final z in zones) _ZoneCard(zone: z),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 单个域名卡片：点击展开详情（小三角旋转），展开后可进入管理
class _ZoneCard extends StatefulWidget {
  final Zone zone;
  const _ZoneCard({required this.zone});

  @override
  State<_ZoneCard> createState() => _ZoneCardState();
}

class _ZoneCardState extends State<_ZoneCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final z = widget.zone;
    final active = z.status == 'active';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: CfHoverLift(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          decoration: BoxDecoration(
            gradient: Ios.glassGradient,
            borderRadius: BorderRadius.circular(Ios.radius),
            border: Border.all(color: Ios.cardBorder, width: 1),
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
              children: [
                // 头部行：点击展开/收起
                InkWell(
                  onTap: () =>
                      setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(Ios.radius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      IosIconBadge(
                        icon: Icons.public,
                        color: active ? Ios.green : Ios.gray,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              z.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (active ? Ios.green : Ios.gray)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    active ? '已激活' : z.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: active ? Ios.green : Ios.gray,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    z.plan,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: Ios.gray),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 小三角：展开时旋转 90°（微动效）
                      AnimatedRotation(
                        turns: _expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: const Icon(
                          Icons.play_arrow,
                          size: 18,
                          color: Ios.gray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 展开详情区（带高度过渡动画）
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 240),
                sizeCurve: Curves.easeOutCubic,
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Ios.fill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _kv('状态', active ? '已激活（DNS 生效）' : z.status),
                        _kv('套餐', z.plan),
                        _kv('域名 ID', z.id),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Ios.blue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(Ios.radius),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ZoneHomePage(zone: z),
                              ),
                            ),
                            icon: const Icon(Icons.tune, size: 18),
                            label: const Text('进入管理',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
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

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 12, color: Ios.gray)),
            ),
            Expanded(
              child: SelectableText(
                v,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
}
