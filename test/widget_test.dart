import 'package:flutter_test/flutter_test.dart';

import 'package:cloudflare_manager/src/models.dart';

void main() {
  test('Account JSON round-trip', () {
    const a = Account(
      id: '1',
      name: 'test',
      authType: AuthType.globalKey,
      email: 'a@b.com',
      globalKey: 'k',
    );
    final b = Account.fromJson(a.toJson());
    expect(b.id, '1');
    expect(b.authType, AuthType.globalKey);
    expect(b.email, 'a@b.com');
    expect(b.globalKey, 'k');
  });

  test('AuthType fromCode defaults to token', () {
    expect(AuthTypeX.fromCode(null), AuthType.token);
    expect(AuthTypeX.fromCode('token'), AuthType.token);
    expect(AuthTypeX.fromCode('globalKey'), AuthType.globalKey);
  });

  test('DnsRecord body omits proxied for TXT', () {
    const r = DnsRecord(
      id: 'x',
      type: 'TXT',
      name: '@',
      content: 'hello',
      proxied: true,
      ttl: 1,
    );
    final body = r.toBody();
    expect(body.containsKey('proxied'), false);
    expect(body['type'], 'TXT');
  });

  test('Zone parses nested plan/account', () {
    final z = Zone.fromJson({
      'id': 'z1',
      'name': 'example.com',
      'status': 'active',
      'plan': {'name': 'Free'},
      'account': {'id': 'acc1'},
    });
    expect(z.name, 'example.com');
    expect(z.plan, 'Free');
    expect(z.accountId, 'acc1');
  });
}
