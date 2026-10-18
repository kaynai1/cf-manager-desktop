import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class TurnstilePage extends ConsumerWidget {
  final String accountId;
  const TurnstilePage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turnstile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(turnstileProvider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<TurnstileWidget>>(
        value: ref.watch(turnstileProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('站点（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无 Turnstile 站点'),
                for (final w in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.verified, color: Ios.orange),
                    title: w.name ?? w.sitekey,
                    subtitle: w.domain,
                    value: w.sitekey,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Ios.red, size: 20),
                      onPressed: () async {
                        final api = ref.read(apiProvider);
                        if (api == null) return;
                        try {
                          await api.deleteTurnstile(accountId, w.sitekey);
                          ref.invalidate(turnstileProvider(accountId));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('$e')));
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
