import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/identity_header.dart';
import 'package:freepiv/ui/compositions/identity_tabs_header.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:freepiv/ui/compositions/pixiv_text.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// The author page: the identity header scrolling away
/// above the pinned tabs Illustrations, Manga, Novels, Bookmarks, Following
/// and Details, each keeping its own scroll and pages.
class UserDetailPage extends ConsumerWidget {
  const UserDetailPage({this.userId, this.userDetail, this.initialTab = UserContentTabKind.illust, super.key}) : assert(userId != null || userDetail != null);

  final UserContentTabKind initialTab;
  final int? userId;
  final UserDetailResult? userDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = userDetailProvider(UserDetailArgs(userId: userId, userDetail: userDetail));
    final value = ref.watch(provider);
    final shown = value.asData?.value ?? userDetail;
    final id = userId ?? userDetail!.user.id;
    final Widget content = switch (value) {
      AsyncValue(:final value?) => UserDetailContent(key: ValueKey(value.user.id), detail: value, initialTab: initialTab),
      AsyncValue(:final error?) when shown == null => AppPageError.fromError(error: error, onRetry: () => unawaited(ref.read(provider.notifier).reload())),
      _ when shown != null => UserDetailContent(key: ValueKey(shown.user.id), detail: shown, initialTab: initialTab),
      _ => const _UserDetailSkeleton(),
    };
    // The window shows the author's name; the backdrop takes the banner's or
    // the avatar's colours.
    return FrostWindowTitleContribution(
      path: AppLocations.user(id),
      page: shown == null
          ? null
          : FrostPageTitle(id: id, title: shown.user.name, kind: 'user', imageUrl: shown.profile.backgroundImageUrl ?? shown.user.profileImageUrls.medium),
      child: content,
    );
  }
}

User userOf(UserInfo info) => User(id: info.id, name: info.name, account: info.account, profileImageUrls: info.profileImageUrls, isFollowed: info.isFollowed);

class UserDetailContent extends ConsumerStatefulWidget {
  const UserDetailContent({required this.detail, this.initialTab = UserContentTabKind.illust, super.key});

  final UserDetailResult detail;
  final UserContentTabKind initialTab;

  static const tabs = UserContentTabKind.values;

  @override
  ConsumerState<UserDetailContent> createState() => _UserDetailContentState();
}

