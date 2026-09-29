import 'package:freepiv/shared/ui/fp_icon.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/newest_page.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_toolbar.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:freepiv/shared/widgets/app_click_surface.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_collapsible_header.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/features/search/presentation/widgets/search_header.dart';
import 'package:freepiv/features/pixivision/widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/widgets/search_input.dart';
import 'package:freepiv/shared/widgets/constrained_segmented_button.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';

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
  testWidgets('audience tabs stay outside the moving page during switches', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [newestProvider.overrideWith(_LocalNewest.new)],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
            home: const AppLayoutScope(child: NewestPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final toolbar = find.byType(NewestToolbar);
    final initial = tester.getRect(toolbar);
    expect(toolbar, findsOneWidget);
    expect(find.ancestor(of: toolbar, matching: find.byType(TabBarView)), findsNothing);
    await tester.tap(find.byType(Tab).at(1));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getRect(toolbar), initial);
    await tester.pumpAndSettle();
    expect(tester.getRect(toolbar), initial);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sidebar footer and scrollable destinations share the same hit area', (tester) async {
    Widget item(String label) => DesktopNavItem(label: label, fpIcon: FpIconName.home, selected: false, onTap: () {});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Expanded(child: ListView(children: [item('Home')])),
                  item('Proxy'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final surfaces = find.byType(AppClickSurface);
    expect(tester.getSize(surfaces.first), tester.getSize(surfaces.last));
    expect(tester.getSize(surfaces.last).width, 76);
    expect(tester.takeException(), isNull);
  });

  test('profile header keeps its avatar clear of the back action at every width', () {
    // One geometry with or without a cover, so the loading skeleton and the
    // loaded header never differ in height.
    for (final width in [390.0, 700.0, 1280.0]) {
      final layout = UserCollapsibleHeaderLayout.forWidth(width);
      expect(layout.avatarTop, greaterThanOrEqualTo(AppMetrics.controlHeight + AppMetrics.compactGap));
      expect(layout.horizontalPadding, AppMetrics.columnPadding(width).left);
    }
  });
  testWidgets('search keeps one search action and adapts type controls without overflow', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      for (final scale in [1.0, 2.0]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MaterialApp(
                theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
                home: MediaQuery(
                  data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
                  child: AppLayoutScope(
                    child: Scaffold(
                      body: SearchHeader(onSearch: (_) {}, onSelected: (_) {}),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(tester.takeException(), isNull);
        final input = tester.getRect(find.byType(SearchInput));
        if (size.width < 600) {
          // Phones keep the query row for the field and put the type in tabs.
          expect(tester.getRect(find.byType(SearchTypeTabs)).top, greaterThanOrEqualTo(input.bottom));
        } else {
          final selector = tester.getRect(find.byWidgetPredicate((widget) => widget is SearchTypeSelector || widget is SearchTypeMenuButton));
          expect(selector.left, greaterThan(input.right));
          expect(selector.center.dy, closeTo(input.center.dy, 1));
        }
      }
    }
  });

  testWidgets('segment icon and label remain vertically aligned after selection', (tester) async {
    for (final selected in [0, 1]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppSegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 0, icon: Icon(Icons.image_outlined), label: Text('Illustrations')),
                  ButtonSegment(value: 1, icon: Icon(Icons.menu_book_outlined), label: Text('Novels')),
                ],
                selected: {selected},
                onSelectionChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      for (final entry in [(Icons.image_outlined, 'Illustrations'), (Icons.menu_book_outlined, 'Novels')]) {
        expect((tester.getCenter(find.byIcon(entry.$1)).dy - tester.getCenter(find.text(entry.$2)).dy).abs(), lessThan(1));
      }
      expect(tester.takeException(), isNull);
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
              home: AppLayoutScope(
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
