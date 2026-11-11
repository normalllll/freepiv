// app-owned: avatar cropper
//
// The square viewport that picks the part of an image a profile image keeps:
// drag to pan, pinch, wheel or slider to zoom, a circular mask that shows how
// Pixiv displays the result. Frost has no component for it; the gestures and
// the mask are painted and laid out here. Nothing is encoded in Dart: the
// result is a rectangle in source pixels, which `prepare_profile_image` turns
// into the uploaded JPEG.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:freepiv/app/immersive_pages.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

/// The square a crop keeps, in pixels of the source image as it is displayed.
@immutable
class AvatarCrop {
  const AvatarCrop({required this.x, required this.y, required this.side});

  final int x, y, side;

  @override
  int get hashCode => Object.hash(x, y, side);

  @override
  bool operator ==(Object other) => other is AvatarCrop && other.x == x && other.y == y && other.side == side;

  @override
  String toString() => 'AvatarCrop($x, $y, $side)';
}

/// Where the viewport looks into an image: the point at its centre and how
/// many source pixels its side covers. Pixiv shows a profile image about
/// 170 px wide, so zooming in stops where the viewport covers [closestSide]
/// source pixels; zooming out stops at the image's short side.
class AvatarCropController extends ChangeNotifier {
  AvatarCropController({required this.sourceWidth, required this.sourceHeight})
    : assert(sourceWidth > 0 && sourceHeight > 0),
      _side = math.min(sourceWidth, sourceHeight).toDouble(),
      _center = Offset(sourceWidth / 2, sourceHeight / 2);

  /// The most zoomed in the viewport gets: this many source pixels per side.
  static const closestSide = 170.0;

  final int sourceWidth, sourceHeight;

  double _side;
  Offset _center;
  int _holds = 0;

  double get _shortSide => math.min(sourceWidth, sourceHeight).toDouble();

  /// Source pixels the viewport covers at the widest, which is the short side.
  double get widestSide => _shortSide;

  /// Source pixels the viewport covers at the closest.
  double get narrowestSide => math.min(closestSide, _shortSide);

  /// How many source pixels the viewport's side covers now.
  double get visibleSide => _side;

  /// The source point at the viewport's centre.
  Offset get center => _center;

  /// The viewport's side in logical pixels; set by the widget that lays it out.
  double viewport = 0;

  /// Logical pixels per source pixel.
  double get scale => viewport / _side;

  /// Whether there is any zoom to adjust.
  bool get canZoom => widestSide - narrowestSide > 0.5;

  /// Zoom as a share of the range, 0 for the widest view and 1 for the closest.
  /// The range is logarithmic, so a slider moves the picture evenly.
  double get zoom => canZoom ? (math.log(widestSide / _side) / math.log(widestSide / narrowestSide)).clamp(0.0, 1.0) : 0;

  /// Whether a finger, the pointer or a slider is moving the picture: the
  /// guide lines show meanwhile.
  bool get interacting => _holds > 0;

  /// The square that is in view, in whole source pixels inside the image.
  AvatarCrop get crop {
    final side = _side.round().clamp(1, _shortSide.floor());
    final x = (_center.dx - _side / 2).round().clamp(0, sourceWidth - side);
    final y = (_center.dy - _side / 2).round().clamp(0, sourceHeight - side);
    return AvatarCrop(x: x, y: y, side: side);
  }

  /// The part of the source image that is in view.
  Rect get visibleRect => Rect.fromCenter(center: _center, width: _side, height: _side);

  void _keepInside() {
    final half = _side / 2;
    _center = Offset(_center.dx.clamp(half, sourceWidth - half), _center.dy.clamp(half, sourceHeight - half));
  }

  /// Moves the picture by [delta] logical pixels, as a drag does.
  void panBy(Offset delta) {
    if (viewport <= 0) return;
    _center -= delta / scale;
    _keepInside();
    notifyListeners();
  }

  /// Shows [side] source pixels, clamped to the zoom range, around [focal]
  /// (a position in the viewport, 0 to 1 on each axis) that stays where it is.
  void zoomToSide(double side, {Offset focal = const Offset(.5, .5)}) {
    final next = side.clamp(narrowestSide, widestSide);
    final origin = _center - Offset(_side / 2, _side / 2);
    final anchor = origin + Offset(focal.dx * _side, focal.dy * _side);
    _side = next;
    _center = anchor - Offset(focal.dx * next, focal.dy * next) + Offset(next / 2, next / 2);
    _keepInside();
    notifyListeners();
  }

