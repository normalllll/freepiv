import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/pixivision/widgets.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';

void main() {
  testWidgets('editorial cards and skeletons fit portrait and horizontal layouts in both themes', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const article = ArticleSummary(id: 1, title: 'A long editorial title that wraps across lines', url: 'https://www.pixivision.net/en/a/1', tags: []);
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      for (final dark in [false, true]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: dark
                  ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
                  : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
              home: FrostLayoutScope(
                child: Scaffold(
                  body: ListView(
                    children: const [
                      PixivisionCard(article: article),
                      PixivisionCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(PixivisionCard).first), tester.getSize(find.byType(PixivisionCard).last));
      }
    }
  });
}
