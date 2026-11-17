import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_sidebar.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/ui/custom/reader/reader_paragraph.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

void main() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  /// Three chapters; the second holds two uploaded pictures, the third a third.
  final body = [
    '[chapter:Departure]',
    for (var i = 0; i < 6; i++) '$readerParagraph a$i',
    '[chapter:Harbour]',
    '[uploadedimage:1]',
    for (var i = 0; i < 8; i++) '$readerParagraph b$i',
    '[uploadedimage:2]',
    '[chapter:Return]',
    for (var i = 0; i < 6; i++) '$readerParagraph c$i',
    '[uploadedimage:3]',
    '$readerParagraph end',
  ].join('\n\n');

  Future<void> mount(WidgetTester tester, {required Size size, Map<String, dynamic> settings = readerScrollSettings, String? text}) =>
      mountReader(tester, history, size: size, settings: settings, text: readerText(text ?? body));

  Future<void> key(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await settlePilot(tester, frames: 4);
  }

  Finder sidebar() => find.byType(ReaderSidebar);

  group('docked or over the text', () {
    for (final (size, docked) in [(const Size(1400, 900), true), (desktopSize, true), (const Size(900, 800), false), (phoneSize, false)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}: ${docked ? 'beside the text' : 'over the text, on the shown bars'}', (tester) async {
        await mount(tester, size: size);
        await key(tester, LogicalKeyboardKey.keyT);
        expect(sidebar(), findsOneWidget);
        expect(readerState(tester).sidebar, ReaderSidebarTab.contents);
        expect(readerState(tester).sidebarDocked, docked);
        expect(tester.getSize(sidebar()).width, readerSidebarWidth);
        expect(tester.getTopLeft(sidebar()).dx, 0);
        expect(readerState(tester).chromeVisible, !docked, reason: 'over the text, the bars stand under it');
        expectNoLayoutErrors(tester);
      });
    }

    testWidgets('docking pushes the column over without changing its width or laying the text out again', (tester) async {
      await mount(tester, size: const Size(1400, 900));
      final layout = readerState(tester).layout!;
      final paragraph = find.byType(ReaderParagraph).first;
      final before = tester.getTopLeft(paragraph);
      final width = tester.getSize(paragraph).width;

      await key(tester, LogicalKeyboardKey.keyT);
      expect(readerState(tester).sidebarDocked, isTrue);
      expect(identical(readerState(tester).layout, layout), isTrue, reason: 'the same layout, not a new one');
      expect(readerState(tester).layout!.columnWidth, layout.columnWidth);
      expect(tester.getSize(paragraph).width, width);
      expect(tester.getTopLeft(paragraph).dx - before.dx, closeTo(readerSidebarWidth / 2, .5), reason: 'the column is centred in what is left');
      expect(tester.getTopLeft(paragraph).dy, before.dy);

      await key(tester, LogicalKeyboardKey.keyT);
      expect(sidebar(), findsNothing);
      expect(tester.getTopLeft(paragraph), before);
      expect(tester.getSize(paragraph).width, width);
    });

    testWidgets('paged: docked only where the pages keep their columns, else over the text', (tester) async {
      // One wide page with room to spare.
      await mount(tester, size: const Size(1100, 1200), settings: readerPagedSettings);
      final column = readerState(tester).layout!.columnWidth;
      await key(tester, LogicalKeyboardKey.keyT);
      expect(readerState(tester).sidebarDocked, isTrue);
      expect(readerState(tester).layout!.columnWidth, column);
      expectNoLayoutErrors(tester);

      // A spread would be narrowed by it: the sidebar lies over the pages.
      await mount(tester, size: const Size(1400, 900), settings: readerPagedSettings);
      final spread = readerState(tester).layout!.columnWidth;
      await key(tester, LogicalKeyboardKey.keyT);
      expect(readerState(tester).sidebarDocked, isFalse);
      expect(readerState(tester).layout!.columnWidth, spread);
    });

    testWidgets('the T key toggles it, Escape and the close button close it, the bars first stay', (tester) async {
      await mount(tester, size: const Size(900, 800));
      await key(tester, LogicalKeyboardKey.keyT);
      expect(sidebar(), findsOneWidget);
      await key(tester, LogicalKeyboardKey.escape);
      expect(sidebar(), findsNothing);
      expect(readerState(tester).chromeVisible, isTrue, reason: 'the first Escape closes the panel only');
      await key(tester, LogicalKeyboardKey.escape);
      expect(readerState(tester).chromeVisible, isFalse);

      await key(tester, LogicalKeyboardKey.keyT);
      await tester.tap(find.byKey(const ValueKey('reader-sidebar-close')));
      await settlePilot(tester);
      expect(sidebar(), findsNothing);

      await key(tester, LogicalKeyboardKey.keyT);
      await tester.tapAt(const Offset(880, 400));
      await settlePilot(tester);
      expect(sidebar(), findsNothing, reason: 'a tap beside the panel hides the bars and takes it with them');
      expect(readerState(tester).chromeVisible, isFalse);
    });

    testWidgets('the bottom panel opens the contents and the illustrations, the latter only when there are some', (tester) async {
      await mount(tester, size: desktopSize);
      await showReaderBars(tester);
      await tester.tap(find.byKey(const ValueKey('reader-illustrations')));
      await settlePilot(tester);
      expect(readerState(tester).sidebar, ReaderSidebarTab.illustrations);
      await tester.tap(find.byKey(const ValueKey('reader-contents')));
      await settlePilot(tester);
      expect(readerState(tester).sidebar, ReaderSidebarTab.contents);

      await mount(tester, size: desktopSize, text: readerChapters());
      await showReaderBars(tester);
      expect(find.byKey(const ValueKey('reader-illustrations')), findsNothing);
      expect(find.byKey(const ValueKey('reader-contents')), findsOneWidget);
    });
  });

  group('contents', () {
    testWidgets('a row for each chapter; tapping one goes there, and the sidebar stays when docked', (tester) async {
      await mount(tester, size: const Size(1400, 900));
      await key(tester, LogicalKeyboardKey.keyT);
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('reader-chapter-$i')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('reader-chapter-2')));
      await settlePilot(tester);
      expect(readerController(tester).chapter.index, 2);
      expect(sidebar(), findsOneWidget);
      expect(tester.widget<FrostListRow>(find.byKey(const ValueKey('reader-chapter-2'))).selected, isTrue, reason: 'the chapter being read is marked');
      expect(tester.widget<FrostListRow>(find.byKey(const ValueKey('reader-chapter-0'))).selected, isFalse);
    });

    testWidgets('over the text, going to a chapter closes the sidebar and the bars', (tester) async {
      await mount(tester, size: phoneSize);
      await key(tester, LogicalKeyboardKey.keyT);
      await tester.tap(find.byKey(const ValueKey('reader-chapter-1')));
      await settlePilot(tester);
      expect(readerController(tester).chapter.index, 1);
      expect(sidebar(), findsNothing);
      expect(readerState(tester).chromeVisible, isFalse);
    });

    testWidgets('each chapter shows its progress: nothing before, part of the current, all of the read ones', (tester) async {
      await mount(tester, size: const Size(1400, 900));
      final controller = readerController(tester);
      controller.goToChapter(1);
      await settlePilot(tester);
      // Half way through the second chapter.
      final chapter = controller.model.chapters[1];
      controller.goToOffset((chapter.startOffset + chapter.endOffset) ~/ 2);
      await settlePilot(tester);
      await key(tester, LogicalKeyboardKey.keyT);
      double value(int index) =>
          tester.widget<FrostProgressBar>(find.descendant(of: find.byKey(ValueKey('reader-chapter-$index')), matching: find.byType(FrostProgressBar))).value;
      expect(value(0), 1);
      expect(value(1), closeTo(.5, .05));
      expect(value(2), 0);
      controller.goToOffset(chapter.endOffset - 1);
      await settlePilot(tester);
      expect(value(1), closeTo(1, .05), reason: 'it follows the reading position');
    });

    testWidgets('opening it brings the current chapter into view', (tester) async {
      final chapters = [for (var i = 0; i < 40; i++) '[chapter:Chapter $i]\n\n$readerParagraph $i'].join('\n\n');
      await mount(tester, size: const Size(1400, 900), text: chapters);
      readerController(tester).goToChapter(30);
      await settlePilot(tester);
      await key(tester, LogicalKeyboardKey.keyT);
      final row = find.byKey(const ValueKey('reader-chapter-30'));
      expect(row, findsOneWidget);
      final rect = tester.getRect(row);
      expect(rect.top, greaterThanOrEqualTo(tester.getTopLeft(find.byKey(const ValueKey('reader-contents-list'))).dy));
      expect(rect.bottom, lessThanOrEqualTo(900));
    });
  });

  group('illustrations', () {
    testWidgets('a thumbnail for each picture in text order; a tap goes to it and a double tap opens the viewer on it', (tester) async {
      await mount(tester, size: const Size(1400, 900));
      await showReaderBars(tester);
      await tester.tap(find.byKey(const ValueKey('reader-illustrations')));
      await settlePilot(tester);
      final controller = readerController(tester);
      final blocks = controller.model.imageBlocks;
      expect(blocks.length, 3);
      for (final block in blocks) {
        expect(find.byKey(ValueKey('reader-illustration-$block')), findsOneWidget);
      }
      final first = tester.getTopLeft(find.byKey(ValueKey('reader-illustration-${blocks[0]}')));
      final second = tester.getTopLeft(find.byKey(ValueKey('reader-illustration-${blocks[1]}')));
      expect(second.dy > first.dy || second.dx > first.dx, isTrue, reason: 'in the order of the text');

      await tester.tap(find.byKey(ValueKey('reader-illustration-${blocks[1]}')));
      await settlePilot(tester);
      expect(controller.offset, controller.model.offsetOf(blocks[1]));
      expect(sidebar(), findsOneWidget, reason: 'docked: it stays');

      final target = find.byKey(ValueKey('reader-illustration-${blocks[2]}'));
      openedLocations.clear();
      openedExtras.clear();
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(target);
      await settlePilot(tester);
      final args = openedExtras.whereType<OriginalImageViewerArgs>().single;
      expect(args.pages.length, 3, reason: 'every uploaded picture is a page');
      expect(args.initialIndex, 2);
      expect(controller.offset, isNot(controller.model.offsetOf(blocks[2])), reason: 'a double tap opens and does not also go there');
    });

    testWidgets('the open button on a thumbnail opens the viewer at that picture', (tester) async {
      await mount(tester, size: const Size(1400, 900));
      await showReaderBars(tester);
      await tester.tap(find.byKey(const ValueKey('reader-illustrations')));
      await settlePilot(tester);
      final blocks = readerController(tester).model.imageBlocks;
      openedExtras.clear();
      await tester.tap(find.byKey(ValueKey('reader-illustration-open-${blocks[1]}')));
      await settlePilot(tester);
      expect(openedExtras.whereType<OriginalImageViewerArgs>().single.initialIndex, 1);
    });

    testWidgets('an embedded work is a thumbnail too, and opens its own page', (tester) async {
      final text = readerText(
        '$readerParagraph\n\n[pixivimage:9001]\n\n[uploadedimage:1]\n\n$readerParagraph',
        works: [
          const WebviewNovelEmbeddedWork(key: '9001', illustId: 9001, page: 1, visible: true, title: 'A work', xRestrict: 0, userId: '1', userName: 'Someone'),
        ],
      );
      await mountReader(tester, history, size: const Size(1400, 900), text: text);
      await showReaderBars(tester);
      await tester.tap(find.byKey(const ValueKey('reader-illustrations')));
      await settlePilot(tester);
      final blocks = readerController(tester).model.imageBlocks;
      expect(blocks.length, 2);
      openedLocations.clear();
      await tester.tap(find.byKey(ValueKey('reader-illustration-open-${blocks[0]}')));
      await settlePilot(tester);
      expect(openedLocations.last, '/illust/9001');
    });

    testWidgets('a thumbnail is the shape of its picture', (tester) async {
      await mount(tester, size: const Size(1400, 900));
      await showReaderBars(tester);
      await tester.tap(find.byKey(const ValueKey('reader-illustrations')));
      await settlePilot(tester);
      final blocks = readerController(tester).model.imageBlocks;
      final sizes = [for (final block in blocks) tester.getSize(find.byKey(ValueKey('reader-illustration-$block')))];
      for (final size in sizes) {
        expect(size.width / size.height, closeTo(novelImageFallbackSize.width / novelImageFallbackSize.height, .02), reason: 'no size is known yet');
      }
    });
  });
}
