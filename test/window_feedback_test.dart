import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/app/window/native_window.dart';

void main() {
  testWidgets('close caption stays red after hover animation in both themes', (tester) async {
    const channel = MethodChannel('desktop_window');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async => call.method == 'getState' ? <String, Object>{} : null);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(400, 300));
    addTearDown(mouse.removePointer);
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark
              ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
              : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: const NativeWindowFrame(
            title: 'freepiv',
            leading: Icon(Icons.image),
            background: Colors.white,
            foreground: Colors.black,
            border: Colors.grey,
            labels: NativeWindowLabels(minimize: 'Minimize', maximize: 'Maximize', restore: 'Restore', close: 'Close'),
            child: SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final close = find.ancestor(of: find.byIcon(Icons.close_rounded), matching: find.byType(IconButton));
      await mouse.moveTo(tester.getCenter(close));
      for (final elapsed in [20, 90, 200, 500]) {
        await tester.pump(Duration(milliseconds: elapsed));
        final material = tester.widget<Material>(find.descendant(of: close, matching: find.byType(Material)).first);
        expect(material.color, FrostCaptionColors.closeHover);
        expect(find.descendant(of: close, matching: find.byType(AnimatedContainer)), findsNothing);
      }
      await mouse.moveTo(const Offset(400, 300));
      await tester.pumpAndSettle();
      final material = tester.widget<Material>(find.descendant(of: close, matching: find.byType(Material)).first);
      expect(material.color!.a, 0);
      expect(tester.takeException(), isNull);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
