import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 最近操作记录（内存中，最多 50 条）
class ActivityEntry {
  final DateTime time;
  final String text;
  final String kind; // done | info | fail
  const ActivityEntry(this.time, this.text, this.kind);
}

class ActivityLog extends ChangeNotifier {
  ActivityLog._();
  static final ActivityLog instance = ActivityLog._();

  final List<ActivityEntry> _items = [];
  List<ActivityEntry> get items => List.unmodifiable(_items);

  void add(String text, {String kind = 'done'}) {
    _items.insert(0, ActivityEntry(DateTime.now(), text, kind));
    if (_items.length > 50) _items.removeLast();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// 把 API 调用翻译成人能看懂的一句话
  static String describe(String method, String path) {
    final verb = switch (method) {
      'POST' => '创建',
      'PUT' => '写入',
      'PATCH' => '修改',
      'DELETE' => '删除',
      _ => method,
    };
    final p = path.toLowerCase();
    String what;
    if (p.contains('dns_records')) {
      what = 'DNS 记录';
    } else if (p.contains('cfd_tunnel')) {
      what = 'Tunnel';
    } else if (p.contains('purge_cache')) {
      return '清除缓存';
    } else if (p.contains('/settings/')) {
      what = '域名设置';
    } else if (p.contains('pagerules')) {
      what = '页面规则';
    } else if (p.contains('/r2/')) {
      what = 'R2 存储桶';
    } else if (p.contains('storage/kv')) {
      what = 'KV';
    } else if (p.contains('/d1/')) {
      what = 'D1 数据库';
    } else if (p.contains('/workers/')) {
      what = 'Worker';
    } else if (p.contains('/pages/')) {
      what = 'Pages 项目';
    } else if (p.contains('tokens')) {
      what = 'API 令牌';
    } else if (p.contains('firewall') || p.contains('access_rules')) {
      what = '访问规则';
    } else if (p.contains('dnssec')) {
      what = 'DNSSEC';
    } else if (p.contains('email/routing')) {
      what = '邮件路由';
    } else if (p.contains('challenges/widgets')) {
      what = 'Turnstile';
    } else {
      what = '配置';
    }
    return '$verb$what';
  }
}

final activityProvider =
    ChangeNotifierProvider<ActivityLog>((ref) => ActivityLog.instance);

/// 外观：跟随系统 / 浅色 / 深色
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
