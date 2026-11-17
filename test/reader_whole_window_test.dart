import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/immersive_pages.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/novel_download_source.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_top_bar.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reader_page.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

class _Window extends ChangeNotifier implements FrostWindowActions {
  @override
  FrostCaptionState get captionState => const FrostCaptionState(maximized: false, active: true, maximizeHovered: false, maximizePressed: false, failed: false);
  @override
  void updateHitRegions(List<FrostHitRegion> regions) {}
  @override
  Future<void> minimize() async {}
  @override
  Future<void> toggleMaximized() async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> retry() async {}
}

Widget _shelled(Widget page) => FrostWindowCaptionScope(window: _Window(), child: _shell(page));

Widget _shell(Widget page) => FrostShell(
  brand: const FrostShellBrand(expanded: FrostText('Brandname')),
  destinations: const [
    FrostNavDestination(icon: FrostIconData.glyph(IconData(0xe000)), label: 'Home'),
    FrostNavDestination(icon: FrostIconData.glyph(IconData(0xe001)), label: 'Find'),
  ],
  selectedIndex: 0,
  atDestinationRoot: false,
  onDestinationSelected: (_) {},
  canGoBack: true,
  onBack: () {},
  showsMobileNavigation: true,
  child: FrostShellDestination(child: page),
);

Future<void> _mount(WidgetTester tester, Size size) async {
  await readerStorageIdle(tester);
  final novel = sampleNovels(count: 1, title: 'A novel').single;
  await mountPilotPage(
    tester,
    _shelled(
      DownloadSourceScope(
        source: novelDownloadSource(novel),
        child: NovelReaderContent(
          detail: NovelDetailData(novel: novel, webviewNovel: readerText(readerChapters())),
        ),
      ),
    ),
    size: size,
    settings: {...sampleSettings, ...readerScrollSettings},
  );
  await readerStorageIdle(tester);
  await settlePilot(tester);
}

void main() {
  group('the reader and the window', () {
    testWidgets('beside a sidebar the reader has the whole window with its top bar in the title row', (tester) async {
      await _mount(tester, const Size(1147, 717));
      expect(find.byType(FrostNavItem), findsNothing);
      expect(find.text('Brandname'), findsNothing);
      expect(tester.getTopLeft(find.byType(NovelReaderContent)), Offset.zero);
      expect(find.byType(ReaderTitleRow), findsOneWidget);
      expect(find.byType(ReaderTopBar), findsNothing, reason: 'the title row hosts the top bar');

      readerState(tester).chrome.show();
      await settlePilot(tester);
      expect(find.byKey(const ValueKey('reader-more')), findsOneWidget);
      expect(tester.getRect(find.byKey(const ValueKey('reader-more'))).top, lessThan(48));
      expect(immersivePageCount.value, 0, reason: 'the sidebar layout needs no marker');
    });

    testWidgets('on a phone the top bar stays over the text and the page marks itself immersive', (tester) async {
      await _mount(tester, const Size(390, 844));
      expect(find.byType(FrostNavItem), findsNothing);
      readerState(tester).chrome.show();
      await settlePilot(tester);
      expect(find.byType(ReaderTopBar), findsOneWidget);
      expect(tester.getSize(find.byType(ReaderTitleRow)).height, 0, reason: 'the title row takes no room over the text');
      expect(immersivePageCount.value, 1);
    });

    testWidgets('the page makes popovers solid', (tester) async {
      await _mount(tester, const Size(1147, 717));
      final context = tester.element(find.byType(ReaderTitleRow));
      expect(context.findAncestorWidgetOfExactType<FrostSolidMaterial>(), isNotNull);
      final reading = tester.element(find.byType(NovelReaderContent).first);
      expect(reading.findAncestorWidgetOfExactType<FrostSolidMaterial>(), isNull, reason: 'the content sits inside, not above, the material');
    });
  });
}
