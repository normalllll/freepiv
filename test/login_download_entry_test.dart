import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/login/presentation/login_page.dart';
import 'package:frost_ui/frost_ui.dart';

void main() {
  testWidgets('signed out, the login page keeps the shell and its download entry', (tester) async {
    tester.view.physicalSize = const Size(1147, 717);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await AppSettings.initialize(store: SampleSettingsStore());
    pixivAccountNotifier.value = null;
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
    expect(AppRouter.currentUri.path, AppRoute.login.path);
    expect(find.byType(LoginPage), findsOneWidget);
    final shell = tester.widget<FrostShell>(find.byType(FrostShell));
    expect(shell.taskEntry!.visible, isTrue, reason: 'sample downloads exist');
    expect(find.byType(FrostShellTaskButton), findsOneWidget);
    expect(shell.canGoBack, isFalse, reason: 'nothing to go back to from the login page');
  });
}
