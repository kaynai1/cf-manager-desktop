import 'package:flutter/material.dart';
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(apiTokensProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Ios.orange,
        foregroundColor: Colors.white,
        onPressed: () => _create(context, ref),
        child: const Icon(Icons.add),
      ),
      body: AsyncView<List<ApiToken>>(
        value: ref.watch(apiTokensProvider),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            IosSectionHeader('令牌（${list.length}）'),
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
                          tooltip: '滚动更新',
                          onPressed: () async {
                            final api = ref.read(apiProvider);
                            if (api == null) return;
                            try {
                              await api.rollApiToken(t.id);
                              ref.invalidate(apiTokensProvider);
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

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final groups = await ref.read(permissionGroupsProvider.future);
    if (!context.mounted) return;
    final name = TextEditingController();
    String? groupId = groups.isNotEmpty ? groups.first.id : null;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text(
                          '权限组（${groups.length} 个可选）',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Ios.gray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 320),
                          decoration: BoxDecoration(
                            color: Ios.fill,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: groups.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('加载中…',
                                      style:
                                          TextStyle(color: Ios.gray)),
                                )
                              : Scrollbar(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: groups.length,
                                    itemBuilder: (c, i) {
                                      final g = groups[i];
                                      final selected = g.id == groupId;
                                      return InkWell(
                                        onTap: () =>
                                            setSt(() => groupId = g.id),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? Ios.blue
                                                    .withValues(alpha: 0.12)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: selected
                                                  ? Ios.blue
                                                      .withValues(alpha: 0.4)
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                selected
                                                    ? Icons
                                                        .radio_button_checked
                                                    : Icons
                                                        .radio_button_unchecked,
                                                size: 18,
                                                color: selected
                                                    ? Ios.blue
                                                    : Ios.gray,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  g.localName,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: selected
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                    color: selected
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
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
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
                                height: 48,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Ios.orange,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(Ios.radius),
                                    ),
                                  ),
                                  onPressed: (name.text.trim().isEmpty ||
                                          groupId == null)
                                      ? null
                                      : () => Navigator.pop(ctx, true),
                                  child: const Text('创建令牌',
                                      style: TextStyle(
                                          fontSize: 15,
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
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && groupId != null) {
      final api = ref.read(apiProvider);
      if (api == null) return;
      try {
        await api.createApiToken(name.text.trim(), groupId!);
        ref.invalidate(apiTokensProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }
}