  /// Zooms in by [factor] (out below 1) around [focal].
  void zoomBy(double factor, {Offset focal = const Offset(.5, .5)}) => zoomToSide(_side / factor, focal: focal);

  /// Sets the zoom as a share of the range, around the viewport's centre.
  void setZoom(double value) {
    if (!canZoom) return;
    final share = value.clamp(0.0, 1.0);
    zoomToSide(widestSide * math.pow(narrowestSide / widestSide, share).toDouble());
  }

  /// Back to the whole short side, centred.
  void reset() {
    _side = _shortSide;
    _center = Offset(sourceWidth / 2, sourceHeight / 2);
    notifyListeners();
  }

  /// Something starts moving the picture; pair with [release].
  void hold() {
    _holds++;
    if (_holds == 1) notifyListeners();
  }

  void release() {
    if (_holds == 0) return;
    _holds--;
    if (_holds == 0) notifyListeners();
  }
}

const _maskDim = Color(0x8C000000);
const _guideColor = Color(0x99FFFFFF);
const _circleColor = Color(0xFFFFFFFF);
const _backdrop = Color(0xFF101012);
const _guideFade = Duration(milliseconds: 180);
const _wheelZoom = Duration(milliseconds: 140);
const _wheelRest = Duration(milliseconds: 450);
// What a dialog keeps for its title, the slider and the buttons, and the room around them.
const _dialogChrome = 300.0;
const _viewportMinimum = 200.0;
const _sliderGap = 16.0;

/// The square viewport: the image under a circular cut-out mask, with the
/// rule-of-thirds guides while it is being moved.
class AvatarCropViewport extends StatefulWidget {
  const AvatarCropViewport({required this.image, required this.controller, super.key});

  final ui.Image image;
  final AvatarCropController controller;

  @override
  State<AvatarCropViewport> createState() => _AvatarCropViewportState();
}

class _AvatarCropViewportState extends State<AvatarCropViewport> with SingleTickerProviderStateMixin {
  late final _wheel = AnimationController(vsync: this, duration: _wheelZoom);
  Timer? _wheelRelease;
  bool _wheelHeld = false;
  double _gestureStartSide = 1;
  int _pointers = 0;
  Offset _wheelFocal = const Offset(.5, .5);
  double _wheelFrom = 1, _wheelTo = 1;

  AvatarCropController get _controller => widget.controller;

  @override
  void dispose() {
    _wheelRelease?.cancel();
    _wheel.dispose();
    super.dispose();
  }

  Offset _focalOf(Offset local) {
    final side = _controller.viewport;
    return side <= 0 ? const Offset(.5, .5) : Offset((local.dx / side).clamp(0.0, 1.0), (local.dy / side).clamp(0.0, 1.0));
  }

  void _pointerDown(PointerDownEvent event) {
    _pointers++;
    _controller.hold();
  }

  void _pointerEnd(PointerEvent event) {
    if (_pointers == 0) return;
    _pointers--;
    _controller.release();
  }

  void _scaleStart(ScaleStartDetails details) {
    _wheel.stop();
    _gestureStartSide = _controller.visibleSide;
  }

  void _scaleUpdate(ScaleUpdateDetails details) {
    _controller.panBy(details.focalPointDelta);
    if (details.pointerCount > 1 || details.scale != 1) {
      _controller.zoomToSide(_gestureStartSide / details.scale, focal: _focalOf(details.localFocalPoint));
    }
  }

  void _wheelTick() => _controller.zoomToSide(ui.lerpDouble(_wheelFrom, _wheelTo, Curves.easeOutCubic.transform(_wheel.value))!, focal: _wheelFocal);

