import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/fanbox/fanbox_actions.dart' show fanboxImageHeaders;
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/rust_extended_network_image_provider.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';

/// A FANBOX image in a Frost media frame, fetched with the FANBOX session
/// (images of supported plans need it); a failed one offers a retry.
class AppFanboxImage extends ConsumerStatefulWidget {
  const AppFanboxImage({required this.url, this.aspectRatio, this.radius = FrostRadius.lg, this.fit = BoxFit.cover, super.key});

  final String? url;
  final double? aspectRatio;
  final double radius;
  final BoxFit fit;

  @override
  ConsumerState<AppFanboxImage> createState() => _AppFanboxImageState();
}

class _AppFanboxImageState extends ConsumerState<AppFanboxImage> {
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    final url = widget.url ?? '';
    final uri = Uri.tryParse(url);
    final placeholder = FrostMediaFrame(aspectRatio: widget.aspectRatio, radius: widget.radius, child: const SizedBox.expand());
    final override = pixivImageOverride?.call(url);
    final ImageProvider image;
    if (override != null) {
      image = override;
    } else {
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return placeholder;
      final session = ref.watch(fanboxSessionProvider);
      if (!session.hasValue) return placeholder;
      image = RustExtendedNetworkImageProvider(
        request: MediaRequest(url: url, allowDiskCache: false, accountKey: session.value ?? '', headers: fanboxImageHeaders(uri, session.value)),
        mediaStream: ref.watch(rustMediaTransportProvider).stream,
        reloadRevision: _revision,
      );
    }
    return FrostMediaFrame(
      image: image,
      aspectRatio: widget.aspectRatio,
      radius: widget.radius,
      fit: widget.fit,
      errorBuilder: (context, error) => Center(
        child: FrostButton.iconOnMedia(icon: PivIcons.refreshCw, label: context.t.common.retry, onPressed: () => setState(() => _revision++)),
      ),
    );
  }
}
