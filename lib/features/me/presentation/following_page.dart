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
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart' show Restrict;
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/bookmark_options.dart';
import 'package:freepiv/ui/compositions/user_card.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The users the signed-in account follows, public or
/// private: a centred reading column of user rows whose Follow button never
/// opens the row.
class FollowingPage extends ConsumerStatefulWidget {
  const FollowingPage({super.key});

  @override
  ConsumerState<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends ConsumerState<FollowingPage> {
  var _restrict = Restrict.public;

  @override
  Widget build(BuildContext context) => _AccountUserList(
    title: context.t.me.following,
    emptyTitle: context.t.me.emptyFollowing,
    above: AppRestrictPicker(value: _restrict, onChanged: (value) => setState(() => _restrict = value)),
    source: (ref, userId) => ref.watch(userFollowingUsersProvider(userId: userId, restrict: _restrict)),
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

/// The signed-in account's My pixiv friends, in the same rows as
/// [FollowingPage].
class MypixivPage extends ConsumerWidget {
  const MypixivPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _AccountUserList(title: context.t.me.mypixiv, emptyTitle: context.t.me.emptyMypixiv, source: (ref, userId) => ref.watch(mypixivSourceProvider(userId)));
}

class _AccountUserList extends ConsumerWidget {
  const _AccountUserList({required this.title, required this.emptyTitle, required this.source, this.above});

  final String title;
  final String emptyTitle;

  /// Shown above the list, at the start of the content column.
  final Widget? above;
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
                  if (above case final above?)
                    FrostSliverContentColumn(
                      maxWidth: double.infinity,
                      sliver: SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: FrostGap.related),
                          child: Align(alignment: AlignmentDirectional.centerStart, child: above),
                        ),
                      ),
                    ),
                  AppSliverUserGrid(
                    source: users,
                    empty: FrostEmptyState(icon: PivIcons.users, title: emptyTitle),
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
