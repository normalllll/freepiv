import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/logic/optimistic_mutation.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'illust_bookmark_logic.g.dart';

class IllustBookmarkArgs {
  final String runtimeTag;
  final int illustId;
  final bool isBookmarked;
  final bool isNovel;

  const IllustBookmarkArgs({required this.runtimeTag, required this.illustId, required this.isBookmarked, required this.isNovel});

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is IllustBookmarkArgs && other.runtimeTag == runtimeTag;
  }

  @override
  int get hashCode => runtimeTag.hashCode;
}

class IllustBookmarkState {
  final int illustId;
  final bool isBookmarked;
  final bool isNovel;
  final bool updating;

  const IllustBookmarkState({required this.illustId, required this.isBookmarked, required this.isNovel, this.updating = false});

  IllustBookmarkState copyWith({int? illustId, bool? isBookmarked, bool? isNovel, bool? updating}) {
    return IllustBookmarkState(
      illustId: illustId ?? this.illustId,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isNovel: isNovel ?? this.isNovel,
      updating: updating ?? this.updating,
    );
  }
}

@Riverpod(keepAlive: true)
class IllustBookmark extends _$IllustBookmark {
  @override
  IllustBookmarkState build(IllustBookmarkArgs args) {
    return IllustBookmarkState(illustId: args.illustId, isBookmarked: args.isBookmarked, isNovel: args.isNovel, updating: false);
  }

  Future<void> toggle() async {
    if (state.updating) return;

    final previous = state;
    final nextBookmarked = !previous.isBookmarked;

    await runOptimisticMutation(
      previous: previous,
      optimistic: previous.copyWith(isBookmarked: nextBookmarked, updating: true),
      read: () => state,
      write: (next) => state = next,
      mutate: () {
        if (nextBookmarked) {
          return pixivApi.postBookmarkAdd(
            id: previous.illustId,
            options: BookmarkAddOptions(tags: [], restrict: Restrict.public, isNovel: previous.isNovel),
          );
        }

        return pixivApi.postBookmarkDelete(id: previous.illustId, isNovel: previous.isNovel);
      },
      settle: (current) => current.copyWith(updating: false),
      rollback: (previous) => previous.copyWith(updating: false),
    );
  }
}
