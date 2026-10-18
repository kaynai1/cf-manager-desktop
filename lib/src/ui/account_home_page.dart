import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'account_info_page.dart';
import 'access_page.dart';
import 'ai_gateway_page.dart';
import 'api_tokens_page.dart';
import 'd1_page.dart';
import 'do_page.dart';
import 'ios.dart';
import 'kv_page.dart';
import 'members_page.dart';
import 'pages_page.dart';
import 'queues_page.dart';
import 'r2_page.dart';
import 'turnstile_page.dart';
import 'vectorize_page.dart';
import 'workers_page.dart';
import 'zone_list_page.dart';

class AccountHomePage extends ConsumerWidget {
  const AccountHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountsProvider).selected;
    final accountId = account?.accountId;

    void go(Widget page) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );

    void goId(Widget Function(String id) builder) {
      if (accountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先在「编辑账号」里填写 Account ID')),
        );
        return;
      }
      go(builder(accountId));
    }

    return Scaffold(
      appBar: AppBar(title: Text(account?.name ?? 'Cloudflare')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const IosSectionHeader('域名'),
          IosCard(
            children: [
              IosRow(
                leading: const IosIconBadge(icon: Icons.public, color: Ios.blue),
                title: '域名（Zones）',
                subtitle: 'DNS · 设置 · 规则 · 安全 · 分析',
                chevron: true,
                onTap: () => go(const ZoneListPage()),
              ),
            ],
          ),
          const IosSectionHeader('开发者平台'),
          IosCard(
            children: [
              IosRow(
                leading: const IosIconBadge(icon: Icons.bolt, color: Ios.orange),
                title: 'Workers',
                chevron: true,
                onTap: () => goId((id) => WorkersPage(accountId: id)),
              ),
              IosRow(
                leading:
                    const IosIconBadge(icon: Icons.key, color: Ios.purple),
                title: 'Workers KV',
                chevron: true,
                onTap: () => goId((id) => KvPage(accountId: id)),
              ),
              IosRow(
                leading: const IosIconBadge(icon: Icons.storage, color: Ios.blue),
                title: 'D1 数据库',
                chevron: true,
                onTap: () => goId((id) => D1Page(accountId: id)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.inventory_2, color: Ios.teal),
                title: 'R2 对象存储',
                chevron: true,
                onTap: () => goId((id) => R2Page(accountId: id)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.web, color: Ios.orange),
                title: 'Pages',
                chevron: true,
                onTap: () => goId((id) => PagesPage(accountId: id)),
              ),
              IosRow(
                leading:
                    const IosIconBadge(icon: Icons.list, color: Ios.green),
                title: 'Queues',
                chevron: true,
                onTap: () => goId((id) => QueuesPage(accountId: id)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.auto_awesome, color: Ios.purple),
                title: 'AI Gateway',
                chevron: true,
                onTap: () => goId((id) => AiGatewayPage(accountId: id)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.scatter_plot, color: Ios.teal),
                title: 'Vectorize',
                chevron: true,
                onTap: () => goId((id) => VectorizePage(accountId: id)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.memory, color: Ios.gray),
                title: 'Durable Objects',
                chevron: true,
                onTap: () => goId((id) => DoPage(accountId: id)),
              ),
            ],
          ),
          const IosSectionHeader('网络服务'),
          IosCard(
            children: [
              IosRow(
                leading:
                    const IosIconBadge(icon: Icons.verified, color: Ios.orange),
                title: 'Turnstile',
                chevron: true,
                onTap: () => goId((id) => TurnstilePage(accountId: id)),
              ),
              IosRow(
                leading: const IosIconBadge(icon: Icons.lock, color: Ios.green),
                title: 'Zero Trust · Access',
                chevron: true,
                onTap: () => goId((id) => AccessPage(accountId: id)),
              ),
            ],
          ),
          const IosSectionHeader('账号'),
          IosCard(
            children: [
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.badge, color: Ios.blue),
                title: '账号信息',
                chevron: true,
                onTap: () => goId((id) => AccountInfoPage(accountId: id)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.people, color: Ios.purple),
                title: '成员',
                chevron: true,
                onTap: () => goId((id) => MembersPage(accountId: id)),
              ),
              IosRow(
                leading: const IosIconBadge(
                    icon: Icons.vpn_key, color: Ios.orange),
                title: 'API 令牌',
                chevron: true,
                onTap: () => go(const ApiTokensPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
