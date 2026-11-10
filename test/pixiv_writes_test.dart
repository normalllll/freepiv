import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/route_activity.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/me/logic/account_edit_logic.dart';
import 'package:freepiv/features/me/presentation/account_edit_pages.dart';
import 'package:freepiv/features/me/presentation/following_page.dart';
import 'package:freepiv/features/novel/domain/novel_text_parser.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/logic/novel_marker_logic.dart';
import 'package:freepiv/features/novel/presentation/detail/novel_detail_page.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reader_page.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_model.dart';
import 'package:freepiv/features/series/series_page.dart';
import 'package:freepiv/features/series/series_widgets.dart';
import 'package:freepiv/features/series/watchlist_page.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/features/user_detail/presentation/user_identity_header.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/logic/bookmark_options_logic.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/bookmark_options.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

/// Records the writes and answers the lists; any other request fails.
class _Api implements PixivApi {
  final writes = <String>[];
  final restricts = <Restrict>[];
  Object? failure;
  BookmarkAddOptions? bookmark;
  UserProfileEdit? profile;
  UserWorkspaceEdit? workspace;

  Future<String> _write(String name) async {
    if (failure case final failure?) throw failure;
    writes.add(name);
    return '';
  }

  @override
  Future<String> postBookmarkAdd({required int id, required BookmarkAddOptions options}) {
    bookmark = options;
    return _write('bookmark add $id');
  }

  @override
  Future<String> postBookmarkDelete({required int id, required bool isNovel}) => _write('bookmark delete $id');

  @override
  Future<String> postFollowAdd({required int userId, required Restrict restrict}) => _write('follow $userId ${restrict.name}');

  @override
  Future<String> postWatchlistAdd({required int seriesId, required bool isNovel}) => _write('watch $seriesId novel=$isNovel');

  @override
  Future<String> postWatchlistDelete({required int seriesId, required bool isNovel}) => _write('unwatch $seriesId novel=$isNovel');

  @override
  Future<String> postNovelMarkerAdd({required int novelId, required int page}) => _write('marker $page');

  @override
  Future<String> postNovelMarkerDelete({required int novelId}) => _write('marker delete');

  @override
  Future<String> postAiShowSettings({required SearchAiMode mode}) => _write('ai ${mode.name}');

  @override
  Future<String> postUserProfileEdit({required UserProfileEdit edit}) {
    profile = edit;
    return _write('profile');
  }

  @override
  Future<String> postUserWorkspaceEdit({required UserWorkspaceEdit edit}) {
    workspace = edit;
    return _write('workspace');
  }

