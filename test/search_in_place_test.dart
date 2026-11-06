import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:frost_ui/frost_ui.dart';

Future<void> _frames(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Submits [text] from the title bar search, as Enter there would.
Future<void> _submit(WidgetTester tester, String text) async {
  final element = tester.element(find.byType(AppTitleBarSearch, skipOffstage: false));
  final ref = element as WidgetRef;
  ref.read(appSearchSessionProvider).controller.text = text;
  AppSearchActions(ref, element).submit(type: SearchType.illust);
  await _frames(tester);
}

void main() {
  for (final (name, location, firstWords) in [
    ('a result page', AppLocations.search(AppSearchKind.illust, 'miku'), 'miku'),
    ('a tag search', AppLocations.tagSearch('miku'), 'miku'),
  ]) {
    testWidgets('submitting on $name changes its words in place, in the app router', (tester) async {
      tester.view.physicalSize = const Size(1147, 717);
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

      AppRouter.router.push(location);
      await _frames(tester);
      expect(AppRouter.rightNavigatorDepth, 1);
      expect(find.byKey(ValueKey(('illust', firstWords))), findsOneWidget);

      await _submit(tester, 'rin');
      expect(AppRouter.rightNavigatorDepth, 1, reason: 'no new result page');
      expect(AppRouter.currentUri.toString(), location, reason: 'the same page, not a replacement');
      expect(find.byKey(const ValueKey(('illust', 'rin'))), findsOneWidget, reason: 'its results now show the new words');
      expect(find.byKey(ValueKey(('illust', firstWords))), findsNothing);

      // Off the result pages a submission opens one.
      AppRouter.popRightNavigator();
      await _frames(tester);
      await _submit(tester, 'len');
      expect(AppRouter.currentUri.toString(), AppLocations.search(AppSearchKind.illust, 'len'));
      expect(AppRouter.rightNavigatorDepth, 1);
    });
  }
}
