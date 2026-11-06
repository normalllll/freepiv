import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/downloads/models/download_summary.dart';
import 'package:freepiv/features/downloads/presentation/download_dock_button.dart';

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
}
