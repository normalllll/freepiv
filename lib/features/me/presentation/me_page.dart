import 'package:freepiv/app/router/app_navigation.dart';
import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:go_router/go_router.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  final _scrollController = ScrollController();
  ValueListenable<({int index, int sequence})>? _primaryReselection;

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
    if (signal == null || appRouteDestinations[signal.index].route != AppRoute.me || signal.sequence == 0 || !_scrollController.hasClients) return;
    final duration = FrostMotion.duration(context, FrostMotion.navigation);
    if (duration == Duration.zero) {
      _scrollController.jumpTo(0);
    } else {
      unawaited(_scrollController.animateTo(0, duration: duration, curve: Curves.easeOutCubic));
    }
  }

  @override
  void dispose() {
    _primaryReselection?.removeListener(_handlePrimaryReselection);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return FrostAutoScaffold(
      builder: (context, layout, orientation, useHorizontalLayout) {
        return Scaffold(
          body: SafeArea(
            child: ValueListenableBuilder<UserAccountResult?>(
              valueListenable: pixivAccountNotifier,
              builder: (context, account, child) {
                return SingleChildScrollView(
                  key: const PageStorageKey('me-overview'),
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _MeColumns(
                    account: [
                      _MeAccountCard(account: account),
                      if (account == null) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => context.pushNamed(AppRoute.login.name),
                          icon: const Icon(Icons.login),
                          label: Text(translations.login.signInToPixiv),
                        ),
                      ],
                    ],
                    groups: [
                      FrostGroupedRows(
                        children: [
                          _MeNavigationEntry(
                            icon: Icons.bookmarks_outlined,
                            title: translations.user.tabs.bookmarks,
                            enabled: int.tryParse(account?.user.id ?? '') != null,
                            onTap: () =>
                                context.pushNamed(AppRoute.userDetail.name, pathParameters: {'id': account!.user.id}, queryParameters: {'tab': 'bookmarks'}),
                          ),
                          _MeNavigationEntry(
                            icon: Icons.person_add_alt_1_outlined,
                            title: translations.me.following,
                            enabled: account != null,
                            onTap: () => context.pushNamed(AppRoute.meFollowing.name),
                          ),
                          _MeNavigationEntry(
                            icon: Icons.people_outline,
                            title: translations.me.followers,
                            enabled: account != null,
                            onTap: () => context.pushNamed(AppRoute.meFollowers.name),
                          ),
                        ],
                      ),
                      FrostGroupedRows(
                        children: [
                          _MeNavigationEntry(
                            icon: Icons.download_outlined,
                            title: translations.settings.downloads.tasksTitle,
                            enabled: true,
                            onTap: () => context.pushNamed(AppRoute.downloads.name),
                          ),
                          _MeNavigationEntry(icon: Icons.info_outline, title: translations.me.about, enabled: true, onTap: _openAbout),
                          _MeNavigationEntry(icon: Icons.settings_outlined, title: translations.me.settings, enabled: true, onTap: _openSettings),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _openSettings() {
    context.pushNamed(AppRoute.settings.name);
  }

  void _openAbout() {
    context.pushNamed(AppRoute.about.name);
  }
}

class MeUserListPage extends StatefulWidget {
  const MeUserListPage({required this.kind, super.key});

  final MeUserListKind kind;

  @override
  State<MeUserListPage> createState() => _MeUserListPageState();
}

class _MeUserListPageState extends State<MeUserListPage> {
  int? _userId;
  _MeUserListSource? _source;

  @override
  void initState() {
    super.initState();
    pixivAccountNotifier.addListener(_handleAccountChanged);
    _configureSource(pixivAccountNotifier.value);
  }

  @override
  void didUpdateWidget(covariant MeUserListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _source?.dispose();
      _userId = null;
      _source = null;
      _configureSource(pixivAccountNotifier.value);
    }
  }

  @override
  void dispose() {
    pixivAccountNotifier.removeListener(_handleAccountChanged);
    _source?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final title = _title(translations);
    final emptyTitle = switch (widget.kind) {
      MeUserListKind.following => translations.me.emptyFollowing,
      MeUserListKind.followers => translations.me.emptyFollowers,
    };
    final emptyIcon = switch (widget.kind) {
      MeUserListKind.following => Icons.person_add_disabled_outlined,
      MeUserListKind.followers => Icons.people_outline,
    };
    final source = _source;

    return FrostAutoScaffold(
      builder: (context, layout, orientation, useHorizontalLayout) {
        return Scaffold(
          body: FrostCollapsingHeader(
            header: frostWindowCaptionShowsPageTitle(context, useHorizontalLayout: useHorizontalLayout) ? null : FrostPageHeader(title: Text(title)),
            child: SafeArea(
              child: source == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FrostEmptyContent(
                            icon: FrostIconData.glyph(Icons.account_circle_outlined),
                            title: translations.settings.account.notSignedIn,
                            message: translations.settings.account.signedOutSubtitle,
                          ),
                          FilledButton.icon(
                            onPressed: () => context.pushNamed(AppRoute.login.name),
                            icon: const Icon(Icons.login),
                            label: Text(translations.login.signInToPixiv),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (useHorizontalLayout) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
                            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                          ),
                        ],
                        Expanded(
                          child: _MeUserListPane(source: source, emptyIcon: emptyIcon, emptyTitle: emptyTitle),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  void _handleAccountChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _configureSource(pixivAccountNotifier.value);
    });
  }

  void _configureSource(UserAccountResult? account) {
    final userId = int.tryParse(account?.user.id ?? '');
    if (_userId == userId && _source?.kind == widget.kind) {
      return;
    }

    _source?.dispose();
    _userId = userId;

    if (userId == null) {
      _source = null;
      return;
    }

    _source = _MeUserListSource(userId: userId, kind: widget.kind);
  }

  String _title(Translations translations) {
    return switch (widget.kind) {
      MeUserListKind.following => translations.me.following,
      MeUserListKind.followers => translations.me.followers,
    };
  }
}

class _MeAccountCard extends StatelessWidget {
  const _MeAccountCard({required this.account});

  final UserAccountResult? account;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final colorScheme = Theme.of(context).colorScheme;
    final user = account?.user;
    final userId = int.tryParse(user?.id ?? '');
    // Name first, then the public @account, then the private e-mail as the
    // quietest line.
    final secondary = Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant);

    return FrostSurface(
      role: FrostSurfaceRole.glassPanel,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MeAccountAvatar(
                  imageUrl: user?.profileImageUrls.px170X170 ?? user?.profileImageUrls.px50X50,
                  onTap: userId == null
                      ? null
                      : () {
                          context.pushNamed(AppRoute.userDetail.name, pathParameters: {'id': '$userId'});
                        },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? translations.settings.account.notSignedIn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user == null ? translations.settings.account.signedOutSubtitle : '@${user.account}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: secondary,
                      ),
                      if (user != null && user.mailAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.mailAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: userId == null ? null : () => context.pushNamed(AppRoute.userDetail.name, pathParameters: {'id': '$userId'}),
                icon: const Icon(Icons.account_circle_outlined),
                label: Text(translations.me.profile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeAccountAvatar extends StatelessWidget {
  const _MeAccountAvatar({required this.imageUrl, required this.onTap});

  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = FrostThemeTokens.of(context);
    final imageUrl = this.imageUrl;

    Widget avatar = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tokens.line.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: SizedBox.square(
          dimension: 58,
          child: imageUrl == null || imageUrl.isEmpty
              ? const _MeAccountAvatarFallback()
              : PixivImage(
                  url: imageUrl,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(29),
                  placeholder: (context) => const _MeAccountAvatarFallback(),
                  errorBuilder: (context) => const _MeAccountAvatarFallback(),
                ),
        ),
      ),
    );

    final onTap = this.onTap;
    if (onTap == null) {
      return avatar;
    }

    avatar = Tooltip(
      message: context.t.me.openProfile,
      child: FrostClickSurface(customBorder: const CircleBorder(), onTap: onTap, child: avatar),
    );

    return Semantics(button: true, label: context.t.me.openProfile, child: avatar);
  }
}

class _MeAccountAvatarFallback extends StatelessWidget {
  const _MeAccountAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(child: Icon(Icons.account_circle_outlined, size: 32));
  }
}

class _MeNavigationEntry extends StatelessWidget {
  const _MeNavigationEntry({required this.icon, required this.title, required this.enabled, required this.onTap});

  final IconData icon;
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(enabled: enabled, onTap: enabled ? onTap : null, leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right));
  }
}

class _MeUserListPane extends StatefulWidget {
  const _MeUserListPane({required this.source, required this.emptyIcon, required this.emptyTitle});

  final _MeUserListSource source;
  final IconData emptyIcon;
  final String emptyTitle;

  @override
  State<_MeUserListPane> createState() => _MeUserListPaneState();
}

class _MeUserListPaneState extends State<_MeUserListPane> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureLoaded);
  }

  @override
  void didUpdateWidget(covariant _MeUserListPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      Future.microtask(_ensureLoaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FrostRefreshView(
      onRefresh: () => widget.source.refresh(true),
      builder: (context, physics, locators) {
        return AnimatedBuilder(
          animation: widget.source,
          builder: (context, child) => FrostLoadStateSwitcher(phase: widget.source.phase, child: _buildPhase(context, physics, locators)),
        );
      },
    );
  }

  Widget _buildPhase(BuildContext context, ScrollPhysics? physics, FrostRefreshLocators locators) {
    final source = widget.source;
    final lastError = source.lastError;

    if (source.phase == FrostLoadPhase.loading) {
      return FrostLoadingScrollView(physics: physics, slivers: [?locators.sliverHeader, const SliverUserPreviewerSkeletonGrid()]);
    }

    if (!source.initialized && lastError != null) {
      return FrostSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: FrostErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return FrostSliverFillBody(
        physics: physics,
        sliverHeader: locators.sliverHeader,
        child: FrostEmptyContent(icon: FrostIconData.glyph(widget.emptyIcon), title: widget.emptyTitle),
      );
    }

    return FrostLoadingScrollView(
      physics: physics,
      slivers: [
        ?locators.sliverHeader,
        SliverUserPreviewGrid(source: source),
      ],
    );
  }

  void _ensureLoaded() {
    if (!mounted || widget.source.initialized || widget.source.refreshing) {
      return;
    }

    unawaited(widget.source.refresh(true));
  }
}

enum MeUserListKind { following, followers }

class _MeUserListSource extends FrostCursorListSource<UserPreview, UserPageResult> {
  _MeUserListSource({required this.userId, required this.kind});

  final int userId;
  final MeUserListKind kind;

  @override
  Future<UserPageResult> loadFirstPage() {
    return switch (kind) {
      MeUserListKind.following => pixivApi.getFollowingUserPage(userId: userId, restrict: Restrict.public),
      MeUserListKind.followers => pixivApi.getFollowerPage(userId: userId),
    };
  }

  @override
  Future<UserPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextUserPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(UserPageResult page) {
    return page.nextUrl;
  }

  @override
  List<UserPreview> itemsFromPage(UserPageResult page) {
    return page.userPreviews;
  }
}

/// The account card heads the page; the entry groups follow in one column,
/// or side by side once the content area is wide enough. The groups have the
/// same number of rows, so side by side they share one top and bottom edge
/// instead of leaving the account card stranded in a column of its own.
class _MeColumns extends StatelessWidget {
  const _MeColumns({required this.account, required this.groups});

  final List<Widget> account;
  final List<Widget> groups;

  static const _sideBySideWidth = 960.0;

  @override
  Widget build(BuildContext context) {
    return FrostContentColumn(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = constraints.maxWidth >= _sideBySideWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...account,
              const SizedBox(height: 24),
              if (sideBySide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, group) in groups.indexed) ...[if (index > 0) const SizedBox(width: 24), Expanded(child: group)],
                    ],
                  ),
                )
              else
                for (final (index, group) in groups.indexed) ...[if (index > 0) const SizedBox(height: 24), group],
            ],
          );
        },
      ),
    );
  }
}
