import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/features/illust/presentation/widgets/vertical_illust_preview_grid.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:go_router/go_router.dart';
import 'package:frost_data/frost_data.dart';

class IllustUserPreviewSection extends ConsumerWidget {
  const IllustUserPreviewSection({required this.illust, required this.onIllustTap, this.showRecentWorks = true, this.showHeader = true, super.key});

  final Illust illust;
  final IllustOpener onIllustTap;
  final bool showRecentWorks;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = t;
    final userWorks = showRecentWorks ? ref.watch(illustUserWorksProvider(illust.user.id)) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) _UserHeader(user: illust.user),
        if (userWorks != null) ...[
          // Same header and grid as "Related works": a fixed two-row grid in
          // the panel instead of a strip that needs hidden scrolling.
          Row(
            children: [
              Expanded(
                child: IllustSectionTitle(title: translations.illust.section.recentWorks, icon: Icons.person_outline),
              ),
              TextButton(onPressed: () => context.push(AppLocations.user(illust.user.id)), child: Text(translations.discover.viewAll)),
            ],
          ),
          const SizedBox(height: 4),
          FrostLoadStateSwitcher(
            animateSize: true,
            child: userWorks.when(
              loading: () => const RelatedPreviewGridSkeleton(itemCount: _recentWorksCount),
              error: (error, stackTrace) => FrostCompactMessage.error(
                error: error,
                onAction: () {
                  ref.read(illustUserWorksProvider(illust.user.id).notifier).reload();
                },
              ),
              data: (result) => _UserWorksGrid(result: result, currentIllustId: illust.id, onIllustTap: onIllustTap),
            ),
          ),
        ],
      ],
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final identity = Material(
      color: Colors.transparent,
      child: FrostClickSurface(
        onTap: () => context.push(AppLocations.user(user.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 44,
                child: PixivImage(url: user.profileImageUrls.medium, fit: BoxFit.cover, borderRadius: BorderRadius.circular(22)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      '@${user.account}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final follow = UserFollowButton(userId: user.id, initialIsFollowed: user.isFollowed);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Large text must not let the action consume the creator's entire name.
        if (constraints.maxWidth < MediaQuery.textScalerOf(context).scale(300)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              const SizedBox(height: 4),
              Align(alignment: AlignmentDirectional.centerEnd, child: follow),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: identity),
            const SizedBox(width: 8),
            follow,
          ],
        );
      },
    );
  }
}

const _recentWorksCount = 8;

class _UserWorksGrid extends StatelessWidget {
  const _UserWorksGrid({required this.result, required this.currentIllustId, required this.onIllustTap});

  final IllustPageResult result;
  final int currentIllustId;
  final IllustOpener onIllustTap;

  @override
  Widget build(BuildContext context) {
    final works = result.illusts.where((illust) => illust.id != currentIllustId).take(_recentWorksCount).toList(growable: false);

    if (works.isEmpty) {
      return FrostCompactMessage(icon: FrostIconData.glyph(Icons.image_not_supported_outlined), message: t.illust.works.empty);
    }

    return VerticalIllustPreviewGrid(illusts: works, onIllustTap: onIllustTap);
  }
}
