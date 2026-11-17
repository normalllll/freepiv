import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/dev/sample_images.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_paged_view.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

/// A picture that arrives when [gate] completes.
class _Gated extends ImageProvider<_Gated> {
  _Gated(this.image, this.gate, this.id);

  final ui.Image image;
  final Future<void> gate;
  final String id;

  @override
  Future<_Gated> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Gated key, ImageDecoderCallback decode) => OneFrameImageStreamCompleter(gate.then((_) => ImageInfo(image: image)));

  @override
  bool operator ==(Object other) => other is _Gated && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The page number in the footer is the page on show, also while pictures
/// arriving change the pages.
void main() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  ReaderPagedViewState view(WidgetTester tester) => tester.state<ReaderPagedViewState>(find.byType(ReaderPagedView));

  /// The number the footer shows.
  int footerPage(WidgetTester tester) {
    final label = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
        .firstWhere((text) => RegExp(r'^\d+ / \d+').hasMatch(text));
    return int.parse(label.split(' ').first);
  }

  /// The page on show, 1-based, in the pages as they are now.
  int shownPage(WidgetTester tester) {
    final state = view(tester);
    final paginator = state.widget.paginator;
    final first = state.visiblePages.first;
    final chapter = paginator.pageAt(first.startOffset).chapter;
    return paginator.pagesOfChapter(chapter).indexWhere((page) => page.startOffset == first.startOffset) + 1;
  }

  String body() => [
    for (var i = 0; i < 6; i++) ...[for (var line = 0; line < 4; line++) '$readerParagraph $i.$line', '[uploadedimage:${i % 5 + 1}]'],
  ].join('\n\n');

  for (final size in [const Size(390, 800), const Size(750, 900)]) {
    testWidgets('the footer names the page on show through turns forward and back, at ${size.width}', (tester) async {
      await mountReader(tester, history, text: readerText(body()), settings: readerPagedSettings, size: size);
      expect(footerPage(tester), shownPage(tester));
      for (var i = 0; i < 8; i++) {
        view(tester).turn(1);
        await settlePilot(tester);
        expect(footerPage(tester), shownPage(tester), reason: 'forward $i');
      }
      for (var i = 0; i < 5; i++) {
        view(tester).turn(-1);
        await settlePilot(tester);
        expect(footerPage(tester), shownPage(tester), reason: 'back $i');
      }
    });
  }
  testWidgets('the footer names the page on show when pictures arrive late and the pages change', (tester) async {
    const size = Size(390, 800);
    final gate = Completer<void>();
    // Pictures much wider than the default frame, so the pages change when they arrive.
    final wide = (await tester.runAsync(() => createTestImage(width: 400, height: 100)))!;
    final restore = pixivImageOverride;
    pixivImageOverride = (url) => url.startsWith(sampleImageScheme) && !url.contains(':240x') ? _Gated(wide, gate.future, url) : sampleImageProvider(url);
    addTearDown(() => pixivImageOverride = restore);

    await mountReader(tester, history, text: readerText(body()), settings: readerPagedSettings, size: size);
    for (var i = 0; i < 3; i++) {
      view(tester).turn(1);
      await settlePilot(tester);
    }
    final before = view(tester).visiblePages.first.startOffset;
    gate.complete();
    await settlePilot(tester);
    await settlePilot(tester);
    expect(footerPage(tester), shownPage(tester), reason: 'the footer follows the pages after they changed');
    final page = view(tester).visiblePages;
    expect(
      page.first.startOffset <= before && (page.last.endOffset > before || page.last.startOffset == before),
      isTrue,
      reason: 'the page on show holds the reading position',
    );
  });
}
