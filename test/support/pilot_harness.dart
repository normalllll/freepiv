import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/dev/sample_images.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The desktop window and the phone the pilot pages are checked at.
const desktopSize = Size(1147, 717);
const phoneSize = Size(390, 844);

/// Where the pages went: the location of the last page pushed past the
/// page under test.
final openedLocations = <String>[];

/// What each of [openedLocations] was opened with.
final openedExtras = <Object?>[];

/// Mounts [page] alone (no shell) in the app's Frost config, at [size],
/// [textScale] and [locale], with [overrides] (by provider) replacing the
/// sample providers, and
/// a signed-in sample account. Any other location shows its path.
Future<void> mountPilotPage(
  WidgetTester tester,
  Widget page, {
  Size size = desktopSize,
  double textScale = 1,
  AppLocale locale = AppLocale.enUs,
  Map<Object, Override> overrides = const {},
  bool signedIn = true,
  String location = '/',
  Object? extra,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await AppSettings.initialize(store: SampleSettingsStore(sampleSettings));
  await tester.runAsync(() => LocaleSettings.setLocale(locale));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.enUs));
  if (signedIn) {
    pixivAccountNotifier.value = sampleAccount;
    addTearDown(() => pixivAccountNotifier.value = null);
  }
  pixivImageOverride = sampleImageProvider;
  addTearDown(() => pixivImageOverride = null);
  openedLocations.clear();
  openedExtras.clear();
  final uri = Uri.parse(location);
  final router = GoRouter(
    initialLocation: location,
    initialExtra: extra,
    routes: [
      GoRoute(path: uri.path, builder: (context, state) => page),
      GoRoute(
        path: '/:rest(.*)',
        builder: (context, state) {
          openedLocations.add(state.uri.toString());
          openedExtras.add(state.extra);
          return FrostText('opened ${state.uri}');
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    // A new container for every mount, so its overrides apply.
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        ...{...sampleOverrideMap, ...overrides}.values,
      ],
      child: TranslationProvider(
        child: FrostApp.router(config: freepivFrostConfig, routerConfig: router, title: 'freepiv'),
      ),
    ),
  );
  await settlePilot(tester);
}

/// Pumps a bounded number of frames: pages keep idle animations running.
Future<void> settlePilot(WidgetTester tester, {int frames = 12}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Fails on any overflow or other framework error reported while mounted.
void expectNoLayoutErrors(WidgetTester tester, {String? where}) {
  final error = tester.takeException();
  expect(
    error,
    isNull,
    reason:
        'a layout error was reported${where == null ? '' : ' in $where'}: ${error is FlutterError ? error.diagnostics.map((node) => node.toString()).where((line) => line.contains('creator') || line.contains('overflow')).take(3).join(' | ') : error}',
  );
}

/// Of the four interface languages, the one whose strings run longest.
const longestLocale = AppLocale.enUs;

/// A long title, name or tag as data can carry it.
const longText =
    'An extraordinarily long title from the data that keeps on going without any natural place to break, '
    'with Ｆｕｌｌ ｗｉｄｔｈ 文字 と 日本語のとても長いタイトルが続きます';

/// Every key of [section] in the base language's strings, present in all
/// four languages.
void expectLocalesComplete(List<String> sections) {
  Map<String, Object?> read(String name) => jsonDecode(File('lib/i18n/$name.i18n.json').readAsStringSync()) as Map<String, Object?>;
  Iterable<String> keys(Object? node, String prefix) sync* {
    if (node is Map) {
      for (final entry in node.entries) {
        yield* keys(entry.value, '$prefix.${entry.key}');
      }
    } else {
      yield prefix;
    }
  }

  final base = read('en_US');
  for (final name in ['zh_CN', 'zh_Hant_TW', 'ja_JP']) {
    final other = read(name);
    for (final section in sections) {
      final missing = keys(base[section], section).toSet().difference(keys(other[section], section).toSet());
      expect(missing, isEmpty, reason: '$name lacks $section strings');
    }
  }
}

/// The page header's More menu is a bare icon, its label kept for tooltips
/// and accessibility.
void expectIconOnlyMore(WidgetTester tester) {
  final more = FrostScope.labelsOf(tester.element(find.byType(Navigator).last)).more;
  expect(find.bySemanticsLabel(more), findsWidgets, reason: 'the header has a More menu');
  expect(find.text(more), findsNothing, reason: 'its label is not drawn');
}
