import 'package:flutter/foundation.dart' show protected;
import 'package:freepiv/core/block/block_list.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:frost_data/frost_data.dart';

/// How many pages a single load reads at most while everything on them is
/// blocked.
const blockBackfillPages = 5;

/// What a list source keeps of the block list: that it listens to it while it
/// is in use, and which of its loads is the current one.
final class BlockFilterState {
  BlockFilterState(this._changed);

  final void Function(BlockList blocks) _changed;
  var _watching = false;
  var _load = 0;

  /// Starts listening to the block list; does nothing once it does.
  void watch() {
    if (_watching) return;
    _watching = true;
    AppSettings.blockListListenable.addListener(_notify);
  }

  /// Starts a load, which supersedes the one before it.
  int beginLoad() => ++_load;

  bool isCurrent(int load) => load == _load;

  void dispose() {
    _watching = false;
    AppSettings.blockListListenable.removeListener(_notify);
  }

  void _notify() => _changed(AppSettings.blockList);
}

/// The page [readFirst] gives, and where every item on it is blocked the pages
/// [readNext] gives after it, up to [blockBackfillPages] in all, as one load.
/// It stops asking once [mayAsk] says no, or [hasNext] says there are no more.
/// What the last page left of it is returned, empty where all of it was
/// blocked.
Future<List<T>> readUnblocked<T>({
  required Future<List<T>> Function() readFirst,
  required Future<List<T>> Function() readNext,
  required bool Function(T item) isBlocked,
  required bool Function() hasNext,
  required bool Function() mayAsk,
}) async {
  var items = <T>[];
  for (var pages = 1; pages <= blockBackfillPages; pages++) {
    if (pages > 1 && !(mayAsk() && hasNext())) break;
    items = [
      for (final item in await (pages == 1 ? readFirst : readNext)())
        if (!isBlocked(item)) item,
    ];
    if (items.isNotEmpty) break;
  }
  return items;
}

/// A cursor list that leaves out what the block list hides, for the sources
/// that list works or users. Each class keeps its own [itemsFromPage]; this
/// filters what it returns, reads on where a whole page was blocked, and takes
/// the items the block list newly hides out of the loaded list in place.
mixin BlockFilteredCursorList<Item, Page> on FrostCursorListSource<Item, Page> {
  /// Whether [blocks] hides [item].
  bool isBlocked(BlockList blocks, Item item);

  /// Runs after the block list changed and the loaded items were filtered, for
  /// what a source shows apart from its list.
  @protected
  void didChangeBlockList(BlockList blocks) {}

  late final BlockFilterState _blockState = BlockFilterState(_hideBlocked);

  @override
  Future<List<Item>> initList() => _read(() => super.initList());

  @override
  Future<List<Item>> nextList() => _read(() => super.nextList());

  Future<List<Item>> _read(Future<List<Item>> Function() readFirst) {
    _blockState.watch();
    final load = _blockState.beginLoad();
    return readUnblocked(
      readFirst: readFirst,
      readNext: () => super.nextList(),
      isBlocked: (item) => isBlocked(AppSettings.blockList, item),
      hasNext: () => hasNextPage,
      mayAsk: () => !isDisposed && _blockState.isCurrent(load),
    );
  }

  @override
  void clearData() {
    _blockState.beginLoad();
    super.clearData();
  }

  @override
  void dispose() {
    _blockState.dispose();
    super.dispose();
  }

  void _hideBlocked(BlockList blocks) {
    removeWhere((item) => isBlocked(blocks, item));
    didChangeBlockList(blocks);
  }
}
