import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

/// The novel as the downloads list shows the images saved from it.
NovelSource novelDownloadSource(Novel novel) =>
    NovelSource(novelId: novel.id, title: novel.title, subtitle: novel.user.name, thumbnailUrl: novel.imageUrls.squareMedium);
