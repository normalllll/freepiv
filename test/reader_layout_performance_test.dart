import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/image_size_store.dart';
import 'package:freepiv/dev/sample_novel_text.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/features/novel/domain/reader_model.dart';
import 'package:freepiv/ui/custom/reader/reader_layout.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';

const _palette = ReaderPalette(
  background: Color(0xFFFFFFFF),
  text: Color(0xFF1F1F1F),
  secondary: Color(0x991F1F1F),
  link: Color(0xFF0B5CAD),
  ruby: Color(0xBF1F1F1F),
  selection: Color(0x4D0B5CAD),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a long novel lays out its anchor chapter and one screen quickly', () {
    final model = ReaderModel(parseNovelText(sampleLongNovelText()));
    expect(model.totalLength, greaterThan(250000));
    const viewport = 900.0;
    const typesetting = ReaderTypesetting(
      textSize: 18,
      lineHeight: 1.8,
      body: TextStyle(fontSize: 18, height: 1.8, color: Color(0xFF1F1F1F)),
      chapterTitle: TextStyle(fontSize: 18 * 1.3, fontWeight: FontWeight.w600, height: 1.4, color: Color(0xFF1F1F1F)),
      palette: _palette,
    );
    final chapter = model.chapters[model.chapters.length ~/ 2];
    final end = model.chapters[chapter.index + 1].firstBlock;

    final watch = Stopwatch()..start();
    final layout = ReaderLayout(
      model: model,
      typesetting: typesetting,
      width: 720,
      flow: ReaderFlow.scroll,
      sizes: MemoryImageSizeStore(),
      viewportHeight: viewport,
      pageJumpLabel: (page) => 'Go to section $page',
    );
    for (var block = chapter.firstBlock; block < end; block++) {
      layout.metricsOf(block);
    }
    final screenEnd = layout.topOf(end) + viewport;
    for (var block = end; block < layout.blockCount && layout.topOf(block) < screenEnd; block++) {
      layout.metricsOf(block);
    }
    watch.stop();

    // A guard against order-of-magnitude regressions only; loose enough for a
    // busy machine.
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });
}
