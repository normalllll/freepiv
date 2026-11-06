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