  @override
  Future<IllustPageResult> getUserIllustBookmarkPage({required int userId, required Restrict restrict}) async {
    restricts.add(restrict);
    return const IllustPageResult(illusts: [], rankingIllusts: []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #setAccount) return null;
    if (invocation.memberName == #account) return sampleAccount.copyWith(accessToken: 'refreshed by the client');
    throw StateError('unexpected request: ${invocation.memberName}');
  }
}

late _Api _api;

Finder _field(int index) => find.descendant(of: find.byType(FrostTextField).at(index), matching: find.byType(EditableText));

const _ownId = 1000;

UserDetailResult _detail(int id) => UserDetailResult(
  user: UserInfo(id: id, name: 'Name', account: 'name', profileImageUrls: sampleUserDetail.user.profileImageUrls, comment: 'Bio', isFollowed: false),
  profile: sampleUserDetail.profile,
  profilePublicity: sampleUserDetail.profilePublicity,
  workspace: sampleUserDetail.workspace,
);

const _sectioned = 'First part.\n[newpage]\nSecond part.\n[newpage]\nThird part.';

WebviewNovel _text(String body, {String? marker}) {
  final sample = sampleNovelText(70000);
  return WebviewNovel(
    id: sample.id,
    title: sample.title,
    userId: sample.userId,
    coverUrl: sample.coverUrl,
    tags: sample.tags,
    caption: sample.caption,
    cdate: sample.cdate,
    rating: sample.rating,
    text: body,
    marker: marker,
    illusts: const [],
    images: const [],
    glossaryItems: const [],
    replaceableItemIds: const [],
    aiType: 0,
    isOriginal: true,
  );
}

Future<void> _openReader(WidgetTester tester, {String body = _sectioned, String? marker}) => mountPilotPage(
  tester,
  NovelReaderContent(
    detail: NovelDetailData(
      novel: sampleNovels(count: 1).single,
      webviewNovel: _text(body, marker: marker),
    ),
  ),
  observers: [appRootRouteActivity],
);

Future<void> _openOptions(WidgetTester tester, {bool bookmarked = false}) async {
  await mountPilotPage(tester, AppBookmarkOptionsButton(workId: 7, initiallyBookmarked: bookmarked));
  await tester.tap(find.byType(FrostButton));
  await settlePilot(tester);
}

void main() {
  setUp(() => pixivApi = _api = _Api());

  group('bookmark options', () {
    testWidgets('saves private with the chosen and the typed tags', (tester) async {
      await _openOptions(tester);
      expect(find.text(t.bookmarkOptions.remove), findsNothing, reason: 'nothing to remove yet');
      await tester.tap(find.text(t.privacy.private));
      await settlePilot(tester, frames: 3);
      await tester.tap(find.text('girl'));
      await settlePilot(tester, frames: 3);
      await tester.enterText(find.byType(EditableText), '#typed');
      await tester.tap(find.text(t.bookmarkOptions.save));
      await settlePilot(tester);

      expect(_api.writes, ['bookmark add 7']);
      expect(_api.bookmark!.restrict, Restrict.private);
      expect(_api.bookmark!.tags, unorderedEquals(['landscape', 'girl', 'typed']));
      expect(find.byType(FrostDialog), findsNothing, reason: 'closed once saved');
    });

    testWidgets('a failure says why and leaves the dialog open', (tester) async {
      await _openOptions(tester);
      _api.failure = StateError('offline');
      await tester.tap(find.text(t.bookmarkOptions.save));
      await settlePilot(tester);
      expect(find.byType(FrostDialog), findsOneWidget);
    });

    testWidgets('a bookmarked work can be removed', (tester) async {
      await _openOptions(tester, bookmarked: true);
      await tester.tap(find.text(t.bookmarkOptions.remove));
      await settlePilot(tester);
      expect(_api.writes, ['bookmark delete 7']);
    });

    testWidgets('a failed read offers a retry, not a form', (tester) async {
      await mountPilotPage(
        tester,
        const AppBookmarkOptionsButton(workId: 7, initiallyBookmarked: false),
        overrides: {workBookmarkOptionsProvider: workBookmarkOptionsProvider.overrideWith((ref, key) async => throw StateError('offline'))},
      );
      await tester.tap(find.byType(FrostButton));
      await settlePilot(tester);
      expect(find.byType(FrostCompactMessage), findsOneWidget);
      expect(find.byType(FrostTextField), findsNothing);
    });

    testWidgets('fits a phone at double text size', (tester) async {
      await mountPilotPage(tester, const AppBookmarkOptionsButton(workId: 7, initiallyBookmarked: true), size: phoneSize, textScale: 2);
      await tester.tap(find.byType(FrostButton));
      await settlePilot(tester);
      expectNoLayoutErrors(tester);
    });
  });

  group('private lists', () {
    Finder tab(String label) => find.descendant(of: find.byType(FrostTabBar), matching: find.text(label));

    testWidgets("one's own bookmarks switch to private", (tester) async {
      await mountPilotPage(tester, UserDetailPage(userDetail: _detail(_ownId)));
      await tester.tap(tab(t.user.tabs.bookmarks));
      await settlePilot(tester);
      expect(_api.restricts.last, Restrict.public);
      await tester.tap(find.text(t.privacy.private));
      await settlePilot(tester);
      expect(_api.restricts.last, Restrict.private);
    });

    testWidgets("someone else's page has no such choice", (tester) async {
      await mountPilotPage(tester, UserDetailPage(userDetail: _detail(2000)));
      await tester.tap(tab(t.user.tabs.bookmarks));
      await settlePilot(tester);
      expect(find.byType(AppRestrictPicker), findsNothing);
      await tester.tap(tab(t.user.tabs.following));
      await settlePilot(tester);
      expect(find.byType(AppRestrictPicker), findsNothing);
    });

    testWidgets('Following asks for the list chosen', (tester) async {
      final asked = <Restrict>[];
      await mountPilotPage(
        tester,
        const FollowingPage(),
        overrides: {userFollowingUsersProvider: userFollowingUsersProvider.overrideWith2((_) => _RecordingFollowing(asked))},
      );
      expect(asked.last, Restrict.public);
      await tester.tap(find.text(t.privacy.private));
      await settlePilot(tester);
      expect(asked.last, Restrict.private);
    });
  });

  group('following privately', () {
    List<FrostMenuAction> choices(WidgetTester tester) => tester
        .widget<UserIdentityHeader>(find.byType(UserIdentityHeader))
        .more
        .whereType<FrostMenuSection>()
        .expand((section) => section.entries)
        .whereType<FrostMenuAction>()
        .toList();

    testWidgets('More follows privately; the Follow button stays public', (tester) async {
      await mountPilotPage(tester, UserDetailPage(userDetail: _detail(2000)));
      final private = choices(tester).singleWhere((action) => action.label == t.privacy.private);
      expect(private.checked, isFalse);
      private.onSelected!();
      await settlePilot(tester);
      expect(_api.writes, ['follow 2000 private']);
    });

    testWidgets('no choice on one\'s own page', (tester) async {
      await mountPilotPage(tester, UserDetailPage(userDetail: _detail(_ownId)));
      expect(choices(tester), isEmpty);
    });
  });

  group('series', () {
    testWidgets('a novel series shows its length and works, and follows up', (tester) async {
      await mountPilotPage(tester, const SeriesPage(kind: AppSeriesKind.novel, seriesId: 5));
      final series = sampleNovelSeries(5);
      expect(find.text(series.novelSeriesDetail.title), findsOneWidget, reason: 'the header does not repeat it');
      expect(find.text(t.series.title), findsOneWidget);
      expect(tester.widgetList<FrostMetaLine>(find.byType(FrostMetaLine)).first.items, contains(t.series.concluded));
      await tester.tap(find.text(t.series.watch));
      await settlePilot(tester);
      expect(_api.writes, ['watch 5 novel=true']);
      expect(find.text(t.series.watching), findsOneWidget);
    });

    testWidgets('at double text size the author gets the full width, under the cover', (tester) async {
      await mountPilotPage(tester, const SeriesPage(kind: AppSeriesKind.novel, seriesId: 5), size: phoneSize, textScale: 2);
      final series = sampleNovelSeries(5).novelSeriesDetail;
      final author = find.text(series.user.name).first;
      final title = find.text(series.title);
      expect(tester.getTopLeft(author).dy, greaterThan(tester.getTopLeft(title).dy));
      expect(tester.getTopLeft(author).dx, lessThan(tester.getTopLeft(title).dx), reason: 'not in the column beside the cover');
      expectNoLayoutErrors(tester);
    });

    testWidgets('a failed follow-up goes back', (tester) async {
      await mountPilotPage(tester, const SeriesPage(kind: AppSeriesKind.novel, seriesId: 5));
      _api.failure = StateError('offline');
      await tester.tap(find.text(t.series.watch));
      await settlePilot(tester);
      expect(find.text(t.series.watch), findsOneWidget);
    });

    testWidgets('the first episode opens from the series', (tester) async {
      await mountPilotPage(tester, const SeriesPage(kind: AppSeriesKind.manga, seriesId: 5));
      final first = sampleMangaSeries(5).illustSeriesFirstIllust!;
      await tester.tap(find.text(t.series.startFromFirst));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.illust(first.id));
    });

    testWidgets('a followed manga series starts as followed', (tester) async {
      await mountPilotPage(tester, const SeriesPage(kind: AppSeriesKind.manga, seriesId: 5));
      await tester.tap(find.text(t.series.watching));
      await settlePilot(tester);
      expect(_api.writes, ['unwatch 5 novel=false']);
    });

    testWidgets('fits a phone at double text size', (tester) async {
      await mountPilotPage(tester, const SeriesPage(kind: AppSeriesKind.novel, seriesId: 5), size: phoneSize, textScale: 2);
      expectNoLayoutErrors(tester);
    });

    testWidgets('a novel in a series links to it from its page', (tester) async {
      final novel = sampleNovels().firstWhere((novel) => novel.series.id != null);
      await mountPilotPage(tester, NovelDetailPage(novel: novel));
      expect(tester.widget<AppSeriesLink>(find.byType(AppSeriesLink)).seriesId, novel.series.id);
      await tester.tap(find.byType(AppSeriesLink));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.series(AppSeriesKind.novel, novel.series.id!));
    });
  });

