import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/fanbox/login_panel.dart';
import 'package:freepiv/features/fanbox/navigation.dart' show FanboxGroup, fanboxSectionLabel;
import 'package:freepiv/features/fanbox/fanbox_actions.dart' show openFanboxCreator, openFanboxPost, openFanboxTag;
import 'package:freepiv/features/fanbox/fanbox_plans.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart' show FanboxNotice, FanboxPost, FanboxUser;
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/fanbox_rows.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where a FANBOX search goes.
enum FanboxSearchScope { creatorId, creators, tags }

/// FANBOX: one collection at a time in a centred
/// reading column, chosen from the title menu (Feed, Discover, Mine); the
/// header search offers to open a creator by ID or search creators or
/// tags. Each collection loads, fails and pages on its own; saved posts load
/// one by one; without a FANBOX session the page asks to sign in.
class FanboxBrowsePage extends ConsumerStatefulWidget {
  const FanboxBrowsePage({required this.location, super.key});

  final FanboxLocation location;

  @override
  ConsumerState<FanboxBrowsePage> createState() => _FanboxBrowsePageState();
}

class _FanboxBrowsePageState extends ConsumerState<FanboxBrowsePage> {
  late FanboxLocation _location = widget.location;
  late final _search = TextEditingController(text: widget.location.query);
  final _searchFocus = FocusNode();
  final _header = FrostPageHeaderSearchController();
  @override
  void initState() {
    super.initState();
    // The choices under the search follow the typed text.
    _search.addListener(_typed);
  }

  void _typed() => setState(() {});

  @override
  void didUpdateWidget(FanboxBrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) setState(() => _location = widget.location);
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _header.dispose();
    super.dispose();
  }

  void _select(FanboxSection section, {String query = ''}) {
    final location = (section: section, creatorId: '', query: query);
    ref.read(fanboxBrowseSelectionProvider.notifier).select(location);
    setState(() => _location = location);
  }

  void _submit(FanboxSearchScope scope) {
    final query = _search.text.trim();
    if (query.isEmpty) return;
    _header.collapse();
    switch (scope) {
      case FanboxSearchScope.creatorId:
        if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(query)) openFanboxCreator(context, query);
      case FanboxSearchScope.creators:
        _select(FanboxSection.searchCreators, query: query);
      case FanboxSearchScope.tags:
        _select(FanboxSection.searchTags, query: query);
    }
  }

  String _title(BuildContext context) {
    final label = switch (_location) {
      (section: FanboxSection.tag, :final query, creatorId: _) => '#$query',
      (:final section, :final query, creatorId: _) when query.isNotEmpty => '${fanboxSectionLabel(context, section)} · $query',
      (:final section, query: _, creatorId: _) => fanboxSectionLabel(context, section),
    };
    return '${context.t.fanbox.title} · $label';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final session = ref.watch(fanboxSessionProvider);
    final signedIn = session.asData?.value != null;
    final query = _search.text.trim();
    final groups = {FanboxGroup.feed: t.fanboxPage.groupFeed, FanboxGroup.discover: t.fanboxPage.groupDiscover, FanboxGroup.personal: t.fanboxPage.groupMine};
    final header = FrostPageHeader(
      searchController: _header,
      leading: [
        FrostTitleMenu(
          title: _title(context),
          entries: [
            for (final MapEntry(key: group, value: name) in groups.entries)
              FrostMenuSection(
                header: name,
                entries: [
                  for (final section in group.sections)
                    FrostMenuAction(fanboxSectionLabel(context, section), checked: _location.section == section, onSelected: () => _select(section)),
                ],
              ),
          ],
        ),
      ],
      middle: signedIn
          ? FrostSearchInput.suggesting(
              controller: _search,
              focusNode: _searchFocus,
              placeholder: t.fanboxPage.searchPlaceholder,
              // Enter searches tags while tags are shown, creators otherwise.
              onSubmitted: (_) => _submit(_location.section == FanboxSection.searchTags ? FanboxSearchScope.tags : FanboxSearchScope.creators),
              content: query.isEmpty
                  ? null
                  : FrostSearchSection(
                      children: [
                        if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(query))
                          FrostSearchSuggestionRow(
                            label: t.fanboxPage.openCreator(id: query),
                            icon: PivIcons.user,
                            onSelected: () => _submit(FanboxSearchScope.creatorId),
                          ),
                        FrostSearchSuggestionRow(
                          label: t.fanboxPage.searchCreators(query: query),
                          icon: PivIcons.search,
                          onSelected: () => _submit(FanboxSearchScope.creators),
                        ),
                        FrostSearchSuggestionRow(
                          label: t.fanboxPage.searchTags(query: query),
                          icon: PivIcons.tags,
                          onSelected: () => _submit(FanboxSearchScope.tags),
                        ),
                      ],
                    ),
            )
          : null,
      actions: [
        FrostToolbarItem.menu(
          label: FrostScope.labelsOf(context).more,
          icon: PivIcons.more,
          showsLabel: false,
          entries: [
            FrostMenuAction(
              t.fanbox.openWebsite,
              leading: const FrostGlyph.icon(PivIcons.externalLink),
              onSelected: () => unawaited(launchUrl(Uri.parse('https://www.fanbox.cc/'), mode: LaunchMode.externalApplication)),
            ),
            FrostMenuAction(
              t.fanboxPage.accountSettings,
              leading: const FrostGlyph.icon(PivIcons.settings),
              onSelected: () => unawaited(GoRouter.of(context).push(AppRoute.settings.path)),
            ),
          ],
        ),
      ],
    );
    final provider = fanboxBrowseProvider(_location);
    return AppRefreshScope(
      onRefresh: () async {
        ref.invalidate(provider);
        await ref.read(provider.future);
      },
      child: FrostPinnedChrome(
        // The header lines up with the centred column below it.
        chrome: FrostContentColumn(maxWidth: FrostMetrics.readingMaxWidth, child: header),
        body: switch (session) {
          AsyncValue(hasValue: true, value: null) => const _Centred(child: FanboxLoginPanel()),
          AsyncValue(hasValue: true) => FanboxCollectionFeed(key: ValueKey(_location), location: _location),
          AsyncValue(:final error?) => FrostErrorContent.fromError(error: error, onRetry: () => ref.invalidate(fanboxSessionProvider)),
          _ => const _FeedSkeleton(),
        },
      ),
    );
  }
}

