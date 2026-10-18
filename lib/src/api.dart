import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class CfException implements Exception {
  final int status;
  final String message;
  CfException(this.status, this.message);
  @override
  String toString() => 'Cloudflare ($status): $message';
}

/// Cloudflare API v4 客户端，支持 API Token 与 Global API Key 两种鉴权。
class CfApi {
  final Account account;
  CfApi(this.account);

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (account.authType == AuthType.token) {
      h['Authorization'] = 'Bearer ${account.token ?? ''}';
    } else {
      h['X-Auth-Email'] = account.email ?? '';
      h['X-Auth-Key'] = account.globalKey ?? '';
    }
    return h;
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri.https('api.cloudflare.com', '/client/v4$path', query);
    late http.Response res;
    final payload = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        res = await http.get(uri, headers: _headers);
        break;
      case 'POST':
        res = await http.post(uri, headers: _headers, body: payload);
        break;
      case 'PUT':
        res = await http.put(uri, headers: _headers, body: payload);
        break;
      case 'PATCH':
        res = await http.patch(uri, headers: _headers, body: payload);
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: _headers, body: payload);
        break;
      default:
        throw CfException(0, '不支持的方法 $method');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw CfException(res.statusCode, '响应解析失败');
    }
    if (decoded['success'] != true) {
      final errors = (decoded['errors'] as List?) ?? const [];
      final msg = errors.isNotEmpty
          ? (errors.first['message']?.toString() ?? '')
          : 'HTTP ${res.statusCode}';
      throw CfException(res.statusCode, msg);
    }
    return decoded['result'];
  }

  /// 验证凭证。
  Future<void> verify() async {
    if (account.authType == AuthType.token) {
      await _request('GET', '/user/tokens/verify');
    } else {
      await _request('GET', '/user');
    }
  }

  Future<List<Map<String, dynamic>>> listAccountsRaw() async {
    final r = await _request('GET', '/accounts', query: {'per_page': '50'});
    return (r as List).cast<Map<String, dynamic>>();
  }

  Future<List<Zone>> listZones() async {
    final r = await _request('GET', '/zones', query: {'per_page': '100'}) as List;
    return r.map((e) => Zone.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DnsRecord>> listDns(String zoneId) async {
    final r = await _request('GET', '/zones/$zoneId/dns_records',
        query: {'per_page': '100'}) as List;
    return r.map((e) => DnsRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createDns(String zoneId, DnsRecord rec) =>
      _request('POST', '/zones/$zoneId/dns_records', body: rec.toBody());

  Future<void> updateDns(String zoneId, String recordId, DnsRecord rec) =>
      _request('PUT', '/zones/$zoneId/dns_records/$recordId', body: rec.toBody());

  Future<void> deleteDns(String zoneId, String recordId) =>
      _request('DELETE', '/zones/$zoneId/dns_records/$recordId');

  Future<List<WorkerScript>> listWorkers(String accountId) async {
    final r = await _request('GET', '/accounts/$accountId/workers/scripts') as List;
    return r
        .map((e) => WorkerScript.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<R2Bucket>> listR2(String accountId) async {
    final r = await _request('GET', '/accounts/$accountId/r2/buckets');
    final List list = (r is Map && r['buckets'] is List)
        ? r['buckets'] as List
        : (r as List);
    return list.map((e) => R2Bucket.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AiModel>> listAiModels(String accountId) async {
    final r = await _request('GET', '/accounts/$accountId/ai/models/search',
        query: {'per_page': '100'});
    final List list = (r is Map && r['result'] is List)
        ? r['result'] as List
        : (r as List);
    return list.map((e) => AiModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---- 域名设置 ----
  Future<List<ZoneSetting>> getZoneSettings(String zoneId) async {
    final r = await _request('GET', '/zones/$zoneId/settings') as List;
    return r.map((e) => ZoneSetting.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> patchZoneSetting(String zoneId, String name, dynamic value) =>
      _request('PATCH', '/zones/$zoneId/settings/$name',
          body: {'value': value});

  Future<void> purgeCache(
    String zoneId, {
    bool everything = false,
    List<String>? files,
    List<String>? tags,
    List<String>? hosts,
  }) =>
      _request('POST', '/zones/$zoneId/purge_cache', body: {
        if (everything) 'purge_everything': true,
        'files': ?files,
        'tags': ?tags,
        'hosts': ?hosts,
      });

  Future<Map<String, dynamic>> zoneAnalytics(String zoneId) async {
    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(days: 1));
    final q = 'query { viewer { zones(filter: {zoneTag: "$zoneId"}) { '
        'httpRequests1hGroups(limit: 100, filter: {datetime_geq: '
        '"${from.toIso8601String()}", datetime_leq: "${now.toIso8601String()}"}) '
        '{ sum { requests bytes threats pageViews } } } } }';
    final data = await _graphql(q);
    final zones = (data['viewer']?['zones'] as List?) ?? const [];
    var requests = 0, bytes = 0, threats = 0, pageviews = 0;
    if (zones.isNotEmpty) {
      final groups =
          (zones.first['httpRequests1hGroups'] as List?) ?? const [];
      for (final g in groups) {
        final sum = (g['sum'] as Map?) ?? const {};
        requests += (sum['requests'] as num?)?.toInt() ?? 0;
        bytes += (sum['bytes'] as num?)?.toInt() ?? 0;
        threats += (sum['threats'] as num?)?.toInt() ?? 0;
        pageviews += (sum['pageViews'] as num?)?.toInt() ?? 0;
      }
    }
    return {
      'totals': {
        'requests': {'all': requests},
        'bandwidth': {'all': bytes},
        'threats': {'all': threats},
        'pageviews': {'all': pageviews},
        'uniques': {'all': 0},
      }
    };
  }

  Future<Map<String, dynamic>> _graphql(String query) async {
    final uri = Uri.https('api.cloudflare.com', '/client/v4/graphql');
    final res = await http.post(uri,
        headers: _headers, body: jsonEncode({'query': query}));
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw CfException(res.statusCode, 'GraphQL 响应解析失败');
    }
    final errs = decoded['errors'];
    if (errs is List && errs.isNotEmpty) {
      throw CfException(res.statusCode, '${errs.first['message']}');
    }
    return (decoded['data'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getDnssec(String zoneId) async =>
      ((await _request('GET', '/zones/$zoneId/dnssec')) as Map)
          .cast<String, dynamic>();

  Future<void> editDnssec(String zoneId, String status) =>
      _request('PATCH', '/zones/$zoneId/dnssec', body: {'status': status});

  // ---- Page Rules ----
  Future<List<PageRule>> listPageRules(String zoneId) async {
    final r = await _request('GET', '/zones/$zoneId/pagerules') as List;
    return r.map((e) => PageRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createPageRule(
    String zoneId,
    String url,
    List<Map<String, dynamic>> actions,
  ) =>
      _request('POST', '/zones/$zoneId/pagerules', body: {
        'targets': [
          {
            'target': 'url',
            'constraint': {'operator': 'matches', 'value': url},
          }
        ],
        'actions': actions,
        'priority': 1,
        'status': 'active',
      });

  Future<void> deletePageRule(String zoneId, String ruleId) =>
      _request('DELETE', '/zones/$zoneId/pagerules/$ruleId');

  Future<void> setPageRuleStatus(String zoneId, String ruleId, String status) =>
      _request('PATCH', '/zones/$zoneId/pagerules/$ruleId',
          body: {'status': status});

  // ---- 防火墙 / 安全 ----
  Future<List<AccessRule>> listAccessRules(String accountId) async {
    final r = await _request(
        'GET', '/accounts/$accountId/firewall/access_rules/rules',
        query: {'per_page': '100'}) as List;
    return r.map((e) => AccessRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createAccessRule(
    String accountId, {
    required String mode,
    required String target,
    required String value,
    String? notes,
  }) =>
      _request('POST', '/accounts/$accountId/firewall/access_rules/rules',
          body: {
            'mode': mode,
            'configuration': {'target': target, 'value': value},
            'notes': notes ?? '',
          });

  Future<void> deleteAccessRule(String accountId, String ruleId) =>
      _request('DELETE',
          '/accounts/$accountId/firewall/access_rules/rules/$ruleId');

  Future<List<SecurityEvent>> listSecurityEvents(String zoneId) async {
    final from = DateTime.now().toUtc().subtract(const Duration(days: 1));
    final q = 'query { viewer { zones(filter: {zoneTag: "$zoneId"}) { '
        'firewallEventsAdaptive(limit: 20, filter: {datetime_gt: '
        '"${from.toIso8601String()}"}, orderBy: [datetime_DESC]) '
        '{ action source clientIP datetime } } } }';
    final data = await _graphql(q);
    final zones = (data['viewer']?['zones'] as List?) ?? const [];
    if (zones.isEmpty) return [];
    final events =
        (zones.first['firewallEventsAdaptive'] as List?) ?? const [];
    return events
        .map((e) => SecurityEvent(
              action: '${e['action']}',
              source: '${e['source']}',
              ip: e['clientIP'] as String?,
              when: e['datetime'] as String?,
            ))
        .toList();
  }

  Future<List<RateLimit>> listRateLimits(String zoneId) async {
    try {
      final r = await _request(
          'GET', '/zones/$zoneId/rulesets/phases/http_ratelimit/entrypoint');
      final rules =
          (r is Map && r['rules'] is List) ? r['rules'] as List : const [];
      return rules
          .map((e) => RateLimit(
                id: '${e['id']}',
                description: e['description'] as String?,
                disabled: e['enabled'] == false,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ---- 原始文本（KV 值等） ----
  Future<String> _getRaw(String path) async {
    final uri = Uri.https('api.cloudflare.com', '/client/v4$path');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode >= 400) throw CfException(res.statusCode, res.body);
    return res.body;
  }

  Future<void> _putRaw(String path, String value) async {
    final uri = Uri.https('api.cloudflare.com', '/client/v4$path');
    final res = await http.put(uri, headers: _headers, body: value);
    if (res.statusCode >= 400) throw CfException(res.statusCode, res.body);
  }

  // ---- Workers KV ----
  Future<List<KvNamespace>> listKvNamespaces(String accountId) async {
    final r = await _request(
        'GET', '/accounts/$accountId/storage/kv/namespaces') as List;
    return r.map((e) => KvNamespace.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createKvNamespace(String accountId, String title) =>
      _request('POST', '/accounts/$accountId/storage/kv/namespaces',
          body: {'title': title});

  Future<void> deleteKvNamespace(String accountId, String nsId) => _request(
      'DELETE', '/accounts/$accountId/storage/kv/namespaces/$nsId');

  Future<List<KvKey>> listKvKeys(String accountId, String nsId) async {
    final r = await _request(
        'GET', '/accounts/$accountId/storage/kv/namespaces/$nsId/keys',
        query: {'limit': '100'}) as List;
    return r.map((e) => KvKey.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> getKvValue(String accountId, String nsId, String key) =>
      _getRaw('/accounts/$accountId/storage/kv/namespaces/$nsId/values/$key');

  Future<void> putKvValue(
          String accountId, String nsId, String key, String value) =>
      _putRaw(
          '/accounts/$accountId/storage/kv/namespaces/$nsId/values/$key', value);

  Future<void> deleteKvKey(String accountId, String nsId, String key) =>
      _request('DELETE',
          '/accounts/$accountId/storage/kv/namespaces/$nsId/values/$key');

  // ---- D1 ----
  Future<List<D1Database>> listD1(String accountId) async {
    final r = await _request('GET', '/accounts/$accountId/d1/database') as List;
    return r.map((e) => D1Database.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createD1(String accountId, String name) =>
      _request('POST', '/accounts/$accountId/d1/database', body: {'name': name});

  Future<void> deleteD1(String accountId, String uuid) =>
      _request('DELETE', '/accounts/$accountId/d1/database/$uuid');

  Future<List<Map<String, dynamic>>> queryD1(
      String accountId, String uuid, String sql) async {
    final r = await _request(
        'POST', '/accounts/$accountId/d1/database/$uuid/query',
        body: {'sql': sql});
    final list = (r is List) ? r : (r['result'] as List? ?? const []);
    return list.cast<Map<String, dynamic>>();
  }

  // ---- Pages ----
  Future<List<PagesProject>> listPages(String accountId) async {
    final r = await _request('GET', '/accounts/$accountId/pages/projects') as List;
    return r
        .map((e) => PagesProject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PagesDeployment>> listPagesDeployments(
      String accountId, String project) async {
    final r = await _request(
        'GET', '/accounts/$accountId/pages/projects/$project/deployments') as List;
    return r
        .map((e) => PagesDeployment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deletePages(String accountId, String project) =>
      _request('DELETE', '/accounts/$accountId/pages/projects/$project');

  // ---- Queues / AI Gateway / Vectorize / Durable Objects ----
  Future<List<QueueInfo>> listQueues(String accountId) async {
    final r = await _request('GET', '/accounts/$accountId/queues') as List;
    return r.map((e) => QueueInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AiGateway>> listAiGateways(String accountId) async {
    final r = await _request('GET', '/accounts/$accountId/ai-gateway/gateways');
    final list = (r is Map && r['result'] is List)
        ? r['result'] as List
        : (r as List);
    return list.map((e) => AiGateway.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<VectorizeIndex>> listVectorize(String accountId) async {
    final r = await _request(
        'GET', '/accounts/$accountId/vectorize/v2/indexes');
    final list = (r is Map && r['result'] is List)
        ? r['result'] as List
        : (r as List);
    return list
        .map((e) => VectorizeIndex.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DoNamespace>> listDoNamespaces(String accountId) async {
    final r = await _request(
        'GET', '/accounts/$accountId/workers/durable_objects/namespaces');
    final list = (r is Map && r['result'] is List)
        ? r['result'] as List
        : (r as List);
    return list
        .map((e) => DoNamespace.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteWorker(String accountId, String script) =>
      _request('DELETE', '/accounts/$accountId/workers/scripts/$script');

  // ---- R2 管理 ----
  Future<void> createR2Bucket(String accountId, String name) => _request(
      'POST', '/accounts/$accountId/r2/buckets', body: {'name': name});

  Future<void> deleteR2Bucket(String accountId, String name) =>
      _request('DELETE', '/accounts/$accountId/r2/buckets/$name');

  Future<List<Map<String, dynamic>>> listR2Objects(
      String accountId, String bucket) async {
    final r = await _request(
        'GET', '/accounts/$accountId/r2/buckets/$bucket/objects');
    final list = (r is Map && r['result'] is List)
        ? r['result'] as List
        : (r as List? ?? const []);
    return list.cast<Map<String, dynamic>>();
  }

  // ---- API Tokens ----
  Future<List<ApiToken>> listApiTokens() async {
    final r = await _request('GET', '/user/tokens') as List;
    return r.map((e) => ApiToken.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PermissionGroup>> listPermissionGroups() async {
    final r = await _request('GET', '/user/tokens/permission_groups') as List;
    return r
        .map((e) => PermissionGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createApiToken(String name, String permissionGroupId) =>
      _request('POST', '/user/tokens', body: {
        'name': name,
        'policies': [
          {
            'effect': 'allow',
            'resources': {'com.cloudflare.api.account.*': '*'},
            'permission_groups': [
              {'id': permissionGroupId}
            ],
          }
        ],
      });

  Future<void> deleteApiToken(String tokenId) =>
      _request('DELETE', '/user/tokens/$tokenId');

  Future<void> rollApiToken(String tokenId) =>
      _request('PUT', '/user/tokens/$tokenId/value');

  // ---- Turnstile ----
  Future<List<TurnstileWidget>> listTurnstile(String accountId) async {
    final r = await _request('GET', '/accounts/$accountId/challenges/widgets');
    final list = (r is Map && r['result'] is List)
        ? r['result'] as List
        : (r as List);
    return list
        .map((e) => TurnstileWidget.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteTurnstile(String accountId, String sitekey) => _request(
      'DELETE', '/accounts/$accountId/challenges/widgets/$sitekey');

  // ---- Zero Trust Access ----
  Future<List<AccessApp>> listAccessApps(String accountId) async {
    final r = await _request('GET', '/accounts/$accountId/access/apps') as List;
    return r.map((e) => AccessApp.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---- Email Routing（域名级） ----
  Future<Map<String, dynamic>> getEmailRouting(String zoneId) async =>
      ((await _request('GET', '/zones/$zoneId/email/routing')) as Map)
          .cast<String, dynamic>();

  Future<void> enableEmailRouting(String zoneId) =>
      _request('POST', '/zones/$zoneId/email/routing/enable');

  Future<List<EmailRule>> listEmailRules(String zoneId) async {
    final r = await _request('GET', '/zones/$zoneId/email/routing/rules') as List;
    return r.map((e) => EmailRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<EmailAddress>> listEmailAddresses(String zoneId) async {
    final r =
        await _request('GET', '/zones/$zoneId/email/routing/addresses') as List;
    return r
        .map((e) => EmailAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- 账号信息 / 成员 ----
  Future<Map<String, dynamic>> getAccount(String accountId) async =>
      ((await _request('GET', '/accounts/$accountId')) as Map)
          .cast<String, dynamic>();

  Future<List<Member>> listMembers(String accountId) async {
    final r = await _request('GET', '/accounts/$accountId/members') as List;
    return r.map((e) => Member.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getUser() async =>
      ((await _request('GET', '/user')) as Map).cast<String, dynamic>();
}
