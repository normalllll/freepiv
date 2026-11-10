import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/ui/compositions/identity_header.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';

/// An author's banner, or their avatar washed across the same band, so every
/// author's header has one height, known before the author loads.
class UserBanner extends StatelessWidget {
  const UserBanner({required this.coverUrl, required this.avatarUrl, super.key});

  final String? coverUrl;
  final String avatarUrl;

  static const _washBlur = 40.0;

  @override
  Widget build(BuildContext context) {
    if (coverUrl case final url? when url.isNotEmpty) {
      return _StatusIconsOverBanner(
        url: url,
        child: AppPixivImage(url: url, radius: 0),
      );
    }
    return RepaintBoundary(
      child: ClipRect(
        child: Opacity(
          opacity: FrostThemeTokens.of(context).isDark ? .4 : .5,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: _washBlur, sigmaY: _washBlur, tileMode: TileMode.clamp),
            child: AppPixivImage(url: avatarUrl, radius: 0),
          ),
        ),
      ),
    );
  }
}

/// The icon colour that reads on the part of [image] a cover fit in [banner]
/// puts behind a status bar [top] tall. Light icons give way to dark ones
/// where they would fall under 3:1 against that strip.
Future<Brightness?> statusIconsOverBanner(ui.Image image, Size banner, double top) async {
  const columns = 16, rows = 2, darkFromLuminance = .3;
  final full = Size(image.width.toDouble(), image.height.toDouble());
  final crop = Alignment.center.inscribe(applyBoxFit(BoxFit.cover, full, banner).source, Offset.zero & full);
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(
    image,
    Rect.fromLTWH(crop.left, crop.top, crop.width, crop.height * math.min(1, top / banner.height)),
    Rect.fromLTWH(0, 0, columns.toDouble(), rows.toDouble()),
    Paint()..filterQuality = FilterQuality.medium,
  );
  final picture = recorder.endRecording();
  final cells = await picture.toImage(columns, rows);
  picture.dispose();
  final bytes = await cells.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  cells.dispose();
  if (bytes == null) return null;
  var total = 0.0;
  for (var cell = 0; cell < columns * rows; cell++) {
    total += Color.fromARGB(255, bytes.getUint8(cell * 4), bytes.getUint8(cell * 4 + 1), bytes.getUint8(cell * 4 + 2)).computeLuminance();
  }
  return total / (columns * rows) >= darkFromLuminance ? Brightness.dark : Brightness.light;
}

/// The status bar over a banner: its icons take the colour that reads on the
/// strip of the picture behind them, so nothing has to be painted under them.
/// The region moves with the banner, so the icons go back to the theme's once
/// it has scrolled away, and a page opened over this one has the theme's too.
class _StatusIconsOverBanner extends ConsumerStatefulWidget {
  const _StatusIconsOverBanner({required this.url, required this.child});

  final String url;
  final Widget child;

  @override
  ConsumerState<_StatusIconsOverBanner> createState() => _StatusIconsOverBannerState();
}

class _StatusIconsOverBannerState extends ConsumerState<_StatusIconsOverBanner> {
  ImageStream? _stream;
  late final _listener = ImageStreamListener(_measure, onError: (_, _) {});
  int _reading = 0;
  Brightness? _icons;

  @override
  void initState() {
    super.initState();
    _listenAfterLayout();
  }

  /// Rebuilt, the banner may show another picture, even at the same address.
  @override
  void didUpdateWidget(_StatusIconsOverBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _listenAfterLayout();
  }

  /// The strip's share of the picture depends on the laid-out banner.
  void _listenAfterLayout() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final stream = pixivImageProviderFor(ref.read(rustMediaTransportProvider), widget.url).resolve(createLocalImageConfiguration(context));
    // The same picture keeps its reading; another one is read anew.
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  });

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  Future<void> _measure(ImageInfo info, bool _) async {
    final reading = ++_reading;
    final banner = context.size;
    final top = MediaQuery.paddingOf(context).top;
    final icons = banner == null || banner.isEmpty || top <= 0 ? null : await statusIconsOverBanner(info.image, banner, top);
    info.dispose();
    if (!mounted || reading != _reading || icons == null) return;
    setState(() => _icons = icons);
  }

  @override
  Widget build(BuildContext context) {
    final theme = frostSystemOverlayStyle(FrostThemeTokens.of(context));
    final icons = ModalRoute.of(context)?.isCurrent ?? true ? _icons : null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: switch (icons) {
        null => theme,
        Brightness.dark => theme.copyWith(statusBarIconBrightness: Brightness.dark, statusBarBrightness: Brightness.light),
        Brightness.light => theme.copyWith(statusBarIconBrightness: Brightness.light, statusBarBrightness: Brightness.dark),
      },
      child: widget.child,
    );
  }
}

/// The page behind [builder], with the banner at its top: under the status
/// bar and the page header, moving with [controller]. A banner inside the
/// scrolling identity could not reach there, as the sticky header fades
/// whatever passes its controls. [builder] receives the banner's bottom,
/// measured from the top of the page.
class UserBannerBackdrop extends StatelessWidget {
  const UserBannerBackdrop({required this.banner, required this.builder, this.controller, super.key});

