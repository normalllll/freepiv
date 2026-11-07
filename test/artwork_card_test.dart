import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/home/presentation/home_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

void main() {
  _tileTests();
  for (final locale in AppLocale.values) {
    testWidgets('a work card shows its title, its author and the bookmark under the image at double text size (${locale.languageTag})', (tester) async {
      await mountPilotPage(tester, const HomePage(), size: phoneSize, textScale: 2, locale: locale);
      expectNoLayoutErrors(tester, where: 'the home feed');
      final cards = find.byType(AppArtworkCard);
      expect(cards, findsWidgets);
      final card = cards.first;
      final illust = tester.widget<AppArtworkCard>(card).illust;
      final footer = tester.widget<AppArtworkCardFooter>(find.descendant(of: card, matching: find.byType(AppArtworkCardFooter)));
      expect((footer.title, footer.author), (illust.title, illust.user.name));
      expect(find.descendant(of: card, matching: find.text(illust.title)), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text(illust.user.name)), findsOneWidget);
      final bookmark = find.descendant(of: card, matching: find.byType(AppCardBookmarkButton));
      expect(bookmark, findsOneWidget);
      final media = tester.getRect(find.descendant(of: card, matching: find.byType(FrostMediaFrame)).first);
      expect(tester.getRect(bookmark).top, greaterThanOrEqualTo(media.bottom), reason: 'the bookmark sits with the text, not on the image');
      expect(tester.getRect(bookmark).right, closeTo(tester.getRect(card).right, 1), reason: 'at the end of the text');
    });
  }
}

void _tileTests() {
  testWidgets('a Recent works tile is the square image alone; the large card keeps title, author and bookmark', (tester) async {
    final works = sampleIllusts(count: 2);
    await mountPilotPage(
      tester,
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: AppArtworkCard.tile(key: const ValueKey('tile'), illust: works[0])),
            SizedBox(width: 240, child: AppArtworkCard(key: const ValueKey('card'), illust: works[1])),
          ],
        ),
      ),
    );
    final tile = find.byKey(const ValueKey('tile'));
    expect(find.descendant(of: tile, matching: find.byType(AppArtworkCardFooter)), findsNothing);
    expect(find.descendant(of: tile, matching: find.text(works[0].title)), findsNothing);
    expect(find.descendant(of: tile, matching: find.text(works[0].user.name)), findsNothing);
    expect(find.descendant(of: tile, matching: find.byType(AppCardBookmarkButton)), findsNothing);
    expect(tester.getSize(tile), const Size(120, 120), reason: 'square, no text below');
    expect(find.descendant(of: tile, matching: find.byType(FrostBadge)), findsWidgets, reason: 'the corner marks stay');

    final card = find.byKey(const ValueKey('card'));
    expect(find.descendant(of: card, matching: find.text(works[1].title)), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text(works[1].user.name)), findsOneWidget);
    expect(find.descendant(of: card, matching: find.byType(AppCardBookmarkButton)), findsOneWidget);
  });
}
