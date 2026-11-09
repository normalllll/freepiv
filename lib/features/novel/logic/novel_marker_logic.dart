import 'dart:convert';

import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/logic/optimistic_mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'novel_marker_logic.g.dart';

/// The section of a novel's `{"page":N}` marker, or null when there is none.
int? parseNovelMarker(String? marker) {
  if (marker == null || marker.isEmpty) return null;
  try {
    final decoded = jsonDecode(marker);
    if (decoded case {'page': final int page} when page > 0) return page;
  } on FormatException {
    return null;
  }
  return null;
}

class NovelMarkerArgs {
  const NovelMarkerArgs({required this.accountId, required this.novelId, required this.page});

  final String? accountId;
  final int novelId;

  /// Where the state starts; not part of the identity.
  final int? page;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NovelMarkerArgs && other.accountId == accountId && other.novelId == novelId;

  @override
  int get hashCode => Object.hash(accountId, novelId);
}

class NovelMarkerState {
  const NovelMarkerState({required this.page, this.updating = false});

  final int? page;
  final bool updating;
}

/// The novel's reading bookmark on Pixiv. Kept once read: the text the reader
/// opens with is not fetched again after the bookmark changes.
@Riverpod(keepAlive: true)
class NovelMarker extends _$NovelMarker {
  @override
  NovelMarkerState build(NovelMarkerArgs args) => NovelMarkerState(page: args.page);

  Future<void> set(int page) => _change(page, () => pixivApi.postNovelMarkerAdd(novelId: args.novelId, page: page));

  Future<void> remove() => _change(null, () => pixivApi.postNovelMarkerDelete(novelId: args.novelId));

  Future<void> _change(int? page, Future<void> Function() request) async {
    if (state.updating) return;
    if (args.accountId == null || pixivAccountNotifier.value?.user.id != args.accountId) return;
    final previous = state;
    await runOptimisticMutation(
      previous: previous,
      optimistic: NovelMarkerState(page: page, updating: true),
      read: () => state,
      write: (next) => state = next,
      mutate: request,
      settle: (current) => NovelMarkerState(page: current.page),
      rollback: (previous) => NovelMarkerState(page: previous.page),
      canCommit: () => ref.mounted && pixivAccountNotifier.value?.user.id == args.accountId,
    );
  }
}
