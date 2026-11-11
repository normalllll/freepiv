// The app on sample data, for development and screenshots: in-memory
// settings, a sample signed-in account, sample home feeds, trending tags and
// downloads. Requests that sample data does not cover fail as they would
// offline. Run it with `flutter run -d windows -t tool/sample_main.dart`.
import 'package:flutter/widgets.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/window/app_window.dart';
import 'package:freepiv/core/history/history_service.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/dev/sample_images.dart';
import 'package:freepiv/src/rust/frb_generated.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.initialize(store: SampleSettingsStore(sampleSettings));
  pixivImageOverride = sampleImageProvider;
  historyRepository = await sampleHistoryRepository();
  await RustLib.init();
  // Signed in, so the router opens the home page instead of the login page.
  pixivApiFactory = samplePixivApiFor;
  pixivApi = createPixivApi(account: AppSettings.accounts.active?.session);
  pixivAccountNotifier.value = pixivApi.account();
  final window = await prepareAppWindow();
  runApp(FreepivApp(windowController: window, overrides: sampleOverrides));
  await showAppWindow(binding, window);
}
