import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/ui/custom/avatar_cropper.dart';

import 'support/pilot_harness.dart';

Future<ui.Image> _picture(WidgetTester tester, int width, int height) async => (await tester.runAsync(() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = const Color(0xFF3366CC));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}))!;

const _viewport = 300.0;

Future<AvatarCropController> _mount(WidgetTester tester, {int width = 1200, int height = 800}) async {
  final image = await _picture(tester, width, height);
  addTearDown(image.dispose);
  final controller = AvatarCropController(sourceWidth: width, sourceHeight: height);
  addTearDown(controller.dispose);
  await mountPilotPage(
    tester,
    Align(
      child: SizedBox.square(
        dimension: _viewport,
        child: AvatarCropViewport(image: image, controller: controller),
      ),
    ),
  );
  return controller;
}

double _guideOpacity(WidgetTester tester) => tester.renderObject<RenderAnimatedOpacity>(find.byKey(const ValueKey('avatarCropGuides'))).opacity.value;

void main() {
  group('the crop rectangle', () {
    test('starts as the short side, centred', () {
      final controller = AvatarCropController(sourceWidth: 1200, sourceHeight: 800)..viewport = 400;
      expect(controller.crop, const AvatarCrop(x: 200, y: 0, side: 800));
      expect(controller.zoom, 0);
      controller.dispose();
    });

    test('a pan and a zoom move and shrink it', () {
      final controller = AvatarCropController(sourceWidth: 1200, sourceHeight: 800)..viewport = 400;
      // Half a logical pixel per source pixel: 50 px of dragging left is 100 source pixels.
      controller.panBy(const Offset(-50, 0));
      expect(controller.crop, const AvatarCrop(x: 300, y: 0, side: 800));
      controller.zoomBy(2);
      expect(controller.crop, const AvatarCrop(x: 500, y: 200, side: 400));
      // Now one logical pixel per source pixel.
      controller.panBy(const Offset(-100, 100));
      expect(controller.crop, const AvatarCrop(x: 600, y: 100, side: 400));
      controller.dispose();
    });

    test('zooming keeps the point under the focal position', () {
      final controller = AvatarCropController(sourceWidth: 1200, sourceHeight: 800)..viewport = 400;
      controller.zoomBy(2, focal: Offset.zero);
      expect(controller.crop, const AvatarCrop(x: 200, y: 0, side: 400));
      controller.zoomBy(2, focal: const Offset(1, 1));
      expect(controller.crop, const AvatarCrop(x: 400, y: 200, side: 200));
      controller.dispose();
    });

    test('the picture cannot leave the viewport empty', () {
      final controller = AvatarCropController(sourceWidth: 1200, sourceHeight: 800)..viewport = 400;
      controller.panBy(const Offset(-5000, 5000));
      expect(controller.crop, const AvatarCrop(x: 400, y: 0, side: 800));
      controller.panBy(const Offset(9000, -9000));
      expect(controller.crop, const AvatarCrop(x: 0, y: 0, side: 800));
      controller.dispose();
    });

    test('reset shows the short side again', () {
      final controller = AvatarCropController(sourceWidth: 1200, sourceHeight: 800)..viewport = 400;
      controller.zoomBy(3, focal: Offset.zero);
      controller.panBy(const Offset(-20, -20));
      controller.reset();
      expect(controller.crop, const AvatarCrop(x: 200, y: 0, side: 800));
      controller.dispose();
    });
  });

  group('zoom limits', () {
    test('zooming out stops at the short side', () {
      final controller = AvatarCropController(sourceWidth: 1200, sourceHeight: 800)..viewport = 400;
      controller.zoomBy(0.1);
      expect(controller.visibleSide, 800);
      expect(controller.crop.side, 800);
      controller.dispose();
    });

    test('zooming in stops where the viewport covers 170 source pixels', () {
      final controller = AvatarCropController(sourceWidth: 1200, sourceHeight: 800)..viewport = 400;
      controller.zoomBy(100);
      expect(controller.visibleSide, 170);
      expect(controller.crop.side, 170);
      expect(controller.zoom, closeTo(1, 1e-9));
      controller.dispose();
    });

    test('the slider value runs from the widest to the closest view', () {
      final controller = AvatarCropController(sourceWidth: 1200, sourceHeight: 800)..viewport = 400;
      controller.setZoom(1);
      expect(controller.visibleSide, closeTo(170, 1e-9));
      controller.setZoom(0);
      expect(controller.visibleSide, closeTo(800, 1e-9));
      controller.setZoom(.5);
      expect(controller.visibleSide, closeTo(800 * math.sqrt(170 / 800), 1e-9), reason: 'halfway on a logarithmic scale');
      controller.dispose();
    });

    test('a picture smaller than 170 px cannot be zoomed', () {
      final controller = AvatarCropController(sourceWidth: 120, sourceHeight: 100)..viewport = 300;
      expect(controller.canZoom, isFalse);
      controller.zoomBy(4);
      expect(controller.crop, const AvatarCrop(x: 10, y: 0, side: 100));
      controller.dispose();
    });
  });

  group('the viewport', () {
    testWidgets('dragging moves the crop', (tester) async {
      final controller = await _mount(tester);
      final before = controller.crop;
      await tester.drag(find.byType(AvatarCropViewport), const Offset(-60, 0));
      await tester.pump();
      expect(controller.crop.x, greaterThan(before.x));
      expect(controller.crop.y, before.y);
      expect(controller.crop.side, before.side);
    });

    testWidgets('the wheel zooms, and eases to its target', (tester) async {
      final controller = await _mount(tester);
      final center = tester.getCenter(find.byType(AvatarCropViewport));
      await tester.sendEventToBinding(PointerScrollEvent(position: center, scrollDelta: const Offset(0, -100)));
      await tester.pump();
      expect(controller.visibleSide, 800, reason: 'the zoom starts from where it is');
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.visibleSide, lessThan(800));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the wheel zooms at once under reduced motion', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final controller = await _mount(tester);
      final center = tester.getCenter(find.byType(AvatarCropViewport));
      await tester.sendEventToBinding(PointerScrollEvent(position: center, scrollDelta: const Offset(0, -100)));
      await tester.pump();
      expect(controller.visibleSide, lessThan(800));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the thirds show while dragging and fade out on release', (tester) async {
      final controller = await _mount(tester);
      expect(_guideOpacity(tester), 0);
      final gesture = await tester.startGesture(tester.getCenter(find.byType(AvatarCropViewport)));
      await tester.pump();
      expect(controller.interacting, isTrue);
      expect(_guideOpacity(tester), lessThan(.5), reason: 'they fade in');
      await tester.pump(const Duration(milliseconds: 400));
      expect(_guideOpacity(tester), 1);
      await gesture.up();
      await tester.pump();
      expect(controller.interacting, isFalse);
      expect(_guideOpacity(tester), greaterThan(.5), reason: 'they fade out');
      await tester.pump(const Duration(milliseconds: 400));
      expect(_guideOpacity(tester), 0);
    });

    testWidgets('the thirds show and hide at once under reduced motion', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await _mount(tester);
      final gesture = await tester.startGesture(tester.getCenter(find.byType(AvatarCropViewport)));
      await tester.pump();
      expect(_guideOpacity(tester), 1);
      await gesture.up();
      await tester.pump();
      expect(_guideOpacity(tester), 0);
    });
  });
}
