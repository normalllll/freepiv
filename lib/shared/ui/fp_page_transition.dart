import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/ui/fp_ambient_backdrop.dart';
import 'package:freepiv/shared/ui/spring_builder.dart';

/// Page transition shared by pushed routes (docs/MOTION_SPEC.md 5).
///
/// Pushed pages live in the content area beside the sidebar, so the motion
/// stays there too: with the sidebar a page fades in while growing from 0.98,
/// on a phone it rises 24 px. A page an artwork flies into ([heroLed]) moves
/// half as much, leaving the flight as the one motion to follow. On Android a
/// back swipe drives the page directly (predictive back).
///
/// The incoming page carries its own copy of the ambient backdrop while it
/// animates, so transparent pages never show the page underneath through them.
Widget fpPageTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child, {bool heroLed = false}) {
  if (MediaQuery.disableAnimationsOf(context)) return child;
  return _PageTransition(animation: animation, secondaryAnimation: secondaryAnimation, heroLed: heroLed, child: child);
}

class FpPageTransitionsBuilder extends PageTransitionsBuilder {
  const FpPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  Duration get reverseTransitionDuration => AppMotion.exit;

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) =>
      fpPageTransition(context, animation, secondaryAnimation, child);
}

enum _BackPhase { idle, dragging, committing }

class _PageTransition extends StatefulWidget {
  const _PageTransition({required this.animation, required this.secondaryAnimation, required this.heroLed, required this.child});

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool heroLed;
  final Widget child;

  @override
  State<_PageTransition> createState() => _PageTransitionState();
}

class _PageTransitionState extends State<_PageTransition> with WidgetsBindingObserver {
  // A no-bounce spring's path over the page duration: it has settled by the
  // end, so hero flights keep their timing. Exits stay a quicker ease-in.
  static final _enterCurve = SpringCurve(AppMotion.snappy, AppMotion.page);

  late CurvedAnimation _incoming;
  late CurvedAnimation _covered;
  ModalRoute<Object?>? _route;

  _BackPhase _phase = _BackPhase.idle;
  PredictiveBackEvent? _startEvent;
  PredictiveBackEvent? _lastEvent;

  /// The page's pose when the swipe was committed; the exit continues from it.
  _BackPose _committedFrom = _BackPose.rest;

  @override
  void initState() {
    super.initState();
    _curve();
    WidgetsBinding.instance.addObserver(this);
  }

  void _curve() {
    _incoming = CurvedAnimation(parent: widget.animation, curve: _enterCurve, reverseCurve: Curves.easeInCubic);
    _covered = CurvedAnimation(parent: widget.secondaryAnimation, curve: _enterCurve, reverseCurve: Curves.easeInCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void didUpdateWidget(_PageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation || widget.secondaryAnimation != oldWidget.secondaryAnimation) {
      _incoming.dispose();
      _covered.dispose();
      _curve();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _incoming.dispose();
    _covered.dispose();
    super.dispose();
  }

  // Predictive back. Every pushed page listens, so only the page on top of
  // the content navigator answers, and not while a dialog or sheet on the
  // root navigator covers it: then Back closes that instead.
  bool get _swipeable {
    final route = _route;
    if (route == null || !mounted || !route.isCurrent || !route.popGestureEnabled) return false;
    final root = Navigator.of(context, rootNavigator: true);
    return route.navigator == root || !root.canPop();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent || !_swipeable) return false;
    _route!.handleStartBackGesture(progress: 1 - backEvent.progress);
    setState(() {
      _phase = _BackPhase.dragging;
      _startEvent = _lastEvent = backEvent;
    });
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    _route?.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);
    setState(() => _lastEvent = backEvent);
  }

  @override
  void handleCancelBackGesture() {
    // The route animates back to fully shown; the pose follows it to rest.
    _route?.handleCancelBackGesture();
  }

  @override
  void handleCommitBackGesture() {
    _committedFrom = _dragPose(MediaQuery.sizeOf(context));
    setState(() => _phase = _BackPhase.committing);
    _route?.handleCommitBackGesture();
  }

