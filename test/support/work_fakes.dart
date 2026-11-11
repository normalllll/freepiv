import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

/// A user with an [id] and no avatar.
User fakeUser(int id) => User(
  id: id,
  name: 'User $id',
  account: 'user_$id',
  profileImageUrls: const ProfileImageUrls(medium: ''),
);

/// An illustration by user [by] carrying [tags]; the rest of it is plain.
Illust fakeIllust(int id, {int by = 1, List<String> tags = const []}) => Illust(
  id: id,
  title: 'Work $id',
  kind: 'illust',
  imageUrls: const ImageUrls(squareMedium: '', medium: '', large: ''),
  caption: '',
  restrict: 0,
  user: fakeUser(by),
  tags: [for (final tag in tags) Tag(name: tag)],
  tools: const [],
  createDate: '2026-11-01T12:00:00+09:00',
  pageCount: 1,
  width: 1000,
  height: 1000,
  sanityLevel: 2,
  xRestrict: 0,
  metaSinglePage: const MetaSinglePage(),
  metaPages: const [],
  totalView: 1,
  totalBookmarks: 1,
  isBookmarked: false,
  visible: true,
  isMuted: false,
  illustAiType: 1,
);

/// A novel by user [by] carrying [tags].
Novel fakeNovel(int id, {int by = 1, List<String> tags = const []}) => Novel(
  id: id,
  title: 'Novel $id',
  caption: '',
  restrict: 0,
  xRestrict: 0,
  isOriginal: true,
  imageUrls: const ImageUrls(squareMedium: '', medium: '', large: ''),
  createDate: '2026-11-01T12:00:00+09:00',
  tags: [for (final tag in tags) Tag(name: tag)],
  pageCount: 1,
  textLength: 1000,
  user: fakeUser(by),
  series: const Series(),
  totalBookmarks: 1,
  isBookmarked: false,
  totalView: 1,
  visible: true,
  totalComments: 0,
  isMuted: false,
  isMypixivOnly: false,
  isXRestricted: false,
  novelAiType: 1,
);

/// User [id] as a list of users shows them, with no works.
UserPreview fakePreview(int id) => UserPreview(user: fakeUser(id), illusts: const [], isMuted: false);