  group('follow-ups', () {
    testWidgets('a row opens its series; a hidden one does not open', (tester) async {
      await mountPilotPage(tester, const WatchlistPage());
      final list = sampleWatchlist();
      expect(find.text(t.watchlist.unavailable), findsOneWidget);
      await tester.tap(find.text(t.watchlist.unavailable));
      await settlePilot(tester, frames: 3);
      expect(openedLocations, isEmpty);
      await tester.tap(find.text(list.first.title));
      await settlePilot(tester);
      expect(openedLocations.last, AppLocations.series(AppSeriesKind.manga, list.first.id));
    });

    testWidgets('a row can stop following up', (tester) async {
      await mountPilotPage(tester, const WatchlistPage());
      await tester.tap(find.text(t.series.watching).first);
      await settlePilot(tester);
      expect(_api.writes, ['unwatch 1 novel=false']);
    });

    testWidgets('fits a phone at double text size', (tester) async {
      await mountPilotPage(tester, const WatchlistPage(), size: phoneSize, textScale: 2);
      expectNoLayoutErrors(tester);
    });
  });

  group('reading bookmark', () {
    test('sections are counted as Pixiv counts them', () {
      final model = ReaderModel(parseNovelText(_sectioned));
      expect(model.pageCount, 3);
      expect(model.pageOf(0), 1);
      final second = model.firstBlockOfPage(2);
      expect(model.pageOf(second), 2);
      expect(model.pageOf(model.firstBlockOfPage(3)), 3);
      expect(model.pageOf(model.firstBlockOfPage(99)), 3, reason: 'a bookmark past the end stays in the text');
    });

    test('the marker is read from its JSON', () {
      expect(parseNovelMarker('{"page":2}'), 2);
      expect(parseNovelMarker(null), isNull);
      expect(parseNovelMarker(''), isNull);
      expect(parseNovelMarker('not json'), isNull);
    });

    testWidgets('one press sets it at the section being read', (tester) async {
      await _openReader(tester);
      await tester.tap(find.byKey(const ValueKey('reader-marker')));
      await settlePilot(tester);
      expect(_api.writes, ['marker 1']);
    });

    testWidgets('a text of one section has no bookmark button', (tester) async {
      await _openReader(tester, body: 'Only one part.');
      expect(find.byKey(const ValueKey('reader-marker')), findsNothing);
    });

    testWidgets('once set, the menu removes it', (tester) async {
      await _openReader(tester, marker: '{"page":2}');
      await tester.tap(find.byKey(const ValueKey('reader-marker')));
      await settlePilot(tester, frames: 4);
      expect(find.text(t.novel.reader.markerJump(page: 2)), findsOneWidget);
      await tester.tap(find.text(t.novel.reader.markerRemove));
      await settlePilot(tester);
      expect(_api.writes, ['marker delete']);
    });
  });

