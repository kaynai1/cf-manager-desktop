import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class TunnelsPage extends ConsumerWidget {
  final String accountId;
  const TunnelsPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AsyncView<List<CftTunnel>>(
        value: ref.watch(tunnelsProvider(accountId)),
        builder: (list) {
          final healthy = list.where((t) => t.healthy).length;
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              CfPageHeader(
                title: 'Cloudflare Tunnel',
                subtitle: '将本地服务安全映射到公网，无需开端口。'
                    '当前 $healthy / ${list.length} 条已连接。',
                actions: [
                  IosPageAction(
                    label: '新建通道',
                    icon: Icons.add,
                    onPressed: () => _create(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: '刷新',
                    onPressed: () =>
                        ref.invalidate(tunnelsProvider(accountId)),
                  ),
                ],
              ),
              CfTable(
                columns: const ['通道', '状态', '活跃连接', '创建时间', ''],
                emptyState: const CfEmptyState(
                  icon: Icons.route_outlined,
                  title: '还没有 Tunnel',
                  hint: '点击右上角「新建通道」，然后按启动命令在本地运行 cloudflared。',
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
                      CfTable.cellOf(t.healthy
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 8, color: Ios.green),
                                SizedBox(width: 6),
                                Text('已连接',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Ios.green)),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle,
                                    size: 8,
                                    color: (t.connectionState == 'degraded')
                                        ? Ios.orange
                                        : Ios.gray),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    t.connectionState == 'degraded'
                                        ? '降级'
                                        : (t.connectionState ?? '未连接'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: Ios.gray),
                                  ),
                                ),
                              ],
                            )),
                      CfTable.cellOf(Text('${t.connectionsActive ?? 0}',
                          style: const TextStyle(
                              fontSize: 12, color: Ios.gray))),
                      CfTable.cellOf(Text(
                        t.createdAt?.substring(0, 10) ?? '—',
                        style:
                            const TextStyle(fontSize: 12, color: Ios.gray),
                      )),
                      CfTable.cellOf(Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.terminal_outlined,
                                  size: 17, color: Ios.blue),
                              tooltip: '启动命令',
                              onPressed: () => _showRun(context, t),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 17, color: Ios.red),
                              tooltip: '删除',
                              onPressed: () => _delete(context, ref, t),
                            ),
                          ],
                        ),
                      )),
                    ],
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '提示：Tunnel 创建后需在本地下载 cloudflared 并登录运行，'
                  '它才会真正变成"已连接"。'
                  '点击行右侧的终端图标可查看启动命令。',
                  style: TextStyle(fontSize: 12, color: Ios.gray, height: 1.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建 Tunnel'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '名称',
            hintText: '例如 my-tunnel',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final api = ref.read(apiProvider);
    if (api == null) return;
    try {
      await api.createTunnel(accountId, name);
      ref.invalidate(tunnelsProvider(accountId));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已创建，可查看启动命令')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, CftTunnel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除 Tunnel'),
        content: Text('确定删除通道「${t.name}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Ios.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final api = ref.read(apiProvider);
    if (api == null) return;
    try {
      await api.deleteTunnel(accountId, t.id);
      ref.invalidate(tunnelsProvider(accountId));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已删除')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _showRun(BuildContext context, CftTunnel t) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('启动命令'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('1. 下载 cloudflared：\n'
                  '   Windows:  cloudflared-windows-amd64.exe\n'
                  '   macOS:    cloudflared (brew install cloudflared)',
                  style: TextStyle(fontSize: 13, height: 1.6)),
              const SizedBox(height: 8),
              const Text('2. 登录到你的账号：',
                  style: TextStyle(fontSize: 13, color: Ios.gray)),
              SelectableText('cloudflared tunnel login',
                  style: const TextStyle(
                      fontSize: 13, fontFamily: 'monospace',
                      color: Ios.blue)),
              const SizedBox(height: 8),
              const Text('3. 用 token 运行这条通道后即可连接：',
                  style: TextStyle(fontSize: 13, color: Ios.gray)),
              SelectableText('cloudflared tunnel run ${t.id}',
                  style: const TextStyle(
                      fontSize: 13, fontFamily: 'monospace',
                      color: Ios.blue)),
              const SizedBox(height: 8),
              Text('通道名称：${t.name}',
                  style: const TextStyle(fontSize: 13, color: Ios.gray)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}