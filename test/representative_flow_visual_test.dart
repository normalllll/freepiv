import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/shared/layout/fp_page_header.dart';
import 'package:freepiv/shared/layout/fp_pinned_chrome.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_route_pages.dart' as pages;
import 'package:freepiv/app/router/navigator_stack_observer.dart';
import 'package:freepiv/app/router_shell.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/app/window/native_window.dart';
import 'package:freepiv/app/window/window_title.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/core/downloads/download_manager.dart';
import 'package:freepiv/features/downloads/presentation/downloads_page.dart';
import 'package:freepiv/features/home/logic/home_logic.dart';
import 'package:freepiv/features/home/presentation/home_page.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/illust_detail_page.dart';
import 'package:freepiv/features/illust/presentation/illust_related_page.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_related_section.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_image_viewer.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_detail_layout.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/ui/fp_icon.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:go_router/go_router.dart';

class _LocalHomeSource extends HomeIllustListSource {
  _LocalHomeSource(this.works) : super(illustType: IllustType.illust);

  final List<Illust> works;
  int loadCount = 0;

  @override
  Future<IllustPageResult> loadFirstPage() async {
    loadCount++;
    return IllustPageResult(illusts: works, rankingIllusts: works.take(5).toList());
  }
}

class _LocalRelatedSource extends IllustRelatedListSource {
  _LocalRelatedSource(int illustId, this.works) : super(illustId: illustId);

  final List<Illust> works;

  @override
  Future<IllustPageResult> loadFirstPage() async => IllustPageResult(illusts: works, rankingIllusts: const []);
}

class _LocalRelatedWorks extends IllustRelatedWorks {
  _LocalRelatedWorks(this.works);

  final List<Illust> works;

  @override
  IllustRelatedListSource build(int illustId) => _LocalRelatedSource(illustId, works);
}

class _LocalUserWorks extends IllustUserWorks {
  _LocalUserWorks(this.works);

  final List<Illust> works;

  @override
  Future<IllustPageResult> build(int userId) async => IllustPageResult(illusts: works, rankingIllusts: const []);
}

class _LocalIllustDetail extends IllustDetail {
  _LocalIllustDetail(this.works);

  final List<Illust> works;

  @override
  FutureOr<Illust> build(IllustDetailArgs args) => works.firstWhere((work) => work.id == args.resolvedIllustId);
}

class _LocalMediaTransport extends RustMediaTransport {
  _LocalMediaTransport(this.images) : super(null);

  final Map<String, Uint8List> images;
  int streamCount = 0;

  @override
  Stream<rust.MediaChunk> stream(String url, Map<String, String> headers) {
    streamCount++;
    final bytes = images[url]!;
    return Stream.value(rust.MediaChunk(bytes: bytes, received: bytes.length, total: bytes.length));
  }
}

const _secondTitle = 'A long walk through violet fields · 紫の草原を歩くとき、光と影が静かに重なる / Color, distance and memory across the hills';

Illust _work(int id, {int pageCount = 1}) {
  final image = 'https://fixtures.example.test/art/$id.png';
  return Illust(
    id: id,
    title: switch (id) {
      101 => 'Afternoon color study',
      102 => _secondTitle,
      _ => 'Artwork $id · light and shape',
    },
    kind: 'illust',
    imageUrls: ImageUrls(squareMedium: image, medium: image, large: image, original: image),
    caption: 'A local artwork fixture for visual review. Soft light, vivid color and a calm composition.',
    restrict: 0,
    user: const User(
      id: 7,
      name: 'Sample artist',
      account: 'sample_artist',
      profileImageUrls: ProfileImageUrls(medium: 'https://fixtures.example.test/avatar.png'),
    ),
    tags: const [
      Tag(name: 'landscape'),
      Tag(name: 'color'),
      Tag(name: 'illustration'),
    ],
    tools: const [],
    createDate: '2026-01-17T10:30:00+00:00',
    pageCount: pageCount,
    width: 720,
    height: 960,
    sanityLevel: 2,
    xRestrict: 0,
    metaSinglePage: MetaSinglePage(originalImageUrl: image),
    metaPages: pageCount == 1
        ? const []
        : [
            for (var page = 0; page < pageCount; page++)
              MetaPage(
                imageUrls: ImageUrls(squareMedium: image, medium: image, large: image, original: image),
              ),
          ],
    totalView: 3120 + id,
    totalBookmarks: 407 + id,
    isBookmarked: false,
    visible: true,
    isMuted: false,
    totalComments: 0,
    illustAiType: 0,
  );
}

