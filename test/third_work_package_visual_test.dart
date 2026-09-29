import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/features/about/presentation/about_page.dart';
import 'package:freepiv/features/discover/page.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/fanbox/navigation.dart';
import 'package:freepiv/features/fanbox/page.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/features/pixivision/page.dart';
import 'package:freepiv/features/search/logic/search_history_logic.dart';
import 'package:freepiv/features/search/logic/search_trending_tags_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_header.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/widgets/search_input.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _pixivisionHome = 'https://www.pixivision.net/en/';
const _fanboxLocation = (section: FanboxSection.home, creatorId: '', query: '');

final _articles = [
  for (var index = 0; index < 3; index++)
    ArticleSummary(
      id: index + 1,
      title: 'Local article fixture ${index + 1}: color and light in illustration',
      url: 'https://www.pixivision.net/en/a/${index + 1}',
      publishDate: '2026-09-20',
      category: const ArticleLink(title: 'Illustration', url: 'https://www.pixivision.net/en/c/1'),
      tags: const [],
    ),
];

final _pixivisionListing = PixivisionListing(
  ArticlePage(
    url: _pixivisionHome,
    title: 'Latest articles',
    articles: _articles,
    monthlyRanking: _articles,
    recommended: _articles,
    categories: const [ArticleLink(title: 'Illustration', url: 'https://www.pixivision.net/en/c/1')],
  ),
);

class _FixturePixivisionBrowse extends PixivisionBrowse {
  @override
  Future<PixivisionListing> build(String url) async => _pixivisionListing;
}

class _FixtureTrendingTags extends SearchTrendingTags {
  @override
  Future<List<TrendTag>> build() async => const [];
}

class _FixtureFanboxSession extends FanboxSession {
  @override
  Future<String?> build() async => 'local-fixture-session';
}

class _FixtureFanboxBrowse extends FanboxBrowse {
  @override
  Future<FanboxCollection> build(FanboxLocation location) async => const FanboxCollection([]);
}

