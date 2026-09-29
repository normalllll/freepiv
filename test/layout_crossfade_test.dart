import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/shared/ui/layout_crossfade.dart';

class _Draft extends StatefulWidget {
  const _Draft();

  @override
  State<_Draft> createState() => _DraftState();
}

class _DraftState extends State<_Draft> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(controller: controller);
}

void main() {
  Widget app(Object layout, {bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: LayoutCrossfade(layoutIdentity: layout, child: const _Draft()),
      ),
    ),
  );

  testWidgets('breakpoint crossfade keeps one draft and routes input only to it', (tester) async {
    await tester.pumpWidget(app(false));
    await tester.enterText(find.byType(TextField), 'kept');
    await tester.pump();
    final state = tester.state(find.byType(_Draft));
    await tester.pumpWidget(app(true));
    expect(tester.state(find.byType(_Draft)), same(state));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'new layout');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(RawImage), findsNothing);
    expect(find.text('new layout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same layout resize does not capture, reduced motion discards an active snapshot', (tester) async {
    await tester.pumpWidget(app(false));
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(app(false));
    expect(find.byType(RawImage), findsNothing);
    await tester.pumpWidget(app(true));
    expect(find.byType(RawImage), findsOneWidget);
    await tester.pumpWidget(app(true, reduced: true));
    expect(find.byType(RawImage), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid reversal and continued resizing retain one live tree and release the final frame', (tester) async {
    await tester.pumpWidget(app(false));
    final state = tester.state(find.byType(_Draft));
    await tester.pumpWidget(app(true));
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pumpWidget(app(false));
    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.state(find.byType(_Draft)), same(state));
    tester.view.physicalSize = const Size(850, 600);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    tester.view.physicalSize = const Size(900, 600);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(RawImage), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(RawImage), findsNothing);
    expect(find.byType(_Draft), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
