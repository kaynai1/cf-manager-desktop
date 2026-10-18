import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class DnsEditPage extends ConsumerStatefulWidget {
  final Zone zone;
  final DnsRecord? record;
  const DnsEditPage({super.key, required this.zone, this.record});

  @override
  ConsumerState<DnsEditPage> createState() => _DnsEditPageState();
}

class _DnsEditPageState extends ConsumerState<DnsEditPage> {
  static const _types = ['A', 'AAAA', 'CNAME', 'TXT', 'MX', 'NS', 'SRV', 'CAA'];
  static const _ttls = [1, 60, 120, 300, 600, 1800, 3600, 86400];

  final _name = TextEditingController();
  final _content = TextEditingController();
  final _priority = TextEditingController();

  String _type = 'A';
  int _ttl = 1;
  bool _proxied = false;
  bool _busy = false;

  bool get isEdit => widget.record != null;
  bool get _proxyable => _type == 'A' || _type == 'AAAA' || _type == 'CNAME';

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    if (r != null) {
      _type = r.type;
      _name.text = r.name;
      _content.text = r.content;
      _ttl = r.ttl;
      _proxied = r.proxied;
      _priority.text = r.priority?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _content.dispose();
    _priority.dispose();
    super.dispose();
  }

  DnsRecord _build() => DnsRecord(
        id: widget.record?.id ?? '',
        type: _type,
        name: _name.text.trim(),
        content: _content.text.trim(),
        proxied: _proxyable && _proxied,
        ttl: _ttl,
        priority: _type == 'MX' ? int.tryParse(_priority.text.trim()) : null,
      );

  Future<void> _save() async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    final rec = _build();
    if (rec.name.isEmpty || rec.content.isEmpty) {
      _toast('请填写名称和内容');
      return;
    }
    setState(() => _busy = true);
    try {
      if (isEdit) {
        await api.updateDns(widget.zone.id, widget.record!.id, rec);
      } else {
        await api.createDns(widget.zone.id, rec);
      }
      ref.invalidate(dnsProvider(widget.zone.id));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    setState(() => _busy = true);
    try {
      await api.deleteDns(widget.zone.id, widget.record!.id);
      ref.invalidate(dnsProvider(widget.zone.id));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑记录' : '新增记录')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const IosSectionHeader('记录'),
          IosCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: '类型',
                    border: InputBorder.none,
                  ),
                  items: [
                    for (final t in _types)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'A'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: '名称（如 @ 或 www）',
                    border: InputBorder.none,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _content,
                  decoration: const InputDecoration(
                    labelText: '内容（IP / 目标 / 文本）',
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_type == 'MX')
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _priority,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '优先级',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<int>(
                  initialValue: _ttl,
                  decoration: const InputDecoration(
                    labelText: 'TTL',
                    border: InputBorder.none,
                  ),
                  items: [
                    for (final t in _ttls)
                      DropdownMenuItem(
                        value: t,
                        child: Text(t == 1 ? '自动' : '$t 秒'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _ttl = v ?? 1),
                ),
              ),
              if (_proxyable)
                SwitchListTile(
                  value: _proxied,
                  activeTrackColor: Ios.orange,
                  title: const Text('代理（Proxied）'),
                  onChanged: (v) => setState(() => _proxied = v),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: IosButton(
              label: '保存',
              busy: _busy,
              onPressed: _busy ? null : _save,
            ),
          ),
          if (isEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: IosButton(
                label: '删除记录',
                secondary: true,
                onPressed: _busy ? null : _delete,
              ),
            ),
        ],
      ),
    );
  }
}
