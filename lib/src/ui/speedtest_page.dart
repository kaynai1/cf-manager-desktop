import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../activity.dart';
import 'ios.dart';

/// Cloudflare 官方 IPv4 段（https://www.cloudflare.com/ips-v4/）
const _cfRanges = <String>[
  '173.245.48.0/20',
  '103.21.244.0/22',
  '103.22.200.0/22',
  '103.31.4.0/22',
  '141.101.64.0/18',
  '108.162.192.0/18',
  '190.93.240.0/20',
  '188.114.96.0/20',
  '197.234.240.0/22',
  '198.41.128.0/17',
  '162.158.0.0/15',
  '104.16.0.0/13',
  '104.24.0.0/14',
  '172.64.0.0/13',
  '131.0.72.0/22',
];

class _Result {
  final String ip;
  final String range;
  final int sent;
  final int ok;
  final double avgMs;
  const _Result(this.ip, this.range, this.sent, this.ok, this.avgMs);
  double get loss => sent == 0 ? 1 : (sent - ok) / sent;
}

/// 优选 IP：在本机测试 Cloudflare 各 IP 段的 TCP 延迟与丢包，挑出最快的。
class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  int _perRange = 8;
  int _port = 443;
  bool _running = false;
  bool _cancel = false;
  int _done = 0;
  int _total = 0;
  final List<_Result> _results = [];

  List<String> _sample(String cidr, int n, Random rnd) {
    final parts = cidr.split('/');
    final oct = parts[0].split('.').map(int.parse).toList();
    final bits = int.parse(parts[1]);
    final base = (oct[0] << 24) | (oct[1] << 16) | (oct[2] << 8) | oct[3];
    final size = 1 << (32 - bits);
    final out = <String>{};
    var guard = 0;
    while (out.length < n && guard < n * 10) {
      guard++;
      final off = 1 + rnd.nextInt(max(1, size - 2));
      final v = base + off;
      if ((v & 0xFF) == 0 || (v & 0xFF) == 255) continue;
      out.add('${(v >> 24) & 0xFF}.${(v >> 16) & 0xFF}.${(v >> 8) & 0xFF}.${v & 0xFF}');
    }
    return out.toList();
  }

  Future<_Result> _probe(String ip, String range) async {
    const tries = 4;
    var ok = 0;
    var sum = 0;
    for (var i = 0; i < tries; i++) {
      if (_cancel) break;
      final sw = Stopwatch()..start();
      try {
        final s = await Socket.connect(ip, _port,
            timeout: const Duration(milliseconds: 1000));
        sw.stop();
        s.destroy();
        ok++;
        sum += sw.elapsedMilliseconds;
      } catch (_) {
        // 超时 / 拒绝 记为丢包
      }
    }
    return _Result(ip, range, tries, ok, ok == 0 ? 9999 : sum / ok);
  }

  Future<void> _start() async {
    final rnd = Random();
    final jobs = <(String, String)>[];
    for (final r in _cfRanges) {
      for (final ip in _sample(r, _perRange, rnd)) {
        jobs.add((ip, r));
      }
    }
    setState(() {
      _running = true;
      _cancel = false;
      _results.clear();
      _done = 0;
      _total = jobs.length;
    });
    ActivityLog.instance.add('开始优选 IP 测速（${jobs.length} 个）', kind: 'info');

    var idx = 0;
    Future<void> worker() async {
      while (!_cancel) {
        if (idx >= jobs.length) return;
        final j = jobs[idx++];
        final r = await _probe(j.$1, j.$2);
        if (!mounted) return;
        setState(() {
          _done++;
          if (r.ok > 0) _results.add(r);
          _results.sort((a, b) {
            final l = a.loss.compareTo(b.loss);
            return l != 0 ? l : a.avgMs.compareTo(b.avgMs);
          });
        });
      }
    }

    await Future.wait(List.generate(24, (_) => worker()));
    if (!mounted) return;
    setState(() => _running = false);
    if (_results.isNotEmpty) {
      ActivityLog.instance.add(
          '优选完成，最快 ${_results.first.ip} · ${_results.first.avgMs.toStringAsFixed(0)}ms');
    } else {
      ActivityLog.instance.add('优选完成，没有可用 IP', kind: 'fail');
    }
  }

  void _copy(String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _msColor(double ms) => ms < 120
      ? Ios.green
      : ms < 220
          ? const Color(0xFFC75A00)
          : Ios.red;

  @override
  Widget build(BuildContext context) {
    final best = _results.isEmpty ? null : _results.first;
    final top = _results.take(20).toList();
    final avgAll = _results.isEmpty
        ? 0.0
        : _results.map((e) => e.avgMs).reduce((a, b) => a + b) /
            _results.length;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          CfPageHeader(
            title: '优选 IP',
            subtitle: '在本机测试 Cloudflare 各 IP 段的延迟和丢包，找出你网络下最快的节点',
            actions: [
              if (_running)
                CfButton(
                    label: '停止',
                    icon: Icons.stop,
                    onPressed: () => setState(() => _cancel = true))
              else
                CfButton(
                    label: '开始测速',
                    icon: Icons.speed,
                    primary: true,
                    onPressed: _start),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                    child: CfStatTile(
                        label: '最快 IP',
                        value: best?.ip ?? '—',
                        sub: best == null ? '还没测速' : best.range,
                        dot: best == null ? null : Ios.green)),
                const SizedBox(width: 12),
                Expanded(
                    child: CfStatTile(
                        label: '最低延迟',
                        value: best == null
                            ? '—'
                            : best.avgMs.toStringAsFixed(0),
                        suffix: best == null ? null : 'ms',
                        sub: 'TCP $_port 端口握手')),
                const SizedBox(width: 12),
                Expanded(
                    child: CfStatTile(
                        label: '已测试',
                        value: '$_done',
                        suffix: '/ $_total',
                        sub: _running ? '测速中…' : '可用 ${_results.length} 个',
                        dot: _running ? Ios.blue : null)),
                const SizedBox(width: 12),
                Expanded(
                    child: CfStatTile(
                        label: '平均延迟',
                        value: _results.isEmpty
                            ? '—'
                            : avgAll.toStringAsFixed(0),
                        suffix: _results.isEmpty ? null : 'ms',
                        sub: '所有可用 IP')),
              ],
            ),
          ),
          if (_running)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _total == 0 ? null : _done / _total,
                  minHeight: 3,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CfCard(
              title: '测速设置',
              subtitle: '每段抽样越多结果越准，耗时也越长',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    const Text('每个 IP 段抽样', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 10),
                    _Seg(
                      values: const [4, 8, 16, 32],
                      current: _perRange,
                      enabled: !_running,
                      onChanged: (v) => setState(() => _perRange = v),
                    ),
                    const SizedBox(width: 24),
                    const Text('端口', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 10),
                    _Seg(
                      values: const [443, 80, 2053, 8443],
                      current: _port,
                      enabled: !_running,
                      onChanged: (v) => setState(() => _port = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CfCard(
              title: '测速结果',
              subtitle: '按丢包率、延迟排序 · 只显示前 20 个',
              actions: [
                Text('${_results.length} 个',
                    style: const TextStyle(fontSize: 12, color: Ios.gray)),
                CfButton(
                  label: '复制前 10 个',
                  icon: Icons.copy,
                  onPressed: _results.isEmpty
                      ? null
                      : () => _copy(
                          _results.take(10).map((e) => e.ip).join('\n'),
                          '已复制 ${min(10, _results.length)} 个 IP'),
                ),
              ],
              child: top.isEmpty
                  ? CfEmptyState(
                      icon: Icons.speed,
                      title: _running ? '正在测速…' : '暂无测速结果',
                      hint: '点右上角「开始测速」，大约需要 10–60 秒。\n测速在你这台电脑上进行，结果只代表当前网络。',
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < top.length; i++)
                          _row(i, top[i]),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CfCard(
              title: '怎么用优选 IP',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: const Text(
                  '1. 访问用的域名放在 DNSPod / 阿里云等国内 DNS（不能是 Cloudflare 托管的橙色云）。\n'
                  '2. 在 Cloudflare 的「自定义主机名」(Cloudflare for SaaS) 里添加这个域名，回源指向你的 Tunnel 域名。\n'
                  '3. 在国内 DNS 把这个域名的 A 记录指向上面测出来的 IP，建议填 2–3 个。\n'
                  '注意：优选只改善「访问者 → Cloudflare」这一段；NAS 到 Cloudflare 的隧道仍然走海外，大文件传输提升有限。',
                  style: TextStyle(fontSize: 12.5, height: 1.7, color: Ios.gray),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(int i, _Result r) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Ios.sepOf(context))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text('${i + 1}',
                style: const TextStyle(fontSize: 12, color: Ios.mute)),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.ip, style: Ios.mono.copyWith(fontWeight: FontWeight.w600)),
                Text(r.range,
                    style: const TextStyle(fontSize: 11, color: Ios.mute)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: r.loss == 0
                ? const CfPill('无丢包', Ios.green)
                : CfPill('丢包 ${(r.loss * 100).toStringAsFixed(0)}%',
                    const Color(0xFFC75A00)),
          ),
          Text('${r.avgMs.toStringAsFixed(0)} ms',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _msColor(r.avgMs))),
          const SizedBox(width: 8),
          IconButton(
            tooltip: '复制',
            iconSize: 15,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy),
            onPressed: () => _copy(r.ip, '已复制 ${r.ip}'),
          ),
        ],
      ),
    );
  }
}

/// 分段选择（类似 24H / 7D / 30D）
class _Seg extends StatelessWidget {
  final List<int> values;
  final int current;
  final bool enabled;
  final ValueChanged<int> onChanged;
  const _Seg({
    required this.values,
    required this.current,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        border: Border.all(color: Ios.cardBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in values)
            GestureDetector(
              onTap: enabled ? () => onChanged(v) : null,
              child: MouseRegion(
                cursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: v == current ? Ios.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$v',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          v == current ? FontWeight.w700 : FontWeight.w500,
                      color: v == current ? Colors.white : Ios.gray,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
