import 'package:flutter/widgets.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/novel/domain/reading_time.dart';
import 'package:freepiv/features/novel/logic/novel_structure.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/skeletons.dart' show appBones;
import 'package:frost_ui/frost_ui.dart';

/// "About 12 min read", in hours from an hour on.
String novelReadingTimeLabel(BuildContext context, int minutes) {
  final t = context.t.novelDetail;
  if (minutes < 60) return t.readingTime(minutes: minutes);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? t.readingTimeWholeHours(hours: hours) : t.readingTimeHours(hours: hours, minutes: rest);
}

/// The novel's facts as key–value rows: its length with the time it takes, its
/// structure, date and reception. Every row but the date is there from what the
/// novel itself says, so none comes or goes when the text loads; the chapter
/// count joins the structure row then.
class NovelFacts extends StatelessWidget {
  const NovelFacts({required this.novel, required this.structure, this.loading = false, super.key});

  final Novel novel;

  /// Null until the text has loaded.
  final NovelStructure? structure;

  /// Whether the text is loading: the facts are there as bones, with the
  /// chapter count of the structure row among them, so the text's arrival
  /// moves nothing below. A text that failed leaves the count out.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final structure = this.structure;
    // The reader's own count once the text has loaded; Pixiv's until then.
    final minutes = readingMinutes(structure?.totalLength ?? novel.textLength, language: structure?.language);
    final published = formatPixivDate(novel.createDate);
    final chapters = structure?.chapters ?? 0;
    final list = FrostKeyValueList(
      entries: [
        FrostKeyValue(
          label: t.novelDetail.factLength,
          value: [t.novel.detail.totalChars(count: formatCount(novel.textLength)), if (minutes > 0) novelReadingTimeLabel(context, minutes)].join(' · '),
        ),
        FrostKeyValue(
          label: t.novelDetail.factStructure,
          value: [if (loading || chapters > 0) t.novelDetail.chapterCount(count: chapters), t.novelDetail.sectionCount(count: novel.pageCount)].join(' · '),
        ),
        if (published.isNotEmpty) FrostKeyValue(label: t.novelDetail.factPublished, value: published),
        FrostKeyValue(
          label: t.novelDetail.factReception,
          value: '${t.novelDetail.bookmarks(count: formatCount(novel.totalBookmarks))} · ${t.novelDetail.views(count: formatCount(novel.totalView))}',
        ),
      ],
    );
    return loading ? appBones(list) : list;
  }
}
