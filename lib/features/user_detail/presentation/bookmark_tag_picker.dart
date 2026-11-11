import 'package:flutter/widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/logic/bookmark_tags.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:frost_ui/frost_ui.dart';

/// Whether the account's [tags] offer [filter]: "All" always, the bookmarks
/// without a tag whenever the tags are known, a named tag when it is listed.
bool bookmarkTagsOffer(List<BookmarkTag>? tags, BookmarkTagFilter filter) {
  if (filter.isAll) return true;
  if (tags == null) return false;
  return filter.isUncategorized || tags.any((tag) => tag.name == filter.name);
}

/// The bookmarks to show by tag, as a toolbar selector showing the current
/// choice: all, those without a tag, or one of the account's tags with its
/// count. Many tags do not fit a segmented control, so it is always a menu.
///
/// While the tags are unknown ([tags] is null: loading, or failed to load) it
/// offers only "All".
FrostToolbarItem bookmarkTagToolbarItem(
  BuildContext context, {
  required List<BookmarkTag>? tags,
  required BookmarkTagFilter value,
  required ValueChanged<BookmarkTagFilter> onChanged,
}) {
  final t = context.t.user.bookmarks;
  BookmarkTag? uncategorized;
  for (final tag in tags ?? const <BookmarkTag>[]) {
    if (tag.name == BookmarkTagFilter.uncategorizedApiTag) uncategorized = tag;
  }
  final shown = bookmarkTagsOffer(tags, value) ? value : const BookmarkTagFilter.all();
  final choices = <(BookmarkTagFilter, String)>[
    (const BookmarkTagFilter.all(), t.allTags),
    if (tags != null) ...[
      (const BookmarkTagFilter.uncategorized(), uncategorized == null ? t.uncategorized : t.tagCount(name: t.uncategorized, count: uncategorized.count)),
      for (final tag in tags)
        if (tag.name != BookmarkTagFilter.uncategorizedApiTag) (BookmarkTagFilter.named(tag.name), t.tagCount(name: tag.name, count: tag.count)),
    ],
  ];
  return FrostToolbarItem.menu(
    label: t.tag,
    valueLabel: choices.firstWhere((choice) => choice.$1 == shown).$2,
    entries: [for (final (filter, label) in choices) FrostMenuAction(label, checked: filter == shown, onSelected: () => onChanged(filter))],
  );
}
