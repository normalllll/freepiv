import 'package:freepiv/app/theme/accent_color_math.dart';
import 'package:freepiv/app/theme/app_input_feedback.dart';
import 'package:freepiv/app/theme/app_feedback.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/shared/widgets/app_click_surface.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';
import 'package:freepiv/shared/widgets/interaction_controls.dart';
import 'package:freepiv/core/downloads/models/download_task_snapshot.dart';
import 'package:freepiv/core/downloads/models/download_enums.dart';
import 'package:freepiv/core/downloads/models/download_origin.dart';
import 'package:freepiv/features/downloads/presentation/download_task_widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';

void main() {
  test('light interaction surfaces remain distinct from their surrounding surfaces', () {
    final tokens = FreepivThemeTokens.light;
    double contrast(Color a, Color b) {
      final x = a.computeLuminance();
      final y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    for (final background in [tokens.surface, tokens.surfaceRaised]) {
      expect(contrast(tokens.hoverSurface, background), greaterThan(1.05));
      expect(contrast(tokens.pressedSurface, background), greaterThan(1.10));
    }
    expect(tokens.hoverSurface, isNot(tokens.surfaceInset));
    expect(contrast(tokens.hoverSurface, tokens.surfaceRaised), lessThan(1.25), reason: 'Hover should remain a quiet light surface');
    expect(tokens.pressedSurface.computeLuminance(), lessThan(tokens.hoverSurface.computeLuminance()));
    expect(contrast(tokens.textPrimary, tokens.pressedSurface), greaterThan(4.5));
  });
  testWidgets('hover transition frames never flash a dark surface', (tester) async {
    for (final control in <Widget>[
      AppClickSurface(onTap: () {}, child: const SizedBox.expand()),
      AppIconButton(onPressed: () {}, icon: const SizedBox.shrink()),
      TextButton(onPressed: () {}, child: const SizedBox.shrink()),
    ]) {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: Material(
                  color: Colors.white,
                  child: SizedBox(width: 100, height: 60, child: control),
                ),
              ),
            ),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      for (final entering in [true, false, true, false]) {
        await mouse.moveTo(entering ? tester.getCenter(find.byKey(key)) : Offset.zero);
        await tester.pump();
        final samples = <int>[];
        for (var frame = 0; frame < 13; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(() async {
            final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
            final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
            final offset = (30 * image.width + 50) * 4;
            samples.add(data[offset]);
            final hover = FreepivThemeTokens.light.hoverSurface;
            final minimum = [hover.r, hover.g, hover.b].map((channel) => (channel * 255).round() - 1).toList();
            expect(
              List.generate(3, (channel) => data[offset + channel] >= minimum[channel]).every((valid) => valid),
              isTrue,
              reason: 'No dark interpolation frame on ${entering ? "entry" : "exit"}, frame $frame',
            );
            image.dispose();
          });
        }
        expect(samples.first, entering ? greaterThan(samples.last) : lessThan(samples.last), reason: 'Entry and exit must contain intermediate frames');
      }
      await mouse.removePointer();
    }
  });
  testWidgets('keyboard focus survives hover but pointer activation clears its ring in both themes', (tester) async {
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.runAsync(() async {
      final font = File('C:/Windows/Fonts/segoeui.ttf');
      if (await font.exists()) {
        await (FontLoader('Segoe UI')..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())))).load();
      }
    });
    for (final dark in [false, true]) {
      final key = GlobalKey();
      var taps = 0;
      await tester.pumpWidget(
        AppInputFeedback(
          key: ValueKey(dark),
          child: MaterialApp(
            theme: dark
                ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
                : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: 320,
                    height: 180,
                    child: Builder(
                      builder: (context) => ColoredBox(
                        color: Theme.of(context).colorScheme.surface,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppButton(label: 'Follow creator', onPressed: () => taps++),
                            AppIconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final button = find.byType(FilledButton);
      Material surface() => tester.widgetList<Material>(find.descendant(of: button, matching: find.byType(Material))).first;
      BorderSide side() => (surface().shape! as OutlinedBorder).side;
      bool hasFocusOutline() => tester
          .widgetList<CustomPaint>(find.ancestor(of: button, matching: find.byType(CustomPaint)))
          .any((paint) => paint.foregroundPainter?.runtimeType.toString() == '_ButtonFocusPainter');
      final resting = side();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(button));
      await tester.pumpAndSettle();
      expect(side(), resting, reason: 'Hover must not create a focus ring');
      final hover =
          (tester.widget<AnimatedContainer>(find.descendant(of: button, matching: find.byType(AnimatedContainer)).first).decoration as BoxDecoration).color;
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/ui-review/hover-controls-${dark ? 'dark' : 'light'}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await mouse.down(tester.getCenter(button));
      await tester.pumpAndSettle();
      expect(side(), resting);
      expect(
        (tester.widget<AnimatedContainer>(find.descendant(of: button, matching: find.byType(AnimatedContainer)).first).decoration as BoxDecoration).color,
        isNot(hover),
        reason: 'Press is distinguishable from hover',
      );
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/ui-review/pressed-controls-${dark ? 'dark' : 'light'}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await mouse.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(side(), resting, reason: 'Mouse focus must not leave a ring');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 2);
      expect(hasFocusOutline(), isTrue, reason: 'Keyboard activation restores visible focus');
      await mouse.moveTo(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(hasFocusOutline(), isTrue, reason: 'Pointer movement must not erase keyboard focus');
      await mouse.down(tester.getCenter(button));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(side(), resting);
      expect(hasFocusOutline(), isFalse, reason: 'Pointer activation clears the keyboard focus outline');
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('touch hold, cancel, scrolling and context hold have independent actions', (tester) async {
    var taps = 0;
    var holds = 0;
    await tester.pumpWidget(
      AppInputFeedback(
        child: MaterialApp(
          theme: AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en')),
          home: Scaffold(
            body: ListView(
              children: [
                AppClickSurface(
                  onTap: () => taps++,
                  child: const SizedBox(height: 80, child: Text('Tap')),
                ),
                AppClickSurface(
                  onTap: () => taps++,
                  onLongPress: () => holds++,
                  child: const SizedBox(height: 80, child: Text('Context')),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      ),
    );
    Color background(String label) =>
        (tester
                    .widget<AnimatedContainer>(
                      find.descendant(
                        of: find.ancestor(of: find.text(label), matching: find.byType(AppClickSurface)),
                        matching: find.byType(AnimatedContainer),
                      ),
                    )
                    .decoration!
                as ShapeDecoration)
            .color!;
    final normal = background('Tap');
    final touch = await tester.startGesture(tester.getCenter(find.text('Tap')));
    await tester.pump(const Duration(seconds: 1));
    expect(background('Tap'), isNot(normal));
    expect(taps, 0);
    await touch.cancel();
    await tester.pumpAndSettle();
    expect(background('Tap'), normal);
    expect(taps, 0);
    await tester.longPress(find.text('Context'));
    await tester.pumpAndSettle();
    expect(holds, 1);
    expect(taps, 0, reason: 'Long press must not also activate tap');
    await tester.drag(find.text('Tap'), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(taps, 0, reason: 'Scrolling cancels the tap');
    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(background('Tap'), normal);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact download actions fit narrow rows and expose secondary actions in a menu', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final task = DownloadTaskSnapshot(
      id: 'review',
      origin: const ArtworkPage(illustId: 1, pageIndex: 0),
      title: 'Long artwork title for compact download panel',
      filename: 'art.png',
      status: DownloadStatus.failed,
      saveState: SaveState.failed,
      receivedBytes: 0,
      totalBytes: 1000,
      progress: 0,
      localPath: null,
      error: 'Failed',
      log: 'Review log',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: MaterialApp(
            builder: (context, child) => AppInputFeedback(child: child!),
            theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
            home: Scaffold(body: DownloadTaskTile(task: task, compact: true)),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.ancestor(of: find.byIcon(Icons.refresh_outlined), matching: find.byType(AppClickSurface)).first).height, 44);
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text(t.common.viewLog), findsOneWidget);
    expect(find.text(t.settings.downloads.deleteTask), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(t.common.viewLog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('pointer press uses shaped surface feedback without focus outlines', (tester) async {
    for (final circle in [false, true]) {
      final key = GlobalKey();
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => AppInputFeedback(child: child!),
          theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: Material(
                  color: Colors.white,
                  child: AppClickSurface(customBorder: circle ? const CircleBorder() : null, onTap: () => taps++, child: const SizedBox(width: 80, height: 80)),
                ),
              ),
            ),
          ),
        ),
      );
      final target = find.byType(AppClickSurface);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(target));
      await tester.pump();
      expect(appClickCursor.resolve({}), SystemMouseCursors.click);
      await mouse.down(tester.getCenter(target));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
        List<int> pixel(int x, int y) => bytes.sublist((y * image.width + x) * 4, (y * image.width + x) * 4 + 4);
        final pressed = FreepivThemeTokens.light.pressedSurface;
        expect(pixel(40, 40), [
          (pressed.r * 255).round(),
          (pressed.g * 255).round(),
          (pressed.b * 255).round(),
          255,
        ], reason: 'Pressed surface is opaque and neutral');
        expect(pixel(0, 0), [255, 255, 255, 255], reason: 'Feedback must respect rounded corners');
        expect(pixel(1, 40), isNot([252, 97, 157, 255]), reason: 'Pointer press must not add an outline');
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/ui-review/feedback-${circle ? 'circle' : 'rounded'}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
      await mouse.up();
      await tester.pump();
      expect(taps, 1);
      await mouse.removePointer();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 2);
      expect(FocusManager.instance.highlightMode, FocusHighlightMode.traditional);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('nested actions do not activate their parent and disabled content has no action', (tester) async {
    var parent = 0;
    var child = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppInputFeedback(child: child!),
        home: Scaffold(
          body: Material(
            child: AppClickSurface(
              onTap: () => parent++,
              child: Center(
                child: TextButton(onPressed: () => child++, child: const Text('Save')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save'));
    expect(child, 1);
    expect(parent, 0);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppInputFeedback(child: child!),
        home: Scaffold(
          body: Material(child: AppClickSurface(child: SizedBox(width: 80, height: 80))),
        ),
      ),
    );
    await tester.tap(find.byType(AppClickSurface));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(parent, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('select supports keyboard operation and visible focus', (tester) async {
    int selected = 1;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppInputFeedback(child: child!),
        theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: AppSelect<int>(
                value: selected,
                items: const [
                  AppSelectItem(value: 1, label: 'Original'),
                  AppSelectItem(value: 2, label: 'Standard'),
                ],
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Standard'), findsOneWidget);
    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });

  test('button states never introduce color washes; only persistent selection uses the accent wash', () {
    final theme = AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en'));
    final tokens = theme.extension<FreepivThemeTokens>()!;
    // Persistent selection is a low-alpha accent wash over the raised surface,
    // with an accent ink that stays readable on it.
    expect(tokens.selectionSurface, Color.alphaBlend(tokens.selectionFill, tokens.surfaceRaised));
    expect(colorContrast(tokens.selectionInk, tokens.selectionSurface), greaterThanOrEqualTo(4.5));
    for (final style in [theme.textButtonTheme.style!, theme.filledButtonTheme.style!, theme.iconButtonTheme.style!, theme.menuButtonTheme.style!]) {
      for (final state in [WidgetState.hovered, WidgetState.pressed, WidgetState.focused]) {
        expect(style.overlayColor!.resolve({state}), Colors.transparent);
        if (state != WidgetState.focused) {
          expect(style.backgroundColor!.resolve({state}), style.backgroundColor!.resolve({}));
          expect(style.backgroundBuilder, isNotNull);
          expect(style.side!.resolve({state}), style.side!.resolve({}));
        }
      }
    }
  });
}
