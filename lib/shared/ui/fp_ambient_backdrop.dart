import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/accent_color_math.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/theme/transparency_logic.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';

/// Window-wide ambient state shared by every [FpAmbientBackdrop] painter.
///
/// The shell paints one backdrop behind the title bar and navigation, and a
/// route paints an identical one beneath itself while it animates. Both read
/// this controller and paint in window coordinates, so the page and the glass
/// around it always agree, including during the artwork cross-fade.
class AmbientBackdropController extends ChangeNotifier {
  ui.Image? _current;
  ui.Image? _previous;
  double _progress = 1;

  ui.Image? get current => _current;
  ui.Image? get previous => _previous;
  double get progress => _progress;

  void _show(ui.Image? image) {
    if (identical(image, _current)) return;
    _previous?.dispose();
    _previous = _current;
    _current = image;
    _progress = 0;
    notifyListeners();
  }

  void _setProgress(double value) {
    if (_progress == value) return;
    _progress = value;
    if (value >= 1) {
      _previous?.dispose();
      _previous = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _current?.dispose();
    _previous?.dispose();
    super.dispose();
  }
}

class _AmbientScope extends InheritedWidget {
  const _AmbientScope({required this.controller, required super.child});

  final AmbientBackdropController controller;

  @override
  bool updateShouldNotify(_AmbientScope oldWidget) => !identical(controller, oldWidget.controller);
}

/// Owns the ambient state for the window and paints it behind [child].
///
/// [artworkUrl] is the current page's artwork thumbnail, if any. It is
/// decoded at a tiny size and pre-blurred once, so painting it every frame is
/// a single scaled image draw rather than a live full-window blur.
class AmbientBackdropHost extends ConsumerStatefulWidget {
  const AmbientBackdropHost({required this.artworkUrl, required this.child, super.key});

  final String? artworkUrl;
  final Widget child;

  @override
  ConsumerState<AmbientBackdropHost> createState() => _AmbientBackdropHostState();
}

class _AmbientBackdropHostState extends ConsumerState<AmbientBackdropHost> with SingleTickerProviderStateMixin {
  static const _sampleWidth = 48;
  final _controller = AmbientBackdropController();
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))
    ..addListener(() => _controller._setProgress(Curves.easeInOut.transform(_fade.value)));
  final Map<String, ui.Image> _blurred = {};
  String? _requested;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request(widget.artworkUrl);
  }

  @override
  void didUpdateWidget(AmbientBackdropHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artworkUrl != widget.artworkUrl) _request(widget.artworkUrl);
  }

  void _request(String? url) {
    if (url == _requested) return;
    _requested = url;
    _detachStream();
    if (url == null) {
      _present(null);
      return;
    }
    if (_blurred[url] case final cached?) {
      _present(cached.clone());
      return;
    }
    final transport = ref.read(rustMediaTransportProvider);
    final provider = RustExtendedNetworkImageProvider(
      request: MediaRequest(url: url, headers: const {'Referer': 'https://www.pixiv.net/'}),
      decodeWidth: _sampleWidth,
      mediaStream: transport.stream,
      mediaStreamCacheIdentity: transport.imageCacheIdentity,
    );
    final stream = provider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) {
      final source = info.image;
      _detachStream();
      unawaited(_blur(source).then((image) => _accept(url, image)).whenComplete(info.dispose));
    }, onError: (_, _) => _detachStream());
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _detachStream() {
    if (_listener case final listener?) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  static Future<ui.Image> _blur(ui.Image source) {
    final width = _sampleWidth;
    final height = (width * source.height / source.width).round().clamp(8, 96);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    // Clamp the edges so the blur does not fade to transparent at the border.
    canvas.saveLayer(bounds, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3, tileMode: TileMode.clamp));
    canvas.drawImageRect(source, Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()), bounds, Paint()..filterQuality = FilterQuality.medium);
    canvas.restore();
    final picture = recorder.endRecording();
    return picture.toImage(width, height).whenComplete(picture.dispose);
  }

  void _accept(String url, ui.Image image) {
    if (!mounted) {
      image.dispose();
      return;
    }
    if (_blurred.length >= 12) _blurred.remove(_blurred.keys.first)?.dispose();
    _blurred[url] = image;
    if (_requested == url) _present(image.clone());
  }

  void _present(ui.Image? image) {
    if (image == null && _controller.current == null) return;
    _controller._show(image);
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller._setProgress(1);
    } else {
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _detachStream();
    _fade.dispose();
    _controller.dispose();
    for (final image in _blurred.values) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AmbientScope(
      controller: _controller,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: FpAmbientBackdrop()),
          widget.child,
        ],
      ),
    );
  }
}

