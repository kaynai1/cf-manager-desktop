import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class AiGatewayPage extends ConsumerWidget {
  final String accountId;
  const AiGatewayPage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Gateway'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(aiGatewaysProvider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<AiGateway>>(
        value: ref.watch(aiGatewaysProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('网关（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无网关'),
                for (final g in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.auto_awesome, color: Ios.purple),
                    title: g.id,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
