import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/features/search/logic/search_history_logic.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_box.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

class _MemoryStore implements AppSettingsStore {
  final values = <String, dynamic>{};

  @override
  Map<String, dynamic> load() => Map.of(values);

  @override
  Future<void> write(String key, dynamic value) async => value == null ? values.remove(key) : values[key] = value;
}

class _Page extends StatelessWidget {
  const _Page(this.location);

  final String location;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('at $location'),
        const SizedBox(width: 520, child: AppTitleBarSearch()),
        SizedBox(width: 520, child: SearchBox(onSearch: (_) {})),
      ],
    ),
  );
}

Future<(GoRouter, ProviderContainer)> _mount(WidgetTester tester) async {
  await AppSettings.initialize(store: _MemoryStore());
  // No network in tests: failed loads stay failed instead of retrying.
  final container = ProviderContainer(retry: (_, _) => null);
  addTearDown(container.dispose);
  final router = GoRouter(
    routes: [
      for (final path in ['/', AppRoute.searchIllustResult.path, AppRoute.searchNovelResult.path, AppRoute.searchUserResult.path])
        GoRoute(path: path, builder: (context, state) => _Page(state.uri.toString())),
    ],
  );
  addTearDown(router.dispose);
  tester.view.physicalSize = const Size(1147, 717);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(
        child: FrostApp.router(config: freepivFrostConfig, routerConfig: router, title: 'freepiv'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router, container);
}

/// Unmounts and lets the debounce and cache-expiry timers run out.
Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 11));
}

void main() {
  testWidgets('the title bar and the page header show one session with one controller', (tester) async {
    final (_, container) = await _mount(tester);
    final caption = tester.widget<FrostCaptionSearch>(find.byType(FrostCaptionSearch));
    final header = tester.widget<FrostSearchInput>(find.descendant(of: find.byType(SearchBox), matching: find.byType(FrostSearchInput)));
    final session = container.read(appSearchSessionProvider);
    expect(caption.controller, same(session.controller));
    expect(header.controller, same(session.controller));
    expect(caption.controller, isA<FrostTokenEditingController>());
    // A focus node belongs to one field: the header brings its own.
    expect(caption.focusNode, same(session.focusNode));
    expect(header.focusNode, isNot(same(session.focusNode)));

    session.controller.text = 'miku ';
    await tester.pump();
    expect(tester.widget<FrostSearchInput>(find.descendant(of: find.byType(SearchBox), matching: find.byType(FrostSearchInput))).controller.text, 'miku ');
    await _finish(tester);
  });

  testWidgets('submitting trims, records history and opens the results with the chosen type', (tester) async {
    final (router, container) = await _mount(tester);
    final session = container.read(appSearchSessionProvider);
    final element = tester.element(find.byType(AppTitleBarSearch));

    session.controller.text = '   ';
    _submit(element);
    await tester.pumpAndSettle();
    expect(find.text('at /'), findsOneWidget, reason: 'a blank query submits nothing');

    session.controller.text = '  miku  ';
    _submit(element);
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), AppLocations.search(AppSearchKind.illust, 'miku'));
    expect(container.read(searchHistoryProvider).first, 'miku');
    expect(router.canPop(), isTrue);

    session.controller.text = 'rin';
    _submit(tester.element(find.byType(AppTitleBarSearch)), type: SearchType.novel);
    await tester.pumpAndSettle();
    // This flat router has no result page scope, so the submission opens a
    // page; in-place changes are covered with the app router in
    // search_in_place_test.dart.
    expect(find.text('at ${AppLocations.search(AppSearchKind.novel, 'rin')}'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('with words the search group offers every type, the draft type first, and a number opens directly', (tester) async {
    final (_, container) = await _mount(tester);
    final session = container.read(appSearchSessionProvider)..setType(SearchType.novel);
    session.controller.text = '42';
    await tester.pump();
    final groups = _sections(tester);
    expect(groups.first.children.map((item) => (item as FrostSearchSuggestionRow).label), ['Search novels for “42”', 'Search illustrations & manga for “42”', 'Search users for “42”']);
    expect(groups[1].children.map((item) => (item as FrostSearchSuggestionRow).label), ['Open illustration #42', 'Open user #42', 'Open novel #42']);
    await _finish(tester);
  });

  testWidgets('with no words the dropdown has recent searches and the discover entries', (tester) async {
    final (_, container) = await _mount(tester);
    for (final query in ['a', 'b', 'c', 'd', 'e', 'f']) {
      container.read(searchHistoryProvider.notifier).record(query);
    }
    await tester.pump();
    final groups = _sections(tester);
    expect(groups.first.children, hasLength(5));
    expect(groups.first.actionLabel, 'All history');
    expect(groups[1].children.map((item) => (item as FrostSearchSuggestionRow).label), ['Ranking', 'pixivision', 'FANBOX']);
    await _finish(tester);
  });

  testWidgets('Ctrl K is advertised on the title bar search', (tester) async {
    await _mount(tester);
    final caption = tester.widget<FrostCaptionSearch>(find.byType(FrostCaptionSearch));
    expect(caption.hint, const FrostShortcut(LogicalKeyboardKey.keyK, primary: true).hintLabel(tester.element(find.byType(FrostCaptionSearch))));
    expect(caption.placeholder, 'Search illustrations, novels, users');
    await _finish(tester);
  });
}

/// The title bar search's element is a ConsumerWidget's element, a WidgetRef.
void _submit(BuildContext element, {SearchType? type}) => AppSearchActions(element as WidgetRef, element).submit(type: type);

/// The title bar dropdown's sections, in order.
List<FrostSearchSection> _sections(WidgetTester tester) {
  final content = tester.widget<FrostCaptionSearch>(find.byType(FrostCaptionSearch)).content! as Column;
  return content.children.whereType<FrostSearchSection>().toList();
}