class _UserDetailContentState extends ConsumerState<UserDetailContent> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: UserDetailContent.tabs.length, initialIndex: UserDetailContent.tabs.indexOf(widget.initialTab), vsync: this);
  final _outer = ScrollController();
  final _identityKey = GlobalKey();
  final _overlap = SliverOverlapAbsorberHandle();
  bool _identityGone = false;
  var _bookmarks = UserBookmarkKind.illustManga;

  int get _userId => widget.detail.user.id;

  @override
  void initState() {
    super.initState();
    _outer.addListener(_scrolled);
  }

  @override
  void didUpdateWidget(UserDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) _tabs.index = UserDetailContent.tabs.indexOf(widget.initialTab);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _outer.dispose();
    _overlap.dispose();
    super.dispose();
  }

  /// The page header names the author only once the identity header has
  /// scrolled away.
  void _scrolled() {
    final identity = _identityKey.currentContext?.size?.height ?? 0;
    final gone = _outer.hasClients && identity > 0 && _outer.offset >= identity;
    if (gone != _identityGone) setState(() => _identityGone = gone);
  }

  /// The current tab's list; Details has none.
  FrostListSource<Object?>? _source(UserContentTabKind kind) => switch (kind) {
    UserContentTabKind.illust => ref.read(userIllustsProvider(userId: _userId, illustType: IllustType.illust)),
    UserContentTabKind.manga => ref.read(userIllustsProvider(userId: _userId, illustType: IllustType.manga)),
    UserContentTabKind.novel => ref.read(userNovelsProvider(userId: _userId)),
    UserContentTabKind.bookmarks => switch (_bookmarks) {
      UserBookmarkKind.illustManga => ref.read(userIllustBookmarksProvider(userId: _userId)),
      UserBookmarkKind.novel => ref.read(userNovelBookmarksProvider(userId: _userId)),
    },
    UserContentTabKind.following => ref.read(userFollowingUsersProvider(userId: _userId)),
    UserContentTabKind.profile => null,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final detail = widget.detail;
    final labels = {
      UserContentTabKind.illust: t.user.tabs.illustrations,
      UserContentTabKind.manga: t.user.tabs.manga,
      UserContentTabKind.novel: t.user.tabs.novels,
      UserContentTabKind.bookmarks: t.user.tabs.bookmarks,
      UserContentTabKind.following: t.user.tabs.following,
      UserContentTabKind.profile: t.user.tabs.profile,
    };
    return AppRefreshScope(
      onRefresh: () async => _source(UserDetailContent.tabs[_tabs.index])?.refresh(false),
      child: FrostPinnedChrome(
        chrome: FrostPageHeader(title: _identityGone ? FrostText(detail.user.name) : null),
        body: NestedScrollView(
          controller: _outer,
          headerSliverBuilder: (context, _) => [
            AppIdentityTabsHeader(
              overlap: _overlap,
              identity: KeyedSubtree(
                key: _identityKey,
                child: _UserIdentity(detail: detail),
              ),
              tabs: FrostTabBar(
                controller: _tabs,
                scrollable: true,
                tabs: [for (final kind in UserDetailContent.tabs) FrostTab(label: labels[kind]!)],
              ),
            ),
          ],
          body: ListenableBuilder(
            listenable: _tabs,
            builder: (context, _) => TabBarView(
              controller: _tabs,
              children: [
                for (final (index, kind) in UserDetailContent.tabs.indexed)
                  FrostKeepAlive(
                    child: FrostChromeActiveBody(
                      active: _tabs.index == index,
                      child: _UserTab(
                        overlap: _overlap,
                        onRefresh: switch (kind) {
                          UserContentTabKind.profile => null,
                          _ => () async => _source(kind)?.refresh(false),
                        },
                        slivers: _slivers(context, kind),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _slivers(BuildContext context, UserContentTabKind kind) {
    final t = context.t;
    Widget empty(String title) => FrostEmptyState(icon: FrostIconSet.of(context).empty, title: title);
    Widget works(IllustType type, String emptyTitle) => FrostSliverDataWaterfallGrid<Illust>(
      source: ref.watch(userIllustsProvider(userId: _userId, illustType: type)),
      firstLoadSkeleton: const AppArtworkWaterfallSkeleton(),
      empty: empty(emptyTitle),
      itemBuilder: (context, illust, index) => AppArtworkCard(illust: illust),
    );
    Widget column(Widget sliver) => FrostSliverContentColumn(maxWidth: FrostMetrics.readingMaxWidth, sliver: sliver);
    return switch (kind) {
      UserContentTabKind.illust => [works(IllustType.illust, t.user.empty.illustrations)],
      UserContentTabKind.manga => [works(IllustType.manga, t.user.empty.manga)],
      UserContentTabKind.novel => [
        column(
          FrostSliverDataList<Novel>(
            source: ref.watch(userNovelsProvider(userId: _userId)),
            firstLoadSkeleton: const AppRowsSkeleton(),
            empty: empty(t.user.empty.novels),
            itemBuilder: (context, novel, index) => AppNovelRow(novel: novel, showAuthor: false),
          ),
        ),
      ],
      UserContentTabKind.bookmarks => [
        column(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FrostPicker<UserBookmarkKind>.segmented(
                  label: t.user.tabs.bookmarks,
                  value: _bookmarks,
                  onChanged: (kind) => setState(() => _bookmarks = kind),
                  options: [
                    FrostPickerOption(value: UserBookmarkKind.illustManga, label: t.user.bookmarks.illustManga),
                    FrostPickerOption(value: UserBookmarkKind.novel, label: t.user.bookmarks.novels),
                  ],
                ),
              ),
            ),
          ),
        ),
        switch (_bookmarks) {
          UserBookmarkKind.illustManga => FrostSliverDataWaterfallGrid<Illust>(
            source: ref.watch(userIllustBookmarksProvider(userId: _userId)),
            firstLoadSkeleton: const AppArtworkWaterfallSkeleton(),
            empty: empty(t.user.empty.bookmarkIllustrations),
            itemBuilder: (context, illust, index) => AppArtworkCard(illust: illust),
          ),
          UserBookmarkKind.novel => column(
            FrostSliverDataList<Novel>(
              source: ref.watch(userNovelBookmarksProvider(userId: _userId)),
              firstLoadSkeleton: const AppRowsSkeleton(),
              empty: empty(t.user.empty.bookmarkNovels),
              itemBuilder: (context, novel, index) => AppNovelRow(novel: novel),
            ),
          ),
        },
      ],
      UserContentTabKind.following => [
        column(
          FrostSliverDataList<UserPreview>(
            source: ref.watch(userFollowingUsersProvider(userId: _userId)),
            firstLoadSkeleton: const AppRowsSkeleton(),
            empty: empty(t.user.empty.following),
            itemBuilder: (context, preview, index) => AppUserRow(preview: preview),
          ),
        ),
      ],
      UserContentTabKind.profile => [column(SliverToBoxAdapter(child: UserProfileDetails(detail: widget.detail)))],
    };
  }
}

/// One tab's own scroll view under the pinned header and tabs, pulling to
/// refresh where the tab has a list.
class _UserTab extends StatelessWidget {
  const _UserTab({required this.overlap, required this.slivers, required this.onRefresh});

  final SliverOverlapAbsorberHandle overlap;
  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget view(ScrollPhysics? physics, Widget? refreshHeader) => FrostLoadingScrollView(
      // The NestedScrollView's inner controller: desktop platforms do not
      // hand it down on their own, and the tabs would scroll alone.
      primary: true,
      physics: physics,
      slivers: [
        SliverOverlapInjector(handle: overlap),
        ?refreshHeader,
        ...slivers,
      ],
    );
    final refresh = onRefresh;
    if (refresh == null) return view(null, null);
    return FrostNestedRefreshView(
      onRefresh: () async {
        await refresh();
        return true;
      },
      builder: (context, refresh) => view(refresh.physics, refresh.locators.sliverHeader),
    );
  }
}

/// Avatar, name, @account, the stat row, Follow (not on one's own page) and
/// More, then the two-line bio, which a right-click or long press copies.
class _UserIdentity extends StatelessWidget {
  const _UserIdentity({required this.detail});

  final UserDetailResult detail;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final user = userOf(detail.user);
    final profile = detail.profile;
    final bio = plainTextFromHtml(detail.user.comment ?? '').trim();
    final web = Uri.parse('https://www.pixiv.net/users/${user.id}');
    return Padding(
      padding: const EdgeInsets.only(bottom: FrostGap.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostGap.group,
        children: [
          AppIdentityHeader(
            avatar: AppUserAvatar(user: user, size: FrostAvatarSize.xxlarge),
            name: user.name,
            subtitle: '@${user.account}',
            stats: [
              AppIdentityStat(value: formatCount(profile.totalFollowUsers), caption: t.user.stats.following),
              AppIdentityStat(value: formatCount(profile.totalIllusts), caption: t.user.stats.illustrations),
              AppIdentityStat(value: formatCount(profile.totalManga), caption: t.user.stats.manga),
              AppIdentityStat(value: formatCount(profile.totalNovels), caption: t.user.stats.novels),
            ],
            primary: AppFollowButton(user: user),
            more: [
              FrostMenuAction(
                t.userPage.copyLink,
                leading: const FrostGlyph.icon(PivIcons.link),
                onSelected: () => unawaited(_copy(web.toString(), t.userPage.linkCopied)),
              ),
              FrostMenuAction(t.userPage.openInBrowser, leading: const FrostGlyph.icon(PivIcons.externalLink), onSelected: () => unawaited(_open(web))),
            ],
          ),
          if (bio.isNotEmpty)
            FrostContextMenuRegion(
              entries: [
                FrostMenuAction(
                  t.userPage.copyBio,
                  leading: const FrostGlyph.icon(PivIcons.copy),
                  onSelected: () => unawaited(_copy(bio, t.userPage.bioCopied)),
                ),
              ],
              child: AppPixivText(detail.user.comment ?? '', maxLines: 2),
            ),
        ],
      ),
    );
  }
}

Future<void> _copy(String text, String done) async {
  try {
    await copyTextToClipboard(text);
    FrostToast.copied(done);
  } catch (error) {
    toastErrorWithCause(t.userPage.copyFailed, error);
  }
}

Future<void> _open(Uri url) async {
  try {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw StateError('No application opened $url.');
  } catch (error) {
    toastErrorWithCause(t.userPage.openFailed, error);
  }
}

/// The Details tab: birthday, region, job and the links, leaving out what
/// the author has not made public.
class UserProfileDetails extends StatelessWidget {
  const UserProfileDetails({required this.detail, super.key});

  final UserDetailResult detail;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final profile = detail.profile;
    String? text(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
    final birthday = text(profile.birth) ?? text(profile.birthDay);
    final entries = [
      if (birthday case final birthday?) FrostKeyValue(label: t.user.profile.birthday, value: birthday),
      if (text(profile.region) case final region?) FrostKeyValue(label: t.user.profile.region, value: region),
      if (text(profile.job) case final job?) FrostKeyValue(label: t.user.profile.job, value: job),
      for (final (label, url) in [
        (t.user.profile.webpage, profile.webpage),
        (t.user.profile.twitter, profile.twitterUrl),
        (t.user.profile.pawoo, profile.pawooUrl),
      ])
        if (text(url) case final url?) FrostKeyValue.link(label: label, value: url, onPressed: () => unawaited(_open(Uri.parse(url)))),
    ];
    if (entries.isEmpty) return FrostEmptyState(icon: FrostIconSet.of(context).empty, title: t.user.empty.profile);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostGap.group),
      child: FrostKeyValueList(entries: entries),
    );
  }
}

/// While an author known only by their id loads: the identity header and a
/// feed at their size.
class _UserDetailSkeleton extends StatelessWidget {
  const _UserDetailSkeleton();

  @override
  Widget build(BuildContext context) => FrostPinnedChrome(
    chrome: const FrostPageHeader(),
    body: FrostLoadingScrollView(
      slivers: [
        const FrostChromeSpacer(),
        FrostSliverContentColumn(
          maxWidth: double.infinity,
          sliver: SliverToBoxAdapter(
            child: const AppIdentityHeader(
              avatar: FrostAvatar(semanticLabel: '', size: FrostAvatarSize.xxlarge),
              name: 'Sample author',
              subtitle: '@sample_author',
              statsLoading: true,
              stats: [
                AppIdentityStat(value: '000', caption: '        '),
                AppIdentityStat(value: '000', caption: '        '),
              ],
            ).frostSkeleton(true),
          ),
        ),
        const SliverToBoxAdapter(child: AppArtworkWaterfallSkeleton()),
      ],
    ),
  );
}
