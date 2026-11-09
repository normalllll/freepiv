import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/illust/presentation/artwork_actions.dart';
import 'package:freepiv/features/illust/presentation/illust_stage.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/media.dart';

import 'support/pilot_harness.dart';

Future<FrostPagerController> _mount(WidgetTester tester, int count) async {
  final illust = sampleIllusts(count: 1).single;
  final page = artworkPages(illust, ViewerImageQuality.values.first, PreviewImageQuality.values.first).first;
  final pager = FrostPagerController();
  addTearDown(pager.dispose);
  var current = 0;
  await mountPilotPage(
    tester,
    StatefulBuilder(
      builder: (context, setState) => IllustStage(
        illust: illust,
        pages: List.filled(count, page),
        pager: pager,
        page: current,
        onPageChanged: (value) => setState(() => current = value),
        onOpenViewer: (_) {},
      ),
    ),
  );
  return pager;
}

FrostSlider _slider(WidgetTester tester) => tester.widget<FrostSlider>(find.byKey(const ValueKey('illust-page-jump')));

void main() {
  testWidgets('up to ten pages keep the dots', (tester) async {
    await _mount(tester, 10);
    expect(find.byType(FrostPageIndicator), findsOneWidget);
    expect(find.byType(FrostBadge), findsNothing);
  });

  testWidgets('a long work counts its pages in a badge instead', (tester) async {
    await _mount(tester, 135);
    expect(find.byType(FrostPageIndicator), findsNothing);
    expect(find.text('1 / 135'), findsOneWidget);
  });

  testWidgets('dragging only changes the number; the page turns once, on release', (tester) async {
    final pager = await _mount(tester, 135);
    await tester.tap(find.text('1 / 135'));
    await settlePilot(tester);

    _slider(tester).onChanged!(49);
    await settlePilot(tester, frames: 2);
    _slider(tester).onChanged!(99);
    await settlePilot(tester, frames: 2);
    final slider = _slider(tester);
    expect(slider.valueLabel!(slider.value), '100 / 135', reason: 'the number follows the drag');
    expect(pager.page, 0, reason: 'no page turns during a drag');

    _slider(tester).onChangeEnd!(99);
    await settlePilot(tester);
    expect(pager.page, 99);
  });

  for (final count in [5, 135]) {
    testWidgets('swiping still turns the page with $count pages', (tester) async {
      final pager = await _mount(tester, count);
      await tester.drag(find.byType(FrostPager), const Offset(-700, 0));
      await settlePilot(tester);
      expect(pager.page, 1);
    });
  }
}
