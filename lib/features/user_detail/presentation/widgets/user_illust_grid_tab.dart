import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_tab_scaffold.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/shared/widgets/error.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/illust_waterfall_skeleton.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:go_router/go_router.dart';

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
    return source.refresh(source.isEmpty);
  }

  void _ensureLoaded() {
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

  final DataListSource<Illust> source;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;
  final List<Widget> leadingSlivers;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return DataLoadingCustomScrollView(physics: physics, slivers: [?sliverHeader, ...leadingSlivers, const SliverIllustWaterfallSkeleton()]);
    }

    if (!source.initialized && lastError != null) {
      return _SliverStateBody(
        physics: physics,
        sliverHeader: sliverHeader,
        leadingSlivers: leadingSlivers,
        child: ErrorContent(message: formatPixivError(lastError), onRetry: () => source.refresh(true)),
      );
    }

    if (source.initialized && source.isEmpty) {
      return _SliverStateBody(
        physics: physics,
        sliverHeader: sliverHeader,
        leadingSlivers: leadingSlivers,
        child: EmptyContent(icon: Icons.image_not_supported_outlined, title: emptyTitle),
      );
    }

    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?sliverHeader,
        ...leadingSlivers,
        SliverDataWaterfallGrid<Illust>(
          source: source,
          padding: const EdgeInsets.all(12),
          maxCrossAxisExtent: 240,
          itemBuilder: (context, illust, index) {
            return IllustPreviewer(
              illust: illust,
              onTap: () {
                context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': '${illust.id}'}, extra: illust);
              },
            );
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
    return DataSliverFillBody(physics: physics, sliverHeader: sliverHeader, leadingSlivers: leadingSlivers, child: child);
  }
}
