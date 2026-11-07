import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/newest_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

/// Every first-page request, by feed.
final _requested = <NewestFeedKey>[];

class _Feed extends NewestListSource {
  _Feed(NewestFeedKey key, this.answer) : super(key: key);

  final Future<Object> Function(NewestFeedKey key) answer;

  @override
  Future<Object> loadFirstPage() {
    _requested.add(key);
    return answer(key);
  }

  @override
  Future<Object> loadNextPage(String nextUrl) async => const IllustPageResult(illusts: [], rankingIllusts: []);
}

class _Newest extends Newest {
  _Newest(this.answer);

  final Future<Object> Function(NewestFeedKey key) answer;

  @override
  NewestListSource createSource(NewestFeedKey key) => _Feed(key, answer);
}

Future<Object> _sample(NewestFeedKey key) => SampleNewestSource(key).loadFirstPage();

Future<void> _mount(WidgetTester tester, {Future<Object> Function(NewestFeedKey key) answer = _sample, Size size = desktopSize, double textScale = 1}) {
  _requested.clear();
  return mountPilotPage(
    tester,
    const NewestPage(),
    size: size,
    textScale: textScale,
    overrides: {newestProvider: newestProvider.overrideWith(() => _Newest(answer))},
  );
}

Future<void> _choose(WidgetTester tester, Key menu, String option) async {
  await tester.tap(find.byKey(menu));
  await settlePilot(tester);
  await tester.tap(find.text(option).last);
  await settlePilot(tester);
}

Future<void> _showAudience(WidgetTester tester, String tab) async {
  await tester.tap(find.descendant(of: find.byType(FrostTabBar), matching: find.text(tab)));
  await settlePilot(tester);
}

void main() {
  testWidgets('every legal audience, type and scope is reachable from the menus and asks for its own feed', (tester) async {
    await _mount(tester);
    final t = context();
    expect(_requested, [const NewestFeedKey(audience: NewestAudience.following, workType: NewestWorkType.illustManga)]);
    expect(find.byType(AppArtworkCard), findsWidgets);

    final reached = <NewestFeedKey>{..._requested};
    for (final scope in NewestFollowScope.values) {
      await _choose(tester, const ValueKey('newest-scope'), newestFollowScopeLabel(t, scope));
      for (final type in newestWorkTypeOptions(NewestAudience.following)) {
        await _choose(tester, const ValueKey('newest-type'), newestWorkTypeLabel(t, type));
        expect(_requested, contains(NewestFeedKey(audience: NewestAudience.following, workType: type, followScope: scope)));
        reached.addAll(_requested);
      }
    }
    await _choose(tester, const ValueKey('newest-scope'), t.newest.followScope.all);

    await _showAudience(tester, t.newest.audience.mypixiv);
    expect(find.byKey(const ValueKey('newest-scope')), findsNothing, reason: 'only Following has a scope');
    for (final type in newestWorkTypeOptions(NewestAudience.mypixiv)) {
      await _choose(tester, const ValueKey('newest-type'), newestWorkTypeLabel(t, type));
      reached.addAll(_requested);
    }
    await _showAudience(tester, t.newest.audience.everyone);
    for (final type in newestWorkTypeOptions(NewestAudience.everyone)) {
      await _choose(tester, const ValueKey('newest-type'), newestWorkTypeLabel(t, type));
      reached.addAll(_requested);
    }
    expect(reached, newestFeedKeys.toSet(), reason: 'the 11 legal combinations');
    expectNoLayoutErrors(tester);
  });

  testWidgets('moving between audiences keeps the type that still holds', (tester) async {
    await _mount(tester);
    final t = context();
    // Illust & Manga for follows becomes Illust for everyone.
    await _showAudience(tester, t.newest.audience.everyone);
    expect(_requested.last, const NewestFeedKey(audience: NewestAudience.everyone, workType: NewestWorkType.illust));
    expect(find.descendant(of: find.byKey(const ValueKey('newest-type')), matching: find.text(t.newest.workType.illust)), findsOneWidget);

    // Everyone's Manga becomes Illust & Manga for My pixiv.
    await _choose(tester, const ValueKey('newest-type'), t.newest.workType.manga);
    await _showAudience(tester, t.newest.audience.mypixiv);
    expect(_requested.last, const NewestFeedKey(audience: NewestAudience.mypixiv, workType: NewestWorkType.illustManga));

    // Novels stay novels everywhere.
    await _choose(tester, const ValueKey('newest-type'), t.newest.workType.novel);
    expect(find.byType(AppNovelRow), findsWidgets);
    await _showAudience(tester, t.newest.audience.everyone);
    expect(_requested.last, const NewestFeedKey(audience: NewestAudience.everyone, workType: NewestWorkType.novel));
    expect(find.byType(AppNovelRow), findsWidgets);
    expect(find.byType(AppArtworkCard), findsNothing);
  });

  testWidgets('empty: each audience says what is missing; private follows say so apart', (tester) async {
    await _mount(tester, answer: (key) async => const IllustPageResult(illusts: [], rankingIllusts: []));
    final t = context();
    expect(find.text(t.newest.empty.following), findsOneWidget);
    await _choose(tester, const ValueKey('newest-scope'), t.newest.followScope.private);
    expect(find.text(t.newest.empty.privateFollows), findsOneWidget);
    expect(find.text(t.newest.empty.following), findsNothing);
    await _showAudience(tester, t.newest.audience.everyone);
    expect(find.text(t.newest.empty.everyone), findsOneWidget);
  });

  testWidgets('loading shows card placeholders; a failed feed retries over the section', (tester) async {
    final never = Completer<Object>();
    await _mount(tester, answer: (_) => never.future);
    expect(find.byType(AppArtworkWaterfallSkeleton), findsOneWidget);

    var attempts = 0;
    await _mount(
      tester,
      answer: (key) async {
        if (attempts++ == 0) throw StateError('offline');
        return SampleNewestSource(key).loadFirstPage();
      },
    );
    expect(find.byType(FrostErrorContent), findsOneWidget);
    await tester.tap(find.text(context().common.retry));
    await settlePilot(tester);
    expect(find.byType(FrostErrorContent), findsNothing);
    expect(find.byType(AppArtworkCard), findsWidgets);
  });

  testWidgets('long titles and names fit a phone at double text size, with the menus in the tab row', (tester) async {
    await _mount(
      tester,
      size: phoneSize,
      textScale: 2,
      answer: (key) async => key.isNovel
          ? NovelPageResult(novels: sampleNovels(count: 3, title: longText, author: longText), rankingNovels: const [])
          : IllustPageResult(illusts: sampleIllusts(count: 4), rankingIllusts: const []),
    );
    expectNoLayoutErrors(tester, where: 'illustrations');
    expect(find.byKey(const ValueKey('newest-type')), findsNothing, reason: 'a phone has one menu for type and scope');
    await _choose(tester, const ValueKey('newest-feed'), context().newest.workType.novel);
    expect(find.byType(AppNovelRow), findsWidgets);
    await _choose(tester, const ValueKey('newest-feed'), context().newest.followScope.private);
    expect(_requested.last, const NewestFeedKey(audience: NewestAudience.following, workType: NewestWorkType.novel, followScope: NewestFollowScope.private));
    expectNoLayoutErrors(tester, where: 'novels');
  });

  test('the newest strings exist in all four languages', () => expectLocalesComplete(['newest']));
}

Translations context() => t;
