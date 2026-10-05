import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/features/fanbox/account_settings.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';

class _SignedOutSession extends FanboxSession {
  @override
  Future<String?> build() async => null;
}

void main() {
  testWidgets('FANBOX account controls have no empty error block below them', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fanboxSessionProvider.overrideWith(_SignedOutSession.new)],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
            home: const Scaffold(
              body: SingleChildScrollView(child: SizedBox(width: 480, child: FanboxAccountSettings())),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final sectionBottom = tester.getBottomLeft(find.byType(FanboxAccountSettings)).dy;
    final controlsBottom = tester.getBottomLeft(find.descendant(of: find.byType(FanboxAccountSettings), matching: find.byType(Wrap))).dy;
    expect(sectionBottom - controlsBottom, lessThan(2));
  });
}
