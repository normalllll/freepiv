import 'package:flutter/material.dart';
import 'package:freepiv/features/newest/logic/newest_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';

int newestAudienceIndex(NewestAudience audience) {
  return NewestAudience.values.indexOf(audience);
}

NewestAudience newestAudienceForIndex(int index) {
  final values = NewestAudience.values;
  if (index <= 0) {
    return values.first;
  }
  if (index >= values.length - 1) {
    return values.last;
  }
  return values[index];
}

List<NewestFeedKey> newestFeedKeysForAudience(NewestAudience audience) {
  return [
    for (final key in newestFeedKeys)
      if (key.audience == audience) key,
  ];
}

NewestWorkType selectedNewestWorkType(NewestState state, NewestAudience audience) {
  final workType = switch (audience) {
    NewestAudience.following => state.followingWorkType,
    NewestAudience.mypixiv => state.mypixivWorkType,
    NewestAudience.everyone => state.everyoneWorkType,
  };
  return normalizeNewestWorkType(audience, workType);
}

String newestWorkTypeLabel(NewestWorkType workType, Translations translations) {
  return switch (workType) {
    NewestWorkType.illustManga => translations.newest.workType.illustManga,
    NewestWorkType.illust => translations.newest.workType.illust,
    NewestWorkType.manga => translations.newest.workType.manga,
    NewestWorkType.novel => translations.newest.workType.novel,
  };
}

String newestWorkTypeCompactLabel(NewestWorkType workType, Translations translations) {
  return switch (workType) {
    NewestWorkType.illustManga => translations.newest.workType.compactArt,
    NewestWorkType.illust => translations.newest.workType.compactIllust,
    NewestWorkType.manga => translations.newest.workType.compactManga,
    NewestWorkType.novel => translations.newest.workType.compactNovel,
  };
}

IconData newestWorkTypeIcon(NewestWorkType workType) {
  return switch (workType) {
    NewestWorkType.illustManga => Icons.collections_outlined,
    NewestWorkType.illust => Icons.image_outlined,
    NewestWorkType.manga => Icons.auto_stories_outlined,
    NewestWorkType.novel => Icons.menu_book_outlined,
  };
}

String newestFollowScopeLabel(NewestFollowScope scope, Translations translations) {
  return switch (scope) {
    NewestFollowScope.all => translations.newest.followScope.all,
    NewestFollowScope.private => translations.newest.followScope.private,
    NewestFollowScope.public => translations.newest.followScope.public,
  };
}

String newestFollowScopeCompactLabel(NewestFollowScope scope, Translations translations) {
  return switch (scope) {
    NewestFollowScope.all => translations.newest.followScope.compactAll,
    NewestFollowScope.private => translations.newest.followScope.compactPrivate,
    NewestFollowScope.public => translations.newest.followScope.compactPublic,
  };
}
