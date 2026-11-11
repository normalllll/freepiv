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
import 'package:freepiv/ui/compositions/sectioned_page.dart';
import 'package:freepiv/ui/compositions/user_card.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The users the signed-in account follows: public and
/// private as sections whose tabs stay in the pinned bar, each a list of user
/// rows whose Follow button never opens the row.
class FollowingPage extends ConsumerStatefulWidget {
  const FollowingPage({super.key});

  @override
  ConsumerState<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends ConsumerState<FollowingPage> with SingleTickerProviderStateMixin {
  static const _restricts = [Restrict.public, Restrict.private];

  late final _tabs = TabController(length: _restricts.length, animationDuration: FrostMotion.navigation, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ValueListenableBuilder(
      valueListenable: pixivAccountNotifier,
      builder: (context, account, _) {
        final userId = int.tryParse(account?.user.id ?? '');
        final header = FrostPageHeader(title: FrostText(t.me.following));
        if (userId == null) return _SignedOut(header: header);
        FrostListSource<UserPreview> users(int section) => ref.watch(userFollowingUsersProvider(userId: userId, restrict: _restricts[section]));
        return AppSectionedPage(
          controller: _tabs,
          header: header,
          tabs: [
            FrostTab(label: t.privacy.public),
            FrostTab(label: t.privacy.private),
          ],
          onRefresh: (section) => ref.read(userFollowingUsersProvider(userId: userId, restrict: _restricts[section])).refresh(false),
          slivers: (context, section) => [
            AppSliverUserGrid(
              source: users(section),
              empty: FrostEmptyState(icon: PivIcons.users, title: t.me.emptyFollowing),
            ),
          ],
        );
      },
    );
  }
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

/// An account list's page while no account is signed in: it offers to sign in.
class _SignedOut extends StatelessWidget {
  const _SignedOut({required this.header});

  final Widget header;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
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
}

class _AccountUserList extends ConsumerWidget {
  const _AccountUserList({required this.title, required this.emptyTitle, required this.source});

  final String title;
  final String emptyTitle;
  final FrostListSource<UserPreview> Function(WidgetRef ref, int userId) source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder(
      valueListenable: pixivAccountNotifier,
      builder: (context, account, _) {
        final userId = int.tryParse(account?.user.id ?? '');
        final header = FrostPageHeader(title: FrostText(title));
        if (userId == null) return _SignedOut(header: header);
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
