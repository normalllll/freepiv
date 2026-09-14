import 'package:freepiv/shared/widgets/search_input.dart';
import 'package:freepiv/shared/widgets/floating_filter_sliver.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'logic.dart';
import 'cards.dart';
import 'layout.dart';
import 'navigation.dart';

class FanboxHomeSkeleton extends StatelessWidget {
  const FanboxHomeSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SearchInputRegion(child: LoadingSkeletonBlock(width: double.infinity, height: 44, radius: 22)),
        SizedBox(
          height: compactFilterHeight(context),
          child: FanboxContent(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
              child: Skeletonizer(
                child: FanboxSectionNavigation(section: FanboxSection.home, onSelected: (_) {}),
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) =>
                SingleChildScrollView(padding: fanboxScrollPadding(constraints.maxWidth), child: const FanboxCollectionSkeleton()),
          ),
        ),
      ],
    );
  }
}

const _user = FanboxUser(id: '', name: 'Creator name');
const _post = FanboxPost(
  id: '',
  creatorId: '',
  user: _user,
  title: 'Article title',
  excerpt: 'Article description',
  publishedDatetime: '',
  updatedDatetime: '',
  feeRequired: 0,
  isRestricted: false,
  isLiked: false,
  likeCount: 0,
  commentCount: 0,
  tags: [],
  blocks: [],
);
const _plan = FanboxPlan(id: '', creatorId: '', user: _user, title: 'Creator plan', description: 'Plan description', fee: 0);
const _creator = FanboxCreator(
  creatorId: '',
  user: _user,
  description: 'Creator description',
  isFollowed: false,
  isSupported: false,
  hasAdultContent: false,
  profileLinks: [],
  profileImages: [],
);
const _notice = FanboxNotice(id: '', kind: '', userName: 'Creator name', title: 'Message title', body: 'Message content', date: '', isUnread: false);

class FanboxCollectionSkeleton extends StatelessWidget {
  const FanboxCollectionSkeleton({this.section = FanboxSection.home, this.itemCount, super.key});
  final FanboxSection section;
  final int? itemCount;
  @override
  Widget build(BuildContext context) {
    // Conservative row heights keep the viewport covered without stretching cards.
    final minimumHeight = switch (section) {
      FanboxSection.home ||
      FanboxSection.supporting ||
      FanboxSection.creatorPosts ||
      FanboxSection.tag ||
      FanboxSection.bookmarks ||
      FanboxSection.plans ||
      FanboxSection.creatorPlans => 320.0,
      FanboxSection.searchTags => 48.0,
      FanboxSection.notices || FanboxSection.messages => 160.0,
      _ => 76.0,
    };
    final count = itemCount ?? (MediaQuery.sizeOf(context).height / minimumHeight).ceil();
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          for (var index = 0; index < count; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: switch (section) {
                FanboxSection.plans || FanboxSection.creatorPlans => const FanboxPlanCard(_plan),
                FanboxSection.home ||
                FanboxSection.supporting ||
                FanboxSection.creatorPosts ||
                FanboxSection.tag ||
                FanboxSection.bookmarks => FanboxPostCard(post: _post, onTap: () {}, onCreator: () {}),
                FanboxSection.searchTags => FanboxTagCard(const FanboxTag(name: 'Tag name'), onTap: () {}),
                FanboxSection.notices || FanboxSection.messages => const FanboxNoticeCard(_notice),
                _ => FanboxCreatorCard(_creator, onTap: () {}),
              },
            ),
        ],
      ),
    );
  }
}

class FanboxArticleSkeleton extends StatelessWidget {
  const FanboxArticleSkeleton({this.title, super.key});
  final String? title;
  @override
  Widget build(BuildContext context) => Skeletonizer.zone(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title == null ? const Bone.text(words: 5) : Skeletonizer(child: Text(title!, style: Theme.of(context).textTheme.headlineMedium)),
        const SizedBox(height: 16),
        const ListTile(contentPadding: EdgeInsets.zero, title: Bone.text(words: 2), subtitle: Bone.text(words: 3)),
        const SizedBox(height: 16),
        for (var index = 0; index < (MediaQuery.sizeOf(context).height / 24).ceil(); index++)
          const Padding(padding: EdgeInsets.only(bottom: 12), child: Bone.text()),
      ],
    ),
  );
}