  void _signal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.scrollDelta.dy == 0) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      event as PointerScrollEvent;
      // Each notch of 100 is about a sixth more or less of the view.
      final factor = math.exp(-event.scrollDelta.dy * .0016);
      _wheelFocal = _focalOf(event.localPosition);
      if (!_wheelHeld) {
        _wheelHeld = true;
        _controller.hold();
      }
      _wheelRelease?.cancel();
      _wheelRelease = Timer(_wheelRest, () {
        _wheelHeld = false;
        _controller.release();
      });
      final target = (_wheel.isAnimating ? _wheelTo : _controller.visibleSide) / factor;
      if (MediaQuery.disableAnimationsOf(context)) {
        _wheel.stop();
        _controller.zoomToSide(target, focal: _wheelFocal);
        return;
      }
      _wheelFrom = _controller.visibleSide;
      _wheelTo = target.clamp(_controller.narrowestSide, _controller.widestSide);
      _wheel
        ..removeListener(_wheelTick)
        ..addListener(_wheelTick)
        ..forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = constraints.biggest.shortestSide;
      _controller.viewport = side;
      return Semantics(
        label: context.t.profileEdit.cropTitle,
        image: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Listener(
            onPointerDown: _pointerDown,
            onPointerUp: _pointerEnd,
            onPointerCancel: _pointerEnd,
            onPointerSignal: _signal,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _scaleStart,
              onScaleUpdate: _scaleUpdate,
              child: SizedBox.square(
                dimension: side,
                child: RepaintBoundary(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(painter: _ImagePainter(widget.image, _controller)),
                      const CustomPaint(painter: _MaskPainter()),
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) => IgnorePointer(
                          child: AnimatedOpacity(
                            key: const ValueKey('avatarCropGuides'),
                            opacity: _controller.interacting ? 1 : 0,
                            duration: FrostMotion.duration(context, _guideFade),
                            child: const CustomPaint(painter: _GuidePainter()),
                          ),
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
    },
  );
}

class _ImagePainter extends CustomPainter {
  _ImagePainter(this.image, this.controller) : super(repaint: controller);

  final ui.Image image;
  final AvatarCropController controller;

  @override
  void paint(Canvas canvas, Size size) {
    // The picture always covers the viewport. Not anti-aliased: the edge of
    // the rectangle is the viewport's own, and blending along its diagonal
    // would leave a faint seam.
    canvas.drawImageRect(
      image,
      controller.visibleRect,
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) => oldDelegate.image != image || oldDelegate.controller != controller;
}

/// Dims what Pixiv's round display cuts off and draws the circle's edge.
class _MaskPainter extends CustomPainter {
  const _MaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final circle = Rect.fromCircle(center: bounds.center, radius: size.shortestSide / 2);
    final outside = Path.combine(PathOperation.difference, Path()..addRect(bounds), Path()..addOval(circle));
    canvas.drawPath(outside, Paint()..color = _maskDim);
    canvas.drawOval(
      circle.deflate(.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _circleColor
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_MaskPainter oldDelegate) => false;
}

class _GuidePainter extends CustomPainter {
  const _GuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _guideColor
      ..strokeWidth = 1;
    for (final share in const [1 / 3, 2 / 3]) {
      canvas.drawLine(Offset(size.width * share, 0), Offset(size.width * share, size.height), paint);
      canvas.drawLine(Offset(0, size.height * share), Offset(size.width, size.height * share), paint);
    }
  }

  @override
  bool shouldRepaint(_GuidePainter oldDelegate) => false;
}

/// The slider under the viewport.
class AvatarCropZoomSlider extends StatefulWidget {
  const AvatarCropZoomSlider({required this.controller, super.key});

  final AvatarCropController controller;

  @override
  State<AvatarCropZoomSlider> createState() => _AvatarCropZoomSliderState();
}

class _AvatarCropZoomSliderState extends State<AvatarCropZoomSlider> {
  bool _held = false;

  void _end() {
    if (!_held) return;
    _held = false;
    widget.controller.release();
  }

  @override
  void dispose() {
    _end();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => FrostSlider(
      value: widget.controller.zoom,
      semanticLabel: context.t.profileEdit.cropZoom,
      onChanged: widget.controller.canZoom
          ? (value) {
              if (!_held) {
                _held = true;
                widget.controller.hold();
              }
              widget.controller.setZoom(value);
            }
          : null,
      onChangeEnd: (_) => _end(),
    ),
  );
}

/// Asks for the part of [image] a profile image keeps. A dialog on wide
/// windows, a page of its own on narrow ones; null when it is cancelled.
Future<AvatarCrop?> showAvatarCropper(BuildContext context, {required ui.Image image}) async {
  AvatarCrop? chosen;
  void choose(AvatarCrop crop) => chosen = crop;
  final bool? done;
  if (FrostSizeClass.of(context) == FrostSizeClass.compact) {
    // The shell's download button would lie over the slider.
    final page = FrostDetailPage<bool>(
      child: ImmersivePage(
        child: _AvatarCropPage(image: image, onChoose: choose),
      ),
    );
    done = await Navigator.of(context).push<bool>(page.createRoute(context));
  } else {
    done = await showFrostDialog<bool>(
      context: context,
      builder: (context) => _AvatarCropDialog(image: image, onChoose: choose),
    );
  }
  return done == true ? chosen : null;
}

/// Owns the controller for as long as its dialog or page is on screen,
/// including the time it spends leaving.
mixin _OwnsCropController<T extends StatefulWidget> on State<T> {
  ui.Image get image;
  late final controller = AvatarCropController(sourceWidth: image.width, sourceHeight: image.height);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _AvatarCropDialog extends StatefulWidget {
  const _AvatarCropDialog({required this.image, required this.onChoose});

  final ui.Image image;
  final ValueChanged<AvatarCrop> onChoose;

  @override
  State<_AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<_AvatarCropDialog> with _OwnsCropController {
  @override
  ui.Image get image => widget.image;

  @override
  Widget build(BuildContext context) {
    final t = context.t.profileEdit;
    return FrostDialog(
      title: t.cropTitle,
      scrollable: false,
      leadingAction: FrostDialogAction(
        label: context.t.common.reset,
        onPressed: () {
          controller.reset();
          return false;
        },
      ),
      actions: [
        FrostDialogAction(label: context.t.common.cancel, role: FrostButtonRole.cancel),
        FrostDialogAction(
          label: t.cropDone,
          value: true,
          isDefault: true,
          onPressed: () {
            widget.onChoose(controller.crop);
            return true;
          },
        ),
      ],
      content: LayoutBuilder(
        builder: (context, constraints) {
          // As wide as the dialog allows, kept to what the window's height
          // leaves besides the title, the slider and the buttons.
          final side = math.max(_viewportMinimum, math.min(constraints.maxWidth, MediaQuery.sizeOf(context).height - _dialogChrome));
          return Align(
            heightFactor: 1,
            child: SizedBox(
              width: side,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox.square(
                    dimension: side,
                    child: AvatarCropViewport(image: image, controller: controller),
                  ),
                  const SizedBox(height: _sliderGap),
                  AvatarCropZoomSlider(controller: controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AvatarCropPage extends StatefulWidget {
  const _AvatarCropPage({required this.image, required this.onChoose});

  final ui.Image image;
  final ValueChanged<AvatarCrop> onChoose;

  @override
  State<_AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<_AvatarCropPage> with _OwnsCropController {
  @override
  ui.Image get image => widget.image;

  @override
  Widget build(BuildContext context) {
    final t = context.t.profileEdit;
    void done() {
      widget.onChoose(controller.crop);
      Navigator.of(context).pop(true);
    }

    return FrostPinnedChrome(
      chrome: FrostPageHeader(
        title: FrostText(t.cropTitle),
        actions: [
          FrostToolbarItem.custom(
            minWidth: MediaQuery.textScalerOf(context).scale(72),
            plated: true,
            overflowEntry: FrostMenuAction(t.cropDone, onSelected: done),
            builder: (context) => FrostButton.prominent(label: t.cropDone, onPressed: done),
          ),
        ],
      ),
      body: Builder(
        builder: (context) => Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ColoredBox(
                  color: _backdrop,
                  child: Padding(
                    padding: const EdgeInsets.all(FrostGap.panelInset),
                    child: Center(
                      child: AvatarCropViewport(image: image, controller: controller),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(FrostGap.panelInset, _sliderGap, FrostGap.panelInset, FrostGap.panelInset),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AvatarCropZoomSlider(controller: controller),
                      const SizedBox(height: FrostGap.related),
                      Align(
                        child: FrostButton.quiet(label: context.t.common.reset, onPressed: controller.reset),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