  group('account forms', () {
    testWidgets('the profile submits the whole form, changed or not', (tester) async {
      await mountPilotPage(tester, const ProfileEditPage());
      final detail = sampleUserDetail;
      await tester.enterText(_field(0), 'New name');
      await settlePilot(tester, frames: 2);
      await tester.tap(find.text(t.profileEdit.save));
      await settlePilot(tester);

      final edit = _api.profile!;
      expect(edit.userName, 'New name');
      expect(edit.gender, 'unknown', reason: 'an empty gender is sent as unknown');
      expect(edit.addressId, detail.profile.addressId);
      expect(edit.jobId, detail.profile.jobId);
      expect(edit.webpage, detail.profile.webpage);
      expect(edit.twitter, detail.profile.twitterAccount ?? '');
      expect(edit.comment, detail.user.comment);
      expect(edit.birthday, detail.profile.birth, reason: 'the stored date, not one put together');
      expect(pixivAccountNotifier.value!.user.name, 'New name', reason: 'the account card reads the stored account');
      expect(pixivAccountNotifier.value!.accessToken, 'refreshed by the client', reason: 'a stale token would fail the next request');
    });

    testWidgets('nothing changed, nothing to save', (tester) async {
      await mountPilotPage(tester, const ProfileEditPage());
      await tester.tap(find.text(t.profileEdit.save));
      await settlePilot(tester);
      expect(_api.writes, isEmpty);
    });

    testWidgets('a nickname is required', (tester) async {
      await mountPilotPage(tester, const ProfileEditPage());
      await tester.enterText(_field(0), '   ');
      await settlePilot(tester, frames: 2);
      await tester.tap(find.text(t.profileEdit.save));
      await settlePilot(tester);
      expect(_api.writes, isEmpty);
      expect(find.text(t.profileEdit.nameRequired), findsOneWidget);
    });

    testWidgets('a region marked global asks for the country', (tester) async {
      await mountPilotPage(
        tester,
        const ProfileEditPage(),
        overrides: {
          profilePresetsProvider: profilePresetsProvider.overrideWith(
            (ref) async => ProfilePresets(
              addresses: [ProfileAddressPreset(id: sampleUserDetail.profile.addressId, name: 'Overseas', isGlobal: true)],
              countries: sampleProfilePresets.countries,
              jobs: sampleProfilePresets.jobs,
            ),
          ),
        },
      );
      expect(find.byWidgetPredicate((widget) => widget is FrostPicker<String> && widget.label == t.profileEdit.country), findsOneWidget);
    });

    testWidgets('the birthday shows its year, and Save ends at the fields\' edge', (tester) async {
      await mountPilotPage(tester, const ProfileEditPage());
      expect(sampleUserDetail.profile.birth, startsWith('1997-'));
      final birthday = tester.widget<FrostDatePicker>(find.byType(FrostDatePicker));
      expect(birthday.showsYear, isTrue);
      expect(birthday.help, isNull);
      final save = find.ancestor(of: find.text(t.profileEdit.save), matching: find.byType(FrostButton));
      expect(tester.getTopRight(save).dx, tester.getTopRight(find.byType(FrostTextField).first).dx);
    });

    testWidgets('a region the presets do not list reads as not set and can be chosen again', (tester) async {
      await mountPilotPage(tester, const ProfileEditPage());
      final region = tester.widget<FrostPicker<int>>(find.byWidgetPredicate((widget) => widget is FrostPicker<int> && widget.label == t.profileEdit.region));
      expect(region.value, sampleUserDetail.profile.addressId);
      expect(region.options.first.value, sampleUserDetail.profile.addressId);
      expect(region.options.first.label, t.profileEdit.notSet);
      expect(region.options.skip(1).map((option) => option.value), sampleProfilePresets.addresses.map((address) => address.id));
    });

    testWidgets('leaving with changes asks first', (tester) async {
      await mountPilotPage(tester, const ProfileEditPage());
      await tester.enterText(_field(0), 'Changed');
      await settlePilot(tester, frames: 2);
      expect(
        tester
            .widget<PopScope<Object?>>(
              find.ancestor(of: find.byType(FrostForm), matching: find.byWidgetPredicate((widget) => widget is PopScope<Object?>)).first,
            )
            .canPop,
        isFalse,
      );
    });

    testWidgets('the workspace submits all twelve fields', (tester) async {
      await mountPilotPage(tester, const WorkspaceEditPage());
      final workspace = sampleUserDetail.workspace;
      await tester.enterText(_field(0), 'New computer');
      await settlePilot(tester, frames: 2);
      await tester.tap(find.text(t.profileEdit.save));
      await settlePilot(tester);
      final edit = _api.workspace!;
      expect(edit.pc, 'New computer');
      expect(edit.monitor, workspace.monitor);
      expect(edit.tool, workspace.tool);
      expect(edit.chair, workspace.chair);
      expect(edit.comment, workspace.comment);
    });

    testWidgets('a failed read offers a retry', (tester) async {
      await mountPilotPage(
        tester,
        const WorkspaceEditPage(),
        overrides: {editableUserDetailProvider: editableUserDetailProvider.overrideWith((ref, userId) async => throw StateError('offline'))},
      );
      expect(find.byType(FrostErrorContent), findsOneWidget);
    });

    testWidgets('both fit a phone at double text size', (tester) async {
      await mountPilotPage(tester, const ProfileEditPage(), size: phoneSize, textScale: 2);
      expectNoLayoutErrors(tester);
      await mountPilotPage(tester, const WorkspaceEditPage(), size: phoneSize, textScale: 2);
      expectNoLayoutErrors(tester);
    });
  });

