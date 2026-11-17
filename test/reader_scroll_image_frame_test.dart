import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_controller.dart';
import 'package:freepiv/features/novel/presentation/reader/views/reader_scroll_view.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';
import 'package:freepiv/core/services/app_settings.dart';

const _palette = ReaderPalette(
  background: Color(0xFFFFFFFF),
  text: Color(0xFF1F1F1F),
  secondary: Color(0x991F1F1F),
  link: Color(0xFF0B5CAD),
  ruby: Color(0xBF1F1F1F),
  selection: Color(0x4D0B5CAD),
);

// Margins of 28 on a width of 656 leave a column of 600.
const _typesetting = ReaderTypesetting(
  textSize: 20,
  lineHeight: 1.8,
  body: TextStyle(fontSize: 20, height: 1.8),
  chapterTitle: TextStyle(fontSize: 26, height: 1.4),
  margins: ReaderMargins.regular,
  palette: _palette,
);

const _url = 'https://example.com/novel/1.jpg';
const _image = NovelUploadedImage(
  '1',
  WebviewNovelImage(
    novelImageId: '1',
    urls: WebviewNovelImageUrls(size128X128: _url, size240Mw: _url, size480Mw: _url, size1200X1200: _url, original: _url),
  ),
);

void main() {
  testWidgets('a picture scaled down by the height cap has a frame as wide as the picture, centred', (tester) async {
    final sizes = MemoryImageSizeStore();
    await sizes.record(_url, const Size(400, 1600));
    final model = ReaderModel([
      const NovelLine([NovelPlain('山川')]),
      _image,
      const NovelLine([NovelPlain('河海')]),
    ]);
    final layout = ReaderLayout(
      model: model,
      typesetting: _typesetting,
      width: 656,
      flow: ReaderFlow.scroll,
      sizes: sizes,
      viewportHeight: 800,
      pageJumpLabel: (page) => '$page',
    );
    addTearDown(layout.dispose);
    expect(layout.columnWidth, 600);
    // 600 wide would be 2400 tall; the cap of 0.9 x 800 = 720 leaves 180 wide.
    expect(layout.imageWidthOf(1), 180);
    expect(layout.imageWidthOf(0), 600, reason: 'text blocks keep the column');

    final controller = ReaderController(model: model, initialOffset: 0, mode: ReaderPageMode.scroll, save: (_, _, _) async {});
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 656,
            height: 800,
            child: ReaderScrollView(
              controller: controller,
              layout: layout,
              blockBuilder: (context, block, onSize) => const SizedBox.expand(key: ValueKey('frame')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final frame = tester.getRect(find.byKey(const ValueKey('frame')));
    expect(frame.width, 180);
    expect(frame.center.dx, closeTo(tester.getCenter(find.byType(ReaderScrollView)).dx, .5));
  });
}
