/// The kinds of DownloadSource, as stored.
enum DownloadSourceKind { artwork, pixivision, novel, fanboxPost, fanboxCreator, standalone }

/// What a download was asked for from: the work, article, novel or FANBOX
/// post or creator whose files it saves. The downloads list shows a source as
/// one item holding its files.
///
/// [title], [subtitle] and [thumbnailUrl] are how the source looked when it
/// was downloaded from, so the history reads without the network; two
/// sources are the same item when their [key]s match, whatever their labels.
sealed class DownloadSource {
  const DownloadSource({required this.title, this.subtitle, this.thumbnailUrl});

  /// Null for a work saved before downloads recorded their source, whose
  /// title was never known.
  final String? title;

  /// Who made it: the work's or novel's author, the post's creator.
  final String? subtitle;
  final String? thumbnailUrl;

  DownloadSourceKind get kind;

  /// Identifies the source within its [kind].
  String get id;

  /// Identifies the source among every kind.
  String get key => '${kind.name}:$id';

  @override
  bool operator ==(Object other) => other is DownloadSource && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// A Pixiv illustration, manga or ugoira.
final class ArtworkSource extends DownloadSource {
  const ArtworkSource({required this.illustId, required super.title, super.subtitle, super.thumbnailUrl});

  final int illustId;

  @override
  DownloadSourceKind get kind => DownloadSourceKind.artwork;

  @override
  String get id => '$illustId';
}

/// A Pixivision article; [url] is the article page it opens.
final class PixivisionSource extends DownloadSource {
  const PixivisionSource({required this.articleId, required this.url, required super.title, super.thumbnailUrl});

  final int articleId;
  final String url;

  @override
  DownloadSourceKind get kind => DownloadSourceKind.pixivision;

  @override
  String get id => '$articleId';
}

/// A Pixiv novel; its cover and inline images.
final class NovelSource extends DownloadSource {
  const NovelSource({required this.novelId, required super.title, super.subtitle, super.thumbnailUrl});

  final int novelId;

  @override
  DownloadSourceKind get kind => DownloadSourceKind.novel;

  @override
  String get id => '$novelId';
}

/// Downloads from FANBOX, which need its session to fetch.
sealed class FanboxSource extends DownloadSource {
  const FanboxSource({required super.title, super.subtitle, super.thumbnailUrl});
}

/// A FANBOX post; its cover, images and attached files.
final class FanboxPostSource extends FanboxSource {
  const FanboxPostSource({required this.postId, required super.title, super.subtitle, super.thumbnailUrl});

  final String postId;

  @override
  DownloadSourceKind get kind => DownloadSourceKind.fanboxPost;

  @override
  String get id => postId;
}

/// A FANBOX creator: their profile images and fan card, or every post at
/// once, each file under its post (see DownloadPart).
final class FanboxCreatorSource extends FanboxSource {
  const FanboxCreatorSource({required this.creatorId, required super.title, super.thumbnailUrl});

  final String creatorId;

  @override
  DownloadSourceKind get kind => DownloadSourceKind.fanboxCreator;

  @override
  String get id => creatorId;
}

/// A file saved before downloads recorded their source; it is an item of
/// its own, identified by its task.
final class StandaloneSource extends DownloadSource {
  const StandaloneSource({required this.taskId, required super.title, super.thumbnailUrl});

  final String taskId;

  @override
  DownloadSourceKind get kind => DownloadSourceKind.standalone;

  @override
  String get id => taskId;
}

/// The part of a source a file belongs to, where a source has parts: one
/// post of a creator downloaded whole.
class DownloadPart {
  const DownloadPart({required this.id, required this.title});

  final String id;
  final String title;

  @override
  bool operator ==(Object other) => other is DownloadPart && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
