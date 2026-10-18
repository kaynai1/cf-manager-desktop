enum AuthType { token, globalKey }

extension AuthTypeX on AuthType {
  String get code => this == AuthType.token ? 'token' : 'globalKey';
  String get label =>
      this == AuthType.token ? 'API Token' : 'Global API Key';

  static AuthType fromCode(String? c) =>
      c == 'globalKey' ? AuthType.globalKey : AuthType.token;
}

class Account {
  final String id;
  final String name;
  final AuthType authType;
  final String? token;
  final String? email;
  final String? globalKey;
  final String? accountId;

  const Account({
    required this.id,
    required this.name,
    required this.authType,
    this.token,
    this.email,
    this.globalKey,
    this.accountId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'authType': authType.code,
        'token': token,
        'email': email,
        'globalKey': globalKey,
        'accountId': accountId,
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        authType: AuthTypeX.fromCode(j['authType'] as String?),
        token: j['token'] as String?,
        email: j['email'] as String?,
        globalKey: j['globalKey'] as String?,
        accountId: j['accountId'] as String?,
      );

  Account copyWith({
    String? name,
    AuthType? authType,
    String? token,
    String? email,
    String? globalKey,
    String? accountId,
  }) =>
      Account(
        id: id,
        name: name ?? this.name,
        authType: authType ?? this.authType,
        token: token ?? this.token,
        email: email ?? this.email,
        globalKey: globalKey ?? this.globalKey,
        accountId: accountId ?? this.accountId,
      );
}

class Zone {
  final String id;
  final String name;
  final String status;
  final String plan;
  final String? accountId;
  const Zone({
    required this.id,
    required this.name,
    required this.status,
    required this.plan,
    this.accountId,
  });

  factory Zone.fromJson(Map<String, dynamic> j) => Zone(
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        status: (j['status'] ?? '') as String,
        plan: (j['plan']?['name'] ?? '') as String,
        accountId: j['account']?['id'] as String?,
      );
}

class DnsRecord {
  final String id;
  final String type;
  final String name;
  final String content;
  final bool proxied;
  final int ttl;
  final int? priority;
  const DnsRecord({
    required this.id,
    required this.type,
    required this.name,
    required this.content,
    required this.proxied,
    required this.ttl,
    this.priority,
  });

