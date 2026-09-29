import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/features/downloads/presentation/download_flight.dart';

class _Badge implements DownloadFlightTarget {
  int landings = 0;

  @override
  Rect? get badgeRect => const Rect.fromLTWH(40, 560, 22, 20);

  @override
  void land() => landings++;
}

Future<void> _pumpApp(WidgetTester tester, {bool reduceMotion = false}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        navigatorKey: AppRouter.rootNavigatorKey,
        theme: AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en')),
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion), child: child!),
        home: const Scaffold(body: SizedBox.expand()),
      ),
    ),
  );
}

void main() {
  testWidgets('a download flies from where it was asked for to the badge, which bounces once on landing', (tester) async {
    await _pumpApp(tester);
    final badge = _Badge();
    DownloadFlight.attach(badge);
    addTearDown(() => DownloadFlight.detach(badge));

    DownloadFlight.launch(origin: const Rect.fromLTWH(600, 300, 48, 48));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Mid-flight the token is between the button and the badge, above both.
    final token = tester.getRect(find.byType(ClipOval));
    expect(token.center.dx, inExclusiveRange(62, 624));
    expect(token.center.dy, lessThan(324), reason: 'the jump rises above the button');
    expect(badge.landings, 0);

    await tester.pump(const Duration(milliseconds: 400));
    expect(badge.landings, 1);
    expect(find.byType(ClipOval), findsNothing, reason: 'the token is gone once it lands');
  });

  testWidgets('with reduced motion nothing flies; the badge only bounces', (tester) async {
    await _pumpApp(tester, reduceMotion: true);
    final badge = _Badge();
    DownloadFlight.attach(badge);
    addTearDown(() => DownloadFlight.detach(badge));

    DownloadFlight.launch(origin: const Rect.fromLTWH(600, 300, 48, 48));
    await tester.pump();
    expect(find.byType(ClipOval), findsNothing);
    expect(badge.landings, 1);
  });
}
