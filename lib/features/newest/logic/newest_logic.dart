import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'newest_logic.g.dart';

enum NewestAudience { following, mypixiv, everyone }

enum NewestWorkType { illustManga, illust, manga, novel }

enum NewestFollowScope { all, private, public }

const _followedNewestWorkTypes = [NewestWorkType.illustManga, NewestWorkType.novel];
const _publicNewestWorkTypes = [NewestWorkType.illust, NewestWorkType.manga, NewestWorkType.novel];

List<NewestWorkType> newestWorkTypeOptions(NewestAudience audience) {
  return switch (audience) {
    NewestAudience.following || NewestAudience.mypixiv => _followedNewestWorkTypes,
    NewestAudience.everyone => _publicNewestWorkTypes,
  };
}

NewestWorkType normalizeNewestWorkType(NewestAudience audience, NewestWorkType workType) {
  final options = newestWorkTypeOptions(audience);
  return options.contains(workType) ? workType : options.first;
}

sealed class NewestItem {
  const NewestItem();
}

class NewestIllust extends NewestItem {
  const NewestIllust(this.illust);

  final Illust illust;
}

class NewestNovel extends NewestItem {
  const NewestNovel(this.novel);

  final Novel novel;
}

class NewestFeedKey {
  const NewestFeedKey({required this.audience, required this.workType, this.followScope = NewestFollowScope.all});

  final NewestAudience audience;
  final NewestWorkType workType;
  final NewestFollowScope followScope;

  bool get isNovel => workType == NewestWorkType.novel;

  Restrict? get restrict {
    return switch (followScope) {
      NewestFollowScope.all => null,
      NewestFollowScope.private => Restrict.private,
      NewestFollowScope.public => Restrict.public,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is NewestFeedKey && audience == other.audience && workType == other.workType && followScope == other.followScope;
  }

  @override
  int get hashCode => Object.hash(audience, workType, followScope);
}

const newestFeedKeys = <NewestFeedKey>[
  NewestFeedKey(audience: NewestAudience.following, workType: NewestWorkType.illustManga),
  NewestFeedKey(audience: NewestAudience.following, workType: NewestWorkType.novel),
  NewestFeedKey(audience: NewestAudience.following, workType: NewestWorkType.illustManga, followScope: NewestFollowScope.private),
  NewestFeedKey(audience: NewestAudience.following, workType: NewestWorkType.novel, followScope: NewestFollowScope.private),
  NewestFeedKey(audience: NewestAudience.following, workType: NewestWorkType.illustManga, followScope: NewestFollowScope.public),
  NewestFeedKey(audience: NewestAudience.following, workType: NewestWorkType.novel, followScope: NewestFollowScope.public),
  NewestFeedKey(audience: NewestAudience.mypixiv, workType: NewestWorkType.illustManga),
  NewestFeedKey(audience: NewestAudience.mypixiv, workType: NewestWorkType.novel),
  NewestFeedKey(audience: NewestAudience.everyone, workType: NewestWorkType.illust),
  NewestFeedKey(audience: NewestAudience.everyone, workType: NewestWorkType.manga),
  NewestFeedKey(audience: NewestAudience.everyone, workType: NewestWorkType.novel),
];

class NewestState {
  const NewestState({
    required this.audience,
    required this.followingWorkType,
    required this.mypixivWorkType,
    required this.everyoneWorkType,
    required this.followScope,
    required this.sources,
  });

  final NewestAudience audience;
  final NewestWorkType followingWorkType;
  final NewestWorkType mypixivWorkType;
  final NewestWorkType everyoneWorkType;
  final NewestFollowScope followScope;
  final Map<NewestFeedKey, NewestListSource> sources;

  NewestFeedKey get currentKey {
    return keyForAudience(audience);
  }

  NewestFeedKey keyForAudience(NewestAudience audience) {
    return switch (audience) {
      NewestAudience.following => NewestFeedKey(audience: audience, workType: normalizeNewestWorkType(audience, followingWorkType), followScope: followScope),
      NewestAudience.mypixiv => NewestFeedKey(audience: audience, workType: normalizeNewestWorkType(audience, mypixivWorkType)),
      NewestAudience.everyone => NewestFeedKey(audience: audience, workType: normalizeNewestWorkType(audience, everyoneWorkType)),
    };
  }

  NewestListSource get source => sourceFor(currentKey);

  NewestListSource sourceForAudience(NewestAudience audience) {
    return sourceFor(keyForAudience(audience));
  }

  NewestListSource sourceFor(NewestFeedKey key) => sources[key]!;

