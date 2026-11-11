import 'package:flutter/widgets.dart';
import 'package:freepiv/core/downloads/downloader.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_api_settings.dart';
import 'package:freepiv/src/rust/frb_generated.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

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
  await RustLib.init();
  await initializeDownloadManager();

  pixivApi = _createPixivApi(account: AppSettings.accounts.active?.session);
  pixivAccountNotifier.value = pixivApi.account();
  _appServicesInitialized = true;
}

/// Makes [account] the current account, or with null signs the current one
/// out. An account the app already keeps is updated, not added again.
void setPixivAccount(UserAccountResult? account) {
  pixivApi.setAccount(account: account);
  final book = AppSettings.accounts;
  AppSettings.accounts = account == null ? (book.activeId == null ? book : book.remove(book.activeId!)) : book.activate(account, DateTime.now());
  pixivAccountNotifier.value = account;
}

void refreshPixivApiLanguage() {
  if (!_appServicesInitialized) {
    return;
  }

  pixivApi = _createPixivApi(account: pixivApi.account());
}

void refreshPixivApiProxy() {
  if (!_appServicesInitialized) {
    return;
  }

  pixivApi = _createPixivApi(account: pixivApi.account());
}

PixivApi _createPixivApi({UserAccountResult? account}) {
  return PixivApi(config: buildPixivApiConfig(account: account));
}
