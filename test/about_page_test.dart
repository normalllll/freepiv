import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/updater_service.dart';
import 'package:freepiv/features/about/presentation/about_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/pilot_harness.dart';

final _opened = <String>[];

Future<PackageInfo> _info() async => PackageInfo(appName: 'freepiv', packageName: 'io.github.normalllll.freepiv', version: '1.2.3', buildNumber: '45');

Future<void> _mount(WidgetTester tester, Future<AppUpdateInfo?> Function() check, {Size size = desktopSize, double textScale = 1}) {
  _opened.clear();
  return mountPilotPage(
    tester,
    AboutPage(
      packageInfo: _info,
      checkForUpdate: check,
      openUrl: (url) async {
        _opened.add(url);
        return true;
      },
    ),
    size: size,
    textScale: textScale,
  );
}

void main() {
  testWidgets('the app, its version and build head the page; each link opens outside', (tester) async {
    await _mount(tester, () async => null);
    expect(find.text(t.about.currentVersion(version: '1.2.3', buildNumber: '45')), findsOneWidget);
    for (final (label, url) in [
      (t.about.projectPage, UpdaterService.projectUrl),
      (t.about.releasePage, UpdaterService.latestReleaseUrl),
      (t.about.telegram, 'https://t.me/+ONtNV3HTQ0NhMzVh'),
      (t.about.discord, 'https://discord.gg/jQatz6965H'),
    ]) {
      await tester.tap(find.text(label));
      await settlePilot(tester);
      expect(_opened.last, url);
    }
  });

  testWidgets('checking shows the dots and asks once; the row then says it is up to date', (tester) async {
    final answer = Completer<AppUpdateInfo?>();
    var checks = 0;
    await _mount(tester, () {
      checks++;
      return answer.future;
    });
    await tester.tap(find.text(t.about.checkUpdate));
    await tester.pump();
    expect(find.descendant(of: find.byKey(const ValueKey('about-check-update')), matching: find.byType(FrostActivityIndicator)), findsOneWidget);
    await tester.tap(find.text(t.about.checkUpdate));
    await tester.pump();
    expect(checks, 1, reason: 'a second tap while checking asks nothing');
    answer.complete(null);
    await settlePilot(tester);
    expect(find.descendant(of: find.byKey(const ValueKey('about-check-update')), matching: find.byType(FrostActivityIndicator)), findsNothing);
    expect(find.text(t.about.noUpdate), findsOneWidget);
  });

  testWidgets('a newer release shows its version and opens its page', (tester) async {
    await _mount(tester, () async => const AppUpdateInfo(version: '9.9.9', buildNumber: 99, releaseUrl: 'https://example.test/release', assets: []));
    await tester.tap(find.text(t.about.checkUpdate));
    await settlePilot(tester);
    expect(find.text(t.about.updateAvailable(version: '9.9.9', buildNumber: 99)), findsOneWidget);
    expect(_opened, ['https://example.test/release'], reason: 'no asset for the test platform: the release page');
  });

  testWidgets('a failed check says so in the row and retries from there', (tester) async {
    var attempts = 0;
    await _mount(tester, () async {
      if (attempts++ == 0) throw StateError('offline');
      return null;
    });
    await tester.tap(find.text(t.about.checkUpdate));
    await settlePilot(tester);
    expect(find.text(t.about.checkUpdateFailed), findsOneWidget);
    expect(find.text(t.common.errorWithCause(message: t.about.checkUpdateFailed, cause: t.errors.generic)), findsOneWidget, reason: 'the toast gives the cause');
    await tester.tap(find.text(t.common.retry));
    await settlePilot(tester);
    expect(attempts, 2);
    expect(find.text(t.about.noUpdate), findsOneWidget);
    expect(find.text(t.about.checkUpdateFailed), findsNothing);
  });

  testWidgets('fits a phone at double text size', (tester) async {
    await _mount(tester, () async => throw StateError('offline'), size: phoneSize, textScale: 2);
    await tester.tap(find.text(t.about.checkUpdate));
    await settlePilot(tester);
    expectNoLayoutErrors(tester);
  });

  test('the About strings exist in all four languages', () => expectLocalesComplete(['about']));
}
