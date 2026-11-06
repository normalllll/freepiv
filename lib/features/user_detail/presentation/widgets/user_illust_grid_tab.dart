import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_tab_scaffold.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/illust_waterfall_skeleton.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_data/frost_data.dart';

class UserIllustGridTabBody extends ConsumerStatefulWidget {
  const UserIllustGridTabBody({required this.detail, required this.illustType, required this.physics, this.sliverHeader, super.key});

  final UserDetailResult detail;
  final IllustType illustType;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  ConsumerState<UserIllustGridTabBody> createState() => _UserIllustGridTabBodyState();
}

class _UserIllustGridTabBodyState extends ConsumerState<UserIllustGridTabBody> implements UserDetailTabRefreshController {
  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureLoaded);
  }

  @override
  void didUpdateWidget(UserIllustGridTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.user.id != widget.detail.user.id || oldWidget.illustType != widget.illustType) {
      Future.microtask(_ensureLoaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(userIllustsProvider(userId: widget.detail.user.id, illustType: widget.illustType));

    return AnimatedBuilder(
      animation: source,
      builder: (context, child) {
        return UserIllustGridBody(
          source: source,
          physics: widget.physics,
          sliverHeader: widget.sliverHeader,
          emptyTitle: widget.illustType == IllustType.illust ? context.t.user.empty.illustrations : context.t.user.empty.manga,
        );
      },
    );
  }

  @override
  Future<bool> refreshTab() {
    final source = _readSource();
    return source.refresh(source.items.isEmpty);
  }

  void _ensureLoaded() {
    if (!mounted) return;
    final source = _readSource();
    if (!source.initialized && !source.refreshing) {
      source.refresh(true);
    }
  }

  UserIllustListSource _readSource() {
    return ref.read(userIllustsProvider(userId: widget.detail.user.id, illustType: widget.illustType));
  }
}

class UserIllustGridBody extends StatelessWidget {
  const UserIllustGridBody({
    required this.source,
    required this.physics,
    required this.emptyTitle,
    this.sliverHeader,
    this.leadingSlivers = const [],
    super.key,
  });

  final FrostListSource<Illust> source;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;
  final List<Widget> leadingSlivers;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) => FrostLoadStateSwitcher(phase: source.phase, child: _buildPhase(context));

  Widget _buildPhase(BuildContext context) {
    final lastError = source.lastError;

    if (source.phase == FrostLoadPhase.loading) {
      return FrostLoadingScrollView(physics: physics, slivers: [...leadingSlivers, ?sliverHeader, const SliverIllustWaterfallSkeleton()]);
    }

    if (!source.initialized && lastError != null) {
      return _SliverStateBody(
        physics: physics,
        sliverHeader: sliverHeader,
        leadingSlivers: leadingSlivers,
        child: FrostErrorContent.fromError(error: lastError, onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.items.isEmpty) {
      return _SliverStateBody(
        physics: physics,
        sliverHeader: sliverHeader,
        leadingSlivers: leadingSlivers,
        child: FrostEmptyState(icon: FrostIconData.glyph(Icons.image_not_supported_outlined), title: emptyTitle),
      );
    }

    return FrostLoadingScrollView(
      physics: physics,
      slivers: [
        ...leadingSlivers,
        ?sliverHeader,
        FrostSliverDataWaterfallGrid<Illust>(
          firstLoadSkeleton: const FullScreenLoadingSkeleton(),
          source: source,
          itemBuilder: (context, illust, index) {
            return IllustPreviewer(illust: illust, onOpen: (heroTag) => openIllustDetail(context, illust, heroTag));
          },
        ),
      ],
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
    return FrostSliverFillBody(physics: physics, sliverHeader: sliverHeader, leadingSlivers: leadingSlivers, child: child);
  }
}
