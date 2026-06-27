import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_audience_tab.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_labels.dart';
import 'package:freepiv/features/newest/presentation/page/widgets/newest_toolbar.dart';

class NewestPage extends ConsumerStatefulWidget {
  const NewestPage({super.key});

  @override
  ConsumerState<NewestPage> createState() => _NewestPageState();
}

class _NewestPageState extends ConsumerState<NewestPage> with SingleTickerProviderStateMixin {
  late final TabController _audienceTabController;

  @override
  void initState() {
    super.initState();
    _audienceTabController = TabController(length: NewestAudience.values.length, vsync: this);
    _audienceTabController.addListener(_handleAudienceTabChanged);
    Future.microtask(() {
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
  void dispose() {
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

      _audienceTabController.animateTo(index);
    });

    return Scaffold(
      body: Column(
        children: [
          NewestToolbar(
            tabController: _audienceTabController,
            onAudienceChanged: (audience) {
              ref.read(newestProvider.notifier).setAudience(audience);
            },
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge(state.sources.values.toList()),
              builder: (context, child) {
                return TabBarView(
                  controller: _audienceTabController,
                  children: [
                    for (final audience in NewestAudience.values)
                      NewestAudienceTab(
                        key: PageStorageKey('newest-$audience'),
                        audience: audience,
                        state: state,
                        onWorkTypeChanged: (workType) {
                          ref.read(newestProvider.notifier).setWorkTypeForAudience(audience, workType);
                        },
                        onFollowScopeChanged: (scope) {
                          ref.read(newestProvider.notifier).setFollowScope(scope);
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
