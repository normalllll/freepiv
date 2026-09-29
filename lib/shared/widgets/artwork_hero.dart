import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:go_router/go_router.dart';

/// Opens a work from a card that carries its own hero tag.
typedef IllustOpener = void Function(Illust illust, ArtworkHeroTag heroTag);

/// Pushes the illustration page for [illust]. With the opening card's
/// [heroTag] the card's image flies into the stage and back.
void openIllustDetail(BuildContext context, Illust illust, [ArtworkHeroTag? heroTag]) {
  context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': '${illust.id}'}, extra: heroTag == null ? illust : (illust: illust, heroTag: heroTag));
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
      child: Hero(tag: tag, transitionOnUserGestures: true, createRectTween: _straight, flightShuttleBuilder: _flight, child: child),
    );
  }

  /// A straight path, not Material's arc: the picture travels directly
  /// between the card and the stage.
  static Tween<Rect?> _straight(Rect? begin, Rect? end) => RectTween(begin: begin, end: end);

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
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) =>
          ClipRRect(borderRadius: BorderRadius.lerp(tag.sourceRadius, BorderRadius.zero, Curves.fastOutSlowIn.transform(animation.value))!, child: child),
      child: PixivImage(url: tag.imageUrl),
    );
  }
}
