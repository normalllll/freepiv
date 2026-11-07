import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/settings/presentation/appearance_settings_section.dart';
import 'package:freepiv/features/settings/presentation/proxy_settings_dialog.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/src/rust/api/proxy.dart' as system_proxy;
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

void main() {
  testWidgets('every section fits wide and narrow windows at double text size in every language', (tester) async {
    for (final locale in AppLocale.values) {
      for (final size in [desktopSize, phoneSize]) {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        final labels = [
          t.settings.theme.title,
          t.settings.language.title,
          t.settings.images.title,
          t.settings.proxy.title,
          t.settings.downloads.title,
          t.settings.account.title,
        ];
        for (final label in labels) {
          // A fresh page each time, so a narrow window starts on the list.
          await mountPilotPage(tester, const SettingsPage(), size: size, textScale: 2, locale: locale);
          final entry = find.text(label).first;
          await tester.ensureVisible(entry);
          await tester.tap(entry);
          await settlePilot(tester, frames: 4);
          expectNoLayoutErrors(tester, where: "$label $size $locale");
        }
      }
    }
  });

  testWidgets('the sections of a narrow window sit together on a card and open with a tap', (tester) async {
    await mountPilotPage(tester, const SettingsPage(), size: phoneSize);
    expect(find.byType(FrostGroupedSection), findsOneWidget);
    expect(find.descendant(of: find.byType(FrostGroupedSection), matching: find.byType(FrostListRow)), findsNWidgets(6));
    await tester.tap(find.text(t.settings.account.title).first);
    await settlePilot(tester, frames: 4);
    expect(find.text(t.settings.images.title), findsNothing, reason: 'the section replaced the list');
  });

  testWidgets('a section opened on a narrow window starts under the header, not centred', (tester) async {
    await mountPilotPage(tester, const SettingsPage(), size: phoneSize);
    await tester.tap(find.text(t.settings.downloads.title).first);
    await settlePilot(tester, frames: 4);
    final header = tester.getBottomLeft(find.byType(FrostPageHeader)).dy;
    final section = tester.getTopLeft(find.byType(FrostGroupedSection).first).dy;
    expect(section - header, lessThan(phoneSize.height / 4));
  });

  testWidgets('closing the proxy form while the system proxy is looked up drops the answer', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final lookup = Completer<String?>();
    systemProxyLookup = () => lookup.future;
    addTearDown(() => systemProxyLookup = system_proxy.getSystemProxy);
    try {
      await mountPilotPage(tester, const SettingsPage());
      await tester.tap(find.text(t.settings.proxy.title).first);
      await settlePilot(tester, frames: 4);
      await tester.tap(find.text(t.settings.proxy.shortTitle));
      await settlePilot(tester, frames: 6);
      await tester.tap(find.text(t.settings.proxy.loadSystem));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settlePilot(tester, frames: 6);
      expect(find.text(t.settings.proxy.loadSystem), findsNothing, reason: 'the form closed');
      lookup.complete('http://127.0.0.1:7890');
      await settlePilot(tester, frames: 2);
      expect(tester.takeException(), isNull, reason: 'the closed form is not touched');
      expect(find.text(t.settings.proxy.systemLoaded), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('appearance offers the six presets and a custom colour', (tester) async {
    await mountPilotPage(tester, const SettingsPage());
    expect(find.byType(AppearanceSettingsSection), findsOneWidget);
    expect(find.byType(FrostColorSwatch), findsNWidgets(7));
  });

  testWidgets('the custom editor refuses an unreadable HEX', (tester) async {
    await mountPilotPage(tester, const SettingsPage());
    await tester.tap(find.byWidgetPredicate((widget) => widget is FrostColorSwatch && widget.label == t.settings.theme.custom));
    await settlePilot(tester, frames: 6);
    final hex = find.descendant(of: find.byType(FrostDialog), matching: find.byType(EditableText));
    await tester.enterText(hex, '#12');
    await settlePilot(tester, frames: 2);
    expect(find.text(t.settings.theme.invalidHex), findsOneWidget);
  });

  test('the settings strings exist in all four languages', () => expectLocalesComplete(['settings', 'navigationPlacement', 'signOut', 'fanbox']));
}
