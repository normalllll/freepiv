import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/widgets/artwork_hero.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/src/rust/api/media.dart' as rust;

/// Never delivers an image: the flying picture only needs its frame here.
class _IdleTransport extends RustMediaTransport {
  _IdleTransport() : super(null);

  @override
  Stream<rust.MediaChunk> stream(String url, Map<String, String> headers) => StreamController<rust.MediaChunk>().stream;
}

/// Sends what the Android embedding sends during a back swipe from the left edge.
Future<void> _backGesture(WidgetTester tester, String method, {double? progress}) async {
  final event = progress == null
      ? null
      : {
          'touchOffset': [5.0, 300.0],
          'progress': progress,
          'swipeEdge': 0,
        };
  final message = const StandardMethodCodec().encodeMethodCall(MethodCall(method, event));
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/backgesture', message, (_) {});
}

const _card = Size(100, 100);
const _stage = Size(300, 300);

/// A home page whose card and a detail page whose stage share one artwork
/// hero, as in the app. Returns the stage's and the card's frames before any
/// swipe.
Future<({GlobalKey<NavigatorState> navigator, Rect stage, Rect card})> _pump(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(tester.view.reset);
  final tag = ArtworkHeroTag(imageUrl: 'https://example.invalid/a.jpg', aspectRatio: 1, sourceRadius: BorderRadius.circular(12));
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [rustMediaTransportProvider.overrideWithValue(_IdleTransport())],
      child: MaterialApp(
        navigatorKey: navigator,
        theme: AppTheme.dark(platform: TargetPlatform.android, locale: const Locale('en')),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ArtworkHero(
              tag: tag,
              child: SizedBox.fromSize(key: const ValueKey('card'), size: _card),
            ),
          ),
        ),
      ),
    ),
  );
  final card = tester.getRect(find.byKey(const ValueKey('card')));
  navigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        body: Center(
          child: ArtworkStageHero(
            tag: tag,
            child: SizedBox.fromSize(key: const ValueKey('stage'), size: _stage),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (navigator: navigator, stage: tester.getRect(find.byKey(const ValueKey('stage'))), card: card);
}

/// The frame of the flying picture, null when nothing flies.
Rect? _flying(WidgetTester tester) {
  final finder = find.byType(PixivImage);
  return finder.evaluate().length == 1 ? tester.getRect(finder) : null;
}

void main() {
  testWidgets('during a swipe the picture stays in the page and shrinks with it', (tester) async {
    final (:navigator, :stage, :card) = await _pump(tester);

    await _backGesture(tester, 'startBackGesture', progress: 0);
    await _backGesture(tester, 'updateBackGestureProgress', progress: .8);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final picture = _flying(tester);
    expect(picture, isNotNull, reason: 'the stage lifted its picture into the flight');
    // Far into the swipe it is the stage's frame scaled by the page's own
    // pose (1 - .1 x .8), not travelling toward the card.
    expect(picture!.width / stage.width, closeTo(.92, .02));
    expect(picture.height / stage.height, closeTo(.92, .02));
    expect((picture.center - stage.center).distance, lessThan(25));
    expect(picture.width, greaterThan(card.width * 2));
    // It is clipped to the page's own rounded edge, so it does not stick out of
    // the page's corners: in the picture's coordinates the page spans the whole
    // 400 x 800 around the centred 300 x 300 stage.
    final clip = tester.renderObject<RenderClipRRect>(find.descendant(of: find.byType(CompositedTransformFollower), matching: find.byType(ClipRRect)));
    final edge = clip.clipper!.getClip(_stage);
    expect(edge.left, closeTo(-50, .5));
    expect(edge.top, closeTo(-250, .5));
    expect(edge.width, closeTo(400, .5));
    expect(edge.height, closeTo(800, .5));
    expect(edge.tlRadiusX, closeTo(24, .5));

    await _backGesture(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isTrue);
  });

  testWidgets('a committed swipe flies the picture on from where the swipe left it', (tester) async {
    final (:navigator, :stage, :card) = await _pump(tester);

    await _backGesture(tester, 'startBackGesture', progress: 0);
    await _backGesture(tester, 'updateBackGestureProgress', progress: .8);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final dragged = _flying(tester)!;

    await _backGesture(tester, 'commitBackGesture');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final committed = _flying(tester)!;
    // The route's animation restarts at fully shown when a swipe is committed;
    // the picture must not follow it back to the stage's frame.
    expect(committed.width / stage.width, lessThan(.96), reason: 'did not jump back to the stage');
    expect((committed.center - dragged.center).distance, lessThan(30), reason: 'continues from the swipe, no jump');

    await tester.pump(const Duration(milliseconds: 80));
    final later = _flying(tester)!;
    expect(later.width, lessThan(committed.width));
    expect((later.center - card.center).distance, lessThan((committed.center - card.center).distance));

    await tester.pumpAndSettle();
    expect(_flying(tester), isNull);
    expect(find.byKey(const ValueKey('stage')), findsNothing);
    expect(navigator.currentState!.canPop(), isFalse);
    expect(find.byKey(const ValueKey('card')), findsOneWidget);
  });

  testWidgets('cancelling a swipe puts the picture back in the page', (tester) async {
    final (:navigator, :stage, :card) = await _pump(tester);

    await _backGesture(tester, 'startBackGesture', progress: 0);
    await _backGesture(tester, 'updateBackGestureProgress', progress: .5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_flying(tester), isNotNull);

    await _backGesture(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(_flying(tester), isNull);
    expect(tester.getRect(find.byKey(const ValueKey('stage'))), stage);
    expect(navigator.currentState!.canPop(), isTrue);
  });

  testWidgets('a button back still flies the picture straight from the stage to its card', (tester) async {
    final (:navigator, :stage, :card) = await _pump(tester);

    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final start = _flying(tester)!;
    expect(start.width / stage.width, greaterThan(.9), reason: 'starts at the stage, not at some swipe pose');
    await tester.pump(const Duration(milliseconds: 80));
    final later = _flying(tester)!;
    expect((later.center - card.center).distance, lessThan((start.center - card.center).distance));

    await tester.pumpAndSettle();
    expect(_flying(tester), isNull);
  });
}
