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
import 'package:freepiv/ui/compositions/work_actions.dart';
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

int _columns(WidgetTester tester) =>
    {for (final element in find.byType(AppUserCard).evaluate()) (element.renderObject! as RenderBox).localToGlobal(Offset.zero).dx}.length;

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

Finder _inCard(int index, Type type) => find.descendant(of: find.byType(AppUserCard).at(index), matching: find.byType(type));

void main() {
  for (final (size, columns) in [(phoneSize, 1), (desktopSize, 2), (const Size(1800, 1000), 4), (const Size(3000, 1000), 5)]) {
    testWidgets('the waterfall has $columns columns at $size', (tester) async {
      await _mountGrid(tester, _sample, size: size);
      expect(_columns(tester), columns);
      expect(tester.getSize(find.byType(AppUserCard).first).width, greaterThanOrEqualTo(columns == 1 ? 340 : 380), reason: 'a readable card');
      expectNoLayoutErrors(tester);
    });
  }

  testWidgets('a card with three works has square works above its identity and Follow; the card opens the user and a work opens the work', (tester) async {
    await _mountGrid(tester, _sample);
    final preview = sampleUserPreviews(count: 12).first;
    final works = _inCard(0, AppArtworkCard);
    expect(works, findsNWidgets(3));
    final size = tester.getSize(works.first);
    expect(size.width, moreOrLessEquals(size.height, epsilon: 1), reason: 'square');
    final name = find.descendant(of: find.byType(AppUserCard).first, matching: find.text(preview.user.name));
    expect(name, findsOneWidget);
    expect(tester.getTopLeft(name).dy, greaterThan(tester.getBottomLeft(works.first).dy - 1));
    expect(find.descendant(of: find.byType(AppUserCard).first, matching: find.text('@${preview.user.account}')), findsOneWidget);
    expect(_inCard(0, FrostAvatar), findsOneWidget);
    expect(_inCard(0, AppFollowButton), findsOneWidget);

    await tester.tap(name);
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.user(preview.user.id));
    await _mountGrid(tester, _sample);
    await tester.tap(_inCard(0, AppArtworkCard).first);
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.illust(preview.illusts.first.id));
  });

  for (final works in [1, 2]) {
    testWidgets('a card with $works work(s) keeps them square at the start and shows empty tiles', (tester) async {
      await _mountGrid(
        tester,
        () async => UserPageResult(
          userPreviews: [
            _preview(name: 'three'),
            _preview(name: 'some', works: works),
          ],
        ),
      );
      final full = tester.getSize(_inCard(0, AppArtworkCard).first);
      expect(_inCard(1, AppArtworkCard), findsNWidgets(works));
      expect(tester.getSize(_inCard(1, AppArtworkCard).first), full, reason: 'nothing stretches');
      expect(
        tester.getTopLeft(_inCard(1, AppArtworkCard).first).dx - tester.getTopLeft(find.byType(AppUserCard).at(1)).dx,
        tester.getTopLeft(_inCard(0, AppArtworkCard).first).dx - tester.getTopLeft(find.byType(AppUserCard).at(0)).dx,
      );
      final frames = find.descendant(of: find.byType(AppUserCard).at(1), matching: find.byWidgetPredicate((widget) => widget is FrostMediaFrame));
      expect(
        frames.evaluate().where(
          (element) => element.findAncestorWidgetOfExactType<AppArtworkCard>() == null && element.findAncestorWidgetOfExactType<FrostAvatar>() == null,
        ),
        hasLength(3 - works),
      );
      expect(tester.getSize(find.byType(AppUserCard).at(1)).height, tester.getSize(find.byType(AppUserCard).at(0)).height);
      expectNoLayoutErrors(tester);
    });
  }

  testWidgets('a card without works is only the identity row, with no strip and no note', (tester) async {
    await _mountGrid(
      tester,
      () async => UserPageResult(
        userPreviews: [
          _preview(name: 'three'),
          _preview(name: 'none', works: 0),
        ],
      ),
    );
    expect(_inCard(1, AppArtworkCard), findsNothing);
    expect(
      find
          .descendant(of: find.byType(AppUserCard).at(1), matching: find.byWidgetPredicate((widget) => widget is FrostMediaFrame))
          .evaluate()
          .where((element) => element.findAncestorWidgetOfExactType<FrostAvatar>() == null),
      isEmpty,
    );
    expect(find.text(t.user.noPublicWorks), findsNothing);
    expect(tester.getSize(find.byType(AppUserCard).at(1)).height, lessThan(tester.getSize(find.byType(AppUserCard).at(0)).height / 2));
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
                      _preview(name: longText, works: 1),
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
        expect(find.byType(AppUserCard), findsWidgets);
        expectNoLayoutErrors(tester);
      });
    }
  }

  for (final size in [phoneSize, desktopSize, const Size(3000, 1400)]) {
    testWidgets('the skeleton has the loaded columns, mixes tall and short cards and runs past the window at $size', (tester) async {
      final answer = Completer<UserPageResult>();
      await _mountGrid(tester, () => answer.future, size: size);
      expect(tester.getSize(find.byType(AppUserCardsSkeleton)).height, greaterThan(size.height));
      final heights = {for (final element in find.byType(AppUserCard).evaluate()) element.size!.height};
      expect(heights.length, greaterThan(1), reason: 'tall and short cards');
      final columns = _columns(tester);
      final first = tester.getTopLeft(find.byType(AppUserCard).first);
      final width = tester.getSize(find.byType(AppUserCard).first).width;

      answer.complete(UserPageResult(userPreviews: sampleUserPreviews(count: 12)));
      await settlePilot(tester);
      expect(find.byType(AppUserCardsSkeleton), findsNothing);
      expect(_columns(tester), columns);
      expect(tester.getTopLeft(find.byType(AppUserCard).first), first);
      expect(tester.getSize(find.byType(AppUserCard).first).width, width);
      expectNoLayoutErrors(tester);
    });
  }
}
