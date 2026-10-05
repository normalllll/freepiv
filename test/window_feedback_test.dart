import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/app/window/native_window.dart';

void main() {
  testWidgets('long title remains separate from caption hit regions and window controls', (tester) async {
    const channel = MethodChannel('desktop_window');
    List<dynamic>? regions;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getState') return <String, Object>{};
      if (call.method == 'setRegions') regions = call.arguments as List<dynamic>;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const title = 'Manga: 123456789 · A very long title that must remain readable on hover while the window is narrow';

    for (final width in [480.0, 800.0, 1200.0]) {
      await tester.binding.setSurfaceSize(Size(width, 600));
      await tester.pumpWidget(
        const MaterialApp(
          home: NativeWindowFrame(
            title: title,
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
      final titleRect = tester.getRect(find.byKey(const ValueKey('window-title-text')));
      final brandRect = tester.getRect(find.byKey(const ValueKey('window-brand-text')));
      final minimizeRect = tester.getRect(find.byIcon(Icons.horizontal_rule_rounded));
      expect(tester.widget<Text>(find.byKey(const ValueKey('window-brand-text'))).data, 'freepiv');
      expect(titleRect.left - brandRect.right, greaterThanOrEqualTo(16));
      expect(titleRect.right, lessThan(minimizeRect.left));
      expect(tester.widget<Tooltip>(find.ancestor(of: find.byKey(const ValueKey('window-title-text')), matching: find.byType(Tooltip)).first).message, title);
      expect(regions, isNotNull);
      final center = titleRect.center;
      final captionRegions = regions!.where((entry) => (entry as List<dynamic>)[4] == 'caption').cast<List<dynamic>>();
      expect(
        captionRegions.any(
          (entry) => center.dx >= (entry[0] as num) && center.dx < (entry[2] as num) && center.dy >= (entry[1] as num) && center.dy < (entry[3] as num),
        ),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

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
