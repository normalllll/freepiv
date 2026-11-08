import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/features/search/presentation/search_filter_panel.dart';
import 'package:freepiv/features/search/presentation/search_result_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/user_card.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

Future<void> _mount(WidgetTester tester, {SearchType type = SearchType.illust, Size size = desktopSize, double textScale = 1, SearchFiltersState? filters}) {
  sampleSearchRequests.clear();
  return mountPilotPage(
    tester,
    SearchResultPage(type: type, initialKeyword: 'miku', initialFilters: filters),
    size: size,
    textScale: textScale,
  );
}

/// Chooses [value] in the panel's [field] picker, as its menu would.
Future<void> _pick(WidgetTester tester, String field, Object? value) async {
  final picker = find.byWidgetPredicate((widget) => widget is FrostPicker && widget.label == field);
  expect(picker, findsOneWidget, reason: field);
  (tester.widget(picker) as dynamic).onChanged(value);
  await settlePilot(tester, frames: 2);
}

void main() {
  testWidgets('results load per tab under the words, with sort and filter for works only', (tester) async {
    await _mount(tester);
    expect(tester.widget<AppArtworkCard>(find.byType(AppArtworkCard).first).illust.id, sampleIllusts().first.id);
    expect(sampleSearchRequests.last, const SearchResultRequest(keyword: 'miku', filter: SearchFilterState()));
    await tester.tap(find.text(t.search.type.user));
    await settlePilot(tester);
    final users = sampleUserPreviews(count: 6);
    expect(tester.widget<AppUserCard>(find.byType(AppUserCard).first).preview.user.id, users.first.user.id);
    expect(find.text(users.first.user.name), findsOneWidget);
    final filter = tester.widgetList<FrostButton>(find.byType(FrostButton)).firstWhere((button) => button.label == t.common.filter);
    expect(filter.onPressed, isNull, reason: 'users have no filters');
    expect(filter.tooltip, t.searchPage.noUserFilters);
  });

  testWidgets('new words in place start the results again at the top', (tester) async {
    await _mount(tester);
    // The visible tab's results, scrolling down.
    Finder results() => find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down).hitTestable().first;
    await tester.drag(results(), const Offset(0, -300));
    await settlePilot(tester, frames: 4);
    double offset() => tester.state<ScrollableState>(results()).position.pixels;
    expect(offset(), greaterThan(0));
    tester.widget<AppSearchResultsScope>(find.byType(AppSearchResultsScope)).onSubmitted('rin', SearchType.illust);
    await settlePilot(tester);
    expect(sampleSearchRequests.last.keyword, 'rin');
    expect(offset(), 0);
  });

  testWidgets('the filter panel sends nothing until Apply, then every chosen value', (tester) async {
    await _mount(tester);
    final before = sampleSearchRequests.length;
    await tester.tap(find.byWidgetPredicate((widget) => widget is FrostButton && widget.label == t.common.filter));
    await settlePilot(tester, frames: 6);
    expect(find.byType(SearchFilterPanel), findsOneWidget);
    await _pick(tester, t.search.filters.target, SearchTarget.exactMatchForTags);
    await _pick(tester, t.search.filters.date, SearchDatePreset.week);
    await _pick(tester, t.search.filters.bookmarks, 1000);
    await _pick(tester, t.search.filters.contentType, SearchContentType.manga);
    await _pick(tester, t.search.filters.ratio, SearchRatio.portrait);
    await _pick(tester, t.searchPage.minWidth, 2000);
    await _pick(tester, t.searchPage.minHeight, 1000);
    final tool = find.descendant(of: find.byType(SearchFilterPanel), matching: find.byType(EditableText));
    await tester.ensureVisible(tool);
    await tester.enterText(tool, 'SAI');
    await settlePilot(tester, frames: 2);
    expect(sampleSearchRequests.length, before, reason: 'nothing is searched while choosing');

    await tester.ensureVisible(find.text(t.common.apply));
    await tester.tap(find.text(t.common.apply));
    await settlePilot(tester);
    final filter = sampleSearchRequests.last.filter;
    expect(filter.target, SearchTarget.exactMatchForTags);
    expect(filter.datePreset, SearchDatePreset.week);
    expect(filter.bookmarkTotal, 1000);
    expect(filter.contentType, SearchContentType.manga);
    expect(filter.ratio, SearchRatio.portrait);
    expect(filter.minWidth, 2000);
    expect(filter.minHeight, 1000);
    expect(filter.tool, 'SAI');
    final options = filter.toOptions(DateTime(2026, 11, 7));
    expect(
      (options.startDate, options.endDate, options.bookmarkTotal, options.widthMin, options.heightMin, options.tool),
      ('2026-11-01', '2026-11-07', 1000, 2000, 1000, 'SAI'),
    );
    expect(find.byType(FrostFilterBar), findsOneWidget, reason: 'the filters in effect show over the results');
  });

  testWidgets('a popular preview says it shows one batch', (tester) async {
    await _mount(
      tester,
      filters: const SearchFiltersState(illust: SearchFilterState(order: SearchOrder.popularPreview)),
    );
    expect(find.text(t.search.filters.previewNote), findsOneWidget);
    expect(sampleSearchRequests.last.filter.order, SearchOrder.popularPreview);
  });

  testWidgets('novel filters match by novel targets', (tester) async {
    await _mount(tester, type: SearchType.novel);
    await tester.tap(find.byWidgetPredicate((widget) => widget is FrostButton && widget.label == t.common.filter));
    await settlePilot(tester, frames: 6);
    await _pick(tester, t.search.filters.target, SearchNovelTarget.text);
    expect(find.byWidgetPredicate((widget) => widget is FrostPicker && widget.label == t.search.filters.contentType), findsNothing);
    await tester.tap(find.text(t.common.apply));
    await settlePilot(tester);
    expect(sampleSearchRequests.last.filter.novelTarget, SearchNovelTarget.text);
  });

  testWidgets('every tab fits a phone at double text size', (tester) async {
    await _mount(
      tester,
      size: phoneSize,
      textScale: 2,
      filters: const SearchFiltersState(illust: SearchFilterState(bookmarkTotal: 1000, ratio: SearchRatio.square)),
    );
    expectNoLayoutErrors(tester);
    for (final label in [t.search.type.novel, t.search.type.user]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await settlePilot(tester);
      expectNoLayoutErrors(tester);
    }
  });

  test('the search strings exist in all four languages', () => expectLocalesComplete(['search', 'searchPage']));
}