/// Paints the window's ambient backdrop, aligned to the window rather than to
/// this widget. Use it wherever the ambient layer has to be opaque locally,
/// such as beneath a route while its transition overlaps the previous page.
class FpAmbientBackdrop extends ConsumerWidget {
  const FpAmbientBackdrop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = FreepivThemeTokens.of(context);
    final plain = ref.watch(reduceTransparencyProvider) || MediaQuery.highContrastOf(context);
    final controller = context.dependOnInheritedWidgetOfExactType<_AmbientScope>()?.controller;
    // No repaint boundary here: the backdrop is window-aligned, so it has to
    // repaint when an ancestor transition moves it.
    return _AmbientPaint(controller: plain ? null : controller, tokens: tokens, plain: plain);
  }
}

class _AmbientPaint extends LeafRenderObjectWidget {
  const _AmbientPaint({required this.controller, required this.tokens, required this.plain});

  final AmbientBackdropController? controller;
  final FreepivThemeTokens tokens;
  final bool plain;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAmbient(controller: controller, tokens: tokens, plain: plain);

  @override
  void updateRenderObject(BuildContext context, _RenderAmbient renderObject) {
    renderObject
      ..controller = controller
      ..tokens = tokens
      ..plain = plain;
  }
}

class _RenderAmbient extends RenderBox {
  _RenderAmbient({required this._controller, required this._tokens, required this._plain});

  AmbientBackdropController? _controller;
  set controller(AmbientBackdropController? value) {
    if (identical(value, _controller)) return;
    if (attached) {
      _controller?.removeListener(markNeedsPaint);
      value?.addListener(markNeedsPaint);
    }
    _controller = value;
    markNeedsPaint();
  }

  FreepivThemeTokens _tokens;
  set tokens(FreepivThemeTokens value) {
    if (value == _tokens) return;
    _tokens = value;
    markNeedsPaint();
  }

  bool _plain;
  set plain(bool value) {
    if (value == _plain) return;
    _plain = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _controller?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final local = offset & size;
    canvas.drawRect(local, Paint()..color = _tokens.canvas);
    if (_plain) return;
    // Window geometry: the view's logical size and this box's window origin.
    final view = ui.PlatformDispatcher.instance.implicitView;
    final window = view == null ? size : view.physicalSize / view.devicePixelRatio;
    final origin = localToGlobal(Offset.zero);
    final windowRect = (offset - origin) & window;
    canvas.save();
    canvas.clipRect(local);
    final controller = _controller;
    if (controller != null) {
      final opacity = _tokens.isDark ? .34 : .40;
      if (controller.previous case final previous? when controller.progress < 1) {
        _paintArtwork(canvas, previous, windowRect, opacity * (1 - controller.progress));
      }
      if (controller.current case final current?) {
        _paintArtwork(canvas, current, windowRect, opacity * controller.progress);
      }
    }
    // Two low-saturation accent washes anchored to opposite window corners.
    final wash = ambientAccent(_tokens.accent);
    final extent = windowRect.longestSide;
    canvas.drawRect(
      local,
      Paint()
        ..shader = RadialGradient(
          colors: [
            wash.withValues(alpha: _tokens.isDark ? .16 : .12),
            wash.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: windowRect.topLeft + Offset(windowRect.width * .12, 0), radius: extent * .62)),
    );
    final counter = HSLColor.fromColor(wash);
    canvas.drawRect(
      local,
      Paint()
        ..shader = RadialGradient(
          colors: [
            counter.withHue((counter.hue + 38) % 360).toColor().withValues(alpha: _tokens.isDark ? .10 : .08),
            counter.toColor().withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: windowRect.bottomRight, radius: extent * .55)),
    );
    canvas.restore();
  }

  void _paintArtwork(Canvas canvas, ui.Image image, Rect windowRect, double opacity) {
    if (opacity <= 0) return;
    final source = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, source.size, windowRect.size);
    final destination = Alignment.center.inscribe(fitted.destination, windowRect);
    canvas.drawImageRect(
      image,
      Alignment.center.inscribe(fitted.source, source),
      destination,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = const ColorFilter.matrix(_desaturate)
        ..color = Color.fromRGBO(0, 0, 0, opacity),
    );
  }

  // Saturation .7 so the artwork tints the page without competing with it.
  static const _desaturate = <double>[
    0.7639, 0.2145, 0.0216, 0, 0, //
    0.0639, 0.9145, 0.0216, 0, 0, //
    0.0639, 0.2145, 0.7216, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}
