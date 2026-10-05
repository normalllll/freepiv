import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';

void main() {
  testWidgets('primary button stays branded through mouse states and exposes independent keyboard focus', (tester) async {
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.runAsync(() async {
      final font = File('C:/Windows/Fonts/segoeui.ttf');
      if (await font.exists()) {
        await (FontLoader('Segoe UI')..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())))).load();
      }
    });

    for (final dark in [false, true]) {
      final boundary = GlobalKey();
      var presses = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: dark
              ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
              : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: boundary,
                child: SizedBox(
                  width: 200,
                  height: 80,
                  child: Center(
                    child: FrostButton(label: 'Continue', kind: FrostButtonKind.primary, onPressed: () => presses++),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.byType(FilledButton);
      final material = tester.widgetList<Material>(find.descendant(of: button, matching: find.byType(Material))).first;
      expect((material.shape! as OutlinedBorder).side, BorderSide.none);
      final bounds = tester.getRect(button);
      final origin = tester.getTopLeft(find.byKey(boundary));
      final sample = Offset(bounds.left + 12, bounds.center.dy) - origin;

      Future<Color> sampleColor(String state, {Offset? point}) async {
        late Color sampled;
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
          final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
          final location = point ?? sample;
          final offset = (location.dy.round() * image.width + location.dx.round()) * 4;
          sampled = Color.fromARGB(255, data[offset], data[offset + 1], data[offset + 2]);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/ui-review/primary-${dark ? 'dark' : 'light'}-$state.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
        return sampled;
      }

      final idle = await sampleColor('idle');
      final focusPoint = Offset(bounds.center.dx, bounds.top - 3) - origin;
      final idleOutline = await sampleColor('idle-outline', point: focusPoint);
      // The solid fill is the accent toned for its white label: still pink,
      // never a neutral or near-black wash.
      final fill = FrostThemeTokens.of(tester.element(button)).actionFill;
      expect(idle.r, closeTo(fill.r, .02));
      expect(idle.g, closeTo(fill.g, .02));
      expect(idle.b, closeTo(fill.b, .02));
      expect(idle.r, greaterThan(idle.g + .3));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(bounds.center);
      await tester.pumpAndSettle();
      final hover = await sampleColor('hover');
      // Under the white label the wash darkens the fill, so its contrast only
      // rises; the hover wash is the stronger of the two.
      expect(hover.r, lessThanOrEqualTo(idle.r));
      expect(hover.g, lessThan(idle.g));
      expect(hover.b, lessThan(idle.b));
      expect((tester.widgetList<Material>(find.descendant(of: button, matching: find.byType(Material))).first.shape! as OutlinedBorder).side, BorderSide.none);

      await mouse.down(bounds.center);
      await tester.pumpAndSettle();
      // Pointer press sinks the button to .98 on the snappy spring.
      final pressScale = tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.ancestor(of: button, matching: find.byType(FrostSpringBuilder)).first,
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .entry(0, 0);
      expect(pressScale, closeTo(.98, .001));
      final pressed = await sampleColor('pressed');
      expect(pressed.r, greaterThan(.86));
      expect(pressed.g, greaterThan(hover.g));
      expect(pressed.g, lessThan(idle.g));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(presses, 1);
      await mouse.removePointer();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final focused = tester.widgetList<Material>(find.descendant(of: button, matching: find.byType(Material))).first;
      expect((focused.shape! as OutlinedBorder).side, BorderSide.none);
      final focusOutline = await sampleColor('focus-outline', point: focusPoint);
      expect(focusOutline, isNot(idleOutline), reason: 'Keyboard focus paints a separate outline outside the button');
      await sampleColor('focus');

      await tester.pumpWidget(
        MaterialApp(
          theme: dark
              ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
              : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: Scaffold(
            body: Center(
              child: FrostButton(label: 'Continue', kind: FrostButtonKind.primary, loading: true, onPressed: () => presses++),
            ),
          ),
        ),
      );
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    }
  });
}
