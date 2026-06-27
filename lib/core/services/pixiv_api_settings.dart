import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

class PixivApiSettings {
  const PixivApiSettings._();

  static const targetIp = '210.140.170.179';
  static const deviceName = 'android';
  static const acceptInvalidCerts = true;
}

PixivApiConfig buildPixivApiConfig({UserAccountResult? account}) {
  return PixivApiConfig(
    targetIp: PixivApiSettings.targetIp,
    language: AppSettings.localeCode ?? LocaleSettings.currentLocale.languageTag,
    deviceName: PixivApiSettings.deviceName,
    account: account ?? AppSettings.accountSession,
    acceptInvalidCerts: PixivApiSettings.acceptInvalidCerts,
  );
}
