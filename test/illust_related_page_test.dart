import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/illust_related_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

class _Related extends IllustRelatedListSource {
  _Related(this.first, {this.next, super.illustId = 1});

  final Future<IllustPageResult> Function() first;
  final Future<IllustPageResult> Function()? next;

  @override
  Future<IllustPageResult> loadFirstPage() => first();

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) => next!();
}

class _RelatedWorks extends IllustRelatedWorks {
  _RelatedWorks(this.source);
  final _Related source;
  @override
  IllustRelatedListSource build(int illustId) => source;
}

Future<void> _mount(WidgetTester tester, _Related source, {Illust? work, Size size = desktopSize, double textScale = 1}) => mountPilotPage(
  tester,
  IllustRelatedPage(illustId: 1, sourceIllust: work),
  size: size,
  textScale: textScale,
  overrides: {illustRelatedWorksProvider: illustRelatedWorksProvider.overrideWith2((_) => _RelatedWorks(source))},
);

void main() {
  testWidgets('the header names the source work by its thumbnail over a full-width waterfall', (tester) async {
    final works = sampleIllusts(count: 12);
    await _mount(tester, _Related(() async => IllustPageResult(illusts: works, rankingIllusts: const [])), work: works.first);
    expect(find.text(t.illust.section.relatedWorks), findsOneWidget);
    final thumbnail = tester.widget<FrostThumbnail>(find.byType(FrostThumbnail));
    expect(thumbnail.semanticLabel, works.first.title);
    expect(find.byType(AppArtworkCard), findsWidgets);
    // Not held to the reading column: cards reach past it on a wide window.
    final right = tester.getTopRight(find.byType(AppArtworkCard).at(4)).dx;
    expect(right, greaterThan((desktopSize.width + FrostMetrics.readingMaxWidth) / 2));
  });

  testWidgets('the work itself is left out of the works like it', (tester) async {
    final works = sampleIllusts(count: 4);
    final source = works[1];
    await _mount(tester, _Related(() async => IllustPageResult(illusts: works, rankingIllusts: const []), illustId: source.id), work: source);
    final shown = tester.widgetList<AppArtworkCard>(find.byType(AppArtworkCard)).map((card) => card.illust.id);
    expect(shown, isNot(contains(source.id)));
    expect(shown, hasLength(works.length - 1));
  });

  testWidgets('empty, loading and failed lists show their state; a failed page retries in place', (tester) async {
    await _mount(tester, _Related(() async => const IllustPageResult(illusts: [], rankingIllusts: [])));
    expect(find.text(t.illust.related.empty), findsOneWidget);

    final never = Completer<IllustPageResult>();
    await _mount(tester, _Related(() => never.future));
    expect(find.byType(AppArtworkWaterfallSkeleton), findsOneWidget);

    var attempts = 0;
    await _mount(
      tester,
      _Related(() async {
        if (attempts++ == 0) throw StateError('offline');
        return IllustPageResult(illusts: sampleIllusts(count: 4), rankingIllusts: const [], nextUrl: 'next');
      }, next: () async => throw StateError('offline')),
    );
    expect(find.byType(FrostErrorContent), findsOneWidget);
    await tester.tap(find.text(t.common.retry));
    await settlePilot(tester);
    expect(find.byType(AppArtworkCard), findsNWidgets(4));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await settlePilot(tester);
    expect(find.byType(AppArtworkCard), findsNWidgets(4), reason: 'the failed page leaves the loaded works in place');
  });

  testWidgets('a long source title fits a phone at double text size', (tester) async {
    final works = sampleIllusts(count: 4);
    await _mount(tester, _Related(() async => IllustPageResult(illusts: works, rankingIllusts: const [])), size: phoneSize, textScale: 2, work: works.first);
    expectNoLayoutErrors(tester);
  });
}
