import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:frost_ui/frost_ui.dart';

void main() {
  testWidgets('the sample app opens on the home page with its sample works and downloads', (tester) async {
    tester.view.physicalSize = const Size(1147, 717);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await AppSettings.initialize(store: SampleSettingsStore(sampleSettings));
    pixivAccountNotifier.value = sampleAccount;
    addTearDown(() => pixivAccountNotifier.value = null);
    await tester.pumpWidget(
      FreepivApp(
        windowController: FrostWindowController(minimumSize: const Size(320, 480)),
        overrides: sampleOverrides,
      ),
    );
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(AppRouter.currentUri.path, '/');
    final shell = tester.widget<FrostShell>(find.byType(FrostShell));
    expect(shell.selectedIndex, 0);
    expect(shell.taskEntry!.visible, isTrue);
    expect(find.byType(AppArtworkCard), findsWidgets);
  });
}
