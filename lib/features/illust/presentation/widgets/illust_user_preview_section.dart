import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/widgets/horizontal_illust_strip.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:go_router/go_router.dart';

class IllustUserPreviewSection extends ConsumerWidget {
  const IllustUserPreviewSection({required this.illust, required this.onIllustTap, super.key});

  final Illust illust;
  final ValueChanged<Illust> onIllustTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = t;
    final userWorks = ref.watch(illustUserWorksProvider(illust.user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IllustSectionTitle(title: translations.illust.section.creator, icon: Icons.person_outline),
        const SizedBox(height: 8),
        _UserHeader(user: illust.user),
        const SizedBox(height: 12),
        Text(translations.illust.section.recentWorks, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        userWorks.when(
          loading: () => const HorizontalIllustStripSkeleton(),
          error: (error, stackTrace) => CompactMessage(
            icon: Icons.error_outline,
            message: translations.illust.works.failed,
            actionLabel: translations.common.retry,
            onAction: () {
              ref.read(illustUserWorksProvider(illust.user.id).notifier).reload();
            },
          ),
          data: (result) => _UserWorksStrip(result: result, currentIllustId: illust.id, onIllustTap: onIllustTap),
        ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          context.pushNamed(AppRoute.userDetail.name, pathParameters: {'id': '${user.id}'});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 44,
                child: PixivImage(url: user.profileImageUrls.medium, fit: BoxFit.cover, borderRadius: BorderRadius.circular(22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.account}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              UserFollowButton(userId: user.id, initialIsFollowed: user.isFollowed),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserWorksStrip extends StatelessWidget {
  const _UserWorksStrip({required this.result, required this.currentIllustId, required this.onIllustTap});

  final IllustPageResult result;
  final int currentIllustId;
  final ValueChanged<Illust> onIllustTap;

  @override
  Widget build(BuildContext context) {
    final works = result.illusts.where((illust) => illust.id != currentIllustId).take(12).toList(growable: false);

    if (works.isEmpty) {
      return CompactMessage(icon: Icons.image_not_supported_outlined, message: t.illust.works.empty);
    }

    return HorizontalIllustStrip(illusts: works, onIllustTap: onIllustTap);
  }
}
