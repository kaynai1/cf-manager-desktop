import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class MembersPage extends ConsumerWidget {
  final String accountId;
  const MembersPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AsyncView<List<Member>>(
        value: ref.watch(membersProvider(accountId)),
        builder: (list) {
          final active = list.where((m) => m.status == 'active').length;
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              CfPageHeader(
                title: '账户成员',
                subtitle: '共 ${list.length} 位成员 · $active 位已激活',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: '刷新',
                    onPressed: () =>
                        ref.invalidate(membersProvider(accountId)),
                  ),
                ],
              ),
              CfTable(
                columns: const ['成员', '状态', '成员 ID'],
                emptyState: const CfEmptyState(
                  icon: Icons.people_outline,
                  title: '暂无成员',
                  hint: '当前账户下没有其他成员，所有者即是你自己。',
                ),
                rows: [
                  for (final m in list)
                    [
                      CfTable.cellOf(Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: Ios.purple.withValues(alpha: 0.15),
                            child: const Icon(Icons.person,
                                size: 15, color: Ios.purple),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              m.email ?? m.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      )),
                      CfTable.cellOf(CfPill(
                          m.status == 'active' ? '已激活' : (m.status ?? '未知'),
                          m.status == 'active'
                              ? Ios.green
                              : (m.status == 'invited'
                                  ? Ios.orange
                                  : Ios.gray))),
                      CfTable.cellOf(Text(m.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Ios.gray))),
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
