import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

void main() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  WebviewNovelEmbeddedWork work({
    String key = '9001',
    int id = 9001,
    int page = 1,
    bool visible = true,
    String? message,
    String title = 'Lanterns on the pier',
    int xRestrict = 0,
    String author = 'Sample author',
  }) => WebviewNovelEmbeddedWork(
    key: key,
    illustId: id,
    page: page,
    visible: visible,
    availableMessage: message,
    title: title,
    xRestrict: xRestrict,
    userId: '2000',
    userName: author,
    imageMedium: readerImageUrl(210, width: 540, height: 756),
    imageOriginal: readerImageUrl(210, width: 1000, height: 1400),
  );

  Future<void> mount(WidgetTester tester, String marker, List<WebviewNovelEmbeddedWork> works, {Size size = desktopSize}) => mountReader(
    tester,
    history,
    text: readerText('$readerParagraph\n\n$marker\n\n$readerParagraph', works: works),
    size: size,
  );

  Finder card() => find.byKey(const ValueKey('reader-work-card'));

  testWidgets('a visible work: the thumbnail, title and author in the height the layout reserves; a tap opens the work', (tester) async {
    await mount(tester, '[pixivimage:9001]', [work()]);
    expect(card(), findsOneWidget);
    expect(tester.getSize(card()).height, readerState(tester).layout!.typesetting.embeddedWorkExtent);
    expect(find.descendant(of: card(), matching: find.text('Lanterns on the pier')), findsOneWidget);
    expect(find.descendant(of: card(), matching: find.text('Sample author')), findsOneWidget);
    expect(
      find.descendant(of: card(), matching: find.textContaining('Page')),
      findsNothing,
      reason: 'the first page needs no number',
    );
    expect(find.descendant(of: card(), matching: find.text('R-18')), findsNothing);
    expect(find.text(t.novel.reader.workUnavailable), findsNothing);

    await tester.tap(card());
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.illust(9001));
    expectNoLayoutErrors(tester);
  });

  testWidgets('a later page of a work is named, and R-18 and R-18G are badges on the card, never hidden or blurred', (tester) async {
    await mount(tester, '[pixivimage:9001-2]', [work(key: '9001-2', page: 2, xRestrict: 1)]);
    expect(find.descendant(of: card(), matching: find.text('${t.novel.reader.workPage(page: 2)} · Sample author')), findsOneWidget);
    expect(find.descendant(of: card(), matching: find.text('R-18')), findsOneWidget);
    expect(find.descendant(of: card(), matching: find.byType(BackdropFilter)), findsNothing);
    expect(
      find.descendant(
        of: card(),
        matching: find.byWidgetPredicate((widget) => widget is ImageFiltered && widget.imageFilter != ImageFilter.matrix(Matrix4.identity().storage)),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: card(), matching: find.text('Lanterns on the pier')),
      findsOneWidget,
      reason: 'the title is shown as it is',
    );

    await mount(tester, '[pixivimage:9001]', [work(xRestrict: 2)]);
    expect(find.descendant(of: card(), matching: find.text('R-18G')), findsOneWidget);
  });

  testWidgets('a work the viewer may not see is greyed with its message and goes nowhere', (tester) async {
    await mount(tester, '[pixivimage:9002-2]', [
      work(key: '9002-2', id: 9002, page: 2, visible: false, message: 'This work is private.', title: '', author: ''),
    ]);
    expect(find.descendant(of: card(), matching: find.text('This work is private.')), findsOneWidget);
    expect(
      find.descendant(of: card(), matching: find.byType(FrostClickSurface)),
      findsNothing,
      reason: 'no navigation',
    );
    expect(tester.widget<Opacity>(find.descendant(of: card(), matching: find.byType(Opacity)).first).opacity, lessThan(1));
    openedLocations.clear();
    await tester.tap(card());
    await settlePilot(tester);
    expect(openedLocations, isEmpty);

    await mount(tester, '[pixivimage:9002]', [work(key: '9002', id: 9002, visible: false)]);
    expect(find.descendant(of: card(), matching: find.text(t.novel.reader.workHidden)), findsOneWidget);
  });

  testWidgets('a work with no data in the novel says it is unavailable', (tester) async {
    await mount(tester, '[pixivimage:12345]', const []);
    expect(find.descendant(of: card(), matching: find.text(t.novel.reader.workUnavailable)), findsOneWidget);
    openedLocations.clear();
    await tester.tap(card());
    await settlePilot(tester);
    expect(openedLocations, isEmpty, reason: 'nothing to open');
    expect(find.descendant(of: card(), matching: find.byType(FrostClickSurface)), findsNothing);
  });

  testWidgets('the card fits a phone at double text size', (tester) async {
    await mountReader(
      tester,
      history,
      text: readerText(
        '$readerParagraph\n\n[pixivimage:9001]\n\n$readerParagraph',
        works: [work(xRestrict: 1, title: 'A very long title of a work that cannot fit one line of the card')],
      ),
      size: phoneSize,
      textScale: 2,
    );
    expectNoLayoutErrors(tester);
  });
}
