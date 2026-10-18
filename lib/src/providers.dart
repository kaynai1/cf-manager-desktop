import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api.dart';
import 'defaults.dart';
import 'models.dart';
import 'store.dart';
import 'store_io.dart';

class AccountsState {
  final List<Account> accounts;
  final String? selectedId;
  final bool loading;
  const AccountsState({
    this.accounts = const [],
    this.selectedId,
    this.loading = true,
  });

  Account? get selected {
    if (accounts.isEmpty) return null;
    for (final a in accounts) {
      if (a.id == selectedId) return a;
    }
    return accounts.first;
  }
}

class AccountsNotifier extends StateNotifier<AccountsState> {
  AccountsNotifier() : super(const AccountsState()) {
    _init();
  }

  Future<void> _init() async {
    List<Account> list;
    String? sel;
    try {
      DiagLog.instance.log('init: loading accounts');
      list =
          await AccountStore.load().timeout(const Duration(seconds: 3), onTimeout: () async {
        DiagLog.instance.log('init: AccountStore.load TIMED OUT');
        return [];
      });
    } catch (_) {
      list = [];
    }
    try {
      sel =
          await AccountStore.selected().timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {
      sel = null;
    }
    DiagLog.instance.log('init: load done, list=${list.length}');
    if (list.isEmpty) {
      try {
        list = List<Account>.from(kDefaultAccounts);
        await AccountStore.save(list).timeout(const Duration(seconds: 3));
        sel = list.first.id;
        await AccountStore.setSelected(sel);
      } catch (_) {
        // 首次写入失败不阻塞进入页面
      }
    }
    DiagLog.instance.log('init: setting state loading=false');
    if (!mounted) return;
    state = AccountsState(accounts: list, selectedId: sel, loading: false);
  }

  Future<void> _persist() => AccountStore.save(state.accounts);

  Future<void> add(Account a) async {
    state = AccountsState(
      accounts: [...state.accounts, a],
      selectedId: a.id,
      loading: false,
    );
    await _persist();
    await AccountStore.setSelected(a.id);
  }

  Future<void> update(Account a) async {
    state = AccountsState(
      accounts: [
        for (final x in state.accounts) if (x.id == a.id) a else x,
      ],
      selectedId: state.selectedId,
      loading: false,
    );
    await _persist();
  }

  Future<void> remove(String id) async {
    final list = state.accounts.where((x) => x.id != id).toList();
    final sel = state.selectedId == id ? null : state.selectedId;
    state = AccountsState(accounts: list, selectedId: sel, loading: false);
    await _persist();
    await AccountStore.setSelected(sel);
  }

  Future<void> select(String id) async {
    state = AccountsState(
      accounts: state.accounts,
      selectedId: id,
      loading: false,
    );
    await AccountStore.setSelected(id);
  }
}

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, AccountsState>(
  (ref) => AccountsNotifier(),
);

final apiProvider = Provider<CfApi?>((ref) {
  final acc = ref.watch(accountsProvider).selected;
  return acc == null ? null : CfApi(acc);
});

final zonesProvider = FutureProvider<List<Zone>>((ref) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listZones();
});

final dnsProvider =
    FutureProvider.family<List<DnsRecord>, String>((ref, zoneId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listDns(zoneId);
});

final workersProvider =
    FutureProvider.family<List<WorkerScript>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listWorkers(accountId);
});

final r2Provider =
    FutureProvider.family<List<R2Bucket>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listR2(accountId);
});

final aiProvider =
    FutureProvider.family<List<AiModel>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listAiModels(accountId);
});

final zoneSettingsProvider =
    FutureProvider.family<List<ZoneSetting>, String>((ref, zoneId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.getZoneSettings(zoneId);
});

final zoneAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, zoneId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return {};
  return api.zoneAnalytics(zoneId);
});

final dnssecProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, zoneId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return {};
  return api.getDnssec(zoneId);
});

final pageRulesProvider =
    FutureProvider.family<List<PageRule>, String>((ref, zoneId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listPageRules(zoneId);
});

final accessRulesProvider =
    FutureProvider.family<List<AccessRule>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listAccessRules(accountId);
});

final securityEventsProvider =
    FutureProvider.family<List<SecurityEvent>, String>((ref, zoneId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listSecurityEvents(zoneId);
});

final rateLimitsProvider =
    FutureProvider.family<List<RateLimit>, String>((ref, zoneId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listRateLimits(zoneId);
});

// ---- 开发者平台（账号级） ----
final kvNamespacesProvider =
    FutureProvider.family<List<KvNamespace>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listKvNamespaces(accountId);
});

final kvKeysProvider = FutureProvider.family<List<KvKey>, (String, String)>(
    (ref, arg) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listKvKeys(arg.$1, arg.$2);
});

final d1Provider =
    FutureProvider.family<List<D1Database>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listD1(accountId);
});

final pagesProvider =
    FutureProvider.family<List<PagesProject>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listPages(accountId);
});

final pagesDeploymentsProvider =
    FutureProvider.family<List<PagesDeployment>, (String, String)>(
        (ref, arg) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listPagesDeployments(arg.$1, arg.$2);
});

final queuesProvider =
    FutureProvider.family<List<QueueInfo>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listQueues(accountId);
});

final aiGatewaysProvider =
    FutureProvider.family<List<AiGateway>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listAiGateways(accountId);
});

final vectorizeProvider =
    FutureProvider.family<List<VectorizeIndex>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listVectorize(accountId);
});

final doNamespacesProvider =
    FutureProvider.family<List<DoNamespace>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listDoNamespaces(accountId);
});

final r2ObjectsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, (String, String)>(
        (ref, arg) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listR2Objects(arg.$1, arg.$2);
});

// ---- 账号级 ----
final apiTokensProvider = FutureProvider<List<ApiToken>>((ref) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listApiTokens();
});

final permissionGroupsProvider =
    FutureProvider<List<PermissionGroup>>((ref) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listPermissionGroups();
});

final turnstileProvider =
    FutureProvider.family<List<TurnstileWidget>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listTurnstile(accountId);
});

final accessAppsProvider =
    FutureProvider.family<List<AccessApp>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listAccessApps(accountId);
});

final membersProvider =
    FutureProvider.family<List<Member>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listMembers(accountId);
});

final accountInfoProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return {};
  return api.getAccount(accountId);
});

final tunnelsProvider =
    FutureProvider.family<List<CftTunnel>, String>((ref, accountId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listTunnels(accountId);
});

final userProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiProvider);
  if (api == null) return {};
  return api.getUser();
});

final emailRoutingProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, zoneId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return {};
  return api.getEmailRouting(zoneId);
});

final emailRulesProvider =
    FutureProvider.family<List<EmailRule>, String>((ref, zoneId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listEmailRules(zoneId);
});

final emailAddressesProvider =
    FutureProvider.family<List<EmailAddress>, String>((ref, zoneId) async {
  final api = ref.watch(apiProvider);
  if (api == null) return [];
  return api.listEmailAddresses(zoneId);
});
