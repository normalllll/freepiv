import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_content_state.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_tab_scaffold.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_data/frost_data.dart';

class UserFollowingTabBody extends ConsumerStatefulWidget {
  const UserFollowingTabBody({required this.detail, required this.physics, this.sliverHeader, super.key});

  final UserDetailResult detail;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  ConsumerState<UserFollowingTabBody> createState() => _UserFollowingTabBodyState();
}

class _UserFollowingTabBodyState extends ConsumerState<UserFollowingTabBody> implements UserDetailTabRefreshController {
  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureLoaded);
  }

  @override
  void didUpdateWidget(UserFollowingTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.user.id != widget.detail.user.id) {
      Future.microtask(_ensureLoaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(userFollowingUsersProvider(userId: widget.detail.user.id));

    return AnimatedBuilder(
      animation: source,
      builder: (context, child) {
        return UserFollowingBody(source: source, physics: widget.physics, sliverHeader: widget.sliverHeader);
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

  UserFollowingListSource _readSource() {
    return ref.read(userFollowingUsersProvider(userId: widget.detail.user.id));
  }
}

class UserFollowingBody extends StatelessWidget {
  const UserFollowingBody({required this.source, required this.physics, this.sliverHeader, super.key});

  final UserFollowingListSource source;
  final ScrollPhysics? physics;
  final Widget? sliverHeader;

  @override
  Widget build(BuildContext context) => FrostLoadStateSwitcher(phase: source.phase, child: _buildPhase(context));

  Widget _buildPhase(BuildContext context) {
    final lastError = source.lastError;

    if (source.phase == FrostLoadPhase.loading) {
      return FrostLoadingScrollView(physics: physics, slivers: [?sliverHeader, const SliverUserPreviewerSkeletonGrid()]);
    }

    if (!source.initialized && lastError != null) {
      return UserErrorBody(error: lastError, onRetry: () => source.refresh(true), physics: physics, sliverHeader: sliverHeader);
    }

    if (source.initialized && source.items.isEmpty) {
      return UserEmptyBody(icon: Icons.people_outline, title: context.t.user.empty.following, physics: physics, sliverHeader: sliverHeader);
    }

    return FrostLoadingScrollView(
      physics: physics,
      slivers: [
        ?sliverHeader,
        SliverUserPreviewGrid(source: source),
      ],
    );
  }
}
