import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

class _Novels extends HomeNovelListSource {
  _Novels(this.first);

  final Future<NovelPageResult> Function() first;

  @override
  Future<NovelPageResult> loadFirstPage() => first();

  @override
  Future<NovelPageResult> loadNextPage(String nextUrl) async => const NovelPageResult(novels: [], rankingNovels: []);
}

Future<void> _mount(WidgetTester tester, Future<NovelPageResult> Function() first, Size size) {
  final source = _Novels(first);
  addTearDown(source.dispose);
  return mountPilotPage(
    tester,
    FrostLoadingScrollView(slivers: [AppSliverNovelGrid(source: source)]),
    size: size,
  );
}

Future<NovelPageResult> _sample() async => NovelPageResult(novels: sampleNovels(count: 12), rankingNovels: const []);

int _columns(WidgetTester tester) =>
    {for (final element in find.byType(AppNovelCard).evaluate()) (element.renderObject! as RenderBox).localToGlobal(Offset.zero).dx}.length;

void main() {
  for (final (size, columns) in [(phoneSize, 1), (desktopSize, 2), (const Size(1800, 1000), 3), (const Size(3000, 1000), 3)]) {
    testWidgets('$columns novel columns at $size, loaded and as a skeleton', (tester) async {
      final answer = Completer<NovelPageResult>();
      await _mount(tester, () => answer.future, size);
      expect(_columns(tester), columns, reason: 'skeleton');
      expect(tester.getSize(find.byType(AppNovelCardsSkeleton)).height, greaterThan(size.height), reason: 'runs past the window');
      final first = tester.getTopLeft(find.byType(AppNovelCard).first);
      final width = tester.getSize(find.byType(AppNovelCard).first).width;

      answer.complete(await _sample());
      await settlePilot(tester);
      expect(find.byType(AppNovelCardsSkeleton), findsNothing);
      expect(_columns(tester), columns, reason: 'loaded');
      expect(tester.getTopLeft(find.byType(AppNovelCard).first), first);
      expect(tester.getSize(find.byType(AppNovelCard).first).width, width);
      expectNoLayoutErrors(tester);
    });
  }

  testWidgets('a card is a module surface with a rounded press, showing what the row shows', (tester) async {
    await _mount(tester, _sample, desktopSize);
    final card = find.byType(AppNovelCard).first;
    final surface = tester.widget<FrostSurface>(find.descendant(of: card, matching: find.byType(FrostSurface)).first);
    expect(surface.role, FrostSurfaceRole.module);
    expect(find.descendant(of: card, matching: find.text(sampleNovels(count: 12).first.title)), findsOneWidget);
    expect(find.descendant(of: card, matching: find.byType(FrostTag)), findsWidgets);
    expect(find.byType(AppNovelRow), findsNothing);
  });
}
