import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frost_data/frost_data.dart';

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
      MediaQuery(
        data: MediaQueryData.fromView(tester.view),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PrimaryScrollController(
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
      ),
    );
    // Cached content on a revisit must not fade in.
    final fading = find.ancestor(
      of: find.text('loading 0'),
      matching: find.byWidgetPredicate((widget) => (widget is Opacity && widget.opacity < 1) || (widget is FadeTransition && widget.opacity.value < 1)),
    );
    expect(fading, findsNothing);

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
}