class _Centred extends StatelessWidget {
  const _Centred({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => FrostLoadingScrollView(
    slivers: [
      const FrostChromeSpacer(),
      FrostSliverContentColumn(
        maxWidth: FrostMetrics.readingMaxWidth,
        sliver: SliverToBoxAdapter(child: child),
      ),
    ],
  );
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) => const _Centred(child: AppRowsSkeleton());
}

/// One FANBOX collection: posts as cards, creators, plans, tags, notices and
/// messages as rows, saved posts one by one; pull to refresh, the next page
/// loads near the end and a failed one retries in place.
class FanboxCollectionFeed extends ConsumerWidget {
  const FanboxCollectionFeed({required this.location, super.key});

  final FanboxLocation location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = fanboxBrowseProvider(location);
    return FrostRefreshView(
      onRefresh: () async {
        ref.invalidate(provider);
        await ref.read(provider.future);
        return true;
      },
      builder: (context, physics, locators) => FrostLoadingScrollView(
        key: PageStorageKey(location),
        physics: physics,
        slivers: [const FrostChromeSpacer(), ?locators.sliverHeader, ...fanboxCollectionSlivers(context, ref, location)],
      ),
    );
  }
}

/// The slivers of one FANBOX collection, for a page's own scroll view.
List<Widget> fanboxCollectionSlivers(BuildContext context, WidgetRef ref, FanboxLocation location) {
  final t = context.t;
  final provider = fanboxBrowseProvider(location);
  final state = ref.watch(provider);
  final data = state.value;
  final entries = data?.entries ?? const <FanboxEntry>[];
  Widget column(Widget sliver) => FrostSliverContentColumn(maxWidth: FrostMetrics.readingMaxWidth, sliver: sliver);
  return [
    if (location.section == FanboxSection.bookmarks)
      column(
        SliverToBoxAdapter(
          child: FrostText(t.fanboxPage.localOnly, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
        ),
      ),
    if (data == null)
      state.hasError
          ? SliverFillRemaining(
              hasScrollBody: false,
              child: FrostErrorContent.fromError(error: state.error!, onRetry: () => ref.invalidate(provider)),
            )
          : column(const SliverToBoxAdapter(child: AppRowsSkeleton()))
    else if (entries.isEmpty && !data.hasMore && data.error == null)
      SliverFillRemaining(
        hasScrollBody: false,
        child: FrostEmptyState(icon: FrostIconSet.of(context).empty, title: t.fanbox.empty),
      )
    else ...[
      column(
        SliverList.separated(
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: FrostGap.related),
          itemBuilder: (context, index) => FanboxEntryView(entry: entries[index]),
        ),
      ),
      column(
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final near = constraints.remainingCacheExtent > 0;
            if (near && data.hasMore && !data.loadingMore && data.error == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(ref.read(provider.notifier).loadMore()));
            }
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: FrostGap.group),
                child: data.error != null
                    ? FrostCompactMessage.error(
                        error: data.error!,
                        actionLabel: t.fanbox.retry,
                        onAction: () => unawaited(ref.read(provider.notifier).loadMore()),
                      )
                    : data.loadingMore
                    ? Center(child: FrostActivityIndicator(semanticLabel: t.fanbox.loadMore))
                    : const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    ],
  ];
}

