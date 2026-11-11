import 'package:flutter/widgets.dart';
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
  Widget build(BuildContext context) => Column(
    children: [
      Text('at $location'),
      const SizedBox(width: 520, child: AppTitleBarSearch()),
      SizedBox(width: 520, child: SearchBox(onSearch: (_) {})),
    ],
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

  testWidgets('the title bar search chooses the type inside its field', (tester) async {
    await _mount(tester);
    FrostToolbarMenuButton menu() => tester.widget<FrostCaptionSearch>(find.byType(FrostCaptionSearch)).actions.single as FrostToolbarMenuButton;
    expect(menu().valueLabel, t.search.type.illustManga);
    expect(menu().entries.map((entry) => (entry as FrostMenuAction).label), [t.search.type.illustManga, t.search.type.novel, t.search.type.user]);
    expect((menu().entries.first as FrostMenuAction).checked, isTrue);
    (menu().entries[1] as FrostMenuAction).onSelected!();
    await tester.pump();
    expect(menu().valueLabel, t.search.type.novel);
    expect((menu().entries[1] as FrostMenuAction).checked, isTrue);
    await _finish(tester);
  });

  testWidgets('the title bar search gives its room to the placeholder, not a shortcut hint', (tester) async {
    await _mount(tester);
    final caption = tester.widget<FrostCaptionSearch>(find.byType(FrostCaptionSearch));
    expect(caption.hint, isNull);
    expect(caption.placeholder, 'Search illustrations, novels, users');
    await _finish(tester);
  });
}

/// The title bar search's element is a ConsumerWidget's element, a WidgetRef.
void _submit(BuildContext element, {SearchType? type}) => AppSearchActions(element as WidgetRef, element).submit(type: type);
