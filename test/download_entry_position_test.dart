import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/downloads/presentation/download_entry.dart';
import 'package:frost_ui/frost_ui.dart';

const _key = 'downloadEntryPosition';

Future<void> _mountPhone(WidgetTester tester, SampleSettingsStore store) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await AppSettings.initialize(store: store);
  pixivAccountNotifier.value = sampleAccount;
  addTearDown(() => pixivAccountNotifier.value = null);
  AppRouter.router.go(AppRoute.home.path);
  await tester.pumpWidget(
    FreepivApp(
      windowController: FrostWindowController(minimumSize: const Size(320, 480)),
      overrides: sampleOverrides,
    ),
  );
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

FrostShellTaskEntry _entry(WidgetTester tester) => tester.widget<FrostShell>(find.byType(FrostShell)).taskEntry!;

void main() {
  test('the entry starts where it was left and saves where it is moved', () async {
    final store = SampleSettingsStore({
      _key: {'edge': 'start', 'fraction': .25},
    });
    await AppSettings.initialize(store: store);
    final entry = appDownloadTaskEntry(DownloadActivity.empty, revealed: true);
    expect(entry.initialFloatingPosition, const FrostFloatingEntryPosition(edge: FrostFloatingEntryEdge.start, fraction: .25));

    entry.onFloatingPositionChanged!(const FrostFloatingEntryPosition(edge: FrostFloatingEntryEdge.end, fraction: .6));
    expect(store.values[_key], {'edge': 'end', 'fraction': .6});

    // The next launch reads it back.
    await AppSettings.initialize(store: SampleSettingsStore(store.values));
    expect(appDownloadTaskEntry(DownloadActivity.empty, revealed: true).initialFloatingPosition, const FrostFloatingEntryPosition(fraction: .6));
  });

  test('an unreadable saved position falls back to the default corner', () async {
    await AppSettings.initialize(
      store: SampleSettingsStore({
        _key: {'edge': 'left', 'fraction': 3},
      }),
    );
    expect(appDownloadTaskEntry(DownloadActivity.empty, revealed: true).initialFloatingPosition, const FrostFloatingEntryPosition());
  });

  testWidgets('in the phone layout the dragged button is saved and comes back on the next launch', (tester) async {
    final store = SampleSettingsStore({
      ...sampleSettings,
      _key: {'edge': 'end', 'fraction': .5},
    });
    await _mountPhone(tester, store);
    final button = find.byType(FrostShellTaskButton);
    expect(button, findsOneWidget);
    expect(tester.getCenter(button).dx, greaterThan(195), reason: 'it starts at the saved end edge');

    await tester.drag(button, const Offset(-300, 0));
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.getCenter(button).dx, lessThan(195));
    final saved = store.values[_key] as Map;
    expect(saved['edge'], 'start', reason: 'the move is saved');

    await tester.pumpWidget(const SizedBox());
    await _mountPhone(tester, SampleSettingsStore(store.values));
    expect(_entry(tester).initialFloatingPosition.edge, FrostFloatingEntryEdge.start);
    expect(tester.getCenter(find.byType(FrostShellTaskButton)).dx, lessThan(195), reason: 'it comes back where it was left');
  });
}
