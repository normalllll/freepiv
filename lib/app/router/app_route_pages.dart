import 'package:flutter/material.dart';
import 'package:freepiv/app/router/detail_transition_page.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/work_comments_page.dart';
import 'package:freepiv/features/downloads/presentation/downloads_page.dart';
import 'package:freepiv/features/home/presentation/home_page.dart';
import 'package:freepiv/features/illust/presentation/illust_detail_page.dart';
import 'package:freepiv/features/login/presentation/login_page.dart';
import 'package:freepiv/features/me/presentation/me_page.dart';
import 'package:freepiv/features/newest/presentation/page/newest_page.dart';
import 'package:freepiv/features/novel/presentation/detail/novel_detail_page.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reader_page.dart';
import 'package:freepiv/features/ranking/presentation/ranking_work_pages.dart';
import 'package:freepiv/features/search/presentation/search_illust_result_page.dart';
import 'package:freepiv/features/search/presentation/search_novel_result_page.dart';
import 'package:freepiv/features/search/presentation/search_page.dart';
import 'package:freepiv/features/search/presentation/search_user_result_page.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:go_router/go_router.dart';

Page<void> loginPage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: LoginPage());
}

Page<void> homePage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: HomePage());
}

Page<void> newestPage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: NewestPage());
}

Page<void> rankingIllustPage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: RankingIllustPage());
}

Page<void> rankingMangaPage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: RankingMangaPage());
}

Page<void> rankingNovelPage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: RankingNovelPage());
}

Page<void> searchPage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: SearchPage());
}

Page<void> searchIllustResultPage(BuildContext context, GoRouterState state) {
  return NoTransitionPage(child: SearchIllustResultPage(keyword: state.uri.queryParameters['q'] ?? ''));
}

Page<void> searchNovelResultPage(BuildContext context, GoRouterState state) {
  return NoTransitionPage(child: SearchNovelResultPage(keyword: state.uri.queryParameters['q'] ?? ''));
}

Page<void> searchUserResultPage(BuildContext context, GoRouterState state) {
  return NoTransitionPage(child: SearchUserResultPage(keyword: state.uri.queryParameters['q'] ?? ''));
}

Page<void> mePage(BuildContext context, GoRouterState state) {
  return const NoTransitionPage(child: MePage());
}

Page<void> meFollowingPage(BuildContext context, GoRouterState state) {
  return detailTransitionPage(
    key: state.pageKey,
    child: const MeUserListPage(kind: MeUserListKind.following),
  );
}

Page<void> meFollowersPage(BuildContext context, GoRouterState state) {
  return detailTransitionPage(
    key: state.pageKey,
    child: const MeUserListPage(kind: MeUserListKind.followers),
  );
}

Page<void> settingsPage(BuildContext context, GoRouterState state) {
  return detailTransitionPage(key: state.pageKey, child: const SettingsPage());
}

Page<void> downloadsPage(BuildContext context, GoRouterState state) {
  return detailTransitionPage(key: state.pageKey, child: const DownloadsPage());
}

Page<void> originalImageViewerPage(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  if (extra is! OriginalImageViewerArgs || extra.pages.isEmpty) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return detailTransitionPage(
    key: state.pageKey,
    child: OriginalImageViewerPage(args: extra),
  );
}

Page<void> illustDetailPage(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  final illust = extra is Illust ? extra : null;
  final illustId = int.tryParse(state.pathParameters['id'] ?? '');

  if (illustId == null && illust == null) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return detailTransitionPage(
    key: state.pageKey,
    child: IllustDetailPage(illustId: illustId, illust: illust),
  );
}

Page<void> illustCommentsPage(BuildContext context, GoRouterState state) {
  final illustId = int.tryParse(state.pathParameters['id'] ?? '');
  if (illustId == null) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return detailTransitionPage(
    key: state.pageKey,
    child: WorkCommentsPage(workType: CommentWorkType.illust, workId: illustId, totalComments: _commentCountFromExtra(state.extra)),
  );
}

Page<void> novelDetailPage(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  final novel = extra is Novel ? extra : null;
  final novelId = int.tryParse(state.pathParameters['id'] ?? '');

  if (novelId == null && novel == null) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return detailTransitionPage(
    key: state.pageKey,
    child: NovelDetailPage(novelId: novel == null ? novelId : null, novel: novel),
  );
}

Page<void> novelReaderPage(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  final novel = extra is Novel ? extra : null;
  final novelId = int.tryParse(state.pathParameters['id'] ?? '');

  if (novelId == null && novel == null) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return detailTransitionPage(
    key: state.pageKey,
    child: NovelReaderPage(novelId: novel == null ? novelId : null, novel: novel),
  );
}

Page<void> novelCommentsPage(BuildContext context, GoRouterState state) {
  final novelId = int.tryParse(state.pathParameters['id'] ?? '');
  if (novelId == null) {
    return _missingRoutePage(key: state.pageKey, message: t.common.notFound);
  }

  return detailTransitionPage(
    key: state.pageKey,
    child: WorkCommentsPage(workType: CommentWorkType.novel, workId: novelId, totalComments: _commentCountFromExtra(state.extra)),
  );
}

Page<void> userDetailPage(BuildContext context, GoRouterState state) {
  final extra = state.extra;

  if (extra is UserDetailResult) {
    return detailTransitionPage(
      key: state.pageKey,
      child: UserDetailPage(userDetail: extra),
    );
  }

  final userId = extra is int ? extra : int.tryParse(state.pathParameters['id'] ?? '');
  if (userId == null) {
    return _missingRoutePage(key: state.pageKey, message: t.user.error.missingUser);
  }

  return detailTransitionPage(
    key: state.pageKey,
    child: UserDetailPage(userId: userId),
  );
}

int? _commentCountFromExtra(Object? extra) {
  return extra is int ? extra : null;
}

Page<void> _missingRoutePage({required LocalKey key, required String message}) {
  return detailTransitionPage(
    key: key,
    child: AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        return Scaffold(
          appBar: shouldUseDesktopShell ? null : AppBar(title: Text(context.t.common.notFound)),
          body: Center(child: Text(message)),
        );
      },
    ),
  );
}
