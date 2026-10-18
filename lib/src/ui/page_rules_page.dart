import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

const _presets = <String, List<Map<String, dynamic>>>{
  '始终使用 HTTPS': [
    {'id': 'always_use_https'}
  ],
  '缓存全部': [
    {'id': 'cache_level', 'value': 'cache_everything'}
  ],
  '绕过缓存': [
    {'id': 'cache_level', 'value': 'bypass'}
  ],
  '关闭安全防护': [
    {'id': 'disable_security'}
  ],
  '浏览器缓存 1 天': [
    {'id': 'browser_cache_ttl', 'value': 86400}
  ],
};

class PageRulesPage extends ConsumerStatefulWidget {
  final Zone zone;
  const PageRulesPage({super.key, required this.zone});

  @override
  ConsumerState<PageRulesPage> createState() => _PageRulesPageState();
}

class _PageRulesPageState extends ConsumerState<PageRulesPage> {
  bool _busy = false;

  Future<void> _add() async {
    final url = TextEditingController();
    String preset = _presets.keys.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('新增 Page Rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: url,
                decoration: const InputDecoration(
                  labelText: 'URL 匹配（如 example.com/*）',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: preset,
                decoration: const InputDecoration(labelText: '动作'),
                items: [
                  for (final k in _presets.keys)
                    DropdownMenuItem(value: k, child: Text(k)),
                ],
                onChanged: (v) => setSt(() => preset = v ?? preset),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && url.text.trim().isNotEmpty) {
      final api = ref.read(apiProvider);
      if (api == null) return;
      setState(() => _busy = true);
      try {
        await api.createPageRule(
            widget.zone.id, url.text.trim(), _presets[preset]!);
        ref.invalidate(pageRulesProvider(widget.zone.id));
      } catch (e) {
        _toast('$e');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Rules'),
        actions: [
          IosPageAction(
            label: '新建规则',
            icon: Icons.add,
            onPressed: _busy ? null : _add,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.invalidate(pageRulesProvider(widget.zone.id)),
          ),
        ],
      ),
      body: AsyncView<List<PageRule>>(
        value: ref.watch(pageRulesProvider(widget.zone.id)),
        builder: (rules) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('Page Rules（${rules.length}，免费版 3 条）'),
            IosCard(
              children: [
                if (rules.isEmpty) const IosRow(title: '暂无规则'),
                for (final r in rules)
                  IosRow(
                    leading: IosIconBadge(
                      icon: Icons.rule,
                      color: r.status == 'active' ? Ios.green : Ios.gray,
                    ),
                    title: r.target,
                    subtitle: r.actions
                        .map((a) => '${a['id']}')
                        .join(', '),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Ios.red, size: 20),
                      onPressed: () async {
                        final api = ref.read(apiProvider);
                        if (api == null) return;
                        try {
                          await api.deletePageRule(widget.zone.id, r.id);
                          ref.invalidate(pageRulesProvider(widget.zone.id));
                        } catch (e) {
                          _toast('$e');
                        }
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
