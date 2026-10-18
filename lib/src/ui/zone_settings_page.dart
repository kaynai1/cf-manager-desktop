import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import 'ios.dart';

const _groupOf = <String, String>{
  'ssl': 'SSL/TLS',
  'min_tls_version': 'SSL/TLS',
  'tls_1_3': 'SSL/TLS',
  'automatic_https_rewrites': 'SSL/TLS',
  'always_use_https': 'SSL/TLS',
  'opportunistic_encryption': 'SSL/TLS',
  'tls_client_auth': 'SSL/TLS',
  'security_header': 'SSL/TLS',
  'brotli': '速度',
  'rocket_loader': '速度',
  'early_hints': '速度',
  'h2_prioritization': '速度',
  'http2': '速度',
  'http3': '速度',
  'zero_rtt': '速度',
  'prefetch_preload': '速度',
  'mirage': '速度',
  'image_resizing': '速度',
  'webp': '速度',
  'fonts': '速度',
  'cache_level': '缓存',
  'browser_cache_ttl': '缓存',
  'always_online': '缓存',
  'development_mode': '缓存',
  'sort_query_string_for_cache': '缓存',
  'origin_error_page_pass_thru': '缓存',
  'websockets': '网络',
  'ip_geolocation': '网络',
  'ipv6': '网络',
  'grpc': '网络',
  'onion': '网络',
  'pseudo_ipv4': '网络',
  'response_buffering': '网络',
  'proxy_read_timeout': '网络',
  'true_client_ip_header': '网络',
  'email_obfuscation': 'Scrape Shield',
  'hotlink_protection': 'Scrape Shield',
  'server_side_exclude': 'Scrape Shield',
  'security_level': '安全',
  'browser_check': '安全',
  'challenge_ttl': '安全',
  'privacy_pass': '安全',
  'waf': '安全',
  'advanced_ddos': '安全',
};

const _labelOf = <String, String>{
  'ssl': 'SSL/TLS 加密模式',
  'min_tls_version': '最低 TLS 版本',
  'tls_1_3': 'TLS 1.3',
  'automatic_https_rewrites': '自动 HTTPS 重写',
  'always_use_https': '始终使用 HTTPS',
  'opportunistic_encryption': '机会性加密',
  'tls_client_auth': 'TLS 客户端认证',
  'security_header': 'HSTS',
  'brotli': 'Brotli 压缩',
  'rocket_loader': 'Rocket Loader',
  'early_hints': 'Early Hints',
  'h2_prioritization': 'HTTP/2 优先级',
  'http2': 'HTTP/2',
  'http3': 'HTTP/3',
  'zero_rtt': '0-RTT 连接恢复',
  'prefetch_preload': '预取 Preload',
  'mirage': 'Mirage 图片优化',
  'image_resizing': '图片调整',
  'webp': 'WebP',
  'fonts': '字体优化',
  'cache_level': '缓存级别',
  'browser_cache_ttl': '浏览器缓存 TTL',
  'always_online': '始终在线',
  'development_mode': '开发模式',
  'sort_query_string_for_cache': '查询字符串排序',
  'origin_error_page_pass_thru': '源站错误页透传',
  'websockets': 'WebSockets',
  'ip_geolocation': 'IP 地理位置',
  'ipv6': 'IPv6',
  'grpc': 'gRPC',
  'onion': 'Onion 路由',
  'pseudo_ipv4': '伪 IPv4',
  'response_buffering': '响应缓冲',
  'proxy_read_timeout': '代理读取超时',
  'true_client_ip_header': 'True-Client-IP 头',
  'email_obfuscation': '邮箱地址混淆',
  'hotlink_protection': '防盗链',
  'server_side_exclude': '服务器端排除',
  'security_level': '安全级别',
  'browser_check': '浏览器完整性检查',
  'challenge_ttl': '质询通过时长',
  'privacy_pass': 'Privacy Pass',
  'waf': 'WAF',
  'advanced_ddos': '高级 DDoS',
};

const _optionsOf = <String, List<String>>{
  'ssl': ['off', 'flexible', 'full', 'strict'],
  'min_tls_version': ['1.0', '1.1', '1.2', '1.3'],
  'tls_1_3': ['on', 'off', 'zrt'],
  'cache_level': ['aggressive', 'basic', 'simplified'],
  'security_level': [
    'essentially_off',
    'low',
    'medium',
    'high',
    'under_attack',
  ],
  'pseudo_ipv4': ['off', 'add_header', 'overwrite_header'],
  'browser_cache_ttl': [
    '0', '30', '60', '300', '600', '900', '1800', '3600', '7200', '10800',
    '14400', '18000', '28800', '43200', '57600', '86400', '172800', '259200',
    '345600', '432000', '518400', '604800', '1209600', '2419200', '2592000',
    '5184000', '7776000', '15552000', '31536000',
  ],
  'challenge_ttl': [
    '300', '900', '1800', '2700', '3600', '7200', '10800', '14400', '28800',
    '57600', '86400', '604800', '2592000', '5184000', '7776000', '15552000',
    '31536000',
  ],
};

const _groupOrder = [
  'SSL/TLS',
  '速度',
  '缓存',
  '网络',
  'Scrape Shield',
  '安全',
  '其他',
];

class ZoneSettingsPage extends ConsumerWidget {
  final Zone zone;
  const ZoneSettingsPage({super.key, required this.zone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(zoneSettingsProvider(zone.id)),
          ),
        ],
      ),
      body: AsyncView<List<ZoneSetting>>(
        value: ref.watch(zoneSettingsProvider(zone.id)),
        builder: (settings) {
          final byGroup = <String, List<ZoneSetting>>{};
          for (final s in settings) {
            final g = _groupOf[s.id] ?? '其他';
            byGroup.putIfAbsent(g, () => []).add(s);
          }
          final groups = _groupOrder.where(byGroup.containsKey).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              for (final g in groups) ...[
                IosSectionHeader(g),
                IosCard(
                  children: [
                    for (final s in byGroup[g]!) _tile(context, ref, s),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, WidgetRef ref, ZoneSetting s) {
    final label = _labelOf[s.id] ?? s.id;
    if (!s.editable) {
      return IosRow(title: label, value: s.valueLabel);
    }

    if (s.value is bool) {
      return SwitchListTile(
        value: s.value as bool,
        activeTrackColor: Ios.orange,
        title: Text(label),
        onChanged: (v) => _patch(ref, s.id, v),
      );
    }

    final options = _optionsOf[s.id];
    if (options != null) {
      final current = '${s.value}';
      return ListTile(
        title: Text(label),
        trailing: DropdownButton<String>(
          value: options.contains(current) ? current : null,
          underline: const SizedBox.shrink(),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: (v) {
            if (v != null) _patch(ref, s.id, v);
          },
        ),
      );
    }

    return IosRow(title: label, value: s.valueLabel);
  }

  Future<void> _patch(WidgetRef ref, String name, dynamic value) async {
    final api = ref.read(apiProvider);
    if (api == null) return;
    try {
      await api.patchZoneSetting(zone.id, name, value);
    } catch (e) {
      // ignore: avoid_print
      debugPrint('$e');
    }
    ref.invalidate(zoneSettingsProvider(zone.id));
  }
}
