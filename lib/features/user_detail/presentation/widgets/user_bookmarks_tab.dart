import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_tab_scaffold.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_illust_grid_tab.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_novel_list_tab.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_data/frost_data.dart';

class UserBookmarksTabBody extends ConsumerStatefulWidget {
  const UserBookmarksTabBody({required this.detail, required this.physics, this.sliverHeader, super.key});

  final UserDetailResult detail;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  ConsumerState<UserBookmarksTabBody> createState() => _UserBookmarksTabBodyState();
}

class _UserBookmarksTabBodyState extends ConsumerState<UserBookmarksTabBody> implements UserDetailTabRefreshController {
  UserBookmarkKind _bookmarkKind = UserBookmarkKind.illustManga;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _ensureLoaded(_bookmarkKind));
  }

  @override
  void didUpdateWidget(UserBookmarksTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.user.id != widget.detail.user.id) {
      Future.microtask(() => _ensureLoaded(_bookmarkKind));
    }
  }

  @override
  Widget build(BuildContext context) {
    final illustSource = ref.watch(userIllustBookmarksProvider(userId: widget.detail.user.id));
    final novelSource = ref.watch(userNovelBookmarksProvider(userId: widget.detail.user.id));

    return FrostLazyIndexedStack(
      index: _bookmarkKind.index,
      sizing: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: illustSource,
          builder: (context, child) {
            return _buildIllustBookmarks(context, illustSource, widget.physics, widget.sliverHeader);
          },
        ),
        AnimatedBuilder(
          animation: novelSource,
          builder: (context, child) {
            return _buildNovelBookmarks(context, novelSource, widget.physics, widget.sliverHeader);
          },
        ),
      ],
    );
  }

  @override
  Future<bool> refreshTab() {
    final source = _readCurrentSource();
    return source.refresh(source.items.isEmpty);
  }

  Widget _buildIllustBookmarks(BuildContext context, UserIllustBookmarkListSource source, ScrollPhysics? physics, Widget? sliverHeader) {
    return UserIllustGridBody(
      source: source,
      physics: physics,
      sliverHeader: SliverMainAxisGroup(slivers: [?sliverHeader, _selectorSliver(context)]),
      emptyTitle: context.t.user.empty.bookmarkIllustrations,
    );
  }

  Widget _buildNovelBookmarks(BuildContext context, UserNovelBookmarkListSource source, ScrollPhysics? physics, Widget? sliverHeader) {
    return UserNovelListBody(
      source: source,
      physics: physics,
      sliverHeader: SliverMainAxisGroup(slivers: [?sliverHeader, _selectorSliver(context)]),
      emptyTitle: context.t.user.empty.bookmarkNovels,
    );
  }

  Widget _selectorSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: _BookmarkKindSelector(
        value: _bookmarkKind,
        onChanged: (kind) {
          if (_bookmarkKind == kind) {
            return;
          }

          setState(() => _bookmarkKind = kind);
          Future.microtask(() => _ensureLoaded(kind));
        },
      ),
    );
  }

  void _ensureLoaded(UserBookmarkKind kind) {
    if (!mounted) return;
    switch (kind) {
      case UserBookmarkKind.illustManga:
        _ensureSourceLoaded(ref.read(userIllustBookmarksProvider(userId: widget.detail.user.id)));
      case UserBookmarkKind.novel:
        _ensureSourceLoaded(ref.read(userNovelBookmarksProvider(userId: widget.detail.user.id)));
    }
  }

  void _ensureSourceLoaded(FrostListSource<dynamic> source) {
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }

  FrostListSource<dynamic> _readCurrentSource() {
    return switch (_bookmarkKind) {
      UserBookmarkKind.illustManga => ref.read(userIllustBookmarksProvider(userId: widget.detail.user.id)),
      UserBookmarkKind.novel => ref.read(userNovelBookmarksProvider(userId: widget.detail.user.id)),
    };
  }
}

class _BookmarkKindSelector extends StatelessWidget {
  const _BookmarkKindSelector({required this.value, required this.onChanged});

  final UserBookmarkKind value;
  final ValueChanged<UserBookmarkKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    final inset = FrostMetrics.browseInset(MediaQuery.sizeOf(context).width);
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(inset, 10, inset, 6),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FrostPicker<UserBookmarkKind>.segmented(
              label: translations.user.tabs.bookmarks,
              options: [
                FrostPickerOption(
                  value: UserBookmarkKind.illustManga,
                  leading: const FrostGlyph.icon(FrostIconData.glyph(Icons.collections_outlined)),
                  label: translations.user.bookmarks.illustManga,
                ),
                FrostPickerOption(
                  value: UserBookmarkKind.novel,
                  leading: const FrostGlyph.icon(FrostIconData.glyph(Icons.menu_book_outlined)),
                  label: translations.user.bookmarks.novels,
                ),
              ],
              value: value,
              onChanged: (selection) => onChanged(selection),
            ),
          ),
        ),
      ),
    );
  }
}
