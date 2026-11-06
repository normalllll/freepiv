import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_collapsible_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/pixivision/widgets.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';

void main() {
  test('profile header keeps its avatar clear of the back action at every width', () {
    // One geometry with or without a cover, so the loading skeleton and the
    // loaded header never differ in height.
    for (final width in [390.0, 700.0, 1280.0]) {
      final layout = UserCollapsibleHeaderLayout.forWidth(width);
      expect(layout.avatarTop, greaterThanOrEqualTo(40 + FrostGap.related));
      expect(layout.horizontalPadding, FrostMetrics.columnPadding(width).left);
    }
  });

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
