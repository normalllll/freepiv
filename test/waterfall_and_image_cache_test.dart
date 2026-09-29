import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/layout/content_viewport.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';
import 'package:freepiv/shared/widgets/waterfall_grid.dart';

void main() {
  test('artwork columns land tiles nearest the preferred width', () {
    int columns(double width, {double textScale = 1}) =>
        waterfallColumnCount(width: width, preferredTileWidth: AppMetrics.gridExtent, gap: AppMetrics.gridGap, textScale: textScale);
    double tile(double width, int count) => (width + AppMetrics.gridGap) / count - AppMetrics.gridGap;

    expect(columns(319), 1);
    expect(columns(320), 2);
    // Phones stay at two columns.
    expect(columns(358), 2);
    // 2 → 3 where 3 tiles are as close to 220 as 2 tiles (both 45.6 off).
    expect(columns(539.2), 2);
    expect(columns(539.3), 3);
    // An unfolded Fold beside the sidebar and the default 1280 window.
    expect(columns(626), 3);
    expect(columns(1052), 5);
    // 4 → 5 at the same midpoint rule.
    expect(columns(1005.3), 4);
    expect(columns(1005.4), 5);
    expect(columns(684 - AppMetrics.gridGap, textScale: 2), 2);

    // Every width picks the count whose tile is nearest the preferred width.
    for (var width = 320.0; width <= 2400; width += 7) {
      final count = columns(width);
      final nearest = [
        for (var n = 2; n <= 12; n++) n,
      ].reduce((a, b) => (tile(width, a) - AppMetrics.gridExtent).abs() <= (tile(width, b) - AppMetrics.gridExtent).abs() + 1e-9 ? a : b);
      expect(count, nearest, reason: '$width');
    }
  });

  testWidgets('art grid keeps its columns during sidebar expansion and responds to window width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Future<({double first, double fifth})> positions(double width, double reserve) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: ContentColumnBudget(
                  reservedWidth: reserve,
                  child: CustomScrollView(
                    slivers: [
                      SliverWaterfallGrid<int>(
                        items: List.generate(8, (index) => index),
                        itemBuilder: (context, item, index) => SizedBox(
                          key: ValueKey('art-$index'),
                          height: 100,
                          child: const ColoredBox(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return (first: tester.getTopLeft(find.byKey(const ValueKey('art-0'))).dy, fifth: tester.getTopLeft(find.byKey(const ValueKey('art-4'))).dy);
    }

    final collapsed = await positions(1100, 96);
    final expanded = await positions(1004, 0);
    expect(collapsed.fifth, greaterThan(collapsed.first));
    expect(expanded.fifth, collapsed.fifth);
    final wider = await positions(1500, 96);
    expect(wider.fifth, wider.first);
  });

  test('recreated media transport retains the same image cache key', () {
    final firstTransport = RustMediaTransport(null);
    final nextTransport = RustMediaTransport(null);
    final differentProxy = RustMediaTransport('http://proxy.example.test:8080');
    final request = MediaRequest(url: 'https://example.test/art.png');

    RustExtendedNetworkImageProvider image(RustMediaTransport transport) =>
        RustExtendedNetworkImageProvider(request: request, mediaStream: transport.stream, mediaStreamCacheIdentity: transport.imageCacheIdentity);

    expect(image(firstTransport), image(nextTransport));
    expect(image(firstTransport).hashCode, image(nextTransport).hashCode);
    expect(image(firstTransport), isNot(image(differentProxy)));
  });
}
