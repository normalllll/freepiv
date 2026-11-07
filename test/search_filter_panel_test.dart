import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/search_filter_panel.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

Future<void> _mount(WidgetTester tester, SearchType type, Size size, {double textScale = 1, SearchFilterState filter = const SearchFilterState()}) =>
    mountPilotPage(
      tester,
      SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width < 420 ? size.width : 420,
            child: SearchFilterPanel(type: type, filter: filter, onApply: (_) {}, onCancel: () {}),
          ),
        ),
      ),
      size: size,
      textScale: textScale,
    );

void main() {
  for (final size in [desktopSize, phoneSize]) {
    testWidgets('every filter label shows once and the panel lays out at $size', (tester) async {
      await _mount(tester, SearchType.illust, size);
      for (final label in [
        t.search.filters.target,
        t.search.filters.date,
        t.search.filters.bookmarks,
        t.search.filters.contentType,
        t.search.filters.ratio,
        t.searchPage.minWidth,
        t.searchPage.minHeight,
        t.search.filters.tool,
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expectNoLayoutErrors(tester);
    });

    testWidgets('a custom range names its years and fits at double text size at $size', (tester) async {
      await _mount(
        tester,
        SearchType.illust,
        size,
        textScale: 2,
        filter: SearchFilterState(datePreset: SearchDatePreset.custom, customStart: DateTime(2020, 12, 18), customEnd: DateTime(2021, 12, 18)),
      );
      expect(tester.widget<FrostDateRangePicker>(find.byType(FrostDateRangePicker)).showsYear, isTrue);
      expectNoLayoutErrors(tester);
    });

    testWidgets('the novel panel lays out at $size', (tester) async {
      await _mount(tester, SearchType.novel, size);
      expect(find.text(t.search.filters.target), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('the buttons wrap instead of overflowing at double text size at $size', (tester) async {
      await _mount(tester, SearchType.novel, size, textScale: 2);
      expect(find.text(t.common.apply), findsOneWidget);
      expectNoLayoutErrors(tester);
    });
  }

  group('columns', () {
    double dx(WidgetTester tester, String label) => tester.getTopLeft(find.text(label)).dx;
    double dy(WidgetTester tester, String label) => tester.getTopLeft(find.text(label)).dy;

    Future<void> mountAt(WidgetTester tester, Size size, {double textScale = 1, SearchType type = SearchType.illust}) => mountPilotPage(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          child: SearchFilterPanel(type: type, filter: const SearchFilterState(), onApply: (_) {}, onCancel: () {}),
        ),
      ),
      size: size,
      textScale: textScale,
    );

    testWidgets('a wide window has two columns in the agreed order', (tester) async {
      await mountAt(tester, desktopSize);
      expect(dy(tester, t.search.filters.target), dy(tester, t.search.filters.date));
      expect(dx(tester, t.search.filters.date), greaterThan(dx(tester, t.search.filters.target)));
      expect(dy(tester, t.search.filters.bookmarks), greaterThan(dy(tester, t.search.filters.target)));
      expect(dy(tester, t.search.filters.bookmarks), dy(tester, t.search.filters.contentType));
      expect(dy(tester, t.search.filters.ratio), dy(tester, t.search.filters.tool));
      expect(dy(tester, t.searchPage.minWidth), dy(tester, t.searchPage.minHeight));
      expect(dx(tester, t.search.filters.tool), dx(tester, t.search.filters.date));
      expect(dy(tester, t.searchPage.minWidth), greaterThan(dy(tester, t.search.filters.tool)));
      expect(tester.getSize(find.byType(SearchFilterPanel)).width, SearchFilterPanel.twoColumnsWidth);
      expectNoLayoutErrors(tester);
    });

    testWidgets('a narrow window has one column', (tester) async {
      await mountAt(tester, phoneSize);
      expect(dy(tester, t.search.filters.bookmarks), greaterThan(dy(tester, t.search.filters.date)));
      expect(dx(tester, t.search.filters.bookmarks), dx(tester, t.search.filters.date));
      expectNoLayoutErrors(tester);
    });

    testWidgets('double text has one column on a wide window', (tester) async {
      await mountAt(tester, desktopSize, textScale: 2);
      expect(dy(tester, t.search.filters.bookmarks), greaterThan(dy(tester, t.search.filters.date)));
    });

    testWidgets('the novel panel follows the same rule', (tester) async {
      await mountAt(tester, desktopSize, type: SearchType.novel);
      expect(dy(tester, t.search.filters.target), dy(tester, t.search.filters.date));
      expect(dy(tester, t.search.filters.bookmarks), greaterThan(dy(tester, t.search.filters.date)));
      expect(find.text(t.search.filters.contentType), findsNothing);
      expectNoLayoutErrors(tester);
    });
  });
}
