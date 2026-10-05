import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_ui/frost_ui.dart';

Widget _scrollBody(String label) => CustomScrollView(
  key: ValueKey(label),
  slivers: [SliverList.builder(itemCount: 40, itemBuilder: (context, index) => SizedBox(height: 40, child: Text('$label $index')))],
);

void main() {
  testWidgets('first phase shows immediately and a change cross-fades without sharing the scroll controller', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var phase = FrostLoadPhase.loading;
    late StateSetter setPhase;
    await tester.pumpWidget(
      MaterialApp(
        home: PrimaryScrollController(
          controller: controller,
          automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
          child: StatefulBuilder(
            builder: (context, setState) {
              setPhase = setState;
              return FrostLoadStateSwitcher(phase: phase, child: _scrollBody(phase.name));
            },
          ),
        ),
      ),
    );
    // Cached content on a revisit must not fade in.
    expect(tester.widget<FadeTransition>(find.ancestor(of: find.text('loading 0'), matching: find.byType(FadeTransition)).first).opacity.value, 1);

    setPhase(() => phase = FrostLoadPhase.content);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Mid-fade the outgoing phase is only a painted frame: one live tree owns
    // the inherited controller.
    expect(find.text('loading 0'), findsNothing);
    expect(find.text('content 0'), findsOneWidget);
    expect(controller.positions, hasLength(1));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(find.text('loading 0'), findsNothing);
    expect(find.text('content 0'), findsOneWidget);
    expect(controller.position.pixels, 0);
  });

  testWidgets('content columns share one edge at every width', (tester) async {
    for (final width in [390.0, 800.0, 1440.0, 2560.0]) {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const box = SizedBox(key: ValueKey('box'), height: 10, width: double.infinity);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: FrostContentColumn(child: box),
          ),
        ),
      );
      final rect = tester.getRect(find.byKey(const ValueKey('box')));
      final padding = FrostMetrics.columnPadding(width);
      expect(rect.left, padding.left, reason: '$width');
      expect(rect.width, lessThanOrEqualTo(FrostMetrics.contentMaxWidth - FrostMetrics.browseInset(width) * 2 + .01), reason: '$width');
      // A bleeding row reaches past the column by exactly its own inset.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: FrostContentColumn(bleed: 12, child: box),
          ),
        ),
      );
      expect(tester.getRect(find.byKey(const ValueKey('box'))).left, closeTo(padding.left - 12, .01), reason: '$width bleed');
    }
  });
}
