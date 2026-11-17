import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/novel/domain/novel_image_urls.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';

/// One picture of a novel, in the order of the text: an uploaded image or a
/// Pixiv work embedded in it.
class NovelPicture {
  const NovelPicture.uploaded({required this.thumbnailUrl, required this.viewerUrl}) : illustId = null;

  const NovelPicture.work({required this.thumbnailUrl, required int this.illustId}) : viewerUrl = null;

  /// The small picture for a strip.
  final String thumbnailUrl;

  /// The picture for the full-size viewer; null for an embedded work, which
  /// opens its own page.
  final String? viewerUrl;
  final int? illustId;

  bool get isWork => illustId != null;
}

/// What a novel's loaded text says about its shape.
class NovelStructure {
  const NovelStructure({required this.chapters, required this.pictures, required this.language, required this.totalLength});

  /// Titled chapters; 0 when the text has no chapter markers.
  final int chapters;

  /// The parsed text's length, the count the reader measures reading time by.
  final int totalLength;
  final List<NovelPicture> pictures;
  final String? language;
}

/// The shape of the novel's text; null until the text has loaded.
final novelStructureProvider = Provider.autoDispose.family<NovelStructure?, int>((ref, novelId) {
  final webview = ref.watch(novelTextProvider(novelId)).value;
  if (webview == null) return null;
  final model = ReaderModel(parseWebviewNovel(webview));
  final pictures = <NovelPicture>[];
  for (final index in model.imageBlocks) {
    switch (model.blocks[index]) {
      case NovelUploadedImage(:final image?):
        if (novelStripImageUrl(image) case final thumbnail?) {
          pictures.add(NovelPicture.uploaded(thumbnailUrl: thumbnail, viewerUrl: novelViewerImageUrl(image) ?? thumbnail));
        }
      case NovelEmbeddedWork(:final work?, :final illustId):
        if (novelEmbeddedWorkImageUrl(work) case final thumbnail?) pictures.add(NovelPicture.work(thumbnailUrl: thumbnail, illustId: illustId));
      default:
    }
  }
  return NovelStructure(
    chapters: model.blocks.whereType<NovelChapterTitle>().length,
    pictures: pictures,
    language: webview.language,
    totalLength: model.totalLength,
  );
});
