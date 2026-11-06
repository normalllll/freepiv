import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_profile_info_tab.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_ui/frost_ui.dart';

const _detail = UserDetailResult(
  user: UserInfo(
    id: 7,
    name: 'Creator',
    account: 'creator',
    profileImageUrls: ProfileImageUrls(medium: ''),
    isFollowed: false,
  ),
  profile: UserProfile(
    gender: '',
    birth: '',
    birthDay: '',
    birthYear: 0,
    region: 'Taipei',
    addressId: 0,
    countryCode: '',
    job: '',
    jobId: 0,
    totalFollowUsers: 4,
    totalMypixivUsers: 0,
    totalIllusts: 12,
    totalManga: 3,
    totalNovels: 1,
    totalIllustBookmarksPublic: 0,
    totalIllustSeries: 0,
    totalNovelSeries: 0,
    isPremium: false,
    isUsingCustomProfileImage: false,
  ),
  profilePublicity: UserProfilePublicity(gender: '', region: '', birthDay: '', birthYear: '', job: '', pawoo: false),
  workspace: UserWorkspace(
    pc: '',
    monitor: '',
    tool: '',
    scanner: '',
    tablet: '',
    mouse: '',
    printer: '',
    desktop: '',
    music: '',
    desk: '',
    chair: '',
    comment: '',
  ),
);

class _EmptyIllusts extends UserIllustListSource {
  _EmptyIllusts() : super(userId: 7, illustType: IllustType.illust);
  int loads = 0;
  @override
  Future<IllustPageResult> loadFirstPage() async {
    loads++;
    return const IllustPageResult(illusts: [], rankingIllusts: []);
  }
}

class _EmptyFollowing extends UserFollowingListSource {
  _EmptyFollowing() : super(userId: 7);
  @override
  Future<UserPageResult> loadFirstPage() async => const UserPageResult(userPreviews: []);
}

/// The fixture has an unloaded avatar; its placeholder can keep ticking.
Future<void> _advance(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_EmptyIllusts> _mount(WidgetTester tester) async {
  LocaleSettings.setLocale(AppLocale.enUs);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 900);
  addTearDown(tester.view.reset);
  final illusts = _EmptyIllusts();
  final following = _EmptyFollowing();
  addTearDown(illusts.dispose);
  addTearDown(following.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userIllustsProvider(userId: 7, illustType: IllustType.illust).overrideWithValue(illusts),
        userFollowingUsersProvider(userId: 7).overrideWithValue(following),
      ],
      child: TranslationProvider(
        child: FrostScope(
          config: freepivFrostConfig,
          child: MaterialApp(
            theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
            home: const UserDetailContent(detail: _detail, useHorizontalLayout: true),
          ),
        ),
      ),
    ),
  );
  await _advance(tester);
  return illusts;
}

void main() {
  testWidgets('author Details keeps the same nested scroll and pager while refresh is disabled', (tester) async {
    final illusts = await _mount(tester);
    final nested = tester.state<NestedScrollViewState>(find.byType(NestedScrollView));
    final pager = tester.state(find.byType(TabBarView));
    final source = tester.widget<TabBarView>(find.byType(TabBarView)).controller!;
    await tester.tap(find.text(t.user.tabs.profile));
    await _advance(tester);
    final profileIndex = source.index;
    expect(source.animation!.value, profileIndex);
    expect(tester.state(find.byType(NestedScrollView)), same(nested), reason: 'disabling refresh must not replace the reading tree');
    expect(tester.state(find.byType(TabBarView)), same(pager));
    expect(find.byType(UserProfileInfoBody), findsOneWidget);
    expect(find.text('Taipei'), findsOneWidget);
    expect(tester.widget<FrostNestedRefreshView>(find.byType(FrostNestedRefreshView)).onRefresh, isNull, reason: 'Details has no refresh action');
    await tester.tap(find.text(t.user.tabs.illustrations));
    await _advance(tester);
    expect(source.index, 0);
    expect(tester.state(find.byType(NestedScrollView)), same(nested));
    expect(illusts.loads, 1, reason: 'returning preserves the loaded works');
    expect(source.index, isNot(profileIndex));
    expect(tester.widget<FrostNestedRefreshView>(find.byType(FrostNestedRefreshView)).onRefresh, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('switching to Details keeps a collapsed header collapsed', (tester) async {
    await _mount(tester);
    final nested = tester.state<NestedScrollViewState>(find.byType(NestedScrollView));
    nested.outerController.jumpTo(nested.outerController.position.maxScrollExtent);
    await tester.pump();
    final outerOffset = nested.outerController.offset;
    await tester.tap(find.text(t.user.tabs.profile));
    await _advance(tester);
    expect(nested.outerController.offset, outerOffset);
    await tester.pumpWidget(const SizedBox.shrink());
    // FrostTabBar (v0.3.0) brings the selected tab into view with
    // Scrollable.ensureVisible, which also scrolls the page's outer scroll.
  }, skip: true); // frost_ui request freepiv-20261107-tab-bar-ensure-visible
}
