import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'dns_edit_page.dart';
import 'ios.dart';

class DnsPage extends ConsumerWidget {
  final Zone zone;
  const DnsPage({super.key, required this.zone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DNS · ${zone.name}'),
        actions: [
          IosPageAction(
            label: '添加记录',
            icon: Icons.add,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DnsEditPage(zone: zone)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => ref.invalidate(dnsProvider(zone.id)),
          ),
        ],
      ),
      body: AsyncView<List<DnsRecord>>(
        value: ref.watch(dnsProvider(zone.id)),
        builder: (records) {
          final proxied =
              records.where((r) => r.proxied).length;
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              CfPageHeader(
                title: 'DNS 记录',
                subtitle: '共 ${records.length} 条 · $proxied 条已开启橙云代理 · 点击行编辑',
              ),
              CfTable(
                columns: const ['类型', '名称', '内容', '代理状态', ''],
                emptyState: const CfEmptyState(
                  icon: Icons.dns_outlined,
                  title: '还没有 DNS 记录',
                  hint: '点击右上角「添加记录」，为你的域名创建第一条解析。',
                ),
                rows: [
                  for (final r in records)
                    [
                      // 类型
                      CfTable.cellOf(CfPill(
                          r.type,
                          r.type == 'A'
                              ? Ios.blue
                              : r.type == 'AAAA'
                                  ? Ios.teal
                                  : r.type == 'CNAME'
                                      ? Ios.purple
                                      : r.type == 'MX'
                                          ? Ios.green
                                          : Ios.gray)),
                      // 名称
                      CfTable.cellOf(Text(
                        r.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      )),
                      // 内容
                      CfTable.cellOf(Text(
                        r.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: Colors.black87),
                      )),
                      // 代理状态
                      CfTable.cellOf(r.proxied
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud,
                                    size: 14, color: Ios.orange),
                                const SizedBox(width: 5),
                                const Text('已代理',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Ios.orange)),
                              ],
                            )
                          : const Text('仅 DNS',
                              style:
                                  TextStyle(fontSize: 12, color: Ios.gray))),
                      // 操作
                      CfTable.cellOf(Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 17, color: Ios.gray),
                          tooltip: '编辑',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DnsEditPage(zone: zone, record: r),
                            ),
                          ),
                        ),
                      )),
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
