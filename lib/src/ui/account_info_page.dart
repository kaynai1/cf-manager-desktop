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
      appBar: AppBar(title: const Text('账号信息')),
      body: AsyncView<Map<String, dynamic>>(
        value: ref.watch(accountInfoProvider(accountId)),
        builder: (d) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            const IosSectionHeader('账号'),
            IosCard(
              children: [
                IosRow(title: '名称', value: '${d['name'] ?? ''}'),
                IosRow(title: 'ID', value: '${d['id'] ?? ''}'),
                IosRow(title: '类型', value: '${d['type'] ?? ''}'),
                IosRow(
                    title: '创建时间', value: '${d['created_on'] ?? ''}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
