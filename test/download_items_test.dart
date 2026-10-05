import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/features/downloads/logic.dart';
import 'package:freepiv/features/downloads/presentation/download_dock_button.dart';
import 'package:freepiv/features/downloads/presentation/download_floating_panel.dart';
import 'package:freepiv/features/downloads/presentation/downloads_page.dart';
import 'package:freepiv/features/downloads/presentation/mobile_download_floating_window.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

const _work = ArtworkSource(illustId: 101, title: 'Summer sketches', subtitle: 'Mika');
const _article = PixivisionSource(articleId: 9, url: 'https://www.pixivision.net/en/a/9', title: 'Blue skies in illustration');
const _novel = NovelSource(novelId: 77, title: 'The lighthouse keeper', subtitle: 'Ren');
const _post = FanboxPostSource(postId: '500', title: 'March rewards', subtitle: 'Studio Kite');
const _creator = FanboxCreatorSource(creatorId: 'kite', title: 'Studio Kite');

var _clock = 0;

DownloadTaskSnapshot _task(
  DownloadSource source,
  String filename, {
  DownloadStatus status = DownloadStatus.downloaded,
  SaveState saveState = SaveState.saved,
  double progress = 1,
  DownloadPart? part,
  String? error,
}) {
  final created = DateTime(2026, 10, 5, 12, 0, _clock++);
  return DownloadTaskSnapshot(
    id: '${source.key}/$filename',
    origin: ContentFile(Uri.parse('https://example.com/$filename')),
    source: source,
    part: part,
    title: filename,
    filename: filename,
    status: status,
    saveState: saveState,
    receivedBytes: (progress * 2400000).round(),
    totalBytes: 2400000,
    progress: progress,
    localPath: saveState == SaveState.saved ? 'C:/Users/me/Downloads/freepiv/$filename' : null,
    error: error,
    log: null,
    createdAt: created,
    updatedAt: created,
  );
}

const _postA = DownloadPart(id: '1', title: 'January sketches');
const _postB = DownloadPart(id: '2', title: 'February commission');

/// A history with one item of each kind: a saved two-page work, a Pixivision
/// article still downloading, a novel image that failed, a FANBOX post, and
/// a creator still being collected.
List<DownloadTaskSnapshot> _history() {
  _clock = 0;
  return [
    _task(_work, '101_p0.png'),
    _task(_work, '101_p1.png'),
    _task(_article, 'sky_1.jpg'),
    _task(_article, 'sky_2.jpg', status: DownloadStatus.running, saveState: SaveState.none, progress: .4),
    _task(_article, 'sky_3.jpg', status: DownloadStatus.queued, saveState: SaveState.none, progress: 0),
    _task(_novel, 'cover.jpg', status: DownloadStatus.failed, saveState: SaveState.none, progress: 0, error: 'HTTP 403 · Forbidden'),
    for (var index = 0; index < 4; index++) _task(_post, '500_$index.png'),
    _task(_post, '500_files.zip', status: DownloadStatus.running, saveState: SaveState.none, progress: .7),
    _task(_creator, '1_a.png', part: _postA),
    _task(_creator, '1_b.png', part: _postA),
    _task(_creator, '2_a.png', part: _postB, status: DownloadStatus.failed, saveState: SaveState.none, progress: 0, error: 'Connection reset'),
    _task(_creator, '2_b.png', part: _postB, status: DownloadStatus.queued, saveState: SaveState.none, progress: 0),
  ];
}

class _Collecting extends FanboxDownloads {
  _Collecting(this.collecting);

  final Map<String, FanboxCollecting> collecting;

  @override
  Map<String, FanboxCollecting> build() => collecting;
}

Future<void> _loadFonts(WidgetTester tester) async {
  await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  await tester.runAsync(() async {
    for (final (family, path) in [('Roboto', 'C:/Windows/Fonts/segoeui.ttf'), ('Roboto', 'C:/Windows/Fonts/msyh.ttc')]) {
      final font = File(path);
      if (await font.exists()) await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())))).load();
    }
  });
}

