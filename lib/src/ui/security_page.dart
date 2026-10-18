import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class SecurityPage extends ConsumerStatefulWidget {
  final Zone zone;
  final String? accountId;
  const SecurityPage({super.key, required this.zone, this.accountId});

  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  bool _busy = false;

  Future<void> _addAccessRule() async {
    if (widget.accountId == null) return;
    String mode = 'block';
    String target = 'ip';
    final value = TextEditingController();
    final notes = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => CfDialog(
          title: '新增访问规则',
          subtitle: '按 IP / IP 段 / ASN / 国家匹配后执行安全动作',
          confirmLabel: '创建',
          onConfirm: () => Navigator.pop(ctx, true),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: mode,
                decoration: const InputDecoration(labelText: '动作'),
                items: const [
                  DropdownMenuItem(value: 'block', child: Text('阻止')),
                  DropdownMenuItem(value: 'challenge', child: Text('质询')),
                  DropdownMenuItem(value: 'whitelist', child: Text('白名单')),
                  DropdownMenuItem(
                      value: 'js_challenge', child: Text('JS 质询')),
                  DropdownMenuItem(
                      value: 'managed_challenge', child: Text('托管质询')),
                ],
                onChanged: (v) => setSt(() => mode = v ?? mode),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: target,
                decoration: const InputDecoration(labelText: '匹配类型'),
                items: const [
                  DropdownMenuItem(value: 'ip', child: Text('IP')),
                  DropdownMenuItem(value: 'ip_range', child: Text('IP 段')),
                  DropdownMenuItem(value: 'asn', child: Text('ASN')),
                  DropdownMenuItem(value: 'country', child: Text('国家')),
                ],
                onChanged: (v) => setSt(() => target = v ?? target),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: value,
                style: Ios.mono.copyWith(fontSize: 13.5),
                decoration: const InputDecoration(
                  labelText: '匹配值',
                  hintText: '例如 1.2.3.4 或 1.2.3.0/24',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notes,
                decoration: const InputDecoration(
                    labelText: '备注（可选）', hintText: '例如 恶意扫描'),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true && value.text.trim().isNotEmpty) {
      final api = ref.read(apiProvider);
      if (api == null) return;
      setState(() => _busy = true);
      try {
        await api.createAccessRule(
          widget.accountId!,
          mode: mode,
          target: target,
          value: value.text.trim(),
          notes: notes.text.trim(),
        );
        ref.invalidate(accessRulesProvider(widget.accountId!));
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
    final accountId = widget.accountId;
    return Scaffold(
      appBar: AppBar(title: const Text('安全')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          IosSectionHeader('IP 访问规则${accountId == null ? '（需 Account ID）' : ''}'),
          if (accountId != null)
            AsyncView<List<AccessRule>>(
              value: ref.watch(accessRulesProvider(accountId)),
              builder: (rules) => IosCard(
                children: [
                  if (rules.isEmpty) const IosRow(title: '暂无规则'),
                  for (final r in rules)
                    IosRow(
                      leading: IosIconBadge(
                        icon: Icons.block,
                        color: r.mode == 'whitelist' ? Ios.green : Ios.red,
                      ),
                      title: '${r.mode} · ${r.target}',
                      subtitle: r.value,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Ios.red, size: 20),
                        onPressed: () async {
                          final api = ref.read(apiProvider);
                          if (api == null) return;
                          try {
                            await api.deleteAccessRule(accountId, r.id);
                            ref.invalidate(accessRulesProvider(accountId));
                          } catch (e) {
                            _toast('$e');
                          }
                        },
                      ),
                    ),
                ],
              ),
            )
          else
            const IosCard(children: [IosRow(title: '未配置 Account ID')]),
          if (accountId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: IosButton(
                label: '新增访问规则',
                secondary: true,
                icon: Icons.add,
                onPressed: _busy ? null : _addAccessRule,
              ),
            ),

          const IosSectionHeader('速率限制（免费版 1 条）'),
          AsyncView<List<RateLimit>>(
            value: ref.watch(rateLimitsProvider(widget.zone.id)),
            builder: (list) => IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无速率限制规则'),
                for (final r in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.speed, color: Ios.orange),
                    title: r.description ?? r.id,
                    value: r.disabled ? '停用' : '启用',
                  ),
              ],
            ),
          ),

          const IosSectionHeader('安全事件（最近 50 条）'),
          AsyncView<List<SecurityEvent>>(
            value: ref.watch(securityEventsProvider(widget.zone.id)),
            builder: (list) => IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无安全事件'),
                for (final e in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.shield, color: Ios.red),
                    title: '${e.action} · ${e.source}',
                    subtitle: e.ip,
                    value: e.when,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
