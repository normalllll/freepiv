import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/features/downloads/presentation/content_image_entries.dart';
import 'package:freepiv/features/novel/logic/novel_structure.dart';
import 'package:freepiv/features/novel/presentation/detail/widgets/novel_head.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The novel's pictures as small images, each at its own proportions, in one
/// row. An uploaded image opens the viewer on all the uploaded ones; an
/// embedded work opens its own page.
class NovelIllustrations extends ConsumerWidget {
  const NovelIllustrations({required this.novel, required this.pictures, super.key});

  final Novel novel;
  final List<NovelPicture> pictures;

  static const height = 120.0;
  static const phoneHeight = 96.0;

  /// The ratio of an embedded work's picture until it is measured.
  static const workRatio = 3 / 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pictures.isEmpty) return const SizedBox.shrink();
    final t = context.t;
    final phone = FrostSizeClass.of(context) == FrostSizeClass.compact;
    final stripHeight = phone ? phoneHeight : height;
    final uploaded = [for (final picture in pictures) ?picture.viewerUrl];
    void open(NovelPicture picture) {
      if (picture.illustId case final id?) {
        unawaited(GoRouter.of(context).push(AppLocations.illust(id)));
      } else {
        openNovelImages(context, novel, uploaded, uploaded.indexOf(picture.viewerUrl!));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.related,
      children: [
        FrostSectionHeader(title: t.novel.reader.illustrationsCount(count: pictures.length)),
        SizedBox(
          height: stripHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pictures.length,
            separatorBuilder: (context, index) => const SizedBox(width: FrostGap.related),
            itemBuilder: (context, index) => _Tile(
              key: ValueKey(pictures[index].thumbnailUrl),
              novel: novel,
              picture: pictures[index],
              number: index + 1,
              height: stripHeight,
              onPressed: () => open(pictures[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends ConsumerStatefulWidget {
  const _Tile({required this.novel, required this.picture, required this.number, required this.height, required this.onPressed, super.key});

  final Novel novel;
  final NovelPicture picture;
  final int number;
  final double height;
  final VoidCallback onPressed;

  @override
  ConsumerState<_Tile> createState() => _TileState();
}

class _TileState extends ConsumerState<_Tile> {
  Size? _measured;

  double _ratio(ImageSizeStore sizes) {
    final size = _measured ?? sizes.sizeOf(widget.picture.sizeKey ?? widget.picture.thumbnailUrl) ?? (widget.picture.isWork ? null : novelImageFallbackSize);
    if (size == null || size.height <= 0) return NovelIllustrations.workRatio;
    return (size.width / size.height).clamp(0.25, 4.0);
  }

  void _loaded(ImageSizeStore sizes, Size size) {
    unawaited(sizes.record(widget.picture.sizeKey ?? widget.picture.thumbnailUrl, size));
    if (size == _measured) return;
    // The picture may report while the page is building.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _measured = size);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sizes = ref.watch(imageSizeStoreProvider);
    final ratio = _ratio(sizes);
    final url = widget.picture.thumbnailUrl;
    return SizedBox(
      width: widget.height * ratio,
      height: widget.height,
      child: FrostContextMenuRegion(
        entries: contentImageMenu(context, ref.read(rustMediaTransportProvider), url: widget.picture.viewerUrl ?? url, title: widget.novel.title),
        child: FrostMediaCard(
          aspectRatio: ratio,
          semanticLabel: context.t.novel.reader.illustrationAt(number: widget.number),
          media: AppPixivImage(url: url, aspectRatio: ratio, radius: 0, onImageSize: (size) => _loaded(sizes, size)),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}
