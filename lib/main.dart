import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app_links/app_links.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/core/services/updater_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appLinkDispatcher.start();
  await initializeAppServices();
  await initializeLocaleSettings();
  refreshPixivApiLanguage();
  unawaited(UpdaterService.checkOnAppStart());
  PaintingBinding.instance.imageCache.maximumSize = 300;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 512 << 20;
  runApp(const FreepivApp());
}
