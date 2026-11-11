import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'support/frost_test_app.dart';

/// The app's toast host, dark, on the test variant's platform.
Future<void> _pumpHost(WidgetTester tester, {bool reduceMotion = false}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 700);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MediaQuery(
        data: MediaQueryData.fromView(tester.view).copyWith(disableAnimations: reduceMotion),
        child: frostTestApp(brightness: Brightness.dark, home: const SizedBox.expand()),
      ),
    ),
  );
}

void main() {
  errorToastTests();
  duplicateToastTests();

  testWidgets('touch: swiping the capsule up dismisses it; a short drag springs back', variant: TargetPlatformVariant.only(TargetPlatform.android), (tester) async {
    await _pumpHost(tester);
    FrostToast.success('Link copied');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.drag(find.text('Link copied'), const Offset(0, -8));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Link copied'), findsOneWidget);
    await tester.fling(find.text('Link copied'), const Offset(0, -60), 800);
    await tester.pumpAndSettle();
    expect(find.text('Link copied'), findsNothing);
  });

  testWidgets('reduced motion shows and removes notices without movement', variant: TargetPlatformVariant.only(TargetPlatform.android), (tester) async {
    await _pumpHost(tester, reduceMotion: true);
    FrostToast.success('Link copied');
    await tester.pump();
    await tester.pump();
    expect(find.text('Link copied'), findsOneWidget);
    final rect = tester.getRect(find.text('Link copied'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getRect(find.text('Link copied')), rect, reason: 'no drop-in movement');
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();
    expect(find.text('Link copied'), findsNothing);
  });
}

void errorToastTests() {
  testWidgets('a failed action shows one readable line without technical detail', variant: TargetPlatformVariant.only(TargetPlatform.android), (tester) async {
    await _pumpHost(tester);
    toastErrorWithCause('Bookmark failed', const PixivError(kind: PixivErrorKind.httpClient, message: 'reqwest display: error sending request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Bookmark failed'), findsOneWidget);
    expect(find.textContaining('httpClient'), findsNothing);
    expect(find.textContaining('reqwest'), findsNothing);
    expect(tester.getSize(find.textContaining('Bookmark failed')).height, lessThan(60));
    await tester.pump(const Duration(seconds: 6));
  });
}

void duplicateToastTests() {
  testWidgets('desktop: identical notices fold into one card with a count', variant: TargetPlatformVariant.only(TargetPlatform.windows), (tester) async {
    await _pumpHost(tester);
    for (var i = 0; i < 3; i++) {
      FrostToast.success('Link copied');
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Link copied'), findsOneWidget);
    expect(find.textContaining('×3'), findsOneWidget);

    FrostToast.info('Other');
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Other'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
  });
}