/// One entry of a collection.
class FanboxEntryView extends ConsumerWidget {
  const FanboxEntryView({required this.entry, super.key});

  final FanboxEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return switch (entry) {
      FanboxPostEntry(:final post) => AppFanboxPostCard(
        post: post,
        onOpen: () => openFanboxPost(context, post.id, summary: post),
        onCreator: () => openFanboxCreator(context, post.creatorId),
      ),
      FanboxBookmarkEntry(:final postId) => switch (ref.watch(fanboxPostProvider(postId))) {
        AsyncError(:final error, isLoading: false) => FrostCompactMessage.error(
          error: error,
          actionLabel: t.fanbox.retry,
          onAction: () => ref.invalidate(fanboxPostProvider(postId)),
        ),
        AsyncValue(:final value?) => AppFanboxPostCard(
          post: value,
          onOpen: () => openFanboxPost(context, value.id, summary: value),
          onCreator: () => openFanboxCreator(context, value.creatorId),
        ),
        // The size of the card it becomes, so the list does not jump.
        _ => const _PostCardSkeleton(),
      },
      FanboxCreatorEntry(:final creator) => FrostListRow(
        title: creator.user.name,
        contentTitle: true,
        subtitle: FrostRowSubtitle(creator.description.trim(), content: true, maxLines: 2),
        leading: FrostLeading.custom(AppFanboxAvatar(user: creator.user)),
        value: creator.isSupported ? t.fanbox.readable : null,
        accessory: FrostRowAccessory.chevron,
        onPressed: () => openFanboxCreator(context, creator.creatorId, summary: creator),
      ),
      FanboxPlanEntry(:final plan) => FanboxPlanRow(plan: plan, showsCreator: true),
      FanboxTagEntry(:final tag) => FrostListRow(
        title: '#${tag.name}',
        contentTitle: true,
        value: tag.count == null ? null : formatCount(tag.count!),
        accessory: FrostRowAccessory.chevron,
        onPressed: () => openFanboxTag(context, tag.name),
      ),
      FanboxNoticeEntry(:final notice) => FrostListRow(
        title: notice.title.isEmpty ? (notice.userName.isEmpty ? t.fanbox.unknownNotice : notice.userName) : notice.title,
        contentTitle: true,
        subtitle: notice.body.isEmpty ? null : FrostRowSubtitle(notice.body, content: true),
        value: formatPixivDate(notice.date),
        onPressed: switch (notice) {
          FanboxNotice(postId: final post?) => () => openFanboxPost(context, post),
          FanboxNotice(creatorId: final creator?) => () => openFanboxCreator(context, creator),
          _ => null,
        },
      ),
    };
  }
}

/// A post card while its post loads: a card with a cover, as most are.
class _PostCardSkeleton extends StatelessWidget {
  const _PostCardSkeleton();

  static const _post = FanboxPost(
    id: '',
    creatorId: '',
    user: FanboxUser(id: '', name: 'Creator name'),
    title: 'A saved post title',
    excerpt: 'The first lines of the post as its card shows them.',
    // Not an address: the cover keeps its frame without fetching anything.
    coverUrl: 'cover',
    publishedDatetime: '2026-01-01',
    updatedDatetime: '2026-01-01',
    feeRequired: 0,
    isRestricted: false,
    isLiked: false,
    likeCount: 0,
    commentCount: 0,
    tags: [],
    blocks: [],
  );

  @override
  Widget build(BuildContext context) => AppFanboxPostCard(post: _post, onOpen: () {}, onCreator: () {}).frostSkeleton(true);
}