  NewestState copyWith({
    NewestAudience? audience,
    NewestWorkType? followingWorkType,
    NewestWorkType? mypixivWorkType,
    NewestWorkType? everyoneWorkType,
    NewestFollowScope? followScope,
    Map<NewestFeedKey, NewestListSource>? sources,
  }) {
    return NewestState(
      audience: audience ?? this.audience,
      followingWorkType: followingWorkType ?? this.followingWorkType,
      mypixivWorkType: mypixivWorkType ?? this.mypixivWorkType,
      everyoneWorkType: everyoneWorkType ?? this.everyoneWorkType,
      followScope: followScope ?? this.followScope,
      sources: sources ?? this.sources,
    );
  }
}

class NewestListSource extends NextUrlListSource<NewestItem, Object> {
  NewestListSource({required this.key});

  final NewestFeedKey key;

  @override
  Future<Object> loadFirstPage() {
    return _fetchFirstPage();
  }

  @override
  Future<Object> loadNextPage(String nextUrl) {
    if (key.isNovel) {
      return pixivApi.getNextNovelPage(url: nextUrl);
    }

    return pixivApi.getNextIllustPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(Object page) {
    return switch (page) {
      IllustPageResult(:final nextUrl) => nextUrl,
      NovelPageResult(:final nextUrl) => nextUrl,
      _ => null,
    };
  }

  @override
  List<NewestItem> itemsFromPage(Object page) {
    return switch (page) {
      IllustPageResult(:final illusts) => [for (final illust in illusts) NewestIllust(illust)],
      NovelPageResult(:final novels) => [for (final novel in novels) NewestNovel(novel)],
      _ => const <NewestItem>[],
    };
  }

  Future<Object> _fetchFirstPage() async {
    return switch (key.audience) {
      NewestAudience.following =>
        key.isNovel ? pixivApi.getFollowNewNovelPage(restrict: key.restrict) : pixivApi.getFollowNewIllustPage(restrict: key.restrict),
      NewestAudience.mypixiv => key.isNovel ? pixivApi.getMypixivNewNovelPage() : pixivApi.getMypixivNewIllustPage(),
      NewestAudience.everyone => switch (key.workType) {
        NewestWorkType.illust => pixivApi.getNewIllustPage(illustType: IllustType.illust),
        NewestWorkType.manga => pixivApi.getNewIllustPage(illustType: IllustType.manga),
        NewestWorkType.novel => pixivApi.getNewNovelPage(),
        NewestWorkType.illustManga => throw StateError('illustManga is not a valid public newest feed.'),
      },
    };
  }
}

@Riverpod(keepAlive: true)
class Newest extends _$Newest {
  @override
  NewestState build() {
    final sources = {for (final key in newestFeedKeys) key: _createSource(key)};
    ref.onDispose(() {
      for (final source in sources.values) {
        source.dispose();
      }
    });

    return NewestState(
      audience: NewestAudience.following,
      followingWorkType: NewestWorkType.illustManga,
      mypixivWorkType: NewestWorkType.illustManga,
      everyoneWorkType: NewestWorkType.illust,
      followScope: NewestFollowScope.all,
      sources: sources,
    );
  }

  void setAudience(NewestAudience audience) {
    if (state.audience == audience) {
      return;
    }

    state = state.copyWith(audience: audience);
    loadCurrentIfNeeded();
  }

  void setWorkType(NewestWorkType workType) {
    setWorkTypeForAudience(state.audience, workType);
  }

  void setWorkTypeForAudience(NewestAudience audience, NewestWorkType workType) {
    final normalizedWorkType = normalizeNewestWorkType(audience, workType);
    state = switch (audience) {
      NewestAudience.following => state.copyWith(followingWorkType: normalizedWorkType),
      NewestAudience.mypixiv => state.copyWith(mypixivWorkType: normalizedWorkType),
      NewestAudience.everyone => state.copyWith(everyoneWorkType: normalizedWorkType),
    };
    loadSourceIfNeeded(state.sourceForAudience(audience));
  }

  void setFollowScope(NewestFollowScope followScope) {
    if (state.followScope == followScope) {
      return;
    }

    state = state.copyWith(followScope: followScope);
    loadCurrentIfNeeded();
  }

  void loadCurrentIfNeeded() {
    loadSourceIfNeeded(state.source);
  }

  void loadSourceIfNeeded(NewestListSource source) {
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }

  NewestListSource _createSource(NewestFeedKey key) {
    return NewestListSource(key: key);
  }
}
