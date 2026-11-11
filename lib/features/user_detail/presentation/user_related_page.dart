import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/user_card.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The first few authors related to the one whose page this is, at the end of
/// its Details tab, and the way to all of them.
///
/// Nothing shows while they load, when the request fails, or when Pixiv has
/// none: the section only appears with something to offer.
class UserRelatedSection extends ConsumerStatefulWidget {
  const UserRelatedSection({required this.userId, super.key});

  final int userId;

  /// How many authors the section lists before "View all".
  static const shown = 6;

  @override
  ConsumerState<UserRelatedSection> createState() => _UserRelatedSectionState();
}

class _UserRelatedSectionState extends ConsumerState<UserRelatedSection> {
  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_load));
  }

  @override
  void didUpdateWidget(UserRelatedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) unawaited(Future.microtask(_load));
  }

  void _load() {
    if (!mounted) return;
    final source = ref.read(userRelatedSourceProvider(widget.userId));
    if (!source.initialized && !source.busy && source.lastError == null) unawaited(source.refresh(true));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final source = ref.watch(userRelatedSourceProvider(widget.userId));
    return ListenableBuilder(
      listenable: source,
      builder: (context, _) {
        final previews = source.items.take(UserRelatedSection.shown).toList();
        if (previews.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: FrostGap.group),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostSectionHeader(
                title: t.user.related.title,
                actionLabel: t.user.related.viewAll,
                onAction: () => unawaited(GoRouter.of(context).push(AppLocations.userRelated(widget.userId))),
              ),
              for (final preview in previews)
                FrostListRow(
                  leading: FrostLeading.custom(AppUserAvatar(user: preview.user)),
                  title: preview.user.name,
                  trailing: AppFollowButton(user: preview.user, prominent: false),
                  onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.user(preview.user.id))),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Every author related to [userId]: user cards across the whole width,
/// refreshed by pulling.
class UserRelatedPage extends ConsumerWidget {
  const UserRelatedPage({required this.userId, super.key});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final source = ref.watch(userRelatedSourceProvider(userId));
    return AppRefreshScope(
      onRefresh: () => source.refresh(false),
      child: FrostPinnedChrome(
        chrome: FrostPageHeader(title: FrostText(t.user.related.title)),
        body: FrostRefreshView(
          onRefresh: () => source.refresh(false),
          builder: (context, physics, locators) => FrostLoadingScrollView(
            physics: physics,
            slivers: [
              const FrostChromeSpacer(),
              ?locators.sliverHeader,
              AppSliverUserGrid(
                source: source,
                empty: FrostEmptyState(icon: PivIcons.users, title: t.user.related.empty),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
