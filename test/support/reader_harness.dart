import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/route_activity.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/dev/sample_images.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/novel_download_source.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reader_page.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_controller.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

import 'pilot_harness.dart';

const readerParagraph =
    'The boats came back late that evening, and the town waited on the pier as it always did, '
    'lanterns swinging in the wind, until the last sail turned the point and the harbour lights came on one by one.';

/// Three chapters of a dozen paragraphs each.
String readerChapters({List<String> titles = const ['Departure', 'Harbour', 'Return']}) => [
  for (final (index, name) in titles.indexed)
    ['[chapter:$name]', for (var line = 0; line < 12; line++) '$readerParagraph ${index + 1}.${line + 1}'].join('\n\n'),
].join('\n\n');

const readerScrollSettings = <String, dynamic>{'readerFontSize': 18.0, 'readerLineSpacing': 'regular', 'readerAutoScrollStep': 'fast'};
const readerPagedSettings = <String, dynamic>{...readerScrollSettings, 'readerPageMode': 'paged', 'readerPageAnimation': 'slide'};

/// The address of a generated picture; the pilot harness draws it.
String readerImageUrl(int seed, {int width = 600, int height = 800}) => sampleImageUrl(seed, width: width, height: height);

/// Five uploaded pictures of different shapes.
List<WebviewNovelImage> readerImages() => [
  for (final (index, (width, height)) in const [(1200, 675), (900, 900), (800, 1200), (1400, 560), (600, 1500)].indexed)
    WebviewNovelImage(
      novelImageId: '${index + 1}',
      urls: WebviewNovelImageUrls(
        size240Mw: readerImageUrl(200 + index, width: 240, height: (240 * height / width).round()),
        size480Mw: readerImageUrl(200 + index, width: 480, height: (480 * height / width).round()),
        size1200X1200: readerImageUrl(200 + index, width: 1200, height: (1200 * height / width).round()),
        original: readerImageUrl(200 + index, width: width, height: height),
      ),
    ),
];

WebviewNovel readerText(
  String body, {
  String? language,
  String? seriesId,
  String? seriesTitle,
  bool? seriesIsWatched,
  NovelNavigationInfo? seriesNavigation,
  List<WebviewNovelEmbeddedWork>? works,
  List<WebviewNovelImage>? images,
}) {
  final sample = sampleNovelText(70000);
  return WebviewNovel(
    id: sample.id,
    title: sample.title,
    seriesId: seriesId,
    seriesTitle: seriesTitle,
    seriesIsWatched: seriesIsWatched,
    userId: sample.userId,
    coverUrl: sample.coverUrl,
    tags: sample.tags,
    caption: sample.caption,
    cdate: sample.cdate,
    rating: sample.rating,
    text: body,
    illusts: works ?? const [],
    images: images ?? readerImages(),
    seriesNavigation: seriesNavigation,
    glossaryItems: const [],
    replaceableItemIds: const [],
    aiType: 0,
    isOriginal: true,
    language: language,
  );
}

Future<void> readerStorageIdle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
}

/// Mounts the reader on [text] with the reading history [history].
Future<void> mountReader(
  WidgetTester tester,
  HistoryRepository history, {
  WebviewNovel? text,
  Map<String, dynamic> settings = readerScrollSettings,
  Size size = desktopSize,
  double textScale = 1,
  String title = 'A novel',
  Map<Object, Override> overrides = const {},
}) async {
  await readerStorageIdle(tester);
  final novel = sampleNovels(count: 1, title: title).single;
  await mountPilotPage(
    tester,
    DownloadSourceScope(
      source: novelDownloadSource(novel),
      child: NovelReaderContent(
        detail: NovelDetailData(novel: novel, webviewNovel: text ?? readerText(readerChapters())),
      ),
    ),
    size: size,
    textScale: textScale,
    settings: {...sampleSettings, ...settings},
    observers: [appRootRouteActivity],
    history: history,
    overrides: overrides,
  );
  await readerStorageIdle(tester);
  await settlePilot(tester);
}

NovelReaderContentState readerState(WidgetTester tester) => tester.state<NovelReaderContentState>(find.byType(NovelReaderContent));

ReaderController readerController(WidgetTester tester) => readerState(tester).controller!;

/// Shows the bars the way a tap in the middle does.
Future<void> showReaderBars(WidgetTester tester) async {
  readerState(tester).chrome.show();
  await settlePilot(tester);
}
