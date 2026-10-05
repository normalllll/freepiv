import 'login_panel.dart';
import 'package:frost_ui/frost_ui.dart';
import 'skeletons.dart';
import 'navigation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'layout.dart';
import 'logic.dart';
import 'widgets.dart';
import 'cards.dart';

void openFanboxPost(BuildContext context, String id, {FanboxPost? summary}) => context.push('/fanbox/post/${Uri.encodeComponent(id)}', extra: summary);
void openFanboxCreator(BuildContext context, String id, {FanboxCreator? summary}) => context.push('/fanbox/creator/${Uri.encodeComponent(id)}', extra: summary);
void openFanboxTag(BuildContext context, String tag, {String creatorId = ''}) =>
    context.push(Uri(path: '/fanbox/tag', queryParameters: {'section': 'tag', 'q': tag, if (creatorId.isNotEmpty) 'creator': creatorId}).toString());

GoRoute fanboxTagRoute() => GoRoute(
  path: '/fanbox/tag',
  builder: (context, state) =>
      FanboxPage(location: (section: FanboxSection.tag, creatorId: state.uri.queryParameters['creator'] ?? '', query: state.uri.queryParameters['q'] ?? '')),
);

final _fanboxBrowseStorage = PageStorageBucket();

class FanboxPage extends ConsumerStatefulWidget {
  const FanboxPage({required this.location, super.key});
  final FanboxLocation location;
  @override
  ConsumerState<FanboxPage> createState() => _FanboxPageState();
}

