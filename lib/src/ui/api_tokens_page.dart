import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class ApiTokensPage extends ConsumerWidget {
  const ApiTokensPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AsyncView<List<ApiToken>>(
        value: ref.watch(apiTokensProvider),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            CfPageHeader(
              title: 'API 令牌',
              subtitle: '共 ${list.length} 个令牌 · 支持多权限组 · 密钥仅创建时显示一次',
              actions: [
                IosPageAction(
                  label: '创建令牌',
                  icon: Icons.add,
                  onPressed: () => _create(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                  onPressed: () => ref.invalidate(apiTokensProvider),
                ),
              ],
            ),
            CfTable(
              columns: const ['令牌名称', '状态', '创建时间', ''],
              emptyState: const CfEmptyState(
                icon: Icons.vpn_key_outlined,
                title: '还没有 API 令牌',
                hint: '点击右上角「创建令牌」，搜索并勾选所需权限即可生成。',
              ),
              rows: [
                for (final t in list)
                  [
                    CfTable.cellOf(Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    )),
                    CfTable.cellOf(CfPill(
                        t.status ?? '未知',
                        t.status == 'active'
                            ? Ios.green
                            : (t.status == 'expired'
                                ? Ios.red
                                : Ios.gray))),
                    CfTable.cellOf(Text(t.createdOn ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 12, color: Ios.gray))),
                    CfTable.cellOf(Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh,
                                size: 17, color: Ios.blue),
                            tooltip: '重新生成密钥',
                            onPressed: () async {
                              final api = ref.read(apiProvider);
                              if (api == null) return;
                              try {
                                final secret = await api.rollApiToken(t.id);
                                ref.invalidate(apiTokensProvider);
                                if (context.mounted) {
                                  _showSecret(context, t.name, secret);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')));
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 17, color: Ios.red),
                            tooltip: '删除',
                            onPressed: () async {
                              final api = ref.read(apiProvider);
                              if (api == null) return;
                              try {
                                await api.deleteApiToken(t.id);
                                ref.invalidate(apiTokensProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')));
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    )),
                  ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 创建令牌：搜索 + 分组 + 方框多选
  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final groups = await ref.read(permissionGroupsProvider.future);
    if (!context.mounted) return;
    final name = TextEditingController();
    final search = TextEditingController();
    // 默认勾选：域名读取 + DNS 编辑（最常用组合）
    final selected = <String>{
      for (final g in groups)
        if (g.name == 'Zone Read' || g.name == 'DNS Edit') g.id,
    };
    var query = '';

    Widget checkboxRow(PermissionGroup g, StateSetter setSt) {
      final on = selected.contains(g.id);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        child: InkWell(
          onTap: () => setSt(
              () => on ? selected.remove(g.id) : selected.add(g.id)),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                // 标准方形复选框（勾选动效）
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: on ? Ios.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: on ? Ios.blue : Ios.gray,
                      width: 1.6,
                    ),
                  ),
                  child: on
                      ? const Icon(Icons.check,
                          size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    g.localName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                      color: on ? Ios.blue : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: GlassPanel(
              radius: 18,
              blur: 24,
              color: const Color(0xF2FFFFFF),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 18, 12, 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F9FC),
                      border: Border(
                          bottom: BorderSide(color: Color(0x14000000))),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '创建 API 令牌',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: name,
                          onChanged: (_) => setSt(() {}),
                          decoration: InputDecoration(
                            labelText: '令牌名称',
                            hintText: '例如 my-token',
                            filled: true,
                            fillColor: const Color(0xFFF7F9FC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // 快速搜索框
                        TextField(
                          controller: search,
                          onChanged: (v) => setSt(() => query = v.trim()),
                          decoration: InputDecoration(
                            hintText: '搜索权限，如：DNS、缓存、编辑…',
                            prefixIcon: const Icon(Icons.search, size: 19),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close,
                                        size: 16),
                                    onPressed: () {
                                      search.clear();
                                      setSt(() => query = '');
                                    },
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFF7F9FC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '已选 ${selected.length} 项',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Ios.blue,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => setSt(
                                () => selected.addAll(
                                  _filtered(groups, query)
                                      .map((g) => g.id),
                                ),
                              ),
                              child: const Text('选中当前结果',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            if (selected.isNotEmpty)
                              TextButton(
                                onPressed: () =>
                                    setSt(() => selected.clear()),
                                child: const Text('清空',
                                    style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  // 分组权限列表（编辑类 / 读取类 / 其他）
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 360),
                      width: double.infinity,
                      decoration:
                          const BoxDecoration(color: Color(0xFFF7F9FC)),
                      child: groups.isEmpty
                          ? const Center(
                              child: Text('权限组加载中…',
                                  style: TextStyle(color: Ios.gray)),
                            )
                          : Scrollbar(
                              child: ListView(
                                shrinkWrap: true,
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                children: [
                                  for (final kind in const [
                                    '编辑类',
                                    '读取类',
                                    '其他'
                                  ])
                                    ..._buildKindSection(
                                      groups: groups,
                                      kind: kind,
                                      query: query,
                                      selected: selected,
                                      setSt: setSt,
                                      rowBuilder: checkboxRow,
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  // 底部按钮
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          top: BorderSide(color: Color(0x14000000))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Ios.gray,
                                side: const BorderSide(
                                    color: Color(0x1F000000)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('取消',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 44,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Ios.blue,
                                disabledBackgroundColor:
                                    Ios.blue.withValues(alpha: 0.35),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              onPressed: (name.text.trim().isEmpty ||
                                      selected.isEmpty)
                                  ? null
                                  : () => Navigator.pop(ctx, true),
                              child: Text(
                                  '创建令牌（${selected.length} 项权限）',
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && selected.isNotEmpty) {
      final api = ref.read(apiProvider);
      if (api == null) return;
      try {
        final created = await api.createApiToken(
            name.text.trim(), selected.toList());
        ref.invalidate(apiTokensProvider);
        if (context.mounted) {
          _showSecret(
              context, name.text.trim(), created['value'] as String?);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
    search.dispose();
    name.dispose();
  }

  /// 按关键字过滤权限组（匹配中文名与英文原名）
  List<PermissionGroup> _filtered(
      List<PermissionGroup> groups, String query) {
    if (query.isEmpty) return groups;
    final q = query.toLowerCase();
    return groups
        .where((g) =>
            g.localName.toLowerCase().contains(q) ||
            g.name.toLowerCase().contains(q))
        .toList();
  }

  /// 构建一个分类区块（编辑类/读取类/其他），返回标题行 + 匹配的复选框行
  List<Widget> _buildKindSection({
    required List<PermissionGroup> groups,
    required String kind,
    required String query,
    required Set<String> selected,
    required StateSetter setSt,
    required Widget Function(PermissionGroup, StateSetter) rowBuilder,
  }) {
    final list = _filtered(groups, query)
        .where((g) => g.kind == kind)
        .toList();
    if (list.isEmpty) return const [];
    final kindColor =
        kind == '编辑类' ? Ios.orange : (kind == '读取类' ? Ios.blue : Ios.gray);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kindColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$kind（${list.length}）',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: kindColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                  height: 1, color: const Color(0x14000000)),
            ),
          ],
        ),
      ),
      for (final g in list) rowBuilder(g, setSt),
    ];
  }

  /// 一次性显示新令牌密钥（带复制）
  void _showSecret(BuildContext context, String name, String? secret) {
    if (secret == null || secret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('令牌已创建，但 Cloudflare 未返回密钥，请用「重新生成」获取')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              gradient: Ios.glassGradient,
              borderRadius: BorderRadius.circular(Ios.radius),
              border: Border.all(color: Ios.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Ios.cardShadow,
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Ios.radius),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const IosIconBadge(
                            icon: Icons.key_rounded, color: Ios.green,
                            size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '「$name」创建成功',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                '请立即复制保存，密钥只显示这一次',
                                style: TextStyle(
                                    fontSize: 12, color: Ios.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Ios.fill,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Ios.blue.withValues(alpha: 0.3)),
                      ),
                      child: SelectableText(
                        secret,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
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
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: secret));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('已复制到剪贴板')),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('复制密钥',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Ios.fill,
                                foregroundColor: Ios.gray,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(Ios.radius),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('我已保存好',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
