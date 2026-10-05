import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';

void main() {
  testWidgets('settings rows share an undivided group with square middle feedback', (tester) async {
    await tester.runAsync(() async {
      final systemFont = File('C:/Windows/Fonts/segoeui.ttf');
      if (await systemFont.exists()) {
        final bytes = await systemFont.readAsBytes();
        await (FontLoader('Segoe UI')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: RepaintBoundary(
            key: boundary,
            child: Scaffold(
              body: FrostGroupedSettingsList(
                groups: [
                  [
                    for (final label in ['First', 'Middle', 'Last']) ListTile(title: Text(label), onTap: () {}),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final group = find.byType(FrostGroupedRows);
    expect(group, findsOneWidget);
    expect(find.descendant(of: group, matching: find.byType(Divider)), findsNothing);

    BorderRadius corners(String label) {
      BorderRadiusGeometry? value;
      tester.element(find.text(label)).visitAncestorElements((ancestor) {
        if (ancestor.widget case ClipRRect(:final borderRadius)) {
          value = borderRadius;
          return false;
        }
        return true;
      });
      return value!.resolve(TextDirection.ltr);
    }

    expect(corners('First').topLeft.x, FrostMetrics.groupRadius);
    expect(corners('First').bottomLeft.x, 0);
    expect(corners('Middle'), BorderRadius.zero);
    expect(corners('Last').bottomLeft.x, FrostMetrics.groupRadius);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.text('Middle')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image = await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('build/ui-review/settings-group-middle-hover.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
    });
    await mouse.removePointer();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
