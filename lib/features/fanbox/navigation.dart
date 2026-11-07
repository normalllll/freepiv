import 'package:flutter/widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'logic.dart';

String fanboxSectionLabel(BuildContext context, FanboxSection section) {
  final t = context.t.fanbox;
  return switch (section) {
    FanboxSection.home => t.home,
    FanboxSection.supporting => t.supporting,
    FanboxSection.following => t.following,
    FanboxSection.recommended => t.recommended,
    FanboxSection.pixiv => t.pixiv,
    FanboxSection.plans => t.plans,
    FanboxSection.searchCreators => t.searchCreators,
    FanboxSection.searchTags || FanboxSection.tag => t.searchTags,
    FanboxSection.creatorPosts => t.posts,
    FanboxSection.creatorPlans => t.creatorPlans,
    FanboxSection.notices => t.notices,
    FanboxSection.messages => t.messages,
    FanboxSection.bookmarks => t.bookmarks,
  };
}

enum FanboxGroup {
  feed([FanboxSection.home, FanboxSection.supporting]),
  discover([FanboxSection.recommended, FanboxSection.pixiv, FanboxSection.plans, FanboxSection.searchCreators, FanboxSection.searchTags]),
  personal([FanboxSection.following, FanboxSection.bookmarks, FanboxSection.notices, FanboxSection.messages]);

  const FanboxGroup(this.sections);
  final List<FanboxSection> sections;

  /// The group that lists [section]; sections outside every list (a tag's
  /// posts, a creator's) belong with discovery.
  static FanboxGroup of(FanboxSection section) => values.where((group) => group.sections.contains(section)).firstOrNull ?? discover;
}

