import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

class ZoneCachePage extends ConsumerStatefulWidget {
  final Zone zone;
  const ZoneCachePage({super.key, required this.zone});

  @override
  ConsumerState<ZoneCachePage> createState() => _ZoneCachePageState();
}

class _ZoneCachePageState extends ConsumerState<ZoneCachePage> {
  final _urls = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _urls.dispose();
    super.dispose();
  }

  Future<void> _purge({bool everything = false, List<String>? files}) async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    setState(() => _busy = true);
    try {
      await api.purgeCache(widget.zone.id,
          everything: everything, files: files);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已提交清除')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('缓存')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const IosSectionHeader('清除缓存'),
          IosCard(
            children: [
              IosRow(
                leading:
                    const IosIconBadge(icon: Icons.delete_sweep, color: Ios.red),
                title: '清除全部缓存',
                chevron: true,
                onTap: _busy ? null : () => _purge(everything: true),
              ),
            ],
          ),
          const IosSectionHeader('按 URL 清除'),
          IosCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  controller: _urls,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '每行一个 URL，例如：\nhttps://${widget.zone.name}/a.png',
                    filled: true,
                    isDense: true,
                    fillColor: Theme.of(context).brightness == Brightness.light
                        ? Ios.fill
                        : Ios.fillDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: IosButton(
              label: '按 URL 清除',
              busy: _busy,
              onPressed: _busy
                  ? null
                  : () {
                      final files = _urls.text
                          .split(RegExp(r'[\n,]+'))
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      if (files.isEmpty) return;
                      _purge(files: files);
                    },
            ),
          ),
        ],
      ),
    );
  }
}
