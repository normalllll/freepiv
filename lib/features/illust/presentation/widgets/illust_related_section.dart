import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_section.dart';
import 'package:freepiv/features/illust/presentation/widgets/vertical_illust_preview_grid.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';

class IllustRelatedSection extends ConsumerWidget {
  const IllustRelatedSection({required this.illustId, required this.onIllustTap, required this.onShowMore, super.key});

  final int illustId;
  final ValueChanged<Illust> onIllustTap;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = t;
    final source = ref.watch(illustRelatedWorksProvider(illustId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IllustSectionTitle(title: translations.illust.section.relatedWorks, icon: Icons.auto_awesome_mosaic_outlined),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: source,
          builder: (context, child) {
            return _RelatedPreviewBody(source: source, currentIllustId: illustId, onIllustTap: onIllustTap, onShowMore: onShowMore);
          },
        ),
      ],
    );
  }
}

class _RelatedPreviewBody extends StatelessWidget {
  const _RelatedPreviewBody({required this.source, required this.currentIllustId, required this.onIllustTap, required this.onShowMore});

  final IllustRelatedListSource source;
  final int currentIllustId;
  final ValueChanged<Illust> onIllustTap;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    final translations = t;
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return const RelatedPreviewGridSkeleton(itemCount: 8);
    }

    if (!source.initialized && lastError != null) {
      return CompactMessage(
        icon: Icons.error_outline,
        message: translations.illust.related.failed,
        actionLabel: translations.common.retry,
        onAction: () => source.refresh(true),
      );
    }

    final works = source.items.where((illust) => illust.id != currentIllustId).take(8).toList(growable: false);

    if (works.isEmpty) {
      return CompactMessage(icon: Icons.image_not_supported_outlined, message: t.illust.related.empty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VerticalIllustPreviewGrid(illusts: works, onIllustTap: onIllustTap),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: onShowMore, icon: const Icon(Icons.open_in_full_outlined, size: 18), label: Text(translations.illust.related.viewMore)),
      ],
    );
  }
}