  final Widget banner;
  final ScrollController? controller;
  final Widget Function(BuildContext context, double bannerBottom) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final top = MediaQuery.paddingOf(context).top;
      final bottom = top + UserIdentityHeader.bannerHeightFor(constraints.maxWidth);
      // The viewport leaves out the page's scrollbar channel.
      final layer = FrostContentViewport(
        child: Builder(
          builder: (context) => Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: bottom,
              child: RepaintBoundary(child: banner),
            ),
          ),
        ),
      );
      Widget placed(double offset, Widget child) => Positioned(
        top: -offset,
        left: 0,
        right: 0,
        child: IgnorePointer(child: child),
      );
      final page = builder(context, bottom);
      final controller = this.controller;
      double offset() => controller != null && controller.hasClients ? controller.offset.clamp(0.0, bottom) : 0.0;
      return controller == null
          ? Stack(fit: StackFit.expand, children: [placed(0, layer), page])
          : Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(animation: controller, child: layer, builder: (context, child) => placed(offset(), child!)),
                page,
              ],
            );
    },
  );
}

/// An author's identity under the banner of a [UserBannerBackdrop]: the avatar
/// half over the banner's lower edge, everything at the start, and Follow and
/// More together at the end. Narrow content puts the name under the avatar,
/// wider content beside it, and the widest also puts the numbers on the name's
/// row.
class UserIdentityHeader extends StatelessWidget {
  const UserIdentityHeader({
    required this.bannerBottom,
    required this.avatar,
    required this.name,
    required this.subtitle,
    required this.stats,
    this.statsLoading = false,
    this.primary,
    this.more = const [],
    this.bio,
    super.key,
  });

  /// Narrower content than this puts the name under the avatar.
  static const besideFrom = 600.0;

  /// Content this wide puts the numbers on the name's row.
  static const inlineStatsFrom = 900.0;

  static const _avatarExtent = 72.0;
  static const _maxInlineTextScale = 1.3;

  /// The banner's height below the status bar, across a page of [width].
  static double bannerHeightFor(double width) => width < besideFrom
      ? 148
      : width < inlineStatsFrom
      ? 172
      : 200;

  /// The bottom of the banner, measured from the top of the page.
  final double bannerBottom;

  /// A FrostAvatar at [FrostAvatarSize.xxlarge] (72).
  final Widget avatar;
  final String name;
  final String subtitle;
  final List<AppIdentityStat> stats;

  /// Placeholders the size of the stats while they load.
  final bool statsLoading;

  /// Follow; null on one's own page.
  final Widget? primary;
  final List<FrostMenuEntry> more;
  final Widget? bio;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      // This sits under the header; the banner starts at the top of the page.
      final top = math.max(0.0, bannerBottom - MediaQuery.paddingOf(context).top - _avatarExtent / 2);
      return Padding(
        padding: EdgeInsets.only(top: top),
        child: width < besideFrom ? _stacked(context, width) : _beside(context, width),
      );
    },
  );

  Widget _names(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FrostGap.inline,
    children: [
      FrostText(name, content: true, role: FrostTextRole.title1, maxLines: 2, overflow: TextOverflow.ellipsis),
      FrostText(subtitle, role: FrostTextRole.footnote, tone: FrostTextTone.secondary, maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );

  Widget _stats() => Wrap(
    spacing: FrostGap.section,
    runSpacing: FrostGap.related,
    children: [
      for (final stat in stats)
        statsLoading ? FrostStat.skeleton(value: stat.value, unit: null, caption: stat.caption) : FrostStat(value: stat.value, caption: stat.caption),
    ],
  );

  /// Follow and More side by side, never more than half the row, so that a
  /// long label at large text shrinks instead of squeezing the name out.
  Widget _actions(BuildContext context, double width) {
    final moreButton = more.isEmpty
        ? null
        : FrostMenuAnchor(
            entries: more,
            builder: (context, focusNode, toggle) =>
                FrostButton.icon(icon: FrostScope.configOf(context).icons.more, label: FrostScope.labelsOf(context).more, onPressed: toggle),
          );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width / 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: FrostGap.related,
        children: [
          if (primary case final primary?) Flexible(child: primary),
          ?moreButton,
        ],
      ),
    );
  }

  Widget _stacked(BuildContext context, double width) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FrostGap.related,
    children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [avatar, _actions(context, width)]),
      _names(context),
      _stats(),
      ?bio,
    ],
  );

  Widget _beside(BuildContext context, double width) {
    final inline = width >= inlineStatsFrom && MediaQuery.textScalerOf(context).scale(1) <= _maxInlineTextScale;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FrostGap.group,
      children: [
        avatar,
        Expanded(
          child: Padding(
            // Clear of the banner, beside the avatar's lower half.
            padding: const EdgeInsets.only(top: _avatarExtent / 2 + FrostGap.related),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FrostGap.related,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostGap.group,
                  children: [
                    Expanded(child: _names(context)),
                    if (inline) Expanded(child: _stats()),
                    _actions(context, width),
                  ],
                ),
                if (!inline) _stats(),
                ?bio,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
