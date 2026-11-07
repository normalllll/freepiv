import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/illust/presentation/illust_info.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

void main() {
  testWidgets('a skeleton card has the loaded card\'s height, two lines and bookmark', (tester) async {
    const width = 220.0;
    const real = ValueKey('real'), bones = ValueKey('bones');
    await mountPilotPage(
      tester,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            key: real,
            width: width,
            child: AppArtworkCard(illust: illustPlaceholder(), square: true),
          ),
          const SizedBox(key: bones, width: width, child: AppArtworkCardSkeleton(aspectRatio: 1)),
        ],
      ),
    );
    expect(tester.getSize(find.byKey(bones)).height, tester.getSize(find.byKey(real)).height);
    final footer = find.descendant(of: find.byKey(bones), matching: find.byType(AppArtworkCardFooter));
    expect(footer, findsOneWidget);
    expect(find.descendant(of: footer, matching: find.byType(FrostButton)), findsOneWidget);
    expectNoLayoutErrors(tester);
  });

  group('a skeleton fills the window', () {
    Future<int> waterfallCount(WidgetTester tester, Size size) async {
      await mountPilotPage(tester, const SingleChildScrollView(child: AppArtworkWaterfallSkeleton()), size: size);
      return tester.widget<FrostWaterfallGrid<int>>(find.byType(FrostWaterfallGrid<int>)).items.length;
    }

    Future<int> rowCount(WidgetTester tester, Size size) async {
      await mountPilotPage(tester, const SingleChildScrollView(child: AppRowsSkeleton()), size: size);
      return find.bySubtype<FrostListRow>(skipOffstage: false).evaluate().length;
    }

    testWidgets('the waterfall grows with a taller and a wider window', (tester) async {
      final base = await waterfallCount(tester, desktopSize);
      expect(await waterfallCount(tester, Size(desktopSize.width, desktopSize.height * 2)), greaterThan(base));
      expect(await waterfallCount(tester, Size(desktopSize.width * 2, desktopSize.height)), greaterThan(base));
    });

    for (final size in [phoneSize, desktopSize, const Size(2000, 1400)]) {
      testWidgets('the waterfall reaches past the bottom at $size', (tester) async {
        await waterfallCount(tester, size);
        final grid = find.byType(FrostWaterfallGrid<int>);
        expect(tester.getBottomLeft(grid).dy, greaterThanOrEqualTo(size.height));
        expectNoLayoutErrors(tester);
      });

      testWidgets('the rows reach past the bottom at $size', (tester) async {
        await rowCount(tester, size);
        expect(tester.getBottomLeft(find.byType(AppRowsSkeleton)).dy, greaterThanOrEqualTo(size.height));
        expectNoLayoutErrors(tester);
      });
    }

    testWidgets('the rows grow with a taller window', (tester) async {
      expect(await rowCount(tester, Size(desktopSize.width, desktopSize.height * 2)), greaterThan(await rowCount(tester, desktopSize)));
    });

    testWidgets('a number is kept for a short fixed preview', (tester) async {
      await mountPilotPage(tester, const SingleChildScrollView(child: AppArtworkWaterfallSkeleton(count: 4, padding: EdgeInsets.zero)));
      expect(tester.widget<FrostWaterfallGrid<int>>(find.byType(FrostWaterfallGrid<int>)).items, hasLength(4));
    });
  });
}
