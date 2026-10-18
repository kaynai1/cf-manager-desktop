import 'models.dart';

/// 预置默认账号：留空表示不预置，用户在 App 内自行添加。
///
/// 出于安全考虑，**请勿把真实 API Token / Global API Key 写进源码**
/// （会随 APK 打包，可被反编译提取）。如需预置，请自行填入并承担风险。
const List<Account> kDefaultAccounts = <Account>[];
