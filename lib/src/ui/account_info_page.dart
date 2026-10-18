import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'ios.dart';

class AccountInfoPage extends ConsumerWidget {
  final String accountId;
  const AccountInfoPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AsyncView<Map<String, dynamic>>(
        value: ref.watch(accountInfoProvider(accountId)),
        builder: (d) {
          final isLight = Theme.of(context).brightness == Brightness.light;
          final name = '${d['name'] ?? ''}';
          final created = '${d['created_on'] ?? ''}';
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              CfPageHeader(
                title: name.isEmpty ? '账户' : name,
                subtitle: 'Account ID 即下面这串，配置 Workers 系列功能时会用到。',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: '刷新',
                    onPressed: () =>
                        ref.invalidate(accountInfoProvider(accountId)),
                  ),
                ],
              ),
              // 统计卡（官网式：关键数字）
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLight
                          ? [const Color(0xFFE9F0FC), const Color(0xFFF5F8FE)]
                          : [const Color(0xFF182742), const Color(0xFF121C2E)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Ios.blue.withValues(alpha: isLight ? 0.12 : 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Ios.blue, Color(0xFF5B8DEF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.badge,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              accountId,
                              style: Ios.mono.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isLight
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('Account ID（点击可选中复制）',
                                style: TextStyle(
                                    fontSize: 11, color: Ios.gray)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CfTable(
                columns: const ['属性', '值'],
                rows: [
                  [
                    CfTable.cellOf(const Text('名称',
                        style: TextStyle(fontSize: 12, color: Ios.gray))),
                    CfTable.cellOf(Text(name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600))),
                  ],
                  [
                    CfTable.cellOf(const Text('类型',
                        style: TextStyle(fontSize: 12, color: Ios.gray))),
                    CfTable.cellOf(CfPill('${d['type'] ?? 'user'}', Ios.blue)),
                  ],
                  [
                    CfTable.cellOf(const Text('创建时间',
                        style: TextStyle(fontSize: 12, color: Ios.gray))),
                    CfTable.cellOf(Text(created,
                        style: const TextStyle(fontSize: 13))),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
