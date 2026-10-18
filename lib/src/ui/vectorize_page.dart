import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class VectorizePage extends ConsumerWidget {
  final String accountId;
  const VectorizePage({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vectorize'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(vectorizeProvider(accountId)),
          ),
        ],
      ),
      body: AsyncView<List<VectorizeIndex>>(
        value: ref.watch(vectorizeProvider(accountId)),
        builder: (list) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            IosSectionHeader('索引（${list.length}）'),
            IosCard(
              children: [
                if (list.isEmpty) const IosRow(title: '暂无索引'),
                for (final v in list)
                  IosRow(
                    leading: const IosIconBadge(
                        icon: Icons.scatter_plot, color: Ios.teal),
                    title: v.name,
                    value: v.vectors?.toString(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
