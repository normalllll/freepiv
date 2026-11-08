import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/user_card.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

class _Users extends HomeUserListSource {
  _Users(this.first);

  final Future<UserPageResult> Function() first;

  @override
  Future<UserPageResult> loadFirstPage() => first();

  @override
  Future<UserPageResult> loadNextPage(String nextUrl) async => const UserPageResult(userPreviews: []);
}

Future<void> _mountGrid(WidgetTester tester, Future<UserPageResult> Function() first, {Size size = desktopSize, double textScale = 1}) {
  final source = _Users(first);
  addTearDown(source.dispose);
  return mountPilotPage(
    tester,
    FrostLoadingScrollView(slivers: [AppSliverUserGrid(source: source)]),
    size: size,
    textScale: textScale,
  );
}

Future<UserPageResult> _sample() async => UserPageResult(userPreviews: sampleUserPreviews(count: 12));

int _columns(WidgetTester tester, Finder cards) =>
    {for (final element in cards.evaluate()) tester.getTopLeft(find.byElementPredicate((e) => e == element)).dx}.length;

UserPreview _preview({required String name, int works = 3}) => UserPreview(
  user: User(
    id: 7,
    name: name,
    account: name,
    profileImageUrls: const ProfileImageUrls(medium: ''),
  ),
  illusts: sampleIllusts(count: works),
  isMuted: false,
);

void main() {
  for (final (size, columns) in [(phoneSize, 1), (desktopSize, 3), (const Size(1800, 1000), 5)]) {
    testWidgets('the grid has $columns columns at $size', (tester) async {
      await _mountGrid(tester, _sample, size: size);
      expect(_columns(tester, find.byType(AppUserCard)), columns);
      expectNoLayoutErrors(tester);
    });
  }

  testWidgets('a card has its works, identity and Follow; the card opens the user and a work opens the work', (tester) async {
    await _mountGrid(tester, _sample);
    final preview = sampleUserPreviews(count: 12).first;
    final card = find.byType(AppUserCard).first;
    final works = find.descendant(of: card, matching: find.byType(AppArtworkCard));
    expect(works, findsNWidgets(3));
    expect(tester.getSize(works.first).width, greaterThan(90), reason: 'large previews');
    final name = find.descendant(of: card, matching: find.text(preview.user.name));
    expect(name, findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('@${preview.user.account}')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.byType(FrostAvatar)), findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text(t.follow.follow)).evaluate().isNotEmpty ||
          find.descendant(of: card, matching: find.text(t.follow.followed)).evaluate().isNotEmpty,
      isTrue,
    );

    await tester.tap(name);
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.user(preview.user.id));
    await _mountGrid(tester, _sample);
    await tester.tap(works.first);
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.illust(preview.illusts.first.id));
  });

  testWidgets('a user with fewer works keeps the card\'s height', (tester) async {
    await _mountGrid(
      tester,
      () async => UserPageResult(
        userPreviews: [
          _preview(name: 'three'),
          _preview(name: 'one', works: 1),
          _preview(name: 'none', works: 0),
        ],
      ),
    );
    final cards = find.byType(AppUserCard);
    final heights = {for (var index = 0; index < 3; index++) tester.getSize(cards.at(index)).height};
    expect(heights, hasLength(1));
    expect(find.text(t.user.noPublicWorks), findsOneWidget);
    final strip = tester.getSize(find.descendant(of: cards.at(0), matching: find.byType(AppArtworkCard)).first).height;
    expect(tester.getSize(find.descendant(of: cards.at(1), matching: find.byType(AppArtworkCard))).height, moreOrLessEquals(strip, epsilon: 1));
    expectNoLayoutErrors(tester);
  });

  for (final locale in AppLocale.values) {
    for (final size in [desktopSize, phoneSize]) {
      testWidgets('a long name fits at double text size in ${locale.languageCode}-${locale.countryCode} at $size', (tester) async {
        await mountPilotPage(
          tester,
          FrostLoadingScrollView(
            slivers: [
              AppSliverUserGrid(
                source: _Users(
                  () async => UserPageResult(
                    userPreviews: [
                      _preview(name: longText),
                      _preview(name: longText, works: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          size: size,
          textScale: 2,
          locale: locale,
        );
        expect(find.byType(AppUserCard), findsNWidgets(2));
        expectNoLayoutErrors(tester);
      });
    }
  }

  for (final size in [phoneSize, desktopSize, const Size(1800, 1400)]) {
    testWidgets('the skeleton has the loaded grid and tiles and runs past the window at $size', (tester) async {
      final answer = Completer<UserPageResult>();
      await _mountGrid(tester, () => answer.future, size: size);
      expect(find.byType(AppUserCardsSkeleton), findsOneWidget);
      expect(tester.getSize(find.byType(AppUserCardsSkeleton)).height, greaterThan(size.height));
      final cards = find.byType(AppUserCard);
      final columns = _columns(tester, cards);
      final first = tester.getRect(cards.first);
      final second = columns > 1 ? tester.getRect(cards.at(1)) : null;

      answer.complete(UserPageResult(userPreviews: sampleUserPreviews(count: 12)));
      await settlePilot(tester);
      expect(find.byType(AppUserCardsSkeleton), findsNothing);
      expect(_columns(tester, find.byType(AppUserCard)), columns);
      expect(tester.getRect(find.byType(AppUserCard).first), first);
      if (second != null) expect(tester.getRect(find.byType(AppUserCard).at(1)), second);
      expectNoLayoutErrors(tester);
    });
  }
}
