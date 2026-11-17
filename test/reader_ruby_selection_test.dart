import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/ui/custom/reader/reader_line_text.dart';
import 'package:freepiv/ui/custom/reader/reader_text.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';

import 'support/frost_test_app.dart';

const _ink = Color(0xFFB9BEC6);
const _palette = ReaderPalette(
  background: Color(0xFF1C1F24),
  text: _ink,
  secondary: Color(0x99B9BEC6),
  link: Color(0xFF7FB2E5),
  ruby: Color(0xFFB9BEC6),
  selection: Color(0x4D7FB2E5),
);

void main() {
  final typesetting = ReaderTypesetting(
    textSize: 18,
    lineHeight: 1.8,
    body: const TextStyle(fontSize: 18, height: 1.8, color: _ink),
    chapterTitle: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600, height: 1.4, color: _ink),
    palette: _palette,
  );

  /// The pixels of the paragraph as drawn inside a selection area.
  Future<List<int>> pixels(WidgetTester tester, String reading) async {
    final text = ReaderLineText.line(
      NovelLine([const NovelPlain('傍晚，'), NovelRuby('提着灯', reading), const NovelPlain('站在码头边。')]),
      typesetting,
      pageJumpLabel: (page) => 'Go to $page',
    );
    final boundary = GlobalKey();
    await tester.pumpWidget(
      frostTestApp(
        brightness: Brightness.dark,
        home: ReaderSelectableText(
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: boundary,
              child: SizedBox(
                width: 400,
                height: 80,
                child: ReaderParagraph(text: text, typesetting: typesetting),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final render = tester.renderObject<RenderRepaintBoundary>(find.byKey(boundary));
    return (await tester.runAsync(() async {
      final image = await render.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!.buffer.asUint8List().toList();
    }))!;
  }

  testWidgets('readings are painted when the paragraph lies in a selection area', (tester) async {
    // The strut is the same with or without a reading, so only the reading differs.
    final without = await pixels(tester, '');
    final withReading = await pixels(tester, 'tí zhe dēng');
    expect(withReading.length, without.length);
    var differing = 0;
    for (var i = 0; i < withReading.length; i++) {
      if (withReading[i] != without[i]) differing++;
    }
    expect(differing, greaterThan(50), reason: 'the reading draws pixels above its base');
  });
}