  /// The page follows the finger: it shrinks toward 0.9, shifts away from
  /// the edge the swipe started at and a little with vertical movement, and
  /// rounds its corners, uncovering the page below (Android's predictive back
  /// motion, within the content area).
  _BackPose _dragPose(Size size) {
    final progress = (1 - widget.animation.value).clamp(0.0, 1.0);
    final shiftLimit = math.max(0.0, size.width / 20 - 8);
    final direction = _lastEvent?.swipeEdge == SwipeEdge.right ? -1.0 : 1.0;
    final verticalLimit = math.max(0.0, size.height / 20 - 8);
    final verticalDrag = (_lastEvent?.touchOffset?.dy ?? 0) - (_startEvent?.touchOffset?.dy ?? 0);
    final vertical = Curves.easeOut.transform((verticalDrag.abs() / size.height).clamp(0.0, 1.0)) * verticalDrag.sign * verticalLimit;
    // The vertical shift eases back with the rest of the pose when the swipe is
    // cancelled.
    final lastProgress = _lastEvent?.progress ?? 0;
    final verticalShare = lastProgress <= 0 ? 0.0 : (progress / lastProgress).clamp(0.0, 1.0);
    return _BackPose(
      scale: 1 - .1 * progress,
      offset: Offset(direction * shiftLimit * progress, vertical * verticalShare),
      radius: AppMetrics.modalRadius * (progress * 4).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigator = _route?.navigator;
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, ?navigator?.userGestureInProgressNotifier]),
      builder: (context, child) {
        final swiping = (navigator?.userGestureInProgress ?? false) && _phase != _BackPhase.idle;
        final (pose, opacity) = switch (_phase) {
          _ when !swiping => _pushedPose(context),
          _BackPhase.committing => _committedPose(),
          _ => (_dragPose(MediaQuery.sizeOf(context)), 1.0),
        };
        final moving = widget.animation.status != AnimationStatus.completed;
        // Fade and transform are layer properties: the page itself is painted
        // once into its repaint boundary instead of on every frame. One tree
        // shape for every state keeps the page's state when the backdrop copy
        // is dropped or a swipe starts.
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(pose.scale, pose.scale, 1)..setTranslationRaw(pose.offset.dx, pose.offset.dy, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(pose.radius),
              clipBehavior: pose.radius > 0 ? Clip.antiAlias : Clip.none,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Positioned.fill(child: moving ? const FpAmbientBackdrop() : const SizedBox.shrink()),
                  child!,
                ],
              ),
            ),
          ),
        );
      },
      child: RepaintBoundary(child: widget.child),
    );
  }

  (_BackPose, double) _pushedPose(BuildContext context) {
    final hidden = 1 - _incoming.value;
    final amount = widget.heroLed ? .5 : 1.0;
    final pose = AutoScaffold.usesHorizontalLayoutOf(context)
        ? _BackPose(scale: 1 - .02 * amount * hidden, offset: Offset.zero, radius: 0)
        : _BackPose(scale: 1, offset: Offset(0, 24 * amount * hidden), radius: 0);
    // Covered pages dim slightly.
    return (pose, _incoming.value * (1 - _covered.value * .06));
  }

  /// After the swipe is committed the page keeps its pose, shrinks a little
  /// further and fades out.
  (_BackPose, double) _committedPose() {
    final exit = Curves.easeOutCubic.transform((1 - widget.animation.value).clamp(0.0, 1.0));
    final pose = _committedFrom;
    return (_BackPose(scale: pose.scale * (1 - .04 * exit), offset: pose.offset, radius: pose.radius), 1 - exit);
  }
}

class _BackPose {
  const _BackPose({required this.scale, required this.offset, required this.radius});

  static const rest = _BackPose(scale: 1, offset: Offset.zero, radius: 0);

  final double scale;
  final Offset offset;
  final double radius;
}
