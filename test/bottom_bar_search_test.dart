import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_box.dart';
import 'package:frost_ui/frost_ui.dart';

Future<void> _boot(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await AppSettings.initialize(store: SampleSettingsStore(sampleSettings));
  pixivAccountNotifier.value = sampleAccount;
  addTearDown(() => pixivAccountNotifier.value = null);
  AppRouter.router.go(AppRoute.home.path);
  await tester.pumpWidget(
    FreepivApp(
      windowController: FrostWindowController(minimumSize: const Size(320, 480)),
      overrides: sampleOverrides,
    ),
  );
  await _frames(tester);
}

Future<void> _frames(WidgetTester tester) async {
  for (var frame = 0; frame < 15; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

FocusNode? _headerFocus(WidgetTester tester) {
  final input = find.descendant(of: find.byType(SearchBox), matching: find.byType(FrostSearchInput));
  if (input.evaluate().isEmpty) return null;
  return tester.widget<FrostSearchInput>(input.last).focusNode;
}

void main() {
  testWidgets('in the bottom-bar layout the home search entry opens discover with its search focused', (tester) async {
    await _boot(tester, const Size(390, 844));
    expect(appSearchInCaption.value, isFalse);
    final entry = find.byKey(const ValueKey('home-search-entry'));
    expect(entry, findsOneWidget);
    await tester.tap(entry);
    await _frames(tester);
    expect(AppRouter.currentUri.toString(), AppLocations.discover(focusSearch: true));
    expect(_headerFocus(tester)?.hasFocus, isTrue);
  });

  testWidgets('in the bottom-bar layout Ctrl K opens discover instead of the hidden title search', (tester) async {
    await _boot(tester, const Size(390, 844));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await _frames(tester);
    expect(AppRouter.currentUri.path, AppRoute.discover.path);
    expect(_headerFocus(tester)?.hasFocus, isTrue);
  });

  testWidgets('in the sidebar layout the title bar holds the search and Ctrl K focuses it', (tester) async {
    await _boot(tester, const Size(1147, 717));
    if (!appSearchInCaption.value) {
      // Without a native window the shell has no title row to put it in.
      expect(find.byKey(const ValueKey('home-search-entry')), findsOneWidget);
      return;
    }
    expect(find.byKey(const ValueKey('home-search-entry')), findsNothing);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await _frames(tester);
    expect(AppRouter.currentUri.path, AppRoute.home.path);
    expect(tester.widget<FrostCaptionSearch>(find.byType(FrostCaptionSearch)).focusNode.hasFocus, isTrue);
  });
}
