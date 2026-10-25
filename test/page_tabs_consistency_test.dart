import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/fanbox/navigation.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_tab_scaffold.dart';
import 'package:freepiv/i18n/strings.g.dart';

void main() {
  testWidgets('FANBOX filter header fits at 390 width with doubled text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844), textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  final layout = fanboxNavigationLayout(context, 390);
                  return SizedBox(
                    height: layout.height,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
                      child: FanboxSectionNavigation(section: FanboxSection.home, onSelected: (_) {}),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(fanboxNavigationLayout(tester.element(find.byType(FanboxSectionNavigation)), 390).stacked, isFalse);
    expect(
      tester.getRect(find.byType(TabBar)).center.dy,
      closeTo(tester.getRect(find.descendant(of: find.byType(FanboxSectionNavigation), matching: find.byType(TextButton))).center.dy, 16),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('FANBOX group tabs track selected collection without changing the collection selector', (tester) async {
    LocaleSettings.setLocale(AppLocale.enUs);
    var section = FanboxSection.home;
    late StateSetter update;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return FanboxSectionNavigation(section: section, onSelected: (selected) => setState(() => section = selected));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tabs = find.byType(TabBar);
    expect(tester.widget<TabBar>(tabs).controller!.index, 0);
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(section, FanboxSection.recommended);
    expect(tester.widget<TabBar>(tabs).controller!.index, 1);
    update(() => section = FanboxSection.bookmarks);
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(tabs).controller!.index, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('author tabs share page tab geometry and remain reachable at narrow widths', (tester) async {
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.runAsync(() async {
      final systemFont = File('C:/Windows/Fonts/segoeui.ttf');
      if (await systemFont.exists()) {
        final bytes = await systemFont.readAsBytes();
        await (FontLoader('Segoe UI')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final tabs = [
      for (final (index, label) in ['Illustrations', 'Manga', 'Novels', 'Bookmarks', 'Following', 'Profile'].indexed)
        UserDetailTabItem(kind: index, label: label, icon: Icons.image_outlined),
    ];
    for (final width in [390.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 844);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
            home: DefaultTabController(
              length: tabs.length,
              child: Builder(
                builder: (context) => RepaintBoundary(
                  key: boundary,
                  child: Scaffold(
                    body: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: UserDetailTabBar(tabs: tabs, controller: DefaultTabController.of(context)),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 1000)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.isScrollable, isTrue);
      expect(tabBar.tabAlignment, TabAlignment.start);
      // The theme owns the rounded accent indicator; page tab bars only set
      // the shared label padding.
      final indicator = Theme.of(tester.element(find.byType(TabBar))).tabBarTheme.indicator;
      expect(indicator, isA<UnderlineTabIndicator>().having((it) => it.borderSide.width, 'width', FrostMetrics.selectionIndicatorWidth));
      expect(tabBar.indicator, isNull);
      expect(tabBar.labelPadding, EdgeInsets.symmetric(horizontal: FrostMetrics.tabLabelPadding(width)));
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final file = File('build/ui-review/author-tabs-${width.toInt()}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
      });
      if (width < 600) {
        await tester.drag(find.byType(TabBar), const Offset(-1000, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(DefaultTabController.of(tester.element(find.byType(TabBar))).index, 5);
      }
    }
  });
}
