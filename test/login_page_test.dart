import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/login/presentation/login_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

void main() {
  testWidgets('one task in the middle: sign in in the browser, with the proxy settings beside it', (tester) async {
    await mountPilotPage(tester, const LoginPage(), signedIn: false);
    expect(find.text(t.loginPage.signIn), findsOneWidget);
    expect(find.text(t.settings.proxy.open), findsOneWidget);
    await tester.tap(find.text(t.settings.proxy.open));
    await settlePilot(tester);
    expect(find.text(t.settings.proxy.save), findsOneWidget, reason: 'the proxy form opens');
  });

  testWidgets('fits a phone at double text size in every language', (tester) async {
    for (final locale in AppLocale.values) {
      await mountPilotPage(tester, const LoginPage(), signedIn: false, size: phoneSize, textScale: 2, locale: locale);
      expectNoLayoutErrors(tester, where: '$locale');
      expect(find.byType(FrostButton), findsWidgets);
    }
  });

  test('the login strings exist in all four languages', () => expectLocalesComplete(['loginPage', 'login']));
}
