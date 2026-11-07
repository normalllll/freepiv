import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/ranking/logic/ranking_logic.dart';
import 'package:freepiv/features/ranking/presentation/ranking_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:frost_ui/frost_ui.dart';

Future<void> _frames(WidgetTester tester) async {
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _titleOf(WidgetTester tester, int page) =>
    tester.widgetList<FrostTitleMenu>(find.byKey(const ValueKey('ranking-mode'), skipOffstage: false)).elementAt(page).title;

void main() {
  testWidgets('each ranking page keeps the mode its route named; opening one changes nothing shared', (tester) async {
    tester.view.physicalSize = const Size(1147, 717);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await AppSettings.initialize(store: SampleSettingsStore());
    pixivAccountNotifier.value = sampleAccount;
    addTearDown(() => pixivAccountNotifier.value = null);
    AppRouter.router.go(AppRoute.home.path);
    await tester.pumpWidget(
      FreepivApp(
        windowController: FrostWindowController(minimumSize: const Size(320, 480)),
        overrides: sampleOverrides,
      ),
    );
    await _frames(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(FrostShell)));

    AppRouter.router.push(AppLocations.ranking(mode: IllustRankingMode.week.name));
    await _frames(tester);
    AppRouter.router.push(AppLocations.ranking(mode: IllustRankingMode.month.name));
    await _frames(tester);
    expect(tester.takeException(), isNull);
    expect(_titleOf(tester, 0), endsWith(rankingModeLabel(t, IllustRankingMode.week)), reason: 'the page below keeps its own mode');
    expect(_titleOf(tester, 1), endsWith(rankingModeLabel(t, IllustRankingMode.month)));
    expect(container.read(rankingProvider).illustMode, IllustRankingMode.day, reason: 'opening a page does not switch the shared mode');
    expect(container.read(rankingProvider).illustSourceFor(IllustRankingMode.month).initialized, isTrue, reason: 'the route mode loaded');

    // The old per-kind paths open the one page on that kind and mode.
    AppRouter.router.push('${AppRoute.legacyRankingNovel.path}?${AppRouteQuery.mode}=${NovelRankingMode.weekRookie.name}');
    await _frames(tester);
    expect(_titleOf(tester, 2), endsWith(rankingModeLabel(t, NovelRankingMode.weekRookie)));
  });
}
