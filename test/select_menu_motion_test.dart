import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';

void main() {
  testWidgets('select menu fades and moves four pixels over 240 and 180 milliseconds', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('One'));
    await tester.pump();

    final opacity = find.ancestor(of: find.text('Two'), matching: find.byType(Opacity)).first;
    final transform = find.ancestor(of: find.text('Two'), matching: find.byType(Transform)).first;
    expect(tester.widget<Opacity>(opacity).opacity, 0);
    expect(tester.widget<Transform>(transform).transform.getTranslation().y, 4);

    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.widget<Opacity>(opacity).opacity, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.widget<Opacity>(opacity).opacity, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Two'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.widget<Opacity>(opacity).opacity, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 90));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsNothing);
  });

  testWidgets('select preserves keyboard selection, focus return, and rapid reversal', (tester) async {
    var selected = 1;
    await tester.pumpWidget(_host(onChanged: (value) => selected = value));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    final trigger = tester
        .widgetList<Focus>(find.descendant(of: find.byType(FrostSelect<int>), matching: find.byType(Focus)))
        .singleWhere((focus) => focus.focusNode != null);
    expect(trigger.focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(trigger.focusNode!.hasFocus, isTrue);

    await tester.tap(find.text('One').first);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('One').first);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(find.text('One').first);
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows and removes the menu immediately', (tester) async {
    await tester.pumpWidget(_host(disableAnimations: true));
    await tester.tap(find.text('One'));
    await tester.pump();
    final opacity = find.ancestor(of: find.text('Two'), matching: find.byType(Opacity)).first;
    expect(tester.widget<Opacity>(opacity).opacity, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Two'), findsNothing);
  });

  testWidgets('single and long select menus fit at the bottom edge without extra rows', (tester) async {
    tester.view.physicalSize = const Size(390, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget host(List<FrostSelectItem<int>> items, ValueChanged<int> onChanged, {double textScale = 1}) => MaterialApp(
      theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: 250,
                  child: FrostSelect<int>(value: 1, items: items, onChanged: onChanged),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(host(const [FrostSelectItem(value: 1, label: 'Only')], (_) {}));
    await tester.tap(find.text('Only'));
    await tester.pumpAndSettle();
    final singleItem = find.byType(MenuItemButton);
    final singleSurface = find.ancestor(of: singleItem, matching: find.byType(Material)).first;
    expect(tester.getSize(singleSurface).height, closeTo(tester.getSize(singleItem).height, 2));
    expect(tester.getRect(singleSurface).bottom, lessThanOrEqualTo(192));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    var selected = 1;
    await tester.pumpWidget(
      host(
        [for (var index = 1; index <= 10; index++) FrostSelectItem(value: index, label: '选项 $index / Option $index')],
        (value) => selected = value,
        textScale: 2,
      ),
    );
    await tester.tap(find.text('选项 1 / Option 1').first);
    await tester.pumpAndSettle();
    final longSurface = find.ancestor(of: find.byType(MenuItemButton).first, matching: find.byType(Material)).first;
    expect(tester.getRect(longSurface).top, greaterThanOrEqualTo(8));
    expect(tester.getRect(longSurface).bottom, lessThanOrEqualTo(192));
    final last = find.text('选项 10 / Option 10');
    await tester.ensureVisible(last);
    await tester.pumpAndSettle();
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(selected, 10);
    expect(tester.takeException(), isNull);
  });
}

Widget _host({ValueChanged<int>? onChanged, bool disableAnimations = false}) => MaterialApp(
  theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 240,
            child: FrostSelect<int>(
              value: 1,
              items: const [
                FrostSelectItem(value: 1, label: 'One'),
                FrostSelectItem(value: 2, label: 'Two'),
              ],
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  ),
);