Future<Uint8List> _artBytes(int index) async {
  const width = 360.0;
  const height = 480.0;
  const palettes = [
    [Color(0xff476ccb), Color(0xffffc779), Color(0xffff678e)],
    [Color(0xff506d90), Color(0xff83c5bc), Color(0xffffda9e)],
    [Color(0xff845ec2), Color(0xffd65db1), Color(0xffff9671)],
    [Color(0xff335c67), Color(0xff9ecca4), Color(0xffffe7a5)],
  ];
  final colors = palettes[index % palettes.length];
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(width, height), colors, [0, .55, 1]),
  );
  canvas.drawCircle(Offset(250 - index % 3 * 27, 115 + index % 4 * 16), 86, Paint()..color = colors[2].withValues(alpha: .85));
  final ridge = Path()
    ..moveTo(0, 340)
    ..quadraticBezierTo(125, 170, 215, 322)
    ..quadraticBezierTo(293, 250, width, 310)
    ..lineTo(width, height)
    ..lineTo(0, height)
    ..close();
  canvas.drawPath(ridge, Paint()..color = colors[0].withValues(alpha: .88));
  canvas.drawPath(
    Path()
      ..moveTo(0, 390)
      ..quadraticBezierTo(200, 300, width, 420)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close(),
    Paint()..color = colors[1].withValues(alpha: .9),
  );
  final image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<void> _capture(GlobalKey boundary, String name) async {
  final image = await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File(Platform.isAndroid ? '${Directory.systemTemp.path}/representative-$name.png' : 'build/ui-review/representative-$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data!.buffer.asUint8List());
}

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('compact illustration glass follows title overlap and preserves narrow scroll across the split breakpoint', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.enUs));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, (call) async => Directory('build/ui-review/cache').absolute.path);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, null));
    final work = _work(101, pageCount: 2);
    final bytes = await tester.runAsync(() => _artBytes(0));
    final media = _LocalMediaTransport({work.imageUrls.large: bytes!, 'https://fixtures.example.test/avatar.png': bytes});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          illustRelatedWorksProvider(work.id).overrideWith(() => _LocalRelatedWorks(const [])),
          illustUserWorksProvider(work.user.id).overrideWith(() => _LocalUserWorks(const [])),
          rustMediaTransportProvider.overrideWithValue(media),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
            home: AppLayoutScope(child: IllustDetailContent(illust: work)),
          ),
        ),
      ),
    );
    await _pumpRoute(tester);
    final narrow = find.byType(MobileIllustDetailLayout);
    final scroll = find
        .descendant(of: narrow, matching: find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down))
        .first;
    ScrollPosition position() => tester.state<ScrollableState>(scroll).position;
    double glass() => tester.widget<PinnedChromeGlass>(find.descendant(of: narrow, matching: find.byType(PinnedChromeGlass))).opacity;
    expect(glass(), 0, reason: 'no empty strip over the artwork');
    final bodyTitle = find.byWidgetPredicate((widget) => widget is SelectableText && widget.data == work.title);
    final titleTop = tester.getTopLeft(bodyTitle).dy;
    final barBottom = tester.getBottomLeft(find.descendant(of: narrow, matching: find.byType(PinnedChromeGlass))).dy;
    final threshold = titleTop - barBottom + 8;
    position().jumpTo(threshold + 12);
    await tester.pump();
    expect(glass(), closeTo(.5, .01));
    await tester.pump(const Duration(milliseconds: 500));
    expect(glass(), closeTo(.5, .01), reason: 'paused scroll does not complete a timed fade');
    position().jumpTo(threshold + 24);
    await tester.pump();
    expect(glass(), 1);
    position().jumpTo(threshold + 6);
    await tester.pump();
    expect(glass(), closeTo(.25, .01), reason: 'reverse scroll uses the same continuous distance');
    final savedOffset = position().pixels;
    final pagerElement = tester.element(find.byType(IllustImagePager));
    final pageView = find.descendant(of: find.byType(IllustImagePager), matching: find.byType(PageView));
    final pageViewState = tester.state(pageView);
    tester.widget<PageView>(pageView).controller!.jumpToPage(1);
    await tester.pump();
    expect(tester.widget<IllustImagePager>(find.byType(IllustImagePager)).pageIndex, 1);
    tester.view.physicalSize = const Size(1280, 900);
    await _pumpRoute(tester);
    expect(find.byType(DesktopIllustDetailLayout), findsOneWidget);
    expect(tester.element(find.byType(IllustImagePager)), same(pagerElement), reason: 'layout changes retain the active image pager');
    expect(tester.state(pageView), same(pageViewState));
    expect(tester.widget<IllustImagePager>(find.byType(IllustImagePager)).pageIndex, 1);
    tester.view.physicalSize = const Size(390, 844);
    await _pumpRoute(tester);
    expect(position().pixels, closeTo(savedOffset, .01));
    expect(tester.element(find.byType(IllustImagePager)), same(pagerElement));
    expect(tester.state(pageView), same(pageViewState));
    expect(tester.widget<IllustImagePager>(find.byType(IllustImagePager)).pageIndex, 1);
    expect(glass(), closeTo(.25, .01));
    position().jumpTo(0);
    await tester.pump();
    expect(glass(), 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('actual home, detail, related and second detail flow has one shell back control', (tester) async {
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    const nativeWindowChannel = MethodChannel('desktop_window');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(nativeWindowChannel, (call) async => call.method == 'getState' ? <String, Object>{} : null);
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(nativeWindowChannel, null));
    final cacheDirectory = Platform.isAndroid ? await Directory.systemTemp.createTemp('freepiv-ui-review-') : Directory('build/ui-review/cache').absolute;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, (call) async {
      if (call.method == 'getTemporaryDirectory' || call.method == 'getApplicationSupportDirectory' || call.method == 'getApplicationDocumentsDirectory') {
        return cacheDirectory.path;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(pathProvider, null));
    await tester.runAsync(initializeDownloadManager);
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.runAsync(() async {
      final font = File('C:/Windows/Fonts/segoeui.ttf');
      if (await font.exists()) {
        await (FontLoader('Segoe UI')..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())))).load();
      }
      final cjkFont = File('C:/Windows/Fonts/NotoSansSC-VF.ttf');
      if (await cjkFont.exists()) {
        await (FontLoader('Microsoft YaHei UI')..addFont(Future.value(ByteData.sublistView(await cjkFont.readAsBytes())))).load();
      }
    });

    final works = [for (var id = 101; id <= 112; id++) _work(id)];
    final images = <String, Uint8List>{};
    await tester.runAsync(() async {
      for (var i = 0; i < works.length; i++) {
        images[works[i].imageUrls.large] = await _artBytes(i);
      }
      images['https://fixtures.example.test/avatar.png'] = await _artBytes(2);
    });

    final deviceSize = Size(tester.view.physicalSize.width / tester.view.devicePixelRatio, tester.view.physicalSize.height / tester.view.devicePixelRatio);
    if (!Platform.isAndroid) {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
    }
    final previousPlatform = debugDefaultTargetPlatformOverride;
    final platform = Platform.isAndroid ? TargetPlatform.android : TargetPlatform.windows;
    if (kDebugMode) {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = previousPlatform);
    }

    for (final size in Platform.isAndroid ? [deviceSize] : [const Size(390, 844), const Size(800, 900), const Size(1280, 900), const Size(1440, 900)]) {
      for (final brightness in Brightness.values) {
        if (size.width == 1280 && brightness == Brightness.dark) continue;
        if (!Platform.isAndroid) tester.view.physicalSize = size;
        final shellKey = GlobalKey<NavigatorState>();
        final canPop = ValueNotifier<bool>(false);
        late final NavigatorStackObserver observer;
        observer = NavigatorStackObserver(() => canPop.value = observer.canPopPageRoute);
        final router = GoRouter(
          initialLocation: AppRoute.home.path,
          routes: [
            ShellRoute(
              navigatorKey: shellKey,
              observers: [observer],
              builder: (context, state, child) => RouterShell(
                canPopListenable: canPop,
                onBack: () => shellKey.currentState!.maybePop(),
                onResetRightNavigator: () => shellKey.currentState!.popUntil((route) => route.isFirst),
                child: child,
              ),
              routes: [
                GoRoute(path: AppRoute.home.path, name: AppRoute.home.name, pageBuilder: pages.homePage),
                GoRoute(path: AppRoute.downloads.path, name: AppRoute.downloads.name, pageBuilder: pages.downloadsPage),
                GoRoute(path: AppRoute.illustDetail.path, name: AppRoute.illustDetail.name, pageBuilder: pages.illustDetailPage),
                GoRoute(path: AppRoute.illustRelated.path, name: AppRoute.illustRelated.name, pageBuilder: pages.illustRelatedPage),
              ],
            ),
          ],
        );
        final boundary = GlobalKey();
        final titleRegistry = WindowTitleRegistry();
        titleRegistry.attachRouter(router);
        final homeSource = _LocalHomeSource(works);
        final mediaTransport = _LocalMediaTransport(images);
        final label = '${size.width.toInt()}-${brightness.name}';
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              homeIllustSourceProvider.overrideWithValue(homeSource),
              illustRelatedWorksProvider(101).overrideWith(() => _LocalRelatedWorks(works.skip(1).toList())),
              illustRelatedWorksProvider(102).overrideWith(() => _LocalRelatedWorks(works)),
              illustUserWorksProvider(7).overrideWith(() => _LocalUserWorks(works)),
              illustDetailProvider(const IllustDetailArgs(illustId: 101)).overrideWith(() => _LocalIllustDetail(works)),
              illustDetailProvider(const IllustDetailArgs(illustId: 102)).overrideWith(() => _LocalIllustDetail(works)),
              rustMediaTransportProvider.overrideWithValue(mediaTransport),
            ],
            child: TranslationProvider(
              child: MaterialApp.router(
                theme: brightness == Brightness.light
                    ? AppTheme.light(platform: platform, locale: const Locale('en'))
                    : AppTheme.dark(platform: platform, locale: const Locale('en')),
                routerConfig: router,
                builder: (context, child) {
                  final page = AppLayoutScope(child: child!);
                  if (Platform.isAndroid || size.width < 600) return RepaintBoundary(key: boundary, child: page);
                  return RepaintBoundary(
                    key: boundary,
                    child: WindowTitleScope(
                      registry: titleRegistry,
                      child: AnimatedBuilder(
                        animation: titleRegistry,
                        builder: (context, _) => NativeWindowFrame(
                          title: resolveWindowTitle(titleRegistry.uri, context.t, titleRegistry),
                          leading: const Icon(Icons.image),
                          background: Theme.of(context).colorScheme.surface,
                          foreground: Theme.of(context).colorScheme.onSurfaceVariant,
                          border: Theme.of(context).colorScheme.outlineVariant,
                          child: page,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await _pumpRoute(tester);
        expect(find.byType(HomePage), findsOneWidget);
        if (size.width >= 600 && !Platform.isAndroid) {
          expect(tester.widget<Text>(find.byKey(const ValueKey('window-title-text'))).data, t.navigation.home);
        }
        await tester.runAsync(() => _capture(boundary, 'home-$label'));
        if (size.width >= 1200) {
          final back = find.byTooltip('Back');
          final homeLabel = find.descendant(of: find.byType(DesktopNavItem).first, matching: find.text(t.navigation.home)).first;
          final typeLabel = find.text(t.home.illustrations).first;
          final narrowLabelX = tester.getTopLeft(homeLabel).dx;
          final narrowTypeX = tester.getTopLeft(typeLabel).dx;
          // The back control shares the floating sidebar's icon column.
          expect(
            tester.getCenter(back).dx,
            closeTo(tester.getCenter(find.descendant(of: find.byType(DesktopNavItem).first, matching: find.byType(FpIcon))).dx, 1),
          );
          await tester.tap(find.byTooltip(t.navigation.expand));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 80));
          final openingLabelX = tester.getTopLeft(homeLabel).dx;
          final openingTypeX = tester.getTopLeft(typeLabel).dx;
          expect(openingLabelX, greaterThan(narrowLabelX));
          expect(openingTypeX, greaterThan(narrowTypeX));
          if (size.width == 1280) await tester.runAsync(() => _capture(boundary, 'home-expanding-$label'));
          await _pumpRoute(tester);
          final wideLabelX = tester.getTopLeft(homeLabel).dx;
          final wideTypeX = tester.getTopLeft(typeLabel).dx;
          expect(openingLabelX, lessThan(wideLabelX));
          expect(openingTypeX, lessThan(wideTypeX));
          final navigationIcon = find.descendant(of: find.byType(DesktopNavItem).first, matching: find.byType(FpIcon)).first;
          expect(tester.getCenter(back).dx, closeTo(tester.getCenter(navigationIcon).dx, 1));
          await tester.runAsync(() => _capture(boundary, 'home-expanded-$label'));
          await tester.tap(find.byTooltip(t.navigation.collapse));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 80));
          final closingLabelX = tester.getTopLeft(homeLabel).dx;
          final closingTypeX = tester.getTopLeft(typeLabel).dx;
          expect(closingLabelX, lessThan(wideLabelX));
          expect(closingLabelX, greaterThan(narrowLabelX));
          expect(closingTypeX, lessThan(wideTypeX));
          expect(closingTypeX, greaterThan(narrowTypeX));
          if (size.width == 1280) await tester.runAsync(() => _capture(boundary, 'home-collapsing-$label'));
          await _pumpRoute(tester);
          // The back control shares the floating sidebar's icon column.
          expect(
            tester.getCenter(back).dx,
            closeTo(tester.getCenter(find.descendant(of: find.byType(DesktopNavItem).first, matching: find.byType(FpIcon))).dx, 1),
          );
          if (size.width == 1280) {
            await tester.tap(find.byTooltip(t.navigation.expand));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 150));
            final beforeReverse = tester.getTopLeft(typeLabel).dx;
            await tester.tap(find.byTooltip(t.navigation.collapse));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 40));
            final afterReverse = tester.getTopLeft(typeLabel).dx;
            expect(afterReverse, lessThan(beforeReverse));
            expect(afterReverse, greaterThan(narrowTypeX));
            await tester.tap(find.byTooltip(t.navigation.expand));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 16));
            // The spring keeps its momentum: no jump on the reversal, then it
            // turns toward the new target within a short moment.
            expect(tester.getTopLeft(typeLabel).dx, closeTo(afterReverse, 8));
            await tester.pump(const Duration(milliseconds: 150));
            expect(tester.getTopLeft(typeLabel).dx, greaterThan(afterReverse));
            await _pumpRoute(tester);
            await tester.tap(find.byTooltip(t.navigation.collapse));
            await _pumpRoute(tester);
          }
        }

        await tester.tap(find.text('Afternoon color study').first);
        await _pumpRoute(tester);
        expect(find.byType(IllustDetailPage), findsOneWidget);
        if (size.width >= 600 && !Platform.isAndroid) {
          expect(tester.widget<Text>(find.byKey(const ValueKey('window-title-text'))).data, 'Illust: 101 · Afternoon color study');
        }
        expect(GoRouterState.of(tester.element(find.byType(IllustDetailPage))).uri.path, '/illust/101');
        await tester.runAsync(() => _capture(boundary, 'detail-a-$label'));
        if (size.width < 1200) {
          final detailView = find.descendant(
            of: find.byType(IllustDetailPage),
            matching: find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down),
          );
          await tester.drag(detailView.first, const Offset(0, -200));
          await _pumpRoute(tester);
          expect(tester.state<ScrollableState>(detailView.first).position.pixels, greaterThan(0), reason: 'Dragging artwork must scroll the mobile detail');
          await tester.runAsync(() => _capture(boundary, 'detail-a-art-scroll-$label'));
        }

        final more = find.descendant(of: find.byType(IllustRelatedSection), matching: find.byType(OutlinedButton));
        final detailScroll = find.descendant(
          of: find.byType(IllustDetailPage),
          matching: find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down),
        );
        await tester.scrollUntilVisible(more, 300, scrollable: detailScroll.first);
        if (tester.getCenter(more).dy > size.height - 96) {
          await tester.drag(detailScroll.first, const Offset(0, -240));
          await _pumpRoute(tester);
        }
        await tester.tap(more);
        await _pumpRoute(tester);
        expect(find.byType(IllustRelatedPage), findsOneWidget);
        if (size.width >= 600 && !Platform.isAndroid) {
          expect(tester.widget<Text>(find.byKey(const ValueKey('window-title-text'))).data, 'Related works · Afternoon color study');
        }
        expect(GoRouterState.of(tester.element(find.byType(IllustRelatedPage))).uri.path, '/illust/101/related');
        await tester.runAsync(() => _capture(boundary, 'related-$label'));
        final relatedView = find.descendant(
          of: find.byType(IllustRelatedPage),
          matching: find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down),
        );
        await tester.drag(relatedView.first, const Offset(0, -200));
        await _pumpRoute(tester);
        await tester.runAsync(() => _capture(boundary, 'related-scrolled-$label'));
        await tester.drag(relatedView.first, const Offset(0, 200));
        await _pumpRoute(tester);

        await tester.tap(find.text(_secondTitle).first);
        await _pumpRoute(tester);
        expect(find.byType(IllustDetailPage), findsOneWidget);
        if (size.width >= 600 && !Platform.isAndroid) {
          expect(tester.widget<Text>(find.byKey(const ValueKey('window-title-text'))).data, 'Illust: 102 · $_secondTitle');
        }
        expect(GoRouterState.of(tester.element(find.byType(IllustDetailPage))).uri.path, '/illust/102');
        await tester.runAsync(() => _capture(boundary, 'detail-b-$label'));

        if (size.width >= 600) {
          expect(find.byTooltip('Back'), findsOneWidget);
          expect(find.byType(CompactBackButton), findsNothing);
        } else {
          expect(find.byType(CompactBackButton), findsOneWidget);
        }

        for (final expected in ['/illust/101/related', '/illust/101', '/']) {
          if (size.width >= 600) {
            await tester.tap(find.byTooltip('Back'));
          } else {
            await tester.tap(find.byType(CompactBackButton).first);
          }
          await _pumpRoute(tester);
          final activePage = expected.endsWith('/related')
              ? find.byType(IllustRelatedPage)
              : expected == '/'
              ? find.byType(HomePage)
              : find.byType(IllustDetailPage);
          expect(GoRouterState.of(tester.element(activePage)).uri.path, expected);
          if (size.width >= 600 && !Platform.isAndroid) {
            final expectedTitle = switch (expected) {
              '/illust/101/related' => 'Related works · Afternoon color study',
              '/illust/101' => 'Illust: 101 · Afternoon color study',
              _ => t.navigation.home,
            };
            expect(tester.widget<Text>(find.byKey(const ValueKey('window-title-text'))).data, expectedTitle);
          }
          final captureName = switch (expected) {
            '/illust/101/related' => 'related-return',
            '/illust/101' => 'detail-a-return',
            _ => 'home-return',
          };
          await tester.runAsync(() => _capture(boundary, '$captureName-$label'));
        }
        expect(find.byType(HomePage), findsOneWidget);
        if (size.width >= 1200) {
          await tester.tap(find.byTooltip(t.navigation.expand));
          await _pumpRoute(tester);
          await tester.runAsync(() => _capture(boundary, 'home-expanded-return-$label'));
          await tester.tap(find.byTooltip(t.navigation.collapse));
          await _pumpRoute(tester);
        }
        final homeScroll = find.descendant(
          of: find.byType(HomePage),
          matching: find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down),
        );
        await tester.drag(homeScroll.last, const Offset(0, -500));
        await _pumpRoute(tester);
        final scrolledOffset = tester.state<ScrollableState>(homeScroll.last).position.pixels;
        final loadCountBeforeReselect = homeSource.loadCount;
        await tester.tap(
          size.width >= 600
              ? find.byType(DesktopNavItem).first
              // Mobile destinations expose their visible label as semantics, not a tooltip.
              : find
                    .byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == t.navigation.home && widget.properties.button == true)
                    .first,
        );
        await _pumpRoute(tester);
        final reselectedOffset = tester.state<ScrollableState>(homeScroll.last).position.pixels;
        expect(scrolledOffset, greaterThan(0), reason: label);
        expect(reselectedOffset, closeTo(0, .1), reason: label);
        expect(homeSource.loadCount, loadCountBeforeReselect);
        final homeState = tester.state(find.byType(HomePage));
        final mediaLoadsBeforeDownloads = mediaTransport.streamCount;
        for (var visit = 0; visit < 2; visit++) {
          if (size.width >= 600) {
            await tester.tap(find.byWidgetPredicate((widget) => widget is DesktopNavItem && widget.label == t.navigation.more));
            await _pumpRoute(tester);
            await tester.tap(
              find.descendant(
                of: find.byWidgetPredicate((widget) => widget is FpSurface && widget.role == FpSurfaceRole.overlay),
                matching: find.text(t.navigation.downloads),
              ),
            );
          } else {
            // This focused route fixture omits Me; the real mobile entry lives there.
            router.push(AppRoute.downloads.path);
          }
          await _pumpRoute(tester);
          expect(find.byType(DownloadsPage), findsOneWidget);
          if (size.width >= 600) {
            await tester.tap(find.byTooltip('Back'));
          } else {
            await tester.tap(find.byType(CompactBackButton).first);
          }
          await _pumpRoute(tester);
          expect(identical(tester.state(find.byType(HomePage)), homeState), isTrue, reason: label);
          expect(homeSource.loadCount, loadCountBeforeReselect, reason: label);
          expect(mediaTransport.streamCount, mediaLoadsBeforeDownloads, reason: label);
        }
        await tester.runAsync(() => _capture(boundary, 'home-after-downloads-$label'));
        router.go('/illust/101/related');
        await _pumpRoute(tester);
        expect(find.byType(IllustRelatedPage), findsOneWidget);
        if (size.width >= 600) {
          await tester.tap(find.byTooltip('Back'));
        } else {
          await tester.tap(find.byType(CompactBackButton).first);
        }
        await _pumpRoute(tester);
        expect(find.byType(IllustDetailPage), findsOneWidget);
        expect(GoRouterState.of(tester.element(find.byType(IllustDetailPage))).uri.path, '/illust/101');
        expect(tester.takeException(), isNull, reason: label);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
        titleRegistry.dispose();
        router.dispose();
        canPop.dispose();
      }
    }
    await tester.pump(const Duration(milliseconds: 1));
    if (kDebugMode) debugDefaultTargetPlatformOverride = previousPlatform;
  });
}
