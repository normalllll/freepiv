import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/theme/app_feedback.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/features/novel/presentation/widgets/novel_detail_skeleton.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/app/window/native_window.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';
import 'package:freepiv/shared/widgets/app_click_surface.dart';
import 'package:freepiv/shared/widgets/interaction_controls.dart';
import 'package:freepiv/shared/widgets/settings_sections.dart';
import 'package:freepiv/shared/widgets/search_input.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';

ThemeData theme(Brightness brightness) => brightness == Brightness.light
    ? AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en', 'US'))
    : AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en', 'US'));

Widget host(Widget child, {Brightness brightness = Brightness.light, double textScale = 1}) => MaterialApp(
  theme: theme(brightness),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: child),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('light surfaces use the specified neutral palette throughout ThemeData', () {
    const tokens = FreepivThemeTokens.light;
    final colors = theme(Brightness.light).colorScheme;
    expect(tokens.canvas, const Color(0xFFF6F6F6));
    expect(tokens.surfaceInset, const Color(0xFFECECEC));
    expect(tokens.surfaceMuted, const Color(0xFFF1F1F1));
    expect(tokens.hoverSurface, const Color(0xFFE7E7E7));
    expect(tokens.pressedSurface, const Color(0xFFDBDBDB));
    expect(tokens.textPrimary, const Color(0xFF242424));
    expect(tokens.textSecondary, const Color(0xFF606060));
    expect(tokens.line, const Color(0xFFD6D6D6));
    expect(tokens.commentSeparator, const Color(0xFFD0D0D0));
    expect(tokens.commentThreadLine, const Color(0xFFBABABA));
    expect(colors.surfaceContainerLowest, tokens.canvas);
    expect(colors.surfaceContainer, tokens.surfaceInset);
    expect(colors.surfaceContainerHighest, tokens.surfaceMuted);
    expect(colors.surfaceTint, tokens.surfaceTint);
    expect(colors.onSurfaceVariant, tokens.textSecondary);
    expect(colors.outline, tokens.line);
    expect(appFeedbackSurface(tokens, {WidgetState.hovered}), tokens.hoverSurface);
    expect(appFeedbackSurface(tokens, {WidgetState.pressed}), tokens.pressedSurface);
  });

  testWidgets('selected theme option keeps its raised surface while hovered', (tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: host(
          Center(
            child: SizedBox(
              width: 500,
              child: ThemeModeSelector(value: ThemeMode.light, onChanged: (_) {}),
            ),
          ),
        ),
      ),
    );
    final selected = find.byKey(const ValueKey('theme-mode-light'));
    final click = find.descendant(of: selected, matching: find.byType(AppClickSurface));
    expect(tester.widget<AppClickSurface>(click).feedback, AppClickFeedback.quiet);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(selected));
    await tester.pumpAndSettle();
    final stateLayer = tester.widget<AnimatedContainer>(find.descendant(of: click, matching: find.byType(AnimatedContainer)).first);
    expect((stateLayer.decoration! as ShapeDecoration).color!.a, lessThan(.1));
    await mouse.removePointer();
  });

  test('primary and error text maintain contrast in both themes', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance();
      final y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    for (final brightness in Brightness.values) {
      final colors = theme(brightness).colorScheme;
      expect(contrast(colors.primary, colors.onPrimary), greaterThanOrEqualTo(4.5));
      expect(contrast(colors.onSurface, colors.surface), greaterThanOrEqualTo(4.5));
      // Bright pink is a fill/accent; readable labels use neutral ink.
      expect(colors.primary, const Color(0xFFFC619D));
      expect(contrast(colors.primaryContainer, colors.onPrimaryContainer), greaterThanOrEqualTo(4.5));
      expect(contrast(colors.error, colors.surface), greaterThanOrEqualTo(4.5));
    }
  });

  test('switch uses a light thumb on the brand track in both themes', () {
    for (final brightness in Brightness.values) {
      final data = theme(brightness);
      final tokens = brightness == Brightness.light ? FreepivThemeTokens.light : FreepivThemeTokens.dark;
      expect(data.switchTheme.trackColor!.resolve({WidgetState.selected}), tokens.brand);
      expect(data.switchTheme.thumbColor!.resolve({WidgetState.selected}), tokens.isDark ? tokens.textPrimary : tokens.surfaceRaised);
      expect(data.switchTheme.trackOutlineColor!.resolve({}), Colors.transparent);
      expect(data.switchTheme.overlayColor!.resolve({WidgetState.selected, WidgetState.hovered})!.a, lessThan(.1));
    }
  });

  test('navigation follows window width, including portrait desktop windows', () {
    for (final size in [const Size(844, 390), const Size(1024, 768), const Size(1200, 800), const Size(900, 1600)]) {
      expect(isHorizontalSize(size), isTrue);
    }
    for (final size in [const Size(390, 844), const Size(599, 300), const Size(119, 100)]) {
      expect(isHorizontalSize(size), isFalse);
    }
  });

  testWidgets('nested constraints and keyboard do not alter root layout', (tester) async {
    var horizontal = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1024, 768)),
          child: AppLayoutScope(
            child: MediaQuery(
              data: const MediaQueryData(size: Size(300, 700), viewInsets: EdgeInsets.only(bottom: 350)),
              child: Builder(
                builder: (context) {
                  horizontal = AutoScaffold.usesHorizontalLayoutOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(horizontal, isTrue);
  });

  testWidgets('tablet landscape never adds desktop caption controls', (tester) async {
    await tester.pumpWidget(
      host(
        const NativeWindowFrame(
          title: 'freepiv',
          leading: Icon(Icons.image),
          background: Colors.white,
          foreground: Colors.black,
          border: Colors.grey,
          child: Text('content'),
        ),
      ),
    );
    expect(find.text('content'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.byIcon(Icons.horizontal_rule_rounded), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('portrait Windows retains native caption controls', (tester) async {
    const channel = MethodChannel('desktop_window');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async => call.method == 'getState' ? <String, Object>{} : null);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        const NativeWindowFrame(
          title: 'freepiv',
          leading: Icon(Icons.image),
          background: Colors.white,
          foreground: Colors.black,
          border: Colors.grey,
          labels: NativeWindowLabels(minimize: 'Minimize', maximize: 'Maximize', restore: 'Restore', close: 'Close'),
          child: Text('content'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.horizontal_rule_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('action stays keyboard operable and stable during loading', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        Center(
          child: AppButton(label: 'Send', onPressed: () => calls++),
        ),
      ),
    );
    final size = tester.getSize(find.byType(FilledButton));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls, 1);
    await tester.pumpWidget(
      host(
        Center(
          child: AppButton(label: 'Send', loading: true, onPressed: () => calls++),
        ),
      ),
    );
    expect(tester.getSize(find.byType(FilledButton)), size);
    await tester.tap(find.byType(FilledButton));
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('custom text field inherits distinct focus and error borders', (tester) async {
    await tester.pumpWidget(host(const AppTextField(label: 'Proxy', errorText: 'Invalid address')));
    final field = tester.widget<TextField>(find.byType(TextField));
    final decoration = field.decoration!.applyDefaults(theme(Brightness.light).inputDecorationTheme);
    // Typing focus is the accent outline, not the dark keyboard focus ring.
    final tokens = theme(Brightness.light).extension<FreepivThemeTokens>()!;
    expect(decoration.focusedBorder!.borderSide.color, tokens.fieldFocus);
    expect(decoration.focusedBorder!.borderSide.width, AppMetrics.fieldFocusWidth);
    expect(decoration.focusedBorder!.borderSide.color, isNot(decoration.enabledBorder!.borderSide.color));
    expect(decoration.errorBorder!.borderSide.color, theme(Brightness.light).colorScheme.error);
    expect(decoration.enabledBorder!.borderSide.color, isNot(decoration.errorBorder!.borderSide.color));
  });

  test('user errors never include raw responses, credentials or URLs', () {
    const error = PixivError(
      kind: PixivErrorKind.httpStatus,
      status: 401,
      message: 'token=SECRET',
      body: 'SECRET response',
      url: 'https://example.test?token=SECRET',
    );
    expect(formatPixivError(error), t.errors.session);
    expect(formatPixivError(error), isNot(contains('SECRET')));
    expect(formatPixivError(StateError('SECRET')), t.errors.generic);
  });

  testWidgets('search remains operable with long text and a visible keyboard', (tester) async {
    final controller = TextEditingController(text: '長い検索キーワード / 插画与小说 / illustrations');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var submitted = '';
    await tester.pumpWidget(
      host(
        SearchInput(
          controller: controller,
          focusNode: focus,
          hintText: 'Search illustrations, novels and artists',
          onSubmitted: (value) => submitted = value,
          onClear: controller.clear,
          actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list), tooltip: 'Filters')],
        ),
        textScale: 2,
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(submitted, controller.text);
    final inputBounds = tester.getRect(find.byType(TextField));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(tester.getRect(find.byType(TextField)), inputBounds);
    expect(tester.takeException(), isNull);
  });

  testWidgets('novel loading layout fits portrait and landscape with reduced motion', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(390, 844), const Size(844, 390), const Size(1200, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: theme(Brightness.light),
            home: MediaQuery(
              data: MediaQueryData(size: size, disableAnimations: true, textScaler: const TextScaler.linear(2)),
              child: AppLayoutScope(
                child: Builder(
                  builder: (context) {
                    expect(AppMotion.duration(context, AppMotion.page), Duration.zero);
                    return const NovelDetailSkeletonPage();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('settings renders with large text across sizes and themes', (tester) async {
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    // Load a real font for review images; widget tests otherwise use Ahem boxes.
    await tester.runAsync(() async {
      final fontFile = File('C:/Windows/Fonts/segoeui.ttf');
      if (await fontFile.exists()) {
        final loader = FontLoader('Segoe UI')..addFont(Future.value(ByteData.sublistView(await fontFile.readAsBytes())));
        await loader.load();
      }
    });
    for (final size in [const Size(375, 812), const Size(844, 390), const Size(1200, 800)]) {
      for (final brightness in Brightness.values) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: theme(brightness),
              home: MediaQuery(
                data: MediaQueryData(size: size, textScaler: const TextScaler.linear(1.3)),
                child: AppLayoutScope(
                  child: RepaintBoundary(
                    key: boundary,
                    child: Scaffold(
                      appBar: AppBar(title: const Text('Settings')),
                      body: SettingsSections(
                        labels: const ['Appearance', 'Connection', 'Downloads'],
                        groups: [
                          [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Appearance'),
                                  const SizedBox(height: 12),
                                  AppSelect<int>(
                                    value: 0,
                                    items: const [
                                      AppSelectItem(value: 0, label: 'Follow system appearance'),
                                      AppSelectItem(value: 1, label: 'Light'),
                                    ],
                                    onChanged: (_) {},
                                  ),
                                  const SizedBox(height: 16),
                                  AppButton(label: 'Save preferences', kind: AppButtonKind.primary, onPressed: () {}),
                                ],
                              ),
                            ),
                          ],
                          [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: AppTextField(label: 'Connection', errorText: 'Please enter a valid address'),
                            ),
                          ],
                          [ListTile(title: const Text('Download location'), subtitle: const Text('Use the default folder'), onTap: () {})],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size $brightness');
        if (size.width == 375) {
          expect(find.text('Download location'), findsOneWidget);
          expect(find.text('Connection'), findsOneWidget);
        } else if (size.width == 1200) {
          await tester.tap(find.text('Connection'));
          await tester.pumpAndSettle();
          expect(find.text('Please enter a valid address'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/ui-review/settings-${size.width.toInt()}-${brightness.name}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
