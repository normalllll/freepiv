import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/features/me/logic/me_logic.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The users the signed-in account follows, public
/// follows as on Pixiv's app: a centred reading column of user rows whose
/// Follow button never opens the row.
class FollowingPage extends ConsumerWidget {
  const FollowingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _AccountUserList(
    title: context.t.me.following,
    emptyTitle: context.t.me.emptyFollowing,
    source: (ref, userId) => ref.watch(userFollowingUsersProvider(userId: userId)),
  );
}

/// The users following the signed-in account, in the
/// same rows as [FollowingPage].
class FollowersPage extends ConsumerWidget {
  const FollowersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _AccountUserList(
    title: context.t.me.followers,
    emptyTitle: context.t.me.emptyFollowers,
    source: (ref, userId) => ref.watch(followersSourceProvider(userId)),
  );
}

class _AccountUserList extends ConsumerWidget {
  const _AccountUserList({required this.title, required this.emptyTitle, required this.source});

  final String title;
  final String emptyTitle;
  final FrostListSource<UserPreview> Function(WidgetRef ref, int userId) source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return ValueListenableBuilder(
      valueListenable: pixivAccountNotifier,
      builder: (context, account, _) {
        final userId = int.tryParse(account?.user.id ?? '');
        final header = FrostPageHeader(title: FrostText(title));
        if (userId == null) {
          return FrostPinnedChrome(
            chrome: header,
            body: FrostEmptyState(
              icon: PivIcons.user,
              title: t.settings.account.notSignedIn,
              message: t.settings.account.signedOutSubtitle,
              actionLabel: t.login.signInToPixiv,
              onAction: () => unawaited(GoRouter.of(context).push(AppRoute.login.path)),
            ),
          );
        }
        final users = source(ref, userId);
        return AppRefreshScope(
          onRefresh: () => users.refresh(false),
          child: FrostPinnedChrome(
            chrome: header,
            body: FrostRefreshView(
              onRefresh: () => users.refresh(false),
              builder: (context, physics, locators) => FrostLoadingScrollView(
                physics: physics,
                slivers: [
                  const FrostChromeSpacer(),
                  ?locators.sliverHeader,
                  FrostSliverContentColumn(
                    maxWidth: FrostMetrics.readingMaxWidth,
                    sliver: FrostSliverDataList<UserPreview>(
                      source: users,
                      firstLoadSkeleton: const AppRowsSkeleton(),
                      empty: FrostEmptyState(icon: PivIcons.users, title: emptyTitle),
                      itemBuilder: (context, preview, index) => AppUserRow(preview: preview),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
