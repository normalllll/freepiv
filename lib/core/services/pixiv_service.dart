import 'package:flutter/widgets.dart';
import 'package:freepiv/core/downloads/downloader.dart';
import 'package:freepiv/core/services/app_proxy_http_overrides.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_api_settings.dart';
import 'package:freepiv/src/rust/frb_generated.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

late PixivApi pixivApi;
bool _appServicesInitialized = false;
final pixivAccountNotifier = ValueNotifier<UserAccountResult?>(null);

bool get appServicesInitialized => _appServicesInitialized;

Future<void> initializeAppServices() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_appServicesInitialized) {
    return;
  }

  await AppSettings.initialize();
  applyAppProxySettings(AppSettings.proxySettings);
  await RustLib.init();
  await initializeDownloadManager();

  pixivApi = _createPixivApi();
  pixivAccountNotifier.value = pixivApi.account();
  _appServicesInitialized = true;
}

void setPixivAccount(UserAccountResult? account) {
  pixivApi.setAccount(account: account);
  AppSettings.accountSession = account;
  pixivAccountNotifier.value = account;
}

void refreshPixivApiLanguage() {
  if (!_appServicesInitialized) {
    return;
  }

  pixivApi = _createPixivApi(account: pixivApi.account());
}

void refreshPixivApiProxy() {
  applyAppProxySettings(AppSettings.proxySettings);
  if (!_appServicesInitialized) {
    return;
  }

  pixivApi = _createPixivApi(account: pixivApi.account());
}

PixivApi _createPixivApi({UserAccountResult? account}) {
  return PixivApi(config: buildPixivApiConfig(account: account));
}
