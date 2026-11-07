import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/discover/discover_sections.dart';
import 'package:freepiv/features/search/logic/search_history_logic.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_autocomplete_session.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

/// The title bar search alone at the top of a default window.
class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.topCenter,
    child: SizedBox(width: 520, height: 40, child: AppTitleBarSearch()),
  );
}

late SearchAutocompleteSession _session;

Future<void> _mount(WidgetTester tester, {Future<List<Tag>> Function(String word)? autocomplete, List<String> history = const []}) async {
  await mountPilotPage(
    tester,
    const _TitleRow(),
    overrides: {
      appSearchSessionProvider: appSearchSessionProvider.overrideWith((ref) {
        _session = SearchAutocompleteSession(initialType: SearchType.illust, autocomplete: autocomplete ?? sampleAutocomplete);
        ref.onDispose(_session.dispose);
        return _session;
      }),
    },
  );
  final container = ProviderScope.containerOf(tester.element(find.byType(AppTitleBarSearch)));
  final notifier = container.read(searchHistoryProvider.notifier);
  for (final entry in container.read(searchHistoryProvider).toList()) {
    notifier.remove(entry);
  }
  for (final entry in history.reversed) {
    notifier.record(entry);
  }
  await tester.pump();
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(FrostCaptionSearch));
  await settlePilot(tester);
}

Future<void> _type(WidgetTester tester, String text) async {
  _session.controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  await tester.pump(const Duration(milliseconds: 300));
  await settlePilot(tester);
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key, {int times = 1}) async {
  for (var press = 0; press < times; press++) {
    await tester.sendKeyEvent(key);
    await tester.pump();
  }
  await settlePilot(tester);
}

Finder _options() => find.byType(FrostSearchOption);

/// The default Windows window: pointer density.
final _windows = TargetPlatformVariant.only(TargetPlatform.windows);