Future<void> _capture(WidgetTester tester, GlobalKey boundary, String name) async {
  await tester.runAsync(() async {
    final image = await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('build/ui-review/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('download items', () {
    test('group tasks by source, newest first, keeping each part in order', () {
      final items = downloadItemsOf(_history());
      expect(items.map((item) => item.source), [_creator, _post, _novel, _article, _work]);
      final creator = items.first;
      expect(creator.parts.map((part) => part.$1), [_postA, _postB]);
      expect(creator.total, 4);
      expect(creator.completed, 2);
      expect(creator.failed, 1);
      expect(creator.state, DownloadItemState.active);
      expect(items.last.state, DownloadItemState.completed);
      expect(items.last.progress, 1);
    });

    test('a creator still collecting shows before its first file, with no progress yet', () {
      final items = downloadItemsOf(
        [_task(_work, '1_p0.png')],
        collecting: [(source: const FanboxCreatorSource(creatorId: 'new', title: 'New'), posts: 3)],
      );
      expect(items.first.source.key, 'fanboxCreator:new');
      expect(items.first.state, DownloadItemState.collecting);
      expect(items.first.collectedPosts, 3);
      expect(items.first.progress, isNull);
    });

    test('the panel puts items needing attention before finished ones', () {
      final ordered = panelOrder(downloadItemsOf(_history()));
      expect(ordered.map((item) => item.state).toList(), [
        DownloadItemState.active,
        DownloadItemState.active,
        DownloadItemState.failed,
        DownloadItemState.active,
        DownloadItemState.completed,
      ]);
    });
  });

  testWidgets('the desktop panel shows one row per item and opens the item on the downloads page', (tester) async {
    await _loadFonts(tester);
    final boundary = GlobalKey();
    String? opened;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(body: DesktopDownloadDock(railWidth: 80, taskStream: Stream.value(_history()))),
        ),
        GoRoute(
          path: AppRoute.downloads.path,
          name: AppRoute.downloads.name,
          builder: (context, state) {
            opened = state.uri.queryParameters['item'];
            return const Scaffold(body: Text('Full downloads'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(900, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fanboxDownloadsProvider.overrideWith(() => _Collecting(const {}))],
        child: TranslationProvider(
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp.router(routerConfig: router, debugShowCheckedModeBanner: false),
          ),
        ),
      ),
    );
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('desktop-download-button')));
    await _settle(tester);
    expect(find.text('Studio Kite'), findsOneWidget);
    expect(find.text('March rewards'), findsOneWidget);
    expect(find.text('Blue skies in illustration'), findsOneWidget);
    expect(find.text('The lighthouse keeper'), findsOneWidget);
    // Four rows at most; the saved work waits behind "1 more".
    expect(find.text('Summer sketches'), findsNothing);
    expect(find.text(t.settings.downloads.moreItems(count: 1)), findsOneWidget);
    expect(find.text('FANBOX · ${t.settings.downloads.filesProgress(done: 4, total: 5)}'), findsOneWidget);
    await _capture(tester, boundary, 'download-items-panel-desktop');

    await tester.tap(find.text('March rewards'));
    await _settle(tester);
    expect(find.text('Full downloads'), findsOneWidget);
    expect(opened, _post.key);
    expect(tester.takeException(), isNull);
  }, skip: Platform.isAndroid);

  testWidgets('the mobile window lists items, including a creator still being collected', (tester) async {
    await _loadFonts(tester);
    final boundary = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fanboxDownloadsProvider.overrideWith(
            () => _Collecting({'night': (source: const FanboxCreatorSource(creatorId: 'night', title: 'Night Owl Press'), posts: 12)}),
          ),
        ],
        child: TranslationProvider(
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, child) => FrostScope(config: freepivFrostConfig, child: child!),
              home: MediaQuery(
                data: const MediaQueryData(size: Size(390, 844)),
                child: FrostLayoutScope(
                  child: MobileDownloadFloatingWindow(
                    taskStream: Stream.value(_history()),
                    child: const Scaffold(body: SizedBox.expand()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
    await tester.tap(find.byType(DownloadDockButton));
    await _settle(tester);
    expect(find.text('Night Owl Press'), findsOneWidget);
    expect(find.text(t.settings.downloads.collectingPosts(count: 12)), findsOneWidget);
    await _capture(tester, boundary, 'download-items-panel-mobile');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the downloads page opens the focused item and groups a creator by post', (tester) async {
    await _loadFonts(tester);
    final boundary = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fanboxDownloadsProvider.overrideWith(() => _Collecting(const {}))],
        child: TranslationProvider(
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, child) => FrostScope(config: freepivFrostConfig, child: child!),
              home: FrostLayoutScope(
                child: DownloadsPage(focusItem: _creator.key, taskStream: Stream.value(_history())),
              ),
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
    // The creator opens to its posts; a post opens to its files.
    expect(find.text('January sketches'), findsOneWidget);
    expect(find.text('February commission'), findsOneWidget);
    expect(find.text('2_a.png'), findsNothing);
    await tester.tap(find.text('February commission'));
    await _settle(tester);
    expect(find.text('2_a.png'), findsOneWidget);
    expect(find.text('Connection reset'), findsOneWidget);
    await _capture(tester, boundary, 'download-items-page');

    // The failed filter keeps only items with a failed file.
    await tester.tap(find.text(t.settings.downloads.failed).first);
    await _settle(tester);
    expect(find.text('The lighthouse keeper'), findsOneWidget);
    expect(find.text('Summer sketches'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
