import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';

void main() {
  final now = DateTime(2026, 10, 5, 14, 30);

  test('a popular preview has no sort and the other orders map to the date sorts', () {
    expect(const SearchFilterState().sort, SearchSort.dateDesc);
    expect(const SearchFilterState(order: SearchOrder.oldest).sort, SearchSort.dateAsc);
    const preview = SearchFilterState(order: SearchOrder.popularPreview);
    expect(preview.sort, isNull);
    expect(preview.isPopularPreview, isTrue);
  });

  test('a reversed custom range is put in order', () {
    final filter = SearchFilterState(datePreset: SearchDatePreset.custom, customStart: DateTime(2026, 10, 1), customEnd: DateTime(2026, 9, 1));
    expect(filter.dateRange(now), (DateTime(2026, 9, 1), DateTime(2026, 10, 1)));
    final options = filter.toOptions(now);
    expect(options.startDate, '2026-09-01');
    expect(options.endDate, '2026-10-01');
  });

  test('a range longer than a year keeps its last year', () {
    final filter = SearchFilterState(datePreset: SearchDatePreset.custom, customStart: DateTime(2010), customEnd: DateTime(2020));
    final (start, end) = filter.dateRange(now)!;
    expect(end, DateTime(2020));
    expect(end.difference(start).inDays, searchSpanDays);
  });

  test('the one-year preset stays within the span across a leap day', () {
    const filter = SearchFilterState(datePreset: SearchDatePreset.year);
    for (final day in [DateTime(2026, 10, 5), DateTime(2024, 3, 1), DateTime(2025, 2, 28)]) {
      final (start, end) = filter.dateRange(day)!;
      expect(end.difference(start).inDays, lessThanOrEqualTo(searchSpanDays));
    }
  });

  test('options carry the illustration filters and drop a blank tool', () {
    const filter = SearchFilterState(contentType: SearchContentType.manga, ratio: SearchRatio.portrait, minWidth: 2000, minHeight: 1000, tool: '  Photoshop ');
    final options = filter.toOptions(now);
    expect(options.contentType, SearchContentType.manga);
    expect(options.ratio, SearchRatio.portrait);
    expect(options.widthMin, 2000);
    expect(options.heightMin, 1000);
    expect(options.tool, 'Photoshop');
    expect(const SearchFilterState(tool: '   ').toOptions(now).tool, isNull);
  });

  test('bookmark tags include the higher tiers', () {
    expect(searchBookmarkTotalOptions, containsAll([20000, 30000, 50000, 100000]));
  });
}
