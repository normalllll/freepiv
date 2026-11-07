import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/discover/page.dart';
import 'package:freepiv/features/search/logic/search_trending_tags_logic.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/entry_row.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

class _FailingTags extends SearchTrendingTags {
  @override
  Future<List<TrendTag>> build() async => throw StateError('offline');
}

void main() {
  testWidgets('history, the entry row, trending tags and Pixivision', (tester) async {
    await mountPilotPage(tester, const DiscoverPage());
    expect(find.byType(FrostFilterChip), findsNWidgets(6), reason: 'every recent search');
    expect(find.byType(AppEntryRow), findsOneWidget);
    expect(find.text('#初音ミク'), findsOneWidget);
  });

  testWidgets('a trending tag is added to the search as a finished word', (tester) async {
    await mountPilotPage(tester, const DiscoverPage());
    await tester.tap(find.text('#猫'));
    await settlePilot(tester, frames: 3);
    final container = ProviderScope.containerOf(tester.element(find.byType(DiscoverPage)));
    expect(container.read(appSearchSessionProvider).rawText, contains('猫'));
  });

  testWidgets('trending tags that fail retry on their own; Pixivision still shows', (tester) async {
    await mountPilotPage(tester, const DiscoverPage(), overrides: {searchTrendingTagsProvider: searchTrendingTagsProvider.overrideWith(_FailingTags.new)});
    expect(find.byType(FrostCompactMessage), findsOneWidget);
    await tester.scrollUntilVisible(find.text(t.pixivision.title).last, 200, scrollable: find.byType(Scrollable).first);
  });

  testWidgets('two tag columns on a phone at double text size', (tester) async {
    await mountPilotPage(tester, const DiscoverPage(), size: phoneSize, textScale: 2);
    expectNoLayoutErrors(tester);
  });

  test('the discover strings exist in all four languages', () => expectLocalesComplete(['discover', 'discoverPage', 'appSearch']));
}
