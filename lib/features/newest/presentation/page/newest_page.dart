import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/shared/widgets/mouse_drag_scroll.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_audience_tab.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_feed.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_labels.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_toolbar.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_filters.dart';

class NewestPage extends ConsumerStatefulWidget {
  const NewestPage({super.key});

  @override
  ConsumerState<NewestPage> createState() => _NewestPageState();
}

class _NewestPageState extends ConsumerState<NewestPage> with SingleTickerProviderStateMixin {
  late final TabController _audienceTabController;
  final _feedScrollables = <NewestFeedKey, ScrollableState>{};
  ValueListenable<({int index, int sequence})>? _primaryReselection;

  @override
  void initState() {
    super.initState();
    _audienceTabController = TabController(length: NewestAudience.values.length, vsync: this);
    _audienceTabController.addListener(_handleAudienceTabChanged);
    Future.microtask(() {
      if (!mounted) return;
      ref.read(newestProvider.notifier).loadCurrentIfNeeded();
    });
  }

  void _handleAudienceTabChanged() {
    if (_audienceTabController.indexIsChanging) {
      return;
    }

    final audience = newestAudienceForIndex(_audienceTabController.index);
    if (ref.read(newestProvider).audience == audience) {
      return;
    }

    ref.read(newestProvider.notifier).setAudience(audience);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = FrostShellNavigationScope.maybeOf(context)?.primaryReselection;
    if (identical(next, _primaryReselection)) return;
    _primaryReselection?.removeListener(_handlePrimaryReselection);
    _primaryReselection = next;
    next?.addListener(_handlePrimaryReselection);
  }

  void _handlePrimaryReselection() {
    final signal = _primaryReselection?.value;
    if (signal == null || appRouteDestinations[signal.index].route != AppRoute.newest || signal.sequence == 0) return;
    final audience = newestAudienceForIndex(_audienceTabController.index);
    final key = ref.read(newestProvider).keyForAudience(audience);
    final scrollable = _feedScrollables[key];
    if (scrollable == null || !scrollable.mounted) return;
    final position = scrollable.position;
    final duration = FrostMotion.duration(context, FrostMotion.navigation);
    if (duration == Duration.zero) {
      position.jumpTo(0);
    } else {
      unawaited(position.animateTo(0, duration: duration, curve: Curves.easeOutCubic));
    }
  }

  bool _captureFeedScrollable(BuildContext? notificationContext, Axis axis) {
    if (axis != Axis.vertical || notificationContext == null) return false;
    final feed = notificationContext.findAncestorWidgetOfExactType<NewestFeedView>();
    final scrollable = Scrollable.maybeOf(notificationContext);
    if (feed != null && scrollable != null) _feedScrollables[feed.source.key] = scrollable;
    return false;
  }

  @override
  void dispose() {
    _primaryReselection?.removeListener(_handlePrimaryReselection);
    _audienceTabController.removeListener(_handleAudienceTabChanged);
    _audienceTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newestProvider);

    ref.listen<NewestState>(newestProvider, (previous, next) {
      final index = newestAudienceIndex(next.audience);
      if (_audienceTabController.index == index) {
        return;
      }

      _audienceTabController.animateTo(index, duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200));
    });

    final notifier = ref.read(newestProvider.notifier);
    return Scaffold(
      body: FrostPinnedChrome(
        extent: MediaQuery.paddingOf(context).top + NewestToolbar.height,
        chrome: NewestToolbar(
          tabController: _audienceTabController,
          onAudienceChanged: notifier.setAudience,
          filter: NewestFilterButton(
            audience: state.audience,
            state: state,
            onWorkTypeChanged: (workType) => notifier.setWorkTypeForAudience(state.audience, workType),
            onFollowScopeChanged: notifier.setFollowScope,
          ),
        ),
        body: AnimatedBuilder(
          animation: Listenable.merge(state.sources.values.toList()),
          builder: (context, child) {
            return NotificationListener<ScrollMetricsNotification>(
              onNotification: (notification) => _captureFeedScrollable(notification.context, notification.metrics.axis),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) => _captureFeedScrollable(notification.context, notification.metrics.axis),
                child: MouseDragScroll(
                  child: TabBarView(
                    controller: _audienceTabController,
                    children: [
                      for (final audience in NewestAudience.values)
                        NewestAudienceTab(key: PageStorageKey('newest-$audience'), audience: audience, state: state),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
