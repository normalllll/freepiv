import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_content_state.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_tab_scaffold.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';

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
    return source.refresh(source.isEmpty);
  }

  void _ensureLoaded() {
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
  Widget build(BuildContext context) {
    final lastError = source.lastError;

    if (!source.initialized && source.refreshing && source.isEmpty) {
      return DataLoadingCustomScrollView(
        physics: physics,
        slivers: [
          ?sliverHeader,
          const SliverPadding(padding: EdgeInsets.all(12), sliver: SliverUserPreviewerSkeletonList(scrollIllustPreviews: false)),
        ],
      );
    }

    if (!source.initialized && lastError != null) {
      return UserErrorBody(error: lastError, onRetry: () => source.refresh(true), physics: physics, sliverHeader: sliverHeader);
    }

    if (source.initialized && source.isEmpty) {
      return UserEmptyBody(icon: Icons.people_outline, title: context.t.user.empty.following, physics: physics, sliverHeader: sliverHeader);
    }

    return DataLoadingCustomScrollView(
      physics: physics,
      slivers: [
        ?sliverHeader,
        SliverDataList<UserPreview>(
          source: source,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, userPreview, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: UserPreviewer(userPreview: userPreview, scrollIllustPreviews: false),
            );
          },
        ),
      ],
    );
  }
}
