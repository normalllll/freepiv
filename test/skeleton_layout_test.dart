import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/ui/compositions/skeletons.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
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
        expect(tester.getSize(grid).height, greaterThan(size.height));
        expectNoLayoutErrors(tester);
      });

      testWidgets('the rows reach past the bottom at $size', (tester) async {
        await rowCount(tester, size);
        expect(tester.getSize(find.byType(AppRowsSkeleton)).height, greaterThan(size.height));
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

  group('skeleton rows have the loaded rows\' shape', () {
    const width = 720.0;

    Future<void> mountPair(WidgetTester tester, Widget real, Widget bones) => mountPilotPage(
      tester,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: width,
            key: const ValueKey('real'),
            child: Column(children: [real]),
          ),
          SizedBox(
            width: width,
            key: const ValueKey('bones'),
            child: Column(children: [bones]),
          ),
        ],
      ),
      size: const Size(width * 2, 900),
    );

    double height(WidgetTester tester, String key, Type row) =>
        tester.getSize(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(row)).first).height;

    testWidgets('a novel row with its cover', (tester) async {
      final novel = novelPlaceholder();
      await mountPair(tester, AppNovelRow(novel: novel), const AppNovelRowsSkeleton(count: 1));
      expect(height(tester, 'bones', AppNovelRow), height(tester, 'real', AppNovelRow));
      expect(find.descendant(of: find.byKey(const ValueKey('bones')), matching: find.byType(AppPixivImage)), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('novel skeletons fill a taller window', (tester) async {
      Future<int> rows(Widget skeleton, Type row, Size size) async {
        await mountPilotPage(tester, SingleChildScrollView(child: skeleton), size: size);
        return find.byType(row, skipOffstage: false).evaluate().length;
      }

      final tall = Size(desktopSize.width, desktopSize.height * 2);
      expect(await rows(const AppNovelRowsSkeleton(), AppNovelRow, tall), greaterThan(await rows(const AppNovelRowsSkeleton(), AppNovelRow, desktopSize)));
    });
  });

  testWidgets('a picture without an address is a filled bone in a skeleton and an empty frame elsewhere', (tester) async {
    bool isBone(Widget widget) => widget.runtimeType.toString() == '_SkeletonMediaFrame';
    await mountPilotPage(tester, SingleChildScrollView(child: const AppNovelRowsSkeleton(count: 1)));
    expect(find.descendant(of: find.byType(AppPixivImage), matching: find.byWidgetPredicate(isBone)), findsOneWidget);
    await mountPilotPage(tester, SingleChildScrollView(child: AppNovelRow(novel: novelPlaceholder())));
    expect(find.descendant(of: find.byType(AppPixivImage), matching: find.byWidgetPredicate(isBone)), findsNothing);
  });
}
