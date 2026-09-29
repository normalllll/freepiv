import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/layout/fp_pinned_chrome.dart';
import 'package:freepiv/shared/ui/fp_ambient_backdrop.dart';
import 'package:freepiv/shared/widgets/floating_filter_sliver.dart';

Future<void> _pumpBar(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en')),
        home: AppLayoutScope(
          child: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 48,
                child: PinnedChromeGlass(
                  opacity: 1,
                  child: InkWell(key: const ValueKey('bar-content'), onTap: () {}, child: const SizedBox.expand()),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('floating filters reveal from visible overlap on reverse scroll', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AppLayoutScope(
            child: Scaffold(
              body: CustomScrollView(
                controller: controller,
                slivers: const [
                  FloatingFilterSliver(height: 62, child: SizedBox.expand()),
                  SliverToBoxAdapter(child: SizedBox(height: 2000)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    double glass() => tester.widget<PinnedChromeGlass>(find.byType(PinnedChromeGlass, skipOffstage: false)).opacity;
    expect(glass(), 0);
    controller.jumpTo(200);
    await tester.pump();
    expect(glass(), 0, reason: 'a hidden filter has no glass to reveal');
    controller.position.pointerScroll(-12);
    await tester.pump();
    expect(glass(), closeTo(.5, .01), reason: '12 px of the floating bar now overlaps content');
    await tester.pump(const Duration(milliseconds: 500));
    expect(glass(), closeTo(.5, .01), reason: 'stopping does not complete a timed fade');
    controller.position.pointerScroll(-12);
    await tester.pump();
    expect(glass(), 1);
    controller.position.pointerScroll(12);
    await tester.pump();
    expect(glass(), closeTo(.5, .01));
    controller.jumpTo(0);
    await tester.pump();
    expect(glass(), 0);
  });

  testWidgets('desktop bar content is clipped to the floating glass and its margins are masked', (tester) async {
    await _pumpBar(tester, 1280);
    final content = find.byKey(const ValueKey('bar-content'));
    // Hover and press highlights cannot spill past the rounded panel.
    final clip = tester.widget<ClipPath>(find.ancestor(of: content, matching: find.byType(ClipPath)).first);
    final path = clip.clipper!.getClip(const Size(1280, 48));
    expect(path.contains(const Offset(1, 24)), isFalse, reason: 'left margin');
    expect(path.contains(const Offset(1275, 24)), isFalse, reason: 'right margin');
    expect(path.contains(const Offset(640, 24)), isTrue);
    expect(path.contains(const Offset(5, 1)), isFalse, reason: 'rounded corner');
    // Page tab bars start exactly at the glass edge, so the first tab's hover
    // highlight meets it with no unlit strip; its label stays on the inset.
    final tabStart = AppMetrics.pageTabInset(1280);
    expect(path.contains(Offset(tabStart + .5, 24)), isTrue);
    expect(path.contains(Offset(tabStart - .5, 24)), isFalse);
    expect(tabStart + AppMetrics.tabLabelPadding(1280), AppMetrics.browseInset(1280));
    // The margins show the window background instead of content beneath.
    expect(find.byType(FpAmbientBackdrop), findsOneWidget);
  });

  testWidgets('compact bar stays edge to edge without a mask', (tester) async {
    await _pumpBar(tester, 390);
    final content = find.byKey(const ValueKey('bar-content'));
    expect(find.ancestor(of: content, matching: find.byType(ClipPath)), findsNothing);
    expect(find.byType(FpAmbientBackdrop), findsNothing);
  });

  testWidgets('the pinned glass follows the first 24 px of scrolling', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(platform: TargetPlatform.android, locale: const Locale('en')),
          home: AppLayoutScope(
            child: Scaffold(
              body: FpPinnedChrome(
                extent: 48,
                chrome: const SizedBox.shrink(),
                body: CustomScrollView(
                  slivers: [
                    const FpChromeSpacer(),
                    SliverList.builder(itemCount: 40, itemBuilder: (context, index) => const SizedBox(height: 60)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    double glass() => tester.widget<Opacity>(find.descendant(of: find.byType(PinnedChromeGlass), matching: find.byType(Opacity)).first).opacity;
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    expect(glass(), 0);
    scroll.jumpTo(12);
    await tester.pump();
    expect(glass(), closeTo(.5, .01), reason: 'halfway through the reveal distance');
    scroll.jumpTo(200);
    await tester.pump();
    expect(glass(), 1);
    scroll.jumpTo(0);
    await tester.pump();
    expect(glass(), 0);
  });
}
