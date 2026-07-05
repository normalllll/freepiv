enum AppRoute {
  home('/'),
  search('/search'),
  searchIllustResult('/search/illust'),
  searchNovelResult('/search/novel'),
  searchUserResult('/search/user'),
  newest('/newest'),
  rankingIllust('/ranking/illust'),
  rankingManga('/ranking/manga'),
  rankingNovel('/ranking/novel'),
  login('/login'),
  me('/me'),
  meFollowing('/me/following'),
  meFollowers('/me/followers'),
  about('/about'),
  settings('/settings'),
  downloads('/downloads'),
  originalImageViewer('/image-viewer'),
  illustDetail('/illust/:id'),
  illustComments('/illust/:id/comments'),
  novelDetail('/novel/:id'),
  novelReader('/novel/:id/read'),
  novelComments('/novel/:id/comments'),
  userDetail('/user/:id');

  const AppRoute(this.path);

  final String path;
}
