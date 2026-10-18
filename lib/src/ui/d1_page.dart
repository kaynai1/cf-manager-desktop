import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class D1Page extends ConsumerWidget {
  final String accountId;
  const D1Page({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D1 数据库'),
        actions: [
          IosPageAction(
            label: '新建数据库',
            icon: Icons.add,
            onPressed: () async {
              final name = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('新建数据库'),
                  content: TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '名称'),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('创建')),
                  ],
                ),
              );
              if (ok == true && name.text.trim().isNotEmpty) {
                final api = ref.read(apiProvider);
                if (api == null) return;
                try {
                  await api.createD1(accountId, name.text.trim());
                  ref.invalidate(d1Provider(accountId));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.invalidate(d1Provider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<D1Database>>(
        value: ref.watch(d1Provider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('数据库（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无数据库'),
                for (final db in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.storage, color: Ios.blue),
                    title: db.name,
                    subtitle: '${db.uuid} · ${db.numTables ?? 0} 表',
                    chevron: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            D1QueryPage(accountId: accountId, db: db),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Ios.red, size: 20),
                      onPressed: () async {
                        final api = ref.read(apiProvider);
                        if (api == null) return;
                        try {
                          await api.deleteD1(accountId, db.uuid);
                          ref.invalidate(d1Provider(accountId));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('$e')));
                          }
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

class D1QueryPage extends ConsumerStatefulWidget {
  final String accountId;
  final D1Database db;
  const D1QueryPage({super.key, required this.accountId, required this.db});

  @override
  ConsumerState<D1QueryPage> createState() => _D1QueryPageState();
}

class _D1QueryPageState extends ConsumerState<D1QueryPage> {
  final _sql = TextEditingController(text: 'SELECT 1');
  List<Map<String, dynamic>>? _rows;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _sql.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await api.queryD1(widget.accountId, widget.db.uuid, _sql.text);
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.db.name)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const IosSectionHeader('SQL'),
          IosCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  controller: _sql,
                  maxLines: 4,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'SELECT * FROM ...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: IosButton(
              label: '执行',
              busy: _busy,
              onPressed: _busy ? null : _run,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Ios.red)),
            ),
          if (_rows != null) ...[
            IosSectionHeader('结果（${_rows!.length}）'),
            IosCard(
              children: [
                if (_rows!.isEmpty) const IosRow(title: '无结果'),
                for (final row in _rows!)
                  IosRow(
                    title: row.entries
                        .map((e) => '${e.key}=${e.value}')
                        .join('  '),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
