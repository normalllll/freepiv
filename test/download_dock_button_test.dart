import 'package:flutter/material.dart';
import 'package:freepiv/shared/ui/rolling_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/downloads/models/download_summary.dart';
import 'package:freepiv/features/downloads/presentation/download_dock_button.dart';
import 'package:freepiv/i18n/strings.g.dart';

DownloadSummary _summary({int active = 0, int failed = 0, int saved = 0}) => DownloadSummary(
  illustId: null,
  total: active + failed + saved,
  queued: active,
  running: 0,
  downloaded: 0,
  failed: failed,
  cancelled: 0,
  savePending: 0,
  saveFailed: 0,
  saved: saved,
  overallProgress: 0,
);

void main() {
  test('badge shows work needing attention and caps only its visible text', () {
    expect(downloadBadgeCount(_summary(saved: 12)), 0);
    for (final count in [1, 9, 10, 99, 100, 999, 1000]) {
      expect(downloadBadgeCount(_summary(active: count)), count);
      expect(downloadBadgeText(count), count > 999 ? '999+' : '$count');
    }
    expect(downloadBadgeCount(_summary(active: 7, failed: 2)), 2);
  });

  testWidgets('visible badge extends past the clipped button and opens it', (tester) async {
    var opens = 0;
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomRight,
                child: DownloadDockButton(summary: _summary(active: 1000), onPressed: () => opens++),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final badge = tester.getRect(find.byType(RollingText));
      expect(tester.widget<RollingText>(find.byType(RollingText)).text, '999+');
      final icon = tester.getRect(find.byIcon(Icons.downloading_outlined));
      expect(badge.right, greaterThan(icon.right));
      expect(find.bySemanticsLabel(RegExp('1000')), findsOneWidget);
      await tester.tapAt(Offset(badge.right - 2, badge.center.dy));
      expect(opens, brightness == Brightness.light ? 1 : 2);
    }
  });

  testWidgets('two times text scale keeps the button in place as the count changes', (tester) async {
    Future<Rect> pump(int count) async {
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.bottomRight,
                  child: DownloadDockButton(
                    summary: _summary(active: count),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(find.byIcon(Icons.downloading_outlined));
    }

    final one = await pump(1);
    final thousand = await pump(1000);
    expect(thousand, one);
    expect(tester.takeException(), isNull);
  });
}
