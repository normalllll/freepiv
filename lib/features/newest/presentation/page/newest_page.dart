import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/destination_header.dart';
import 'package:freepiv/ui/compositions/sectioned_page.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';

/// Newest: new works from the people followed, from My
/// pixiv friends and from everyone, one section each. The Type menu (and
/// for Following the Scope menu) at the end of the tab row picks the feed;
/// every combination loads, fails and empties on its own.
class NewestPage extends ConsumerStatefulWidget {
  const NewestPage({super.key});

  @override
  ConsumerState<NewestPage> createState() => _NewestPageState();
}

class _NewestPageState extends ConsumerState<NewestPage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: NewestAudience.values.length,
    initialIndex: ref.read(newestProvider).audience.index,
    animationDuration: FrostMotion.navigation,
    vsync: this,
  )..addListener(_tabChanged);
  final _scrolls = [for (final _ in NewestAudience.values) ScrollController()];
  ValueListenable<({int index, int sequence})>? _reselection;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(newestProvider.notifier).loadCurrentIfNeeded();
    });
  }

  void _tabChanged() {
    if (_tabs.indexIsChanging) return;
    ref.read(newestProvider.notifier).setAudience(NewestAudience.values[_tabs.index]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = FrostShellNavigationScope.maybeOf(context)?.primaryReselection;
    if (identical(next, _reselection)) return;
    _reselection?.removeListener(_reselected);
    _reselection = next?..addListener(_reselected);
  }

  /// Selecting Newest again scrolls the current section back to its top.
  void _reselected() {
    final signal = _reselection?.value;
    if (signal == null || signal.sequence == 0 || appRouteDestinations[signal.index].route != AppRoute.newest) return;
    final scroll = _scrolls[_tabs.index];
    if (!scroll.hasClients) return;
    final duration = FrostMotion.duration(context, FrostMotion.navigation);
    if (duration == Duration.zero) {
      scroll.jumpTo(0);
    } else {
      unawaited(scroll.animateTo(0, duration: duration, curve: Curves.easeOutCubic));
    }
  }

  @override
  void dispose() {
    _reselection?.removeListener(_reselected);
    _tabs.dispose();
    for (final scroll in _scrolls) {
      scroll.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = ref.watch(newestProvider);
    ref.listen(newestProvider.select((state) => state.audience), (_, audience) {
      if (_tabs.index != audience.index) _tabs.animateTo(audience.index);
    });
    final audience = NewestAudience.values[_tabs.index];
    return AppSectionedPage(
      header: AppDestinationHeader(title: t.navigation.newest),
      controller: _tabs,
      scrollControllers: _scrolls,
      tabs: [
        FrostTab(label: t.newest.audience.following),
        FrostTab(label: t.newest.audience.mypixiv),
        FrostTab(label: t.newest.audience.everyone),
      ],
      trailing: _FeedMenus(audience: audience, state: state),
      onRefresh: (section) async => state.sourceForAudience(NewestAudience.values[section]).refresh(false),
      // A new type or scope starts the section afresh at its top.
      sectionKey: (section) => state.keyForAudience(NewestAudience.values[section]),
      slivers: (context, section) => _feedSlivers(context, state.sourceForAudience(NewestAudience.values[section])),
    );
  }
}

List<Widget> _feedSlivers(BuildContext context, NewestListSource source) {
  final empty = FrostEmptyState(icon: FrostIconSet.of(context).empty, title: newestEmptyTitle(context.t, source.key));
  if (source.key.isNovel) {
    return [
      FrostSliverContentColumn(
        maxWidth: FrostMetrics.readingMaxWidth,
        sliver: FrostSliverDataList<NewestItem>(
          source: source,
          firstLoadSkeleton: const AppNovelRowsSkeleton(),
          empty: empty,
          itemBuilder: (context, item, index) => switch (item) {
            NewestNovel(:final novel) => AppNovelRow(novel: novel),
            NewestIllust() => const SizedBox.shrink(),
          },
        ),
      ),
    ];
  }
  return [
    FrostSliverDataWaterfallGrid<NewestItem>(
      source: source,
      firstLoadSkeleton: const AppArtworkWaterfallSkeleton(),
      empty: empty,
      itemBuilder: (context, item, index) => switch (item) {
        NewestIllust(:final illust) => AppArtworkCard(illust: illust),
        NewestNovel() => const SizedBox.shrink(),
      },
    ),
  ];
}

/// What an empty feed says, by audience; private follows say so apart.
String newestEmptyTitle(Translations t, NewestFeedKey key) => switch (key.audience) {
  NewestAudience.following when key.followScope == NewestFollowScope.private => t.newest.empty.privateFollows,
  NewestAudience.following => t.newest.empty.following,
  NewestAudience.mypixiv => t.newest.empty.mypixiv,
  NewestAudience.everyone => t.newest.empty.everyone,
};

String newestWorkTypeLabel(Translations t, NewestWorkType type) => switch (type) {
  NewestWorkType.illustManga => t.newest.workType.illustManga,
  NewestWorkType.illust => t.newest.workType.illust,
  NewestWorkType.manga => t.newest.workType.manga,
  NewestWorkType.novel => t.newest.workType.novel,
};

String newestFollowScopeLabel(Translations t, NewestFollowScope scope) => switch (scope) {
  NewestFollowScope.all => t.newest.followScope.all,
  NewestFollowScope.public => t.newest.followScope.public,
  NewestFollowScope.private => t.newest.followScope.private,
};

/// Type ▾, and Scope ▾ for Following; each shows its current value. On a
/// compact width both are one menu with a section each, showing both values
/// short, so the tab row keeps its tabs.
class _FeedMenus extends ConsumerWidget {
  const _FeedMenus({required this.audience, required this.state});

  final NewestAudience audience;
  final NewestState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final notifier = ref.read(newestProvider.notifier);
    final key = state.keyForAudience(audience);
    final following = audience == NewestAudience.following;
    final types = [
      for (final type in newestWorkTypeOptions(audience))
        FrostMenuAction(newestWorkTypeLabel(t, type), checked: type == key.workType, onSelected: () => notifier.setWorkTypeForAudience(audience, type)),
    ];
    final scopes = [
      for (final scope in NewestFollowScope.values)
        FrostMenuAction(newestFollowScopeLabel(t, scope), checked: scope == state.followScope, onSelected: () => notifier.setFollowScope(scope)),
    ];
    if (FrostSizeClass.of(context) == FrostSizeClass.compact) {
      final type = newestWorkTypeCompactLabel(t, key.workType);
      return FrostToolbarMenuButton(
        key: const ValueKey('newest-feed'),
        label: t.common.filter,
        valueLabel: following ? t.newest.compactFilter(workType: type, scope: newestFollowScopeCompactLabel(t, state.followScope)) : type,
        entries: [
          FrostMenuSection(header: t.common.type, entries: types),
          if (following) FrostMenuSection(header: t.newest.followScope.title, entries: scopes),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FrostGap.inline,
      children: [
        FrostToolbarMenuButton(key: const ValueKey('newest-type'), label: t.common.type, valueLabel: newestWorkTypeLabel(t, key.workType), entries: types),
        if (following)
          FrostToolbarMenuButton(
            key: const ValueKey('newest-scope'),
            label: t.newest.followScope.title,
            valueLabel: newestFollowScopeLabel(t, state.followScope),
            entries: scopes,
          ),
      ],
    );
  }
}

String newestWorkTypeCompactLabel(Translations t, NewestWorkType type) => switch (type) {
  NewestWorkType.illustManga => t.newest.workType.compactArt,
  NewestWorkType.illust => t.newest.workType.compactIllust,
  NewestWorkType.manga => t.newest.workType.compactManga,
  NewestWorkType.novel => t.newest.workType.compactNovel,
};

String newestFollowScopeCompactLabel(Translations t, NewestFollowScope scope) => switch (scope) {
  NewestFollowScope.all => t.newest.followScope.compactAll,
  NewestFollowScope.public => t.newest.followScope.compactPublic,
  NewestFollowScope.private => t.newest.followScope.compactPrivate,
};