void main() {
  testWidgets('empty input shows the compact discover, all on one screen', (tester) async {
    await _mount(tester, history: ['a', 'b', 'c', 'd', 'e', 'f']);
    await _open(tester);
    expect(find.text(t.discover.history), findsOneWidget);
    for (final entry in ['a', 'b', 'c', 'd', 'e']) {
      expect(find.text(entry), findsOneWidget);
    }
    expect(find.text('f'), findsNothing, reason: 'the last five searches');
    expect(find.text(t.appSearch.allHistory), findsOneWidget);
    expect(find.text(t.navigation.ranking), findsNothing, reason: 'Ranking, pixivision and FANBOX have their own ways in');
    expect(find.byType(DiscoverTagCard), findsNWidgets(8));
    final tags = tester.widgetList(find.byType(DiscoverTagCard)).map((card) => tester.getRect(find.byWidget(card))).toList();
    expect(tags.map((rect) => rect.top).toSet(), hasLength(2), reason: 'two rows of four');
    expect(find.text(t.appSearch.allTrendingTags), findsOneWidget);
    expect(find.byType(DiscoverArticleCard), findsNWidgets(3));
    final last = tester.getRect(find.byType(DiscoverArticleCard).last);
    expect(last.bottom, lessThanOrEqualTo(desktopSize.height), reason: 'no scrolling in the dropdown at 1147×717');
    expectNoLayoutErrors(tester);
  }, variant: _windows);

  testWidgets('arrow keys and Enter reach the tag cards; All trending tags opens the discover page at the tags', (tester) async {
    await _mount(tester);
    await _open(tester);
    final tags = tester.widgetList<DiscoverTagCard>(find.byType(DiscoverTagCard)).map((card) => card.tag.tag).toList();
    await _key(tester, LogicalKeyboardKey.arrowDown, times: 2);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(tags, contains(_session.rawText.trim()), reason: 'after the section\'s own link come its tag cards');

    await _mount(tester);
    await _open(tester);
    await tester.tap(find.text(t.appSearch.allTrendingTags));
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.discover(section: DiscoverSection.trending.name));
  }, variant: _windows);

  testWidgets('a trending tag card keeps the dropdown open and adds the tag with the caret after it', (tester) async {
    await _mount(tester);
    await _open(tester);
    final cardFinder = find.byType(DiscoverTagCard).first;
    final card = tester.widget<DiscoverTagCard>(cardFinder);
    // The card only shows; the search option around it takes the tap.
    await tester.tap(find.ancestor(of: cardFinder, matching: find.byType(FrostSearchOption)).first);
    await settlePilot(tester);
    expect(_session.rawText, '${card.tag.tag} ');
    expect(_session.controller.selection, TextSelection.collapsed(offset: _session.rawText.length));
    expect(_session.focusNode.hasFocus, isTrue);
    expect(find.text(t.navigation.search), findsOneWidget, reason: 'still open, now on the search rows');
    expect(openedLocations, isEmpty);
  }, variant: _windows);

  testWidgets('typing shows the search rows by draft type, then tag completion that keeps text and caret', (tester) async {
    await _mount(tester);
    await _open(tester);
    _session.setType(SearchType.novel);
    await _type(tester, 'miku');
    final labels = tester.widgetList<FrostSearchSuggestionRow>(find.byType(FrostSearchSuggestionRow)).map((row) => row.label).toList();
    expect(labels.take(3), [t.appSearch.searchNovel(query: 'miku'), t.appSearch.searchIllust(query: 'miku'), t.appSearch.searchUser(query: 'miku')]);
    expect(labels, contains('#mikuオリジナル'));

    await tester.tap(find.text('#mikuオリジナル'));
    await settlePilot(tester);
    expect(_session.rawText, 'mikuオリジナル ');
    expect(_session.controller.selection.baseOffset, _session.rawText.length);
    expect(_session.focusNode.hasFocus, isTrue, reason: 'keepsOpen leaves focus and the dropdown');
    expect(find.text(t.navigation.search), findsOneWidget);
  }, variant: _windows);

  testWidgets('a number offers to open the work, user or novel directly; Enter on a highlighted row opens it', (tester) async {
    await _mount(tester);
    await _open(tester);
    await _type(tester, '42');
    expect(find.text(t.search.direct.illust(id: 42)), findsOneWidget);
    expect(find.text(t.search.direct.user(id: 42)), findsOneWidget);
    expect(find.text(t.search.direct.novel(id: 42)), findsOneWidget);
    // Three search rows, then the open rows.
    await _key(tester, LogicalKeyboardKey.arrowDown, times: 4);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(openedLocations.last, AppLocations.illust(42));
  }, variant: _windows);

  testWidgets('Enter while composing with an input method neither submits nor selects', (tester) async {
    await _mount(tester);
    await _open(tester);
    await _type(tester, 'miku');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    _session.controller.value = const TextEditingValue(text: 'miku か', selection: TextSelection.collapsed(offset: 6), composing: TextRange(start: 5, end: 6));
    await tester.pump();
    await _key(tester, LogicalKeyboardKey.enter);
    expect(openedLocations, isEmpty);
    expect(_session.rawText, 'miku か', reason: 'the composing text stays as typed');
  }, variant: _windows);

  testWidgets('a failed completion says so, with its details and a retry that keeps the dropdown open', (tester) async {
    var attempts = 0;
    await _mount(
      tester,
      autocomplete: (word) async {
        if (attempts++ == 0) throw StateError('completion offline');
        return sampleAutocomplete(word);
      },
    );
    await _open(tester);
    await _type(tester, 'miku');
    expect(find.text(t.appSearch.suggestionsFailed), findsOneWidget);
    expect(find.byType(FrostErrorDetails), findsOneWidget);
    await tester.tap(find.text(t.common.retry));
    await tester.pump(const Duration(milliseconds: 300));
    await settlePilot(tester);
    expect(attempts, 2);
    expect(find.text(t.appSearch.suggestionsFailed), findsNothing);
    expect(find.text('#mikuオリジナル'), findsOneWidget);
    expect(_session.rawText, 'miku');
  }, variant: _windows);

  testWidgets('every row and card in the compact discover is an option the keys reach', (tester) async {
    await _mount(tester, history: ['a']);
    await _open(tester);
    // History row, its section action, three entries, the tags action and eight tags, Pixivision's action and three articles.
    expect(_options(), findsAtLeastNWidgets(1 + 3 + 8 + 3));
    expect(find.descendant(of: _options(), matching: find.byType(DiscoverTagCard)), findsNWidgets(8));
    expect(find.descendant(of: _options(), matching: find.byType(DiscoverArticleCard)), findsNWidgets(3));
  }, variant: _windows);

  test('stale trending tags and Pixivision refresh after ten minutes, not before', () {
    var now = DateTime(2026, 11, 7, 12);
    final freshness = DiscoverFreshness(now: () => now);
    expect(freshness.takeStale(), isFalse, reason: 'the first show starts the clock');
    now = now.add(const Duration(minutes: 9));
    expect(freshness.takeStale(), isFalse);
    now = now.add(const Duration(minutes: 2));
    expect(freshness.takeStale(), isTrue);
    expect(freshness.takeStale(), isFalse, reason: 'fetched again just now');
  });
}
