import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/fanbox_image.dart';
import 'package:freepiv/ui/compositions/fanbox_rows.dart';
import 'package:freepiv/ui/compositions/identity_header.dart';
import 'package:freepiv/ui/compositions/identity_tabs_header.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:frost_ui/frost_ui.dart';

import 'browse_page.dart' show fanboxCollectionSlivers;
import 'fanbox_actions.dart';
import 'fanbox_follow.dart';
import 'logic.dart';

/// A FANBOX creator, a home page: the identity (avatar,
/// name, @ID, description) with Follow and More (download every post, the
/// original page, the Fan Card where supported), then Posts, Plans and
/// Profile (links, profile pictures, tags that open the tag's posts). The
/// header names the creator once the identity has scrolled away.
class FanboxCreatorDetailPage extends ConsumerStatefulWidget {
  const FanboxCreatorDetailPage({required this.creatorId, this.showPlans = false, this.summary, super.key});

  final String creatorId;

  /// Opens on Plans.
  final bool showPlans;

  /// The row it was opened from, shown while the creator loads.
  final FanboxCreator? summary;

  @override
  ConsumerState<FanboxCreatorDetailPage> createState() => _FanboxCreatorDetailPageState();
}

enum _CreatorTab { posts, plans, profile }

class _FanboxCreatorDetailPageState extends ConsumerState<FanboxCreatorDetailPage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: _CreatorTab.values.length,
    initialIndex: widget.showPlans ? _CreatorTab.plans.index : 0,
    animationDuration: FrostMotion.navigation,
    vsync: this,
  );
  final _outer = ScrollController();
  final _overlap = SliverOverlapAbsorberHandle();
  final _identityKey = GlobalKey();
  bool _identityGone = false;

  FanboxLocation _location(_CreatorTab tab) =>
      (section: tab == _CreatorTab.plans ? FanboxSection.creatorPlans : FanboxSection.creatorPosts, creatorId: widget.creatorId, query: '');

  @override
  void initState() {
    super.initState();
    _outer.addListener(_scrolled);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _outer.dispose();
    _overlap.dispose();
    super.dispose();
  }

  void _scrolled() {
    final identity = _identityKey.currentContext?.size?.height ?? 0;
    final gone = _outer.hasClients && identity > 0 && _outer.offset >= identity;
    if (gone != _identityGone) setState(() => _identityGone = gone);
  }

  Future<void> _refresh(_CreatorTab tab) async {
    switch (tab) {
      case _CreatorTab.profile:
        ref.invalidate(fanboxCreatorProvider(widget.creatorId));
        ref.invalidate(fanboxTagsProvider(widget.creatorId));
        await ref.read(fanboxCreatorProvider(widget.creatorId).future);
      case _:
        final provider = fanboxBrowseProvider(_location(tab));
        ref.invalidate(provider);
        await ref.read(provider.future);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = ref.watch(fanboxCreatorProvider(widget.creatorId));
    final creator = state.value ?? widget.summary;
    if (creator == null && state.hasError) {
      return AppPageError.fromError(error: state.error!, onRetry: () => ref.invalidate(fanboxCreatorProvider(widget.creatorId)));
    }
    final page = AppRefreshScope(
      onRefresh: () => _refresh(_CreatorTab.values[_tabs.index]),
      child: FrostPinnedChrome(
        chrome: FrostPageHeader(title: _identityGone && creator != null ? FrostText(creator.user.name) : null),
        body: NestedScrollView(
          controller: _outer,
          headerSliverBuilder: (context, _) => [
            AppIdentityTabsHeader(
              overlap: _overlap,
              identity: KeyedSubtree(
                key: _identityKey,
                child: creator == null ? const _IdentitySkeleton() : _Identity(creator: creator, loaded: state.hasValue),
              ),
              tabs: FrostTabBar(
                controller: _tabs,
                scrollable: true,
                tabs: [
                  FrostTab(label: t.fanbox.posts),
                  FrostTab(label: t.fanbox.creatorPlans),
                  FrostTab(label: t.user.tabs.profile),
                ],
              ),
            ),
          ],
          body: ListenableBuilder(
            listenable: _tabs,
            builder: (context, _) => TabBarView(
              controller: _tabs,
              children: [
                for (final tab in _CreatorTab.values)
                  FrostKeepAlive(
                    child: FrostChromeActiveBody(
                      active: _tabs.index == tab.index,
                      child: FrostNestedRefreshView(
                        onRefresh: () async {
                          await _refresh(tab);
                          return true;
                        },
                        builder: (context, refresh) => FrostLoadingScrollView(
                          // Joins the NestedScrollView on desktop too.
                          primary: true,
                          physics: refresh.physics,
                          slivers: [
                            SliverOverlapInjector(handle: _overlap),
                            ?refresh.locators.sliverHeader,
                            ...switch (tab) {
                              _CreatorTab.profile => [
                                FrostSliverContentColumn(
                                  maxWidth: FrostMetrics.readingMaxWidth,
                                  sliver: SliverToBoxAdapter(
                                    child: creator == null ? const AppRowsSkeleton(count: 3) : _Profile(creator: creator),
                                  ),
                                ),
                              ],
                              _ => fanboxCollectionSlivers(context, ref, _location(tab)),
                            },
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (creator == null) return page;
    return DownloadSourceScope(source: fanboxCreatorDownloadSource(creator), child: page);
  }
}

/// Avatar, name, @ID, Follow and More, then the description.
class _Identity extends ConsumerWidget {
  const _Identity({required this.creator, required this.loaded});

  final FanboxCreator creator;

  /// The page has fetched the creator, not only the row it came from.
  final bool loaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final collecting = ref.watch(fanboxDownloadsProvider.select((creators) => creators.containsKey(creator.creatorId)));
    final description = creator.description.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostGap.group),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostGap.related,
        children: [
          Builder(
            builder: (headerContext) => AppIdentityHeader(
              avatar: AppFanboxAvatar(user: creator.user, size: FrostAvatarSize.xlarge),
              name: creator.user.name,
              subtitle: '@${creator.creatorId}',
              primary: FanboxFollowButton(creatorId: creator.creatorId),
              more: [
                FrostMenuAction(
                  collecting ? t.fanboxPage.collecting : t.fanbox.downloadCreator,
                  leading: const FrostGlyph.icon(PivIcons.download),
                  enabled: loaded && !collecting,
                  onSelected: () => unawaited(downloadFanboxCreator(ref, creator, origin: DownloadFlight.originOf(headerContext))),
                ),
                FrostMenuAction(
                  t.fanbox.openOriginal,
                  leading: const FrostGlyph.icon(PivIcons.externalLink),
                  onSelected: () => unawaited(openFanboxLink(context, fanboxCreatorUrl(creator.creatorId))),
                ),
                if (creator.isSupported)
                  FrostMenuAction(
                    t.fanbox.fanCard,
                    leading: const FrostGlyph.icon(PivIcons.images),
                    onSelected: () => unawaited(showFanCard(context, creator)),
                  ),
              ],
            ),
          ),
          if (description.isNotEmpty) FrostExpandableText(text: description, maxLines: 2),
        ],
      ),
    );
  }
}

class _IdentitySkeleton extends StatelessWidget {
  const _IdentitySkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: FrostGap.group),
    child: AppIdentityHeader(
      avatar: FrostAvatar(semanticLabel: '', size: FrostAvatarSize.xlarge),
      name: 'Sample creator',
      subtitle: '@sample_creator',
    ),
  ).frostSkeleton(true);
}

/// The creator's links, profile pictures and tags.
class _Profile extends ConsumerWidget {
  const _Profile({required this.creator});

  final FanboxCreator creator;

  /// Profile pictures share a row at this width.
  static const _pictureWidth = 160.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tags = ref.watch(fanboxTagsProvider(creator.creatorId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.group,
      children: [
        if (creator.profileLinks.isNotEmpty)
          FrostGroupedSection(
            children: [
              for (final url in creator.profileLinks)
                FrostListRow(
                  leading: const FrostGlyph.icon(PivIcons.link),
                  title: Uri.tryParse(url)?.host ?? url,
                  subtitle: FrostRowSubtitle(url, tone: FrostTextTone.tertiary),
                  accessory: FrostRowAccessory.external,
                  onPressed: () => unawaited(openFanboxLink(context, url)),
                ),
            ],
          ),
        if (creator.profileImages.isNotEmpty)
          FrostGrid(
            minItemWidth: _pictureWidth,
            aspectRatio: 1,
            children: [
              for (final (index, url) in creator.profileImages.indexed)
                FrostContextMenuRegion(
                  entries: fanboxImageMenu(context, ref, url: url),
                  child: FrostClickSurface(
                    shape: FrostClickShape.rounded(BorderRadius.circular(FrostRadius.lg)),
                    onTap: () => openFanboxImages(context, ref, urls: creator.profileImages, index: index, title: creator.user.name),
                    child: AppFanboxImage(url: url, aspectRatio: 1),
                  ),
                ),
            ],
          ),
        FrostSectionHeader(title: t.fanbox.searchTags),
        switch (tags) {
          AsyncValue(:final value?) when value.isEmpty => FrostText(t.fanbox.empty, tone: FrostTextTone.secondary),
          AsyncValue(:final value?) => Wrap(
            spacing: FrostGap.inline,
            runSpacing: FrostGap.inline,
            children: [for (final tag in value) FrostTag(label: '#${tag.name}', onPressed: () => openFanboxTag(context, tag.name, creatorId: creator.creatorId))],
          ),
          AsyncValue(:final error?) => FrostCompactMessage.error(
            error: error,
            actionLabel: t.fanbox.retry,
            onAction: () => ref.invalidate(fanboxTagsProvider(creator.creatorId)),
          ),
          _ => const AppRowsSkeleton(count: 1, subtitle: false),
        },
        if (creator.profileLinks.isEmpty && creator.profileImages.isEmpty && creator.description.trim().isEmpty)
          FrostText(t.fanbox.empty, tone: FrostTextTone.secondary),
      ],
    );
  }
}

/// The Fan Card of a supported creator, with its download.
Future<void> showFanCard(BuildContext context, FanboxCreator creator) {
  final source = fanboxCreatorDownloadSource(creator);
  return showFrostDialog<void>(
    context: context,
    builder: (dialogContext) => DownloadSourceScope(
      source: source,
      child: FrostDialog(
        title: dialogContext.t.fanbox.fanCard,
        showsCloseButton: true,
        content: _FanCard(creatorId: creator.creatorId),
      ),
    ),
  );
}

class _FanCard extends ConsumerWidget {
  const _FanCard({required this.creatorId});

  final String creatorId;

  static const _cardRatio = 1.6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return switch (ref.watch(fanboxSupportProvider(creatorId))) {
      AsyncValue(:final value?) => switch (value.fanCardUrl) {
        final url? => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FrostGap.related,
          children: [
            AppFanboxImage(url: url, aspectRatio: _cardRatio, fit: BoxFit.contain),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FrostButton.outlined(
                label: t.fanbox.download,
                icon: PivIcons.download,
                onPressed: () => unawaited(
                  downloadFanboxFile(ref, url: url, filename: 'fanbox-card-${Uri.encodeComponent(creatorId)}.png', source: DownloadSourceScope.of(context)),
                ),
              ),
            ),
          ],
        ),
        null => FrostText(t.fanbox.empty, tone: FrostTextTone.secondary),
      },
      AsyncValue(:final error?) => FrostCompactMessage.error(error: error, actionLabel: t.fanbox.retry, onAction: () => ref.invalidate(fanboxSupportProvider(creatorId))),
      _ => const FrostMediaFrame(aspectRatio: _cardRatio, child: SizedBox.expand()),
    };
  }
}
