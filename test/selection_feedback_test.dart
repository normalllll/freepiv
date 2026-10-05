import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';

Widget host(Widget child) => ProviderScope(
  child: FrostInputFeedback(
    child: MaterialApp(
      theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
      home: Scaffold(body: Center(child: child)),
    ),
  ),
);

void main() {
  testWidgets('sidebar has exactly one selected highlight throughout rapid switching', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 76,
            child: Column(
              children: [
                for (var index = 0; index < 2; index++)
                  FrostNavItem(label: 'Destination $index', icon: PivIcons.home, selected: selected == index, onTap: () => setState(() => selected = index)),
              ],
            ),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    for (final index in [1, 0, 1, 0]) {
      await mouse.moveTo(tester.getCenter(find.text('Destination $index')));
      await mouse.down(tester.getCenter(find.text('Destination $index')));
      await mouse.up();
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final pills = tester
            .widgetList<AnimatedContainer>(find.descendant(of: find.byType(FrostNavItem), matching: find.byType(AnimatedContainer)))
            .where(
              (pill) => switch (pill.decoration) {
                BoxDecoration(:final color) => color == FrostPalettes.pink.lightNeutral.selectionFill,
                _ => false,
              },
            );
        expect(pills.length, 1);
        expect(tester.widgetList<FrostNavItem>(find.byType(FrostNavItem)).singleWhere((item) => item.selected).label, 'Destination $index');
      }
    }
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu trigger has no ink state layer and supports keyboard selection', (tester) async {
    var value = 1;
    await tester.pumpWidget(
      host(
        FrostMenuButton<int>(
          value: value,
          onSelected: (next) => value = next,
          items: const [
            FrostSelectItem(value: 1, label: 'Public'),
            FrostSelectItem(value: 2, label: 'Private'),
          ],
          child: const Padding(padding: EdgeInsets.all(12), child: Text('Scope')),
        ),
      ),
    );
    final ink = tester.widget<InkWell>(find.descendant(of: find.byType(FrostMenuButton<int>), matching: find.byType(InkWell)));
    expect(ink.splashFactory, NoSplash.splashFactory);
    expect(ink.overlayColor!.resolve({WidgetState.hovered}), Colors.transparent);
    expect(ink.customBorder, isA<RoundedRectangleBorder>());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Private'), findsOneWidget);
    await tester.tap(find.text('Private'));
    await tester.pumpAndSettle();
    expect(value, 2);
    expect(find.text('Private'), findsNothing);
  });

  testWidgets('selected category keeps its readable pill when another category is hovered', (tester) async {
    var selected = 1;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => FrostSegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 1, label: Text('Artwork')),
              ButtonSegment(value: 2, label: Text('Novels')),
            ],
            selected: {selected},
            onSelectionChanged: (values) => setState(() => selected = values.single),
          ),
        ),
      ),
    );
    Color? ink(String label) => tester.renderObject<RenderParagraph>(find.text(label)).text.style?.color;
    // The sliding pill sits under whichever segment its alignment points to.
    double pillCenter() => tester.getCenter(find.descendant(of: find.byType(FrostSpringBuilder), matching: find.byType(DecoratedBox))).dx;
    final tokens = FrostPalettes.pink.lightNeutral;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.text('Novels')));
    await tester.pumpAndSettle();
    expect(ink('Artwork'), tokens.selectionInk);
    expect(ink('Novels'), tokens.textSecondary);
    expect(pillCenter(), closeTo(tester.getCenter(find.text('Artwork')).dx, 1));
    await tester.tap(find.text('Novels'));
    await tester.pumpAndSettle();
    expect(ink('Artwork'), tokens.textSecondary);
    expect(ink('Novels'), tokens.selectionInk);
    expect(pillCenter(), closeTo(tester.getCenter(find.text('Novels')).dx, 1));
    await mouse.removePointer();
  });
}
