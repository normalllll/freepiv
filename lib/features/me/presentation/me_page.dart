import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/app/router/app_navigation.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/features/downloads/presentation/download_entry.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// "Me": the account card, then a list of rows to its
/// follows and followers, and to downloads, About and settings.
/// No works are shown: bookmarks are not always fit to show on their own.
class MePage extends ConsumerStatefulWidget {
  const MePage({super.key});

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage> {
  final _scroll = ScrollController();
  ValueListenable<({int index, int sequence})>? _reselection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = FrostShellNavigationScope.maybeOf(context)?.primaryReselection;
    if (identical(next, _reselection)) return;
    _reselection?.removeListener(_reselected);
    _reselection = next?..addListener(_reselected);
  }

  /// Selecting Me again scrolls back to the top.
  void _reselected() {
    final signal = _reselection?.value;
    if (signal == null || signal.sequence == 0 || appRouteDestinations[signal.index].route != AppRoute.me || !_scroll.hasClients) return;
    final duration = FrostMotion.duration(context, FrostMotion.navigation);
    if (duration == Duration.zero) {
      _scroll.jumpTo(0);
    } else {
      unawaited(_scroll.animateTo(0, duration: duration, curve: Curves.easeOutCubic));
    }
  }

  @override
  void dispose() {
    _reselection?.removeListener(_reselected);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ValueListenableBuilder(
      valueListenable: pixivAccountNotifier,
      builder: (context, account, _) {
        final userId = int.tryParse(account?.user.id ?? '');
        final details = userId == null ? null : userDetailProvider(UserDetailArgs(userId: userId));
        Future<void> refresh() async {
          if (details != null) await ref.read(details.notifier).reload();
        }

        return AppRefreshScope(
          onRefresh: refresh,
          child: FrostPinnedChrome(
            chrome: FrostContentColumn(
              maxWidth: FrostMetrics.readingMaxWidth,
              child: FrostPageHeader(title: FrostText(t.navigation.me)),
            ),
            body: FrostRefreshView(
              scrollController: _scroll,
              onRefresh: () async {
                await refresh();
                return true;
              },
              builder: (context, physics, locators) => FrostLoadingScrollView(
                controller: _scroll,
                physics: physics,
                slivers: [
                  const FrostChromeSpacer(),
                  ?locators.sliverHeader,
                  SliverToBoxAdapter(
                    child: FrostContentColumn(
                      maxWidth: FrostMetrics.readingMaxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: FrostGap.section,
                        children: [
                          if (account == null || userId == null) const _SignedOut() else _AccountCard(account: account, details: details!),
                          ..._rows(context, userId),
                        ],
                      ),
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

  /// The ways on from "Me" as rows with chevrons: the account's own lists
  /// (while signed in), then downloads with its count, About and settings.
  List<Widget> _rows(BuildContext context, int? userId) {
    final t = context.t;
    final router = GoRouter.of(context);
    final downloads = ref.watch(downloadActivityProvider);
    FrostListRow row(FrostIconData icon, String label, String location, {Widget? trailing}) => FrostListRow(
      leading: FrostGlyph.icon(icon),
      title: label,
      trailing: trailing,
      accessory: FrostRowAccessory.chevron,
      onPressed: () => unawaited(router.push(location)),
    );
    return [
      FrostGroupedSection(
        children: [
          row(
            PivIcons.download,
            t.navigation.downloads,
            AppRoute.downloads.path,
            trailing: downloads.badge > 0 ? FrostCountBadge(count: downloads.badge, tone: downloads.badgeTone) : null,
          ),
          row(PivIcons.info, t.me.about, AppRoute.about.path),
          row(PivIcons.settings, t.me.settings, AppRoute.settings.path),
        ],
      ),
    ];
  }
}

/// The account card: avatar, name, @account and e-mail, its counts, and the
/// way to its own author page. The counts wait in placeholders; when they
/// fail only the counts go.
class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account, required this.details});

  static const _inlineProfileMaxTextScale = 1.5;

  final UserAccountResult account;
  final UserDetailProvider details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final user = account.user;
    final avatarUrl = user.profileImageUrls.px170X170;
    final profile = ref.watch(details);
    final counts = profile.value?.profile;
    final loading = profile.isLoading && counts == null;
    final stats = [
      if (counts != null || profile.isLoading) ...[
        (counts == null ? '000' : formatCount(counts.totalFollowUsers), t.user.stats.following),
        (counts == null ? '000' : formatCount(counts.totalIllusts), t.user.stats.illustrations),
        (counts == null ? '000' : formatCount(counts.totalManga), t.user.stats.manga),
        (counts == null ? '000' : formatCount(counts.totalNovels), t.user.stats.novels),
      ],
    ];
    // Beside the name, unless large text needs that line for the name.
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= _inlineProfileMaxTextScale;
    final profileLink = FrostButton.quiet(label: t.me.profile, onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.user(user.id))));
    return FrostSurface(
      role: FrostSurfaceRole.module,
      edge: FrostSurfaceEdge.none,
      elevated: false,
      borderRadius: FrostRadius.borderRadius(FrostRadius.xl),
      child: Padding(
        padding: const EdgeInsets.all(FrostGap.panelInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FrostGap.group,
          children: [
            Row(
              spacing: FrostGap.group,
              children: [
                FrostAvatar.person(
                  name: user.name,
                  colorKey: user.id,
                  size: FrostAvatarSize.large,
                  image: avatarUrl.isEmpty ? null : pixivImageProvider(ref, avatarUrl),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: FrostGap.inline,
                    children: [
                      FrostText(user.name, role: FrostTextRole.headline, content: true, maxLines: 1, overflow: TextOverflow.ellipsis),
                      FrostText('@${user.account}', tone: FrostTextTone.secondary, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (user.mailAddress.isNotEmpty)
                        FrostText(user.mailAddress, role: FrostTextRole.footnote, tone: FrostTextTone.tertiary, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (!largeText) profileLink,
              ],
            ),
            if (stats.isNotEmpty)
              Wrap(
                spacing: FrostGap.section,
                runSpacing: FrostGap.related,
                children: [
                  for (final (value, caption) in stats)
                    loading ? FrostStat.skeleton(value: value, unit: null, caption: caption) : FrostStat(value: value, caption: caption),
                ],
              ),
            if (largeText) Align(alignment: AlignmentDirectional.centerEnd, child: profileLink),
          ],
        ),
      ),
    );
  }
}

/// Signed out: what the account part would hold, and the way to sign in.
class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return FrostEmptyState(
      icon: PivIcons.user,
      title: t.settings.account.notSignedIn,
      message: t.settings.account.signedOutSubtitle,
      actionLabel: t.login.signInToPixiv,
      onAction: () => unawaited(GoRouter.of(context).push(AppRoute.login.path)),
    );
  }
}