class _FanboxPageState extends ConsumerState<FanboxPage> with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  late bool _searchExpanded = widget.location.query.isNotEmpty;
  late final _tabs = TabController(length: FanboxGroup.values.length, initialIndex: FanboxGroup.of(widget.location.section).index, vsync: this);

  /// What each group tab shows, chosen with the collection value beside the
  /// tabs; a group not chosen from shows its first section.
  late final _locations = <FanboxGroup, FanboxLocation>{FanboxGroup.of(widget.location.section): widget.location};

  @override
  void initState() {
    super.initState();
    _search.text = widget.location.query;
  }

  @override
  void didUpdateWidget(covariant FanboxPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.query != widget.location.query) _search.text = widget.location.query;
    if (oldWidget.location != widget.location) _show(widget.location);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  FanboxLocation _locationOf(FanboxGroup group) => _locations[group] ?? (section: group.sections.first, creatorId: '', query: '');

  void _show(FanboxLocation location) {
    final group = FanboxGroup.of(location.section);
    _locations[group] = location;
    if (_tabs.index != group.index) _tabs.animateTo(group.index);
  }

  void _select(FanboxSection section, {String query = ''}) {
    final location = (section: section, creatorId: '', query: query);
    ref.read(fanboxBrowseSelectionProvider.notifier).select(location);
    setState(() => _show(location));
  }

  void _toggleSearch() {
    setState(() => _searchExpanded = !_searchExpanded);
    if (_searchExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    } else {
      _searchFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    final session = ref.watch(fanboxSessionProvider);
    return FanboxScaffold(
      title: t.title,
      actions: session.asData?.value == null
          ? null
          : [IconButton(tooltip: t.searchHint, onPressed: _toggleSearch, icon: Icon(_searchExpanded ? Icons.close : Icons.search))],

      body: session.when(
        loading: () => const FanboxHomeSkeleton(),
        error: (error, _) => FanboxErrorView(error, retry: () => ref.invalidate(fanboxSessionProvider)),
        data: (session) => session == null
            ? const FanboxLoginPanel()
            : Column(
                children: [
                  if (MediaQuery.sizeOf(context).width >= 600)
                    FanboxContent(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Row(
                          children: [
                            Expanded(child: Text(t.title, style: Theme.of(context).textTheme.titleLarge)),
                            IconButton(tooltip: t.searchHint, onPressed: _toggleSearch, icon: Icon(_searchExpanded ? Icons.close : Icons.search)),
                          ],
                        ),
                      ),
                    ),
                  if (_searchExpanded)
                    FrostSearchInputRegion(
                      child: FrostSearchInput(
                        controller: _search,
                        focusNode: _searchFocus,
                        hintText: t.searchHint,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _select(
                              _locationOf(FanboxGroup.values[_tabs.index]).section == FanboxSection.searchTags
                                  ? FanboxSection.searchTags
                                  : FanboxSection.searchCreators,
                              query: value.trim(),
                            );
                          }
                        },
                        actions: [
                          FrostMenuAnchor(
                            menuChildren: [
                              for (final (section, label) in [
                                (FanboxSection.creatorPosts, t.creatorId),
                                for (final section in [FanboxSection.searchCreators, FanboxSection.searchTags]) (section, fanboxSectionLabel(context, section)),
                              ])
                                FrostMenuItem(
                                  onPressed: () {
                                    final query = _search.text.trim();
                                    if (section == FanboxSection.creatorPosts) {
                                      if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(query)) openFanboxCreator(context, query);
                                    } else {
                                      _select(section, query: query);
                                    }
                                  },
                                  child: Text(label),
                                ),
                            ],
                            builder: (context, focusNode, toggle) =>
                                IconButton(focusNode: focusNode, tooltip: context.t.common.type, onPressed: toggle, icon: const Icon(Icons.tune, size: 18)),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: PageStorage(
                      bucket: _fanboxBrowseStorage,
                      // The tabs stay put while the groups slide beneath them.
                      child: FrostPinnedChrome(
                        extent: fanboxNavigationHeight(context),
                        // Tabs carry their label padding, so the row bleeds by it.
                        chrome: FrostContentColumn(
                          bleed: FrostMetrics.tabLabelPadding(MediaQuery.sizeOf(context).width),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 12, 0, 2),
                            child: AnimatedBuilder(
                              animation: _tabs,
                              builder: (context, _) {
                                final location = _locationOf(FanboxGroup.values[_tabs.index]);
                                return FanboxSectionNavigation(section: location.section, controller: _tabs, onSelected: _select);
                              },
                            ),
                          ),
                        ),
                        body: TabBarView(
                          controller: _tabs,
                          children: [
                            for (final group in FanboxGroup.values)
                              FanboxCollectionView(key: ValueKey(_locationOf(group)), location: _locationOf(group), filterSliver: const FrostChromeSpacer()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class FanboxCollectionView extends ConsumerWidget {
  const FanboxCollectionView({required this.location, this.header, this.filterSliver, super.key});
  final FanboxLocation location;
  final Widget? header;
  final Widget? filterSliver;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = fanboxBrowseProvider(location);
    final state = ref.watch(provider);
    return FrostRefreshView(
      onRefresh: () async {
        ref.invalidate(provider);
        await ref.read(provider.future);
        return true;
      },
      builder: (context, physics, locators) => LayoutBuilder(
        builder: (context, constraints) {
          final data = state.value;
          final entries = data?.entries ?? const <FanboxEntry>[];
          return FrostLoadingScrollView(
            key: PageStorageKey(header == null ? location : ('fanbox-creator', location.creatorId)),
            physics: physics,
            slivers: [
              ?filterSliver,
              if (header == null && location.query.isNotEmpty)
                SliverPadding(
                  padding: fanboxScrollPadding(constraints.maxWidth).copyWith(bottom: 0),
                  sliver: SliverToBoxAdapter(
                    child: Text('${fanboxSectionLabel(context, location.section)} · ${location.query}', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              if (header != null)
                SliverPadding(
                  padding: fanboxScrollPadding(constraints.maxWidth).copyWith(bottom: 0),
                  sliver: SliverList.list(children: [_RetainedHeader(child: header!)]),
                ),
              ?locators.sliverHeader,
              if (data == null)
                SliverPadding(
                  padding: fanboxScrollPadding(constraints.maxWidth),
                  sliver: SliverToBoxAdapter(
                    child: state.hasError
                        ? FanboxErrorView(state.error!, retry: () => ref.invalidate(provider))
                        : FanboxCollectionSkeleton(section: location.section),
                  ),
                )
              else if (entries.isEmpty && !data.hasMore && data.error == null && !data.loadingMore)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: FrostEmptyContent(icon: FrostIconData.glyph(Icons.inbox_outlined), title: context.t.fanbox.empty),
                )
              else
                FrostSliverPagedList<FanboxEntry>(
                  key: ValueKey(location),
                  items: entries,
                  hasMore: data.hasMore,
                  loading: data.loadingMore || state.isLoading,
                  hasError: data.error != null,
                  onLoadMore: () async {
                    final notifier = ref.read(provider.notifier);
                    await notifier.loadMore();
                    return context.mounted && ref.read(provider).value?.error == null;
                  },
                  padding: fanboxScrollPadding(constraints.maxWidth),
                  footer: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        if (data.loadingMore) FanboxCollectionSkeleton(section: location.section),
                        if (data.error != null) ...[
                          Text(fanboxError(context, data.error!)),
                          OutlinedButton(onPressed: () => ref.read(provider.notifier).loadMore(), child: Text(context.t.fanbox.loadMore)),
                        ],
                      ],
                    ),
                  ),
                  itemBuilder: (context, entry, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: switch (entry) {
                      FanboxPostEntry(:final post) => FanboxPostCard(
                        post: post,
                        onTap: () => openFanboxPost(context, post.id, summary: post),
                        onCreator: () => openFanboxCreator(context, post.creatorId),
                      ),
                      FanboxCreatorEntry(:final creator) => FanboxCreatorCard(
                        creator,
                        onTap: () => openFanboxCreator(context, creator.creatorId, summary: creator),
                      ),
                      FanboxPlanEntry(:final plan) => FanboxPlanCard(plan),
                      FanboxTagEntry(:final tag) => FanboxTagCard(tag, onTap: () => openFanboxTag(context, tag.name)),
                      FanboxNoticeEntry(:final notice) => FanboxNoticeCard(
                        notice,
                        onPost: notice.postId == null ? null : () => openFanboxPost(context, notice.postId!),
                        onCreator: notice.creatorId == null ? null : () => openFanboxCreator(context, notice.creatorId!),
                      ),
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RetainedHeader extends StatefulWidget {
  const _RetainedHeader({required this.child});
  final Widget child;
  @override
  State<_RetainedHeader> createState() => _RetainedHeaderState();
}

class _RetainedHeaderState extends State<_RetainedHeader> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
