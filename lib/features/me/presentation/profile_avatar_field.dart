import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';

/// The first field of the profile form: the profile image as it is, or the
/// cropped one waiting to be saved, with the buttons to change or undo it and
/// Pixiv's complaint when it refused the upload.
class ProfileAvatarField extends ConsumerWidget {
  const ProfileAvatarField({
    required this.name,
    required this.userId,
    required this.imageUrl,
    required this.replacement,
    required this.enabled,
    required this.onPick,
    required this.onUndo,
    this.working = false,
    this.error,
    super.key,
  });

  final String name;
  final int userId;

  /// The profile image the account has now; empty when it has none.
  final String imageUrl;

  /// The cropped JPEG that will replace it on saving, if one was chosen.
  final Uint8List? replacement;

  /// False while the form is busy.
  final bool enabled;

  /// A picked image is being read or prepared: the field shows that it is
  /// working in place of its buttons.
  final bool working;
  final VoidCallback onPick;
  final VoidCallback onUndo;
  final String? error;

  static const avatarSize = FrostAvatarSize.xlarge;

  /// Frost keeps the gap under a field's label to itself; this repeats it so
  /// the field lines up with the others.
  static const _labelGap = 6.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.profileEdit;
    final changed = replacement != null;
    final avatar = switch (replacement) {
      final bytes? => FrostAvatar(image: MemoryImage(bytes), size: avatarSize, semanticLabel: t.avatar),
      null => FrostAvatar.person(
        name: name,
        colorKey: '$userId',
        size: avatarSize,
        image: imageUrl.isEmpty ? null : pixivImageProvider(ref, imageUrl),
        semanticLabel: t.avatar,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostText(t.avatar, role: FrostTextRole.subheadline, tone: FrostTextTone.secondary),
        const SizedBox(height: _labelGap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            avatar,
            const SizedBox(width: FrostGap.group),
            Expanded(
              child: FrostLoadingGate(
                loading: working,
                builder: (context, showLoading) => showLoading
                    ? Row(
                        children: [
                          FrostActivityIndicator(semanticLabel: t.avatarWorking),
                          const SizedBox(width: FrostGap.related),
                          Flexible(child: FrostText(t.avatarWorking, tone: FrostTextTone.secondary)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: FrostGap.related,
                            runSpacing: FrostGap.related,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FrostButton(label: changed ? t.avatarPickAgain : t.avatarChange, onPressed: enabled ? onPick : null),
                              if (changed) FrostButton.quiet(label: t.avatarUndo, onPressed: enabled ? onUndo : null),
                            ],
                          ),
                          const SizedBox(height: FrostGap.related),
                          FrostText(changed ? t.avatarChanged : t.avatarHint, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
                        ],
                      ),
              ),
            ),
          ],
        ),
        if (error case final message?) ...[const SizedBox(height: FrostGap.related), FrostInlineBanner(tone: FrostBannerTone.negative, message: message)],
      ],
    );
  }
}
