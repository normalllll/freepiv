import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart' show FrostRadius;
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:go_router/go_router.dart';

/// Opens a work from a card that carries its own hero tag.
typedef IllustOpener = void Function(Illust illust, ArtworkHeroTag heroTag);

/// Pushes the illustration page for [illust]. With the opening card's
/// [heroTag] the card's image flies into the stage and back.
void openIllustDetail(BuildContext context, Illust illust, [ArtworkHeroTag? heroTag]) {
  context.push(AppLocations.illust(illust.id), extra: heroTag == null ? illust : (illust: illust, heroTag: heroTag));
}

/// Pairs one artwork card with the detail page it opens.
///
/// Each card instance owns its own tag, compared by identity, so the same
/// work shown in several places at once (the ranking strip and the feed, a
/// background tab, the author's recent works on the detail page) never
/// shares a hero tag: only the tapped card and the detail stage it opened
/// match. A tag is never derived from the work's id for that reason.
final class ArtworkHeroTag {
  ArtworkHeroTag({required this.imageUrl, required this.aspectRatio, required this.sourceRadius});

  /// The uncropped preview the card shows (square cards crop it from the
  /// centre); already cached, so the flight never waits on the network.
  final String imageUrl;

  /// Width over height of the work, for continuous cover-to-contain framing.
  final double aspectRatio;

  /// Corner radius of the card's image, animated to the stage's square edge.
  final BorderRadius sourceRadius;

  @override
  String toString() => 'ArtworkHeroTag#${identityHashCode(this)}';
}

/// Owns one card's [ArtworkHeroTag] for as long as the card shows the same
/// image, so the detail page can fly back to it; a card reused for another
/// image gets a new tag.
class ArtworkHeroSource extends StatefulWidget {
  const ArtworkHeroSource({required this.illust, required this.imageUrl, required this.sourceRadius, required this.builder, super.key});

  final Illust illust;

  /// The uncropped preview the card shows.
  final String imageUrl;
  final BorderRadius sourceRadius;
  final Widget Function(BuildContext context, ArtworkHeroTag tag) builder;

  @override
  State<ArtworkHeroSource> createState() => _ArtworkHeroSourceState();
}

class _ArtworkHeroSourceState extends State<ArtworkHeroSource> {
  ArtworkHeroTag? _tag;

  ArtworkHeroTag get _current {
    final current = _tag;
    if (current != null && current.imageUrl == widget.imageUrl && current.sourceRadius == widget.sourceRadius) return current;
    final illust = widget.illust;
    return _tag = ArtworkHeroTag(
      imageUrl: widget.imageUrl,
      aspectRatio: illust.width > 0 && illust.height > 0 ? illust.width / illust.height : 1,
      sourceRadius: widget.sourceRadius,
    );
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _current);
}

/// The tag of the card that opened the current detail page, if any.
class ArtworkHeroScope extends InheritedWidget {
  const ArtworkHeroScope({required this.tag, required super.child, super.key});

  final ArtworkHeroTag? tag;

  static ArtworkHeroTag? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ArtworkHeroScope>()?.tag;

  @override
  bool updateShouldNotify(ArtworkHeroScope oldWidget) => tag != oldWidget.tag;
}

/// Where the detail stage's picture is while a back swipe moves the page, for
/// the flight that carries it back to its card.
///
/// The stage registers one per tag (see [ArtworkStageHero]); the card's hero,
/// whose tween the flight uses on a pop, finds it by the shared tag.
final class _StagePose {
  _StagePose(this.key);

  final GlobalKey key;

  /// Marks the picture's place in the page, so the flying picture can follow
  /// the page's own transform while the finger drags: the follower is placed
  /// when the layers are composited, after the page has moved, where a rect
  /// read while building would be a frame behind.
  final link = LayerLink();
  ModalRoute<Object?>? route;

  /// Where the picture was when the swipe was committed: the flight carries it
  /// on from there.
  Rect? held;

  bool get userGesture => route?.navigator?.userGestureInProgress ?? false;

  /// Committing restarts the route's animation from fully shown and runs it to
  /// dismissed, so it is reversing; while the finger drags it is not.
  bool get committing => userGesture && route?.animation?.status == AnimationStatus.reverse;
  bool get dragging => userGesture && !committing;

  /// The picture's frame in the navigator, with the page's own back-swipe
  /// transform (scale, shift) applied.
  Rect? liveRect() {
    final box = key.currentContext?.findRenderObject();
    final navigator = route?.navigator?.context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize || navigator is! RenderBox) return null;
    return MatrixUtils.transformRect(box.getTransformTo(navigator), Offset.zero & box.size);
  }
}

/// The page's own edge while a back swipe moves it: the page rounds its
/// corners as it shrinks and clips what is in it, but the flying picture is
/// above the page, so it takes the same rounded edge, in the picture's own
/// (unscaled) coordinates.
class _PageEdgeClipper extends CustomClipper<RRect> {
  _PageEdgeClipper(this.stage, Listenable reclip) : super(reclip: reclip);

