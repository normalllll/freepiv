import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';
import 'package:frost_ui/frost_ui.dart';

/// Pixiv's image hosts serve only requests coming from pixiv.net.
const pixivRefererHeaders = {'Referer': 'https://www.pixiv.net/'};

/// Answers addresses before the network does: the sample app's generated
/// pictures. Null in the app itself.
ImageProvider? Function(String url)? pixivImageOverride;

/// The image at [url] through the app's media transport, cached on disk
/// unless it is fetched for an [accountKey] (an image behind a sign-in).
/// A higher [revision] asks for it again after a failure; [keepBytes] keeps
/// the encoded file for copying and saving ([pixivImageBytes]).
ImageProvider pixivImageProvider(WidgetRef ref, String url, {Map<String, String>? headers, String? accountKey, int revision = 0, bool keepBytes = false}) =>
    pixivImageProviderFor(ref.watch(rustMediaTransportProvider), url, headers: headers, accountKey: accountKey, revision: revision, keepBytes: keepBytes);

/// [pixivImageProvider] through [transport], for code outside a widget's
/// build (the window's ambient backdrop). Equal arguments give an equal
/// provider, so the picture a card already decoded is reused.
ImageProvider pixivImageProviderFor(
  RustMediaTransport transport,
  String url, {
  Map<String, String>? headers,
  String? accountKey,
  int revision = 0,
  bool keepBytes = false,
}) {
  if (pixivImageOverride?.call(url) case final image?) return image;
  return RustExtendedNetworkImageProvider(
    request: MediaRequest(url: url, headers: headers ?? pixivRefererHeaders, allowDiskCache: accountKey == null, accountKey: accountKey ?? ''),
    mediaStream: transport.stream,
    mediaStreamCacheIdentity: transport.imageCacheIdentity,
    reloadRevision: revision,
    cacheRawData: keepBytes,
  );
}

/// The encoded file of a loaded image asked for with `keepBytes`.
Uint8List? pixivImageBytes(ImageProvider image) => image is RustExtendedNetworkImageProvider ? image.rawImageData : null;

/// A Pixiv image in a Frost media frame: Frost's placeholder while it loads
/// and fades it in; a failed image offers a retry in its place. Works without
/// an address (sample data) keep the placeholder.
class AppPixivImage extends ConsumerStatefulWidget {
  const AppPixivImage({
    required this.url,
    this.aspectRatio,
    this.radius = FrostRadius.lg,
    this.fit = BoxFit.cover,
    this.headers,
    this.accountKey,
    this.semanticLabel,
    this.placeholderUrl,
    super.key,
  });

  final String url;

  /// Null fills the parent, which then needs a finite height.
  final double? aspectRatio;
  final double radius;
  final BoxFit fit;
  final Map<String, String>? headers;

  /// The account an image behind a sign-in is fetched for; such an image is
  /// never cached on disk. Null for public images.
  final String? accountKey;
  final String? semanticLabel;

  /// A smaller picture already cached (the card's preview), shown until
  /// [url] arrives.
  final String? placeholderUrl;

  @override
  ConsumerState<AppPixivImage> createState() => _AppPixivImageState();
}

class _AppPixivImageState extends ConsumerState<AppPixivImage> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) {
      return FrostMediaFrame(aspectRatio: widget.aspectRatio, radius: widget.radius, semanticLabel: widget.semanticLabel, child: const SizedBox.expand());
    }
    return FrostMediaFrame(
      image: pixivImageProvider(ref, widget.url, headers: widget.headers, accountKey: widget.accountKey, revision: _revision),
      aspectRatio: widget.aspectRatio,
      radius: widget.radius,
      fit: widget.fit,
      semanticLabel: widget.semanticLabel,
      placeholderBuilder: switch (widget.placeholderUrl) {
        final placeholder? when placeholder.isNotEmpty && placeholder != widget.url => (context, _) => Image(
          image: pixivImageProvider(ref, placeholder, headers: widget.headers, accountKey: widget.accountKey),
          fit: widget.fit,
          excludeFromSemantics: true,
        ),
        _ => null,
      },
      errorBuilder: (context, error) => Center(
        child: FrostButton.iconOnMedia(icon: PivIcons.refreshCw, label: context.t.common.retry, onPressed: () => setState(() => _revision++)),
      ),
    );
  }
}