  group('AI works', () {
    FrostSwitch toggle(WidgetTester tester) => tester.widget<FrostSwitch>(
      find.descendant(
        of: find.ancestor(of: find.text(t.settings.account.showAi), matching: find.byType(FrostListRow)),
        matching: find.byType(FrostSwitch),
      ),
    );

    testWidgets('the setting is saved to the account', (tester) async {
      await mountPilotPage(tester, const SettingsPage());
      await tester.tap(find.text(t.settings.account.title).first);
      await settlePilot(tester);
      expect(toggle(tester).value, isTrue);
      await tester.tap(find.text(t.settings.account.showAi));
      await settlePilot(tester);
      expect(_api.writes, ['ai hide_']);
      expect(toggle(tester).value, isFalse);
    });

    testWidgets('a failure goes back', (tester) async {
      await mountPilotPage(tester, const SettingsPage());
      await tester.tap(find.text(t.settings.account.title).first);
      await settlePilot(tester);
      _api.failure = StateError('offline');
      await tester.tap(find.text(t.settings.account.showAi));
      await settlePilot(tester);
      expect(toggle(tester).value, isTrue);
    });

    testWidgets('stays off the page without an account', (tester) async {
      await mountPilotPage(tester, const SettingsPage(), signedIn: false);
      await tester.tap(find.text(t.settings.account.title).first);
      await settlePilot(tester);
      expect(find.text(t.settings.account.showAi), findsNothing);
    });
  });

  test('the routes resolve', () {
    expect(AppRoute.match(AppLocations.series(AppSeriesKind.manga, 5)), AppRoute.mangaSeries);
    expect(AppRoute.match(AppLocations.series(AppSeriesKind.novel, 5)), AppRoute.novelSeries);
    expect(AppRoute.match('/me/watchlist'), AppRoute.meWatchlist);
  });

  test(
    'the new strings exist in all four languages',
    () => expectLocalesComplete(['privacy', 'bookmarkOptions', 'series', 'watchlist', 'profileEdit', 'workspaceEdit']),
  );
}

class _RecordingFollowing extends UserFollowingUsers {
  _RecordingFollowing(this.asked);

  final List<Restrict> asked;

  @override
  UserFollowingListSource build({required int userId, Restrict restrict = Restrict.public}) {
    asked.add(restrict);
    final source = _EmptyFollowing(userId: userId, restrict: restrict);
    ref.onDispose(source.dispose);
    return source;
  }
}

class _EmptyFollowing extends UserFollowingListSource {
  _EmptyFollowing({required super.userId, required super.restrict});

  @override
  Future<UserPageResult> loadFirstPage() async => const UserPageResult(userPreviews: []);
}