  final _StagePose stage;

  @override
  RRect getClip(Size size) {
    final picture = stage.key.currentContext?.findRenderObject();
    final page = stage.route?.subtreeContext?.findRenderObject();
    final bounds = picture is RenderBox && picture.attached && page is RenderBox && page.attached && page.hasSize
        ? MatrixUtils.transformRect(page.getTransformTo(picture), Offset.zero & page.size)
        : Offset.zero & size;
    // The radius follows the swipe as the page's own does (frost_ui's drag pose).
    final progress = (1 - (stage.route?.animation?.value ?? 1)).clamp(0.0, 1.0);
    return RRect.fromRectAndRadius(bounds, Radius.circular(FrostRadius.xxl * (progress * 4).clamp(0.0, 1.0)));
  }

  @override
  bool shouldReclip(_PageEdgeClipper oldClipper) => true;
}

final Expando<_StagePose> _stagePoses = Expando('ArtworkHero stage pose');

/// A straight path, not Material's arc: the picture travels directly between
/// the card and the stage. A back swipe moves the page, so while the finger
/// drags, the picture stays where the page puts it (the shuttle follows the
/// stage, see [_StagePose.link], and the tween holds still); a committed swipe
/// then flies it on from there.
class _FlightRectTween extends RectTween {
  _FlightRectTween({required super.begin, required super.end, required this.tag});

  final ArtworkHeroTag tag;

  @override
  Rect? lerp(double t) {
    final stage = _stagePoses[tag];
    if (stage == null || !stage.userGesture) {
      stage?.held = null;
      return super.lerp(t);
    }
    if (stage.dragging) return begin;
    return Rect.lerp(stage.held ??= stage.liveRect() ?? begin, end, t);
  }
}

/// The detail stage's artwork hero: an [ArtworkHero] whose position a back
/// swipe can read, so the picture moves with the page while the finger drags.
class ArtworkStageHero extends StatefulWidget {
  const ArtworkStageHero({required this.tag, required this.child, super.key});

  final ArtworkHeroTag tag;
  final Widget child;

  @override
  State<ArtworkStageHero> createState() => _ArtworkStageHeroState();
}

class _ArtworkStageHeroState extends State<ArtworkStageHero> {
  final _pose = _StagePose(GlobalKey());

  @override
  void initState() {
    super.initState();
    _stagePoses[widget.tag] = _pose;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pose.route = ModalRoute.of(context);
  }

  @override
  void didUpdateWidget(ArtworkStageHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag == widget.tag) return;
    if (identical(_stagePoses[oldWidget.tag], _pose)) _stagePoses[oldWidget.tag] = null;
    _stagePoses[widget.tag] = _pose;
  }

  @override
  void dispose() {
    if (identical(_stagePoses[widget.tag], _pose)) _stagePoses[widget.tag] = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _pose.link,
    child: KeyedSubtree(
      key: _pose.key,
      child: ArtworkHero(tag: widget.tag, child: widget.child),
    ),
  );
}

/// The hero around an artwork on either end of the flight.
class ArtworkHero extends StatelessWidget {
  const ArtworkHero({required this.tag, required this.child, super.key});

  final ArtworkHeroTag tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // With reduced motion the page simply appears; nothing flies.
    return HeroMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      // Also on user gestures, so a back swipe's flight exists from the start:
      // it stays with the page while the finger drags and flies on when the
      // swipe is committed (see [_FlightRectTween]).
      child: Hero(
        tag: tag,
        transitionOnUserGestures: true,
        createRectTween: (begin, end) => _FlightRectTween(begin: begin, end: end, tag: tag),
        flightShuttleBuilder: _flight,
        child: child,
      ),
    );
  }

  static Widget _flight(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final tag = (fromContext.widget as Hero).tag as ArtworkHeroTag;
    // Both ends are the picture's own frame: the card's image area and the
    // picture as the stage shows it. Covering the flying frame is therefore
    // exact at both ends, and the card's crop (square tiles, clamped ratios)
    // relaxes steadily as the frame's shape approaches the picture's, with no
    // second timing that could make the picture shrink and regrow. The route
    // animation runs 0 → 1 on push and 1 → 0 on pop: 0 is the card.
    final picture = PixivImage(url: tag.imageUrl);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // While a swipe drags the page the picture is the stage's own
        // square-edged one, following it; the radius and the path to the card
        // begin only when the swipe is committed.
        final stage = _stagePoses[tag];
        if (stage != null && stage.dragging) {
          return CompositedTransformFollower(
            link: stage.link,
            showWhenUnlinked: false,
            child: ClipRRect(clipper: _PageEdgeClipper(stage, animation), child: child),
          );
        }
        return ClipRRect(borderRadius: BorderRadius.lerp(tag.sourceRadius, BorderRadius.zero, Curves.fastOutSlowIn.transform(animation.value))!, child: child);
      },
      child: picture,
    );
  }
}