Future<void> _capture(GlobalKey boundary, String name) async {
  final image = await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File('build/ui-review/third-$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('discover, Pixivision, FANBOX and About visual evidence', (tester) async {
    LocaleSettings.setLocale(AppLocale.enUs);
    PackageInfo.setMockInitialValues(appName: 'freepiv', packageName: 'freepiv', version: '0.1.1', buildNumber: '5', buildSignature: '');
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

    final pixivisionProvider = pixivisionBrowseProvider(_pixivisionHome);
    final fanboxProvider = fanboxBrowseProvider(_fanboxLocation);
    final pages = <String, Widget>{
      'discover': const DiscoverPage(),
      'pixivision': const PixivisionPage(),
      'fanbox': const FanboxPage(location: _fanboxLocation),
      'about': const AboutPage(),
    };

    for (final entry in pages.entries) {
      for (final size in [
        const Size(390, 844),
        if (entry.key == 'fanbox') ...[const Size(583, 720), const Size(584, 720), const Size(664, 720)],
        const Size(800, 900),
        const Size(1440, 900),
      ]) {
        tester.view.physicalSize = size;
        for (final brightness in Brightness.values) {
          final boundary = GlobalKey();
          final overrides = [
            searchHistoryProvider.overrideWithValue(const ['local fixture query', 'illustration study']),
            searchTrendingTagsProvider.overrideWith(_FixtureTrendingTags.new),
            pixivisionProvider.overrideWith(_FixturePixivisionBrowse.new),
            fanboxSessionProvider.overrideWith(_FixtureFanboxSession.new),
            fanboxProvider.overrideWith(_FixtureFanboxBrowse.new),
          ];
          await tester.pumpWidget(
            ProviderScope(
              overrides: overrides,
              child: TranslationProvider(
                child: MaterialApp(
                  theme: brightness == Brightness.dark
                      ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en', 'US'))
                      : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en', 'US')),
                  home: MediaQuery(
                    data: MediaQueryData(size: size),
                    child: AppLayoutScope(
                      child: RepaintBoundary(key: boundary, child: entry.value),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
          await tester.pump();
          expect(find.byWidget(entry.value), findsOneWidget, reason: '${entry.key} widget');
          if (entry.key == 'discover') {
            final historyLeft = tester.getTopLeft(find.text('Recent searches')).dx;
            final trendingLeft = tester.getTopLeft(find.text('Trending Tags')).dx;
            expect(trendingLeft, closeTo(historyLeft, 1), reason: 'discover section left edges at $size');
            if (size.width == 1440) {
              // Segments or dropdown (depending on the measured labels), the
              // type control ends inside the page inset and never scrolls.
              final typeControl = find.byWidgetPredicate((widget) => widget is SearchTypeSelector || widget is SearchTypeMenuButton);
              expect(find.descendant(of: typeControl, matching: find.byType(Scrollable)), findsNothing);
              expect(tester.getRect(typeControl).right, lessThanOrEqualTo(size.width - 12));
            }
          }
          expect(tester.takeException(), isNull, reason: '${entry.key} $size $brightness');
          await tester.runAsync(() => _capture(boundary, '${entry.key}-${size.width.toInt()}-${brightness.name}'));
          if (entry.key == 'fanbox') {
            final groups = tester.widget<TabBar>(find.byType(TabBar));
            expect(groups.isScrollable, isTrue);
            expect(groups.indicator, isNull);
            expect(groups.labelPadding, EdgeInsets.symmetric(horizontal: AppMetrics.tabLabelPadding(size.width)));
            final layout = fanboxNavigationLayout(tester.element(find.byType(TabBar)), size.width);
            final tabRect = tester.getRect(find.byType(TabBar));
            final collectionRect = tester.getRect(find.descendant(of: find.byType(FanboxSectionNavigation), matching: find.byType(TextButton)));
            expect(collectionRect.top > tabRect.bottom, layout.stacked, reason: '$size breakpoint');
            final headerBottom = tabRect.top - 12 + layout.height;
            expect(headerBottom - (layout.stacked ? collectionRect.bottom : tabRect.bottom), lessThanOrEqualTo(14), reason: '$size unused header space');
          }
          if (entry.key == 'pixivision' && size.width == 390 && brightness == Brightness.light) {
            final tabBar = find.byType(TabBar);
            expect(tabBar, findsOneWidget);
            expect(tester.widget<TabBar>(tabBar).isScrollable, isTrue);
            // At phone width the category trigger shares the row, so the
            // second tab starts partly clipped inside the tab strip.
            final rankingTab = find.descendant(of: tabBar, matching: find.text(t.pixivision.ranking));
            await tester.ensureVisible(rankingTab);
            await tester.pump(const Duration(milliseconds: 300));
            await tester.tap(rankingTab);
            await tester.pumpAndSettle();
            expect(tester.widget<TabBar>(tabBar).controller!.index, PixivisionSection.ranking.index);
            expect(find.text(t.pixivision.ranking), findsOneWidget);
            expect(find.textContaining('Local article fixture 1'), findsOneWidget);
            final tabScroller = find.descendant(of: tabBar, matching: find.byType(Scrollable));
            await tester.drag(tabScroller, const Offset(-220, 0));
            await tester.pumpAndSettle();
            expect(tester.getRect(find.text(t.pixivision.tags).first).right, lessThanOrEqualTo(size.width));
          }
          if (entry.key == 'discover' && size.width == 390) {
            // On a phone discover leaves the type to the results page, so the
            // header is just the query row.
            expect(find.byType(SearchTypeSelector), findsNothing);
            expect(find.byType(SearchTypeMenuButton), findsNothing);
            expect(find.byType(SearchTypeTabs), findsNothing);
            expect(find.byType(SearchInput), findsOneWidget);
          }
        }
      }
    }
  });
}