  factory DnsRecord.fromJson(Map<String, dynamic> j) => DnsRecord(
        id: j['id'] as String,
        type: (j['type'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        content: (j['content'] ?? '') as String,
        proxied: (j['proxied'] ?? false) as bool,
        ttl: (j['ttl'] ?? 1) as int,
        priority: j['priority'] as int?,
      );

  Map<String, dynamic> toBody() => {
        'type': type,
        'name': name,
        'content': content,
        'ttl': ttl,
        if (type == 'A' || type == 'AAAA' || type == 'CNAME')
          'proxied': proxied,
        if (priority != null) 'priority': priority,
      };
}

class WorkerScript {
  final String id;
  final String? modifiedOn;
  const WorkerScript({required this.id, this.modifiedOn});
  factory WorkerScript.fromJson(Map<String, dynamic> j) => WorkerScript(
        id: (j['id'] ?? '') as String,
        modifiedOn: j['modified_on'] as String?,
      );
}

class R2Bucket {
  final String name;
  final String? creationDate;
  final String? location;
  const R2Bucket({required this.name, this.creationDate, this.location});
  factory R2Bucket.fromJson(Map<String, dynamic> j) => R2Bucket(
        name: (j['name'] ?? '') as String,
        creationDate: j['creation_date'] as String?,
        location: j['location'] as String?,
      );
}

class AiModel {
  final String id;
  final String? task;
  final String? description;
  const AiModel({required this.id, this.task, this.description});
  factory AiModel.fromJson(Map<String, dynamic> j) => AiModel(
        id: (j['name'] ?? j['id'] ?? '') as String,
        task: (j['task']?['name'] ?? j['task']) as String?,
        description: j['description'] as String?,
      );
}

/// 域名设置项（来自 /zones/{id}/settings）。
class ZoneSetting {
  final String id;
  final dynamic value;
  final bool editable;
  const ZoneSetting({
    required this.id,
    required this.value,
    required this.editable,
  });

  factory ZoneSetting.fromJson(Map<String, dynamic> j) => ZoneSetting(
        id: (j['id'] ?? '') as String,
        value: j['value'],
        editable: (j['editable'] ?? false) as bool,
      );

  String get valueLabel {
    if (value is bool) return value ? '开' : '关';
    return '$value';
  }
}

/// Page Rule。
class PageRule {
  final String id;
  final String target;
  final List<Map<String, dynamic>> actions;
  final int priority;
  final String status;
  const PageRule({
    required this.id,
    required this.target,
    required this.actions,
    required this.priority,
    required this.status,
  });

  factory PageRule.fromJson(Map<String, dynamic> j) => PageRule(
        id: (j['id'] ?? '') as String,
        target: (j['targets']?[0]?['constraint']?['value'] ?? '') as String,
        actions: ((j['actions'] ?? []) as List).cast<Map<String, dynamic>>(),
        priority: (j['priority'] ?? 0) as int,
        status: (j['status'] ?? '') as String,
      );
}

/// 防火墙访问规则（账号级 IP Access Rules）。
class AccessRule {
  final String id;
  final String mode;
  final String target;
  final String? value;
  final String? notes;
  const AccessRule({
    required this.id,
    required this.mode,
    required this.target,
    this.value,
    this.notes,
  });

  factory AccessRule.fromJson(Map<String, dynamic> j) => AccessRule(
        id: (j['id'] ?? '') as String,
        mode: (j['mode'] ?? '') as String,
        target: (j['configuration']?['target'] ?? '') as String,
        value: j['configuration']?['value'] as String?,
        notes: j['notes'] as String?,
      );
}

/// 安全事件。
class SecurityEvent {
  final String action;
  final String source;
  final String? ip;
  final String? when;
  const SecurityEvent({
    required this.action,
    required this.source,
    this.ip,
    this.when,
  });

  factory SecurityEvent.fromJson(Map<String, dynamic> j) => SecurityEvent(
        action: (j['action'] ?? '') as String,
        source: (j['source'] ?? '') as String,
        ip: j['ip'] as String?,
        when: j['occurred_at'] as String?,
      );
}

/// 速率限制规则。
class RateLimit {
  final String id;
  final String? description;
  final bool disabled;
  const RateLimit({required this.id, this.description, required this.disabled});

  factory RateLimit.fromJson(Map<String, dynamic> j) => RateLimit(
        id: (j['id'] ?? '') as String,
        description: j['description'] as String?,
        disabled: (j['disabled'] ?? false) as bool,
      );
}

class KvNamespace {
  final String id;
  final String title;
  const KvNamespace({required this.id, required this.title});
  factory KvNamespace.fromJson(Map<String, dynamic> j) => KvNamespace(
        id: (j['id'] ?? '') as String,
        title: (j['title'] ?? '') as String,
      );
}

class KvKey {
  final String name;
  final int? expiration;
  const KvKey({required this.name, this.expiration});
  factory KvKey.fromJson(Map<String, dynamic> j) =>
      KvKey(name: (j['name'] ?? '') as String, expiration: j['expiration'] as int?);
}

class D1Database {
  final String uuid;
  final String name;
  final int? numTables;
  const D1Database({required this.uuid, required this.name, this.numTables});
  factory D1Database.fromJson(Map<String, dynamic> j) => D1Database(
        uuid: (j['uuid'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        numTables: j['num_tables'] as int?,
      );
}

class PagesProject {
  final String name;
  final String? subdomain;
  final String? createdOn;
  const PagesProject({required this.name, this.subdomain, this.createdOn});
  factory PagesProject.fromJson(Map<String, dynamic> j) => PagesProject(
        name: (j['name'] ?? '') as String,
        subdomain: j['subdomain'] as String?,
        createdOn: j['created_on'] as String?,
      );
}

class PagesDeployment {
  final String id;
  final String? url;
  final String? environment;
  final String? createdOn;
  const PagesDeployment({
    required this.id,
    this.url,
    this.environment,
    this.createdOn,
  });
  factory PagesDeployment.fromJson(Map<String, dynamic> j) => PagesDeployment(
        id: (j['id'] ?? '') as String,
        url: j['url'] as String?,
        environment: j['environment'] as String?,
        createdOn: j['created_on'] as String?,
      );
}

class QueueInfo {
  final String id;
  final String name;
  const QueueInfo({required this.id, required this.name});
  factory QueueInfo.fromJson(Map<String, dynamic> j) => QueueInfo(
        id: (j['queue_id'] ?? j['id'] ?? '') as String,
        name: (j['queue_name'] ?? j['name'] ?? '') as String,
      );
}

class AiGateway {
  final String id;
  const AiGateway({required this.id});
  factory AiGateway.fromJson(Map<String, dynamic> j) =>
      AiGateway(id: (j['id'] ?? '') as String);
}

class VectorizeIndex {
  final String name;
  final int? vectors;
  const VectorizeIndex({required this.name, this.vectors});
  factory VectorizeIndex.fromJson(Map<String, dynamic> j) => VectorizeIndex(
        name: (j['name'] ?? '') as String,
        vectors: (j['vectors_count'] ?? j['vectors']) as int?,
      );
}

class DoNamespace {
  final String id;
  final String? name;
  const DoNamespace({required this.id, this.name});
  factory DoNamespace.fromJson(Map<String, dynamic> j) => DoNamespace(
        id: (j['id'] ?? '') as String,
        name: j['name'] as String?,
      );
}

class ApiToken {
  final String id;
  final String name;
  final String? status;
  final String? createdOn;
  const ApiToken({
    required this.id,
    required this.name,
    this.status,
    this.createdOn,
  });
  factory ApiToken.fromJson(Map<String, dynamic> j) => ApiToken(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        status: j['status'] as String?,
        createdOn: j['created_on'] as String?,
      );
}

class PermissionGroup {
  final String id;
  final String name;
  const PermissionGroup({required this.id, required this.name});
  factory PermissionGroup.fromJson(Map<String, dynamic> j) => PermissionGroup(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
      );
}

class TurnstileWidget {
  final String sitekey;
  final String? name;
  final String? domain;
  const TurnstileWidget({required this.sitekey, this.name, this.domain});
  factory TurnstileWidget.fromJson(Map<String, dynamic> j) => TurnstileWidget(
        sitekey: (j['sitekey'] ?? '') as String,
        name: j['name'] as String?,
        domain: j['domain'] as String?,
      );
}

class AccessApp {
  final String id;
  final String name;
  final String? domain;
  const AccessApp({required this.id, required this.name, this.domain});
  factory AccessApp.fromJson(Map<String, dynamic> j) => AccessApp(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        domain: j['domain'] as String?,
      );
}

class EmailRule {
  final String id;
  final String? to;
  final bool enabled;
  const EmailRule({required this.id, this.to, required this.enabled});
  factory EmailRule.fromJson(Map<String, dynamic> j) => EmailRule(
        id: (j['id'] ?? j['tag'] ?? '') as String,
        to: (j['matchers']?[0]?['value']) as String?,
        enabled: (j['enabled'] ?? false) as bool,
      );
}

class EmailAddress {
  final String email;
  final bool verified;
  const EmailAddress({required this.email, required this.verified});
  factory EmailAddress.fromJson(Map<String, dynamic> j) => EmailAddress(
        email: (j['email'] ?? '') as String,
        verified: (j['verified'] ?? false) as bool,
      );
}

class Member {
  final String id;
  final String? email;
  final String? status;
  const Member({required this.id, this.email, this.status});
  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: (j['id'] ?? '') as String,
        email: j['user']?['email'] as String?,
        status: j['status'] as String?,
      );
}

/// Cloudflare Tunnel（cfd_tunnel / cloudflared）
class CftTunnel {
  final String id;
  final String name;
  final String status;
  final String? createdAt;
  final String? deletedAt;
  final String? connectionState; // 'connected' | 'disconnected' | 'degraded' | ...
  final int? connectionsActive;
  final String? accountTag;
  const CftTunnel({
    required this.id,
    required this.name,
    required this.status,
    this.createdAt,
    this.deletedAt,
    this.connectionState,
    this.connectionsActive,
    this.accountTag,
  });

  factory CftTunnel.fromJson(Map<String, dynamic> j) {
    int active = 0;
    final conns = j['conns'];
    if (conns is List) {
      active = conns.where((c) {
        final m = (c as Map?)?.cast<String, dynamic>();
        return m?['pending_cleanup'] != true;
      }).length;
    }
    final connMap = j['connection'] as Map?;
    final connStatus = connMap?['status'] as String?;
    return CftTunnel(
      id: (j['id'] ?? '') as String,
      name: (j['name'] ?? '') as String,
      status: (j['status'] ?? '') as String,
      createdAt: j['created_at'] as String?,
      deletedAt: j['deleted_at'] as String?,
      connectionState: connStatus ?? (j['status'] as String?),
      connectionsActive: active,
      accountTag: j['account_tag'] as String?,
    );
  }

  bool get healthy =>
      connectionState == 'connected' ||
      connectionState == 'associated' ||
      status == 'healthy';
}


