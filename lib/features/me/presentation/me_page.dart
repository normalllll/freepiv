import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:go_router/go_router.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final tokens = FreepivThemeTokens.of(context);

    return AutoScaffold(
      builder: (context, layout, orientation, shouldUseDesktopShell) {
        return Scaffold(
          backgroundColor: tokens.surface,
          appBar: shouldUseDesktopShell ? null : AppBar(title: Text(translations.navigation.me)),
          body: SafeArea(
            top: shouldUseDesktopShell,
            child: ValueListenableBuilder<UserAccountResult?>(
              valueListenable: pixivAccountNotifier,
              builder: (context, account, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final minHeight = math.max(0.0, constraints.maxHeight - 24);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 560, minHeight: minHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _MeAccountCard(account: account, onSignOut: _signOut),
                                const SizedBox(height: 12),
                                _MeNavigationEntry(
                                  icon: Icons.person_add_alt_1_outlined,
                                  title: translations.me.following,
                                  enabled: account != null,
                                  onTap: () => context.pushNamed(AppRoute.meFollowing.name),
                                ),
                                const SizedBox(height: 8),
                                _MeNavigationEntry(
                                  icon: Icons.people_outline,
                                  title: translations.me.followers,
                                  enabled: account != null,
                                  onTap: () => context.pushNamed(AppRoute.meFollowers.name),
                                ),
                                const Spacer(),
                                _MeAboutEntry(onTap: _openAbout),
                                const SizedBox(height: 8),
                                _MeSettingsEntry(onTap: _openSettings),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _signOut() {
    setPixivAccount(null);
    if (mounted) {
      context.go(AppRoute.login.path);
    }
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

    return AutoScaffold(
      builder: (context, layout, orientation, shouldUseDesktopShell) {
        return Scaffold(
          backgroundColor: FreepivThemeTokens.of(context).surface,
          appBar: shouldUseDesktopShell ? null : AppBar(title: Text(title)),
          body: SafeArea(
            top: shouldUseDesktopShell,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: UserPreviewer.desktopMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: source == null
                      ? EmptyContent(
                          icon: Icons.account_circle_outlined,
                          title: translations.settings.account.notSignedIn,
                          message: translations.settings.account.signedOutSubtitle,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (shouldUseDesktopShell) ...[
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
  const _MeAccountCard({required this.account, required this.onSignOut});

  final UserAccountResult? account;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final colorScheme = Theme.of(context).colorScheme;
    final user = account?.user;
    final userId = int.tryParse(user?.id ?? '');
    final subtitle = user == null
        ? translations.settings.account.signedOutSubtitle
        : user.mailAddress.isEmpty
        ? '@${user.account}'
        : user.mailAddress;

    return EnergeticCard(
      accentColor: FreepivThemeTokens.of(context).brand,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '@${user.account}',
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
              onPressed: account == null ? null : onSignOut,
              icon: const Icon(Icons.logout),
              label: Text(translations.settings.account.signOut),
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            ),
          ),
        ],
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
    final tokens = FreepivThemeTokens.of(context);
    final imageUrl = this.imageUrl;

    Widget avatar = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tokens.brand.withValues(alpha: 0.56), width: 2),
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
      child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: avatar),
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
    return EnergeticCard(
      onTap: enabled ? onTap : null,
      padding: EdgeInsets.zero,
      child: ListTile(enabled: enabled, leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right)),
    );
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
    return DataRefreshView(
      onRefresh: () => widget.source.refresh(true),
      builder: (context, physics, locators) {
        return AnimatedBuilder(
          animation: widget.source,
          builder: (context, child) {
            final source = widget.source;
            final lastError = source.lastError;

            if (!source.initialized && source.refreshing && source.isEmpty) {
              return DataLoadingCustomScrollView(
                physics: physics,
                slivers: [
                  ?locators.sliverHeader,
                  const SliverPadding(padding: EdgeInsets.only(top: 12), sliver: SliverUserPreviewerSkeletonList(scrollIllustPreviews: false)),
                ],
              );
            }

            if (!source.initialized && lastError != null) {
              return DataSliverFillBody(
                physics: physics,
                sliverHeader: locators.sliverHeader,
                child: ErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
              );
            }

            if (source.initialized && source.isEmpty) {
              return DataSliverFillBody(
                physics: physics,
                sliverHeader: locators.sliverHeader,
                child: EmptyContent(icon: widget.emptyIcon, title: widget.emptyTitle),
              );
            }

            return DataLoadingCustomScrollView(
              physics: physics,
              slivers: [
                ?locators.sliverHeader,
                SliverDataList<UserPreview>(
                  source: source,
                  padding: const EdgeInsets.only(top: 12),
                  itemBuilder: (context, userPreview, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: UserPreviewer(userPreview: userPreview, scrollIllustPreviews: false),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _ensureLoaded() {
    if (!mounted || widget.source.initialized || widget.source.refreshing) {
      return;
    }

    unawaited(widget.source.refresh(true));
  }
}

class _MeSettingsEntry extends StatelessWidget {
  const _MeSettingsEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return EnergeticCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.settings_outlined),
        title: Text(translations.me.settings),
        subtitle: Text(translations.me.settingsSubtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _MeAboutEntry extends StatelessWidget {
  const _MeAboutEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;

    return EnergeticCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(translations.me.about),
        subtitle: Text(translations.me.aboutSubtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

enum MeUserListKind { following, followers }

class _MeUserListSource extends NextUrlListSource<UserPreview, UserPageResult> {
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
