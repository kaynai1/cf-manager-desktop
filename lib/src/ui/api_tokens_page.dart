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
      appBar: AppBar(
        title: const Text('API 令牌'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Ios.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _create(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('创建令牌',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.invalidate(apiTokensProvider),
          ),
        ],
      ),
      body: AsyncView<List<ApiToken>>(
        value: ref.watch(apiTokensProvider),
        builder: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
              child: Text(
                '令牌共 ${list.length} 个 · 权限组可多选 · 密钥仅在创建时显示一次',
                style: const TextStyle(fontSize: 13, color: Ios.gray),
              ),
            ),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无令牌'),
                for (final t in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.vpn_key, color: Ios.orange),
                    title: t.name,
                    subtitle: t.createdOn,
                    value: t.status,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Ios.blue, size: 20),
                          tooltip: '重新生成密钥',
                          onPressed: () async {
                            final api = ref.read(apiProvider);
                            if (api == null) return;
                            try {
                              final secret =
                                  await api.rollApiToken(t.id);
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
                              color: Ios.red, size: 20),
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
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 创建令牌：多选权限组对话框
  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final groups = await ref.read(permissionGroupsProvider.future);
    if (!context.mounted) return;
    final name = TextEditingController();
    // 默认勾选：域名读取 + DNS 编辑（最常用组合）
    final selected = <String>{
      for (final g in groups)
        if (g.name == 'Zone Read' || g.name == 'DNS Edit') g.id,
    };
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
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
                              icon: Icons.vpn_key, color: Ios.orange,
                              size: 36),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '创建 API 令牌',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: name,
                        autofocus: true,
                        onChanged: (_) => setSt(() {}),
                        decoration: InputDecoration(
                          labelText: '令牌名称',
                          hintText: '例如 my-token',
                          filled: true,
                          fillColor: Ios.fill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '权限组（已选 ${selected.length} / ${groups.length}，可多选）',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Ios.gray,
                              ),
                            ),
                          ),
                          if (selected.isNotEmpty)
                            TextButton(
                              onPressed: () => setSt(() => selected.clear()),
                              child: const Text('清空',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          TextButton(
                            onPressed: () => setSt(
                              () => selected.addAll(
                                groups.map((g) => g.id),
                              ),
                            ),
                            child: const Text('全选',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Container(
                          constraints:
                              const BoxConstraints(maxHeight: 340),
                          decoration: BoxDecoration(
                            color: Ios.fill,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: groups.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('权限组加载中…',
                                      style:
                                          TextStyle(color: Ios.gray)),
                                )
                              : Scrollbar(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: groups.length,
                                    itemBuilder: (c, i) {
                                      final g = groups[i];
                                      final on = selected.contains(g.id);
                                      return InkWell(
                                        onTap: () => setSt(() => on
                                            ? selected.remove(g.id)
                                            : selected.add(g.id)),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Container(
                                          margin:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: on
                                                ? Ios.blue
                                                    .withValues(alpha: 0.10)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              AnimatedScale(
                                                scale: on ? 1.0 : 0.85,
                                                duration: const Duration(
                                                    milliseconds: 150),
                                                child: Icon(
                                                  on
                                                      ? Icons
                                                          .check_box_rounded
                                                      : Icons
                                                          .check_box_outline_blank_rounded,
                                                  size: 20,
                                                  color: on
                                                      ? Ios.blue
                                                      : Ios.gray,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  g.localName,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: on
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                    color: on
                                                        ? Ios.blue
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
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
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('取消',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 46,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Ios.orange,
                                  disabledBackgroundColor:
                                      Ios.orange.withValues(alpha: 0.4),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(Ios.radius),
                                  ),
                                ),
                                onPressed: (name.text.trim().isEmpty ||
                                        selected.isEmpty)
                                    ? null
                                    : () => Navigator.pop(ctx, true),
                                child: Text(
                                    '创建令牌（${selected.length} 项权限）',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
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
