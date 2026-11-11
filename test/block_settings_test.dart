import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/block/block_list.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

Map<String, dynamic> _settingsWith(BlockList blocks) => {...sampleSettings, 'blockList': blocks.toJson()};

Future<void> _openBlockSection(
  WidgetTester tester, {
  BlockList blocks = const BlockList(),
  Size size = desktopSize,
  double textScale = 1,
  AppLocale locale = AppLocale.enUs,
}) async {
  await mountPilotPage(tester, const SettingsPage(), size: size, textScale: textScale, locale: locale, settings: _settingsWith(blocks));
  await tester.tap(find.text(t.block.title).first);
  await settlePilot(tester, frames: 4);
}

Finder _removeButton(String name) => find.byWidgetPredicate((widget) => widget is FrostButton && widget.label == t.block.remove(name: name));

Finder get _dialogField => find.descendant(of: find.byType(FrostDialog), matching: find.byType(EditableText));

void main() {
  testWidgets('the section sits between browsing history and accounts and says it only applies on this device', (tester) async {
    await _openBlockSection(tester);

    final order = [
      for (final label in [t.history.title, t.block.title, t.settings.account.title]) tester.getTopLeft(find.text(label).first).dy,
    ];
    expect(order[0], lessThan(order[1]));
    expect(order[1], lessThan(order[2]));
    expect(find.text(t.block.localOnly), findsOneWidget);
    expect(find.text(t.block.emptyTags), findsOneWidget);
    expect(find.text(t.block.emptyUsers), findsOneWidget);
  });

  testWidgets('lists the blocked tags and users and each can be removed', (tester) async {
    await _openBlockSection(
      tester,
      blocks: const BlockList().withTag('landscape').withTag('オリジナル').withUser(const BlockedUser(id: 2000, name: 'Sample artist')),
    );

    expect(find.text('#landscape'), findsOneWidget);
    expect(find.text('#オリジナル'), findsOneWidget);
    expect(find.text('Sample artist'), findsOneWidget);
    expect(find.text('${t.common.id} 2000'), findsOneWidget);
    expect(find.text(t.block.emptyTags), findsNothing);

    await tester.tap(_removeButton('landscape'));
    await settlePilot(tester, frames: 2);
    expect(AppSettings.blockList.tags, ['オリジナル']);
    expect(find.text('#landscape'), findsNothing);

    await tester.tap(_removeButton('Sample artist'));
    await settlePilot(tester, frames: 2);
    expect(AppSettings.blockList.users, isEmpty);
    expect(find.text(t.block.emptyUsers), findsOneWidget);
  });

  testWidgets('Add a tag asks for it and blocks it', (tester) async {
    await _openBlockSection(tester);

    await tester.tap(find.text(t.block.addTag));
    await settlePilot(tester, frames: 6);
    await tester.enterText(_dialogField, '  Sample Tag ');
    await tester.tap(find.descendant(of: find.byType(FrostDialog), matching: find.text(t.block.add)));
    await settlePilot(tester, frames: 6);

    expect(AppSettings.blockList.tags, ['Sample Tag'], reason: 'the tag as typed, without the spaces around it');
    expect(find.byType(FrostDialog), findsNothing);
    expect(find.text('#Sample Tag'), findsOneWidget);
  });

  testWidgets('a tag typed with a leading # is stored without it, and one that is blocked that way is refused', (tester) async {
    await _openBlockSection(tester, blocks: const BlockList().withTag('landscape'));

    await tester.tap(find.text(t.block.addTag));
    await settlePilot(tester, frames: 6);
    await tester.enterText(_dialogField, ' ##猫');
    await tester.tap(find.descendant(of: find.byType(FrostDialog), matching: find.text(t.block.add)));
    await settlePilot(tester, frames: 6);

    expect(AppSettings.blockList.tags, ['landscape', '猫']);
    expect(find.text('#猫'), findsOneWidget, reason: 'shown with the # a tag is shown with, stored without');

    await tester.tap(find.text(t.block.addTag));
    await settlePilot(tester, frames: 6);
    await tester.enterText(_dialogField, '#landscape');
    await tester.tap(find.descendant(of: find.byType(FrostDialog), matching: find.text(t.block.add)));
    await settlePilot(tester, frames: 4);
    expect(find.text(t.block.tagExists), findsOneWidget);
    expect(AppSettings.blockList.tags, ['landscape', '猫']);
  });

  testWidgets('a tag that is empty or already blocked keeps the form open with the reason', (tester) async {
    await _openBlockSection(tester, blocks: const BlockList().withTag('landscape'));

    await tester.tap(find.text(t.block.addTag));
    await settlePilot(tester, frames: 6);
    await tester.tap(find.descendant(of: find.byType(FrostDialog), matching: find.text(t.block.add)));
    await settlePilot(tester, frames: 4);
    expect(find.text(t.block.tagRequired), findsOneWidget);

    await tester.enterText(_dialogField, 'landscape');
    await settlePilot(tester, frames: 2);
    expect(find.text(t.block.tagRequired), findsNothing, reason: 'typing clears the reason');
    await tester.tap(find.descendant(of: find.byType(FrostDialog), matching: find.text(t.block.add)));
    await settlePilot(tester, frames: 4);
    expect(find.text(t.block.tagExists), findsOneWidget);
    expect(AppSettings.blockList.tags, ['landscape']);
    expect(find.byType(FrostDialog), findsOneWidget);
  });

  testWidgets('the section fits wide and narrow windows at double text size in every language', (tester) async {
    final blocks = const BlockList().withTag(longText).withUser(BlockedUser(id: 2000, name: longText));
    for (final locale in AppLocale.values) {
      for (final size in [desktopSize, phoneSize]) {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        await mountPilotPage(tester, const SettingsPage(), size: size, textScale: 2, locale: locale, settings: _settingsWith(blocks));
        await tester.tap(find.text(t.block.title).first);
        await settlePilot(tester, frames: 4);
        expectNoLayoutErrors(tester, where: 'the block section $size $locale');
      }
    }
  });

  testWidgets('every block string is in all four languages', (tester) async {
    expectLocalesComplete(['block']);
  });
}
