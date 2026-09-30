import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_profile_info_tab.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';

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

void main() {
  testWidgets('author Details keeps the same nested scroll and pager while refresh is disabled', (tester) async {
    // The fixture has an unloaded avatar; its placeholder can keep ticking.
    Future<void> advance() async {
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

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
          child: MaterialApp(
            theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
            home: const UserDetailContent(detail: _detail, useHorizontalLayout: true),
          ),
        ),
      ),
    );
    await advance();
    final nested = tester.state<NestedScrollViewState>(find.byType(NestedScrollView));
    final pager = tester.state(find.byType(TabBarView));
    final visual = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    final source = tester.widget<TabBarView>(find.byType(TabBarView)).controller!;
    nested.outerController.jumpTo(120);
    await tester.pump();
    final outerOffset = nested.outerController.offset;
    await tester.tap(find.text(t.user.tabs.profile));
    await advance();
    expect(source.index, 5);
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.animation!.value, 5);
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller, same(visual));
    expect(tester.state(find.byType(NestedScrollView)), same(nested), reason: 'disabling refresh must not replace the reading tree');
    expect(tester.state(find.byType(TabBarView)), same(pager));
    expect(nested.outerController.offset, outerOffset);
    expect(find.byType(UserProfileInfoBody), findsOneWidget);
    expect(find.text('Taipei'), findsOneWidget);
    final refresh = tester.widget<PullToRefreshNotification>(find.byType(PullToRefreshNotification));
    final notification = ScrollStartNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 100,
        pixels: 0,
        viewportDimension: 400,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
      context: tester.element(find.byType(UserProfileInfoBody)),
    );
    expect(refresh.notificationPredicate(notification), false, reason: 'Details has no refresh action');
    await tester.tap(find.text(t.user.tabs.illustrations));
    await advance();
    expect(source.index, 0);
    expect(tester.state(find.byType(NestedScrollView)), same(nested));
    expect(illusts.loads, 1, reason: 'returning preserves the loaded works');
    expect(tester.widget<PullToRefreshNotification>(find.byType(PullToRefreshNotification)).notificationPredicate(notification), true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
