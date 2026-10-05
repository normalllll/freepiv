import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/newest_page.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_filters.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_toolbar.dart';
import 'package:freepiv/i18n/strings.g.dart';

class _EmptyFeed extends NewestListSource {
  _EmptyFeed(NewestFeedKey key) : super(key: key);

  @override
  bool get initialized => true;
}

class _LocalNewest extends Newest {
  @override
  NewestState build() {
    final sources = {for (final key in newestFeedKeys) key: _EmptyFeed(key)};
    ref.onDispose(() {
      for (final source in sources.values) {
        source.dispose();
      }
    });
    return super.build().copyWith(sources: sources);
  }
}

void main() {
  testWidgets('compact newest filter keeps one summary row and all valid choices accessible', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final locale in AppLocale.values) {
      LocaleSettings.setLocale(locale);
      for (final width in [320.0, 390.0, 430.0]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, 844);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [newestProvider.overrideWith(_LocalNewest.new)],
              child: TranslationProvider(
                child: MaterialApp(
                  theme: AppTheme.light(platform: TargetPlatform.android, locale: locale.flutterLocale),
                  home: MediaQuery(
                    data: MediaQueryData(size: Size(width, 844), textScaler: TextScaler.linear(scale)),
                    child: const FrostLayoutScope(child: NewestPage()),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final toolbar = tester.widget<TabBar>(find.descendant(of: find.byType(NewestToolbar), matching: find.byType(TabBar)));
          expect(toolbar.isScrollable, isTrue);
          expect(toolbar.tabAlignment, TabAlignment.start);
          final summary = find.descendant(of: find.byType(NewestFilterButton), matching: find.byType(TextButton));
          expect(summary, findsOneWidget);
          // The button's own padding may reach into the inset; its label and
          // chevron stay inside the page inset.
          final label = find.descendant(of: summary, matching: find.byType(Icon)).last;
          expect(tester.getRect(label).right, lessThanOrEqualTo(width - 12));
          expect(tester.getRect(summary).right, lessThanOrEqualTo(width));
          expect(tester.takeException(), isNull, reason: '$locale $width at $scale×');
        }
      }
    }

    tester.view.physicalSize = const Size(390, 844);
    LocaleSettings.setLocale(AppLocale.enUs);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [newestProvider.overrideWith(_LocalNewest.new)],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en', 'US')),
            home: const FrostLayoutScope(child: NewestPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final summary = find.descendant(of: find.byType(NewestFilterButton), matching: find.byType(TextButton));
    await tester.tap(summary);
    await tester.pumpAndSettle();
    expect(find.text(t.newest.workType.novel), findsWidgets);
    expect(find.text(t.newest.followScope.public), findsWidgets);
    await tester.tap(find.text(t.newest.followScope.public).last);
    await tester.pumpAndSettle();
    expect(ProviderScope.containerOf(tester.element(find.byType(NewestPage))).read(newestProvider).followScope, NewestFollowScope.public);
    expect(tester.takeException(), isNull);
  });

  testWidgets('newest page renders its shared controls at compact and wide widths', (tester) async {
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.runAsync(() async {
      final systemFont = File('C:/Windows/Fonts/segoeui.ttf');
      if (await systemFont.exists()) {
        final bytes = await systemFont.readAsBytes();
        await (FontLoader('Segoe UI')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final size in [const Size(390, 844), const Size(800, 900), const Size(1440, 900)]) {
      tester.view.physicalSize = size;
      for (final dark in [false, true]) {
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [newestProvider.overrideWith(_LocalNewest.new)],
            child: TranslationProvider(
              child: MaterialApp(
                theme: dark
                    ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
                    : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
                home: MediaQuery(
                  data: MediaQueryData(size: size),
                  child: FrostLayoutScope(
                    child: RepaintBoundary(key: boundary, child: const NewestPage()),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size ${dark ? 'dark' : 'light'}');
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await render.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          final file = File('build/ui-review/newest-${size.width.toInt()}-${dark ? 'dark' : 'light'}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
        });
      }
    }
  });
}
