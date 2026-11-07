import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';

/// Works like one illustration: a waterfall of cards
/// across the whole width, under a header naming the work they are like by
/// its thumbnail. A page that fails to load more retries in place.
class IllustRelatedPage extends ConsumerStatefulWidget {
  const IllustRelatedPage({required this.illustId, this.sourceIllust, super.key});

  final int illustId;

  /// The work the list is like, when the opener had it.
  final Illust? sourceIllust;

  @override
  ConsumerState<IllustRelatedPage> createState() => _IllustRelatedPageState();
}

class _IllustRelatedPageState extends ConsumerState<IllustRelatedPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final source = ref.read(illustRelatedWorksProvider(widget.illustId));
      if (!source.initialized && !source.refreshing) source.refresh(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final source = ref.watch(illustRelatedWorksProvider(widget.illustId));
    final work = widget.sourceIllust;
    return AppRefreshScope(
      onRefresh: () => source.refresh(false),
      child: FrostPinnedChrome(
        chrome: FrostPageHeader(
          leading: [
            if (work != null)
              FrostThumbnail(
                size: FrostThumbnailSize.small,
                semanticLabel: work.title,
                image: AppPixivImage(url: work.imageUrls.squareMedium, aspectRatio: 1, radius: 0),
              ),
          ],
          title: FrostText(t.illust.section.relatedWorks),
        ),
        body: FrostRefreshView(
          onRefresh: () => source.refresh(false),
          builder: (context, physics, locators) => FrostLoadingScrollView(
            physics: physics,
            slivers: [
              const FrostChromeSpacer(),
              ?locators.sliverHeader,
              FrostSliverDataWaterfallGrid<Illust>(
                source: source,
                firstLoadSkeleton: const AppArtworkWaterfallSkeleton(),
                empty: FrostEmptyState(icon: FrostIconSet.of(context).empty, title: t.illust.related.empty),
                itemBuilder: (context, illust, index) => AppArtworkCard(illust: illust),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
