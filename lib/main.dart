import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/window/app_window.dart';
import 'package:freepiv/app_links/app_links.dart';
import 'package:freepiv/core/downloads/download_manager.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/core/services/updater_service.dart';
import 'package:freepiv/features/fanbox/logic.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await appLinkDispatcher.start();
  useDownloadSessionHeaders(fanboxDownloadSessionHeaders);
  await initializeAppServices();
  await initializeLocaleSettings();
  refreshPixivApiLanguage();
  unawaited(UpdaterService.checkOnAppStart());
  PaintingBinding.instance.imageCache.maximumSize = 300;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 512 << 20;
  // The bundled Noto Sans CJK subsets are distributed under the SIL OFL.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const ['Noto Sans SC', 'Noto Sans JP'], await rootBundle.loadString('assets/fonts/OFL-NotoSansCJK.txt'));
    // The UI icon font is built from Lucide's sources (ISC).
    yield LicenseEntryWithLineBreaks(const ['Lucide'], await rootBundle.loadString('assets/fonts/LICENSE-Lucide.txt'));
  });
  // The native window stays hidden until the first frame is ready, so the
  // runner's template rectangle never shows; it opens where it was left.
  final window = await prepareAppWindow();
  runApp(FreepivApp(windowController: window));
  await showAppWindow(binding, window);
}
