import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_tab_scaffold.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UserNovelListTabBody extends ConsumerStatefulWidget {
  const UserNovelListTabBody({required this.detail, required this.physics, this.sliverHeader, super.key});

  final UserDetailResult detail;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  ConsumerState<UserNovelListTabBody> createState() => _UserNovelListTabBodyState();
}

class _UserNovelListTabBodyState extends ConsumerState<UserNovelListTabBody> implements UserDetailTabRefreshController {
  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureLoaded);
  }

  @override
  void didUpdateWidget(UserNovelListTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.user.id != widget.detail.user.id) {
      Future.microtask(_ensureLoaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(userNovelsProvider(userId: widget.detail.user.id));

    return AnimatedBuilder(
      animation: source,
      builder: (context, child) {
        return UserNovelListBody(source: source, physics: widget.physics, sliverHeader: widget.sliverHeader, emptyTitle: context.t.user.empty.novels);
      },
    );
  }

  @override
  Future<bool> refreshTab() {
    final source = _readSource();
    return source.refresh(source.isEmpty);
  }

  void _ensureLoaded() {
    final source = _readSource();
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }

  UserNovelListSource _readSource() {
    return ref.read(userNovelsProvider(userId: widget.detail.user.id));
  }
}

class UserNovelListBody extends StatelessWidget {
  const UserNovelListBody({
    required this.source,
    required this.physics,
    required this.emptyTitle,
    this.sliverHeader,
    this.leadingSlivers = const [],
    super.key,
  });

  final DataListSource<Novel> source;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;
  final List<Widget> leadingSlivers;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return DataLoadingCustomScrollView(
        physics: physics,
        slivers: [
          ?sliverHeader,
          ...leadingSlivers,
          const SliverPadding(padding: EdgeInsets.all(12), sliver: SliverListSkeleton(itemExtent: 140, itemCount: 8)),
        ],
      );
    }

    if (!source.initialized && lastError != null) {
      return _SliverStateBody(
        physics: physics,
        sliverHeader: sliverHeader,
        leadingSlivers: leadingSlivers,
        child: ErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return _SliverStateBody(
        physics: physics,
        sliverHeader: sliverHeader,
        leadingSlivers: leadingSlivers,
        child: EmptyContent(icon: Icons.menu_book_outlined, title: emptyTitle),
      );
    }

    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?sliverHeader,
        ...leadingSlivers,
        SliverDataList<Novel>(
          source: source,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, novel, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: UserNovelCard(novel: novel),
            );
          },
        ),
      ],
    );
  }
}

class UserNovelCard extends StatelessWidget {
  const UserNovelCard({required this.novel, super.key});

  final Novel novel;

  @override
  Widget build(BuildContext context) {
    return NovelPreviewer(
      novel: novel,
      onTap: () {
        context.pushNamed(AppRoute.novelDetail.name, pathParameters: {'id': '${novel.id}'}, extra: novel);
      },
    );
  }
}

class SliverListSkeleton extends StatelessWidget {
  const SliverListSkeleton({required this.itemExtent, this.itemCount = 8, super.key});

  final double itemExtent;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: itemCount * 2 - 1,
      itemBuilder: (context, index) {
        if (index.isOdd) {
          return const SizedBox(height: 8);
        }

        return Skeletonizer.zone(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: itemExtent - 24,
                child: Row(
                  children: [
                    Bone(width: 72, height: itemExtent - 30, borderRadius: BorderRadius.circular(6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Bone.text(width: double.infinity),
                          const SizedBox(height: 10),
                          const Bone.text(width: 130),
                          const Spacer(),
                          Bone.text(width: 180),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SliverStateBody extends StatelessWidget {
  const _SliverStateBody({required this.child, required this.physics, required this.leadingSlivers, this.sliverHeader});

  final Widget child;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;
  final List<Widget> leadingSlivers;

  @override
  Widget build(BuildContext context) {
    return DataSliverFillBody(physics: physics, sliverHeader: sliverHeader, leadingSlivers: leadingSlivers, child: child);
  }
}
