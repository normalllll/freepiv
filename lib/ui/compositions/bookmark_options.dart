import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/logic/bookmark_options_logic.dart';
import 'package:freepiv/shared/logic/illust_bookmark_logic.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart' show Restrict;
import 'package:frost_ui/frost_ui.dart';

/// Opens a work's bookmark options: a dialog, or a bottom sheet where a dialog
/// has no room.
Future<void> showBookmarkOptions(BuildContext context, {required int workId, required bool initiallyBookmarked, bool novel = false}) =>
    showFrostAdaptiveDialog<void>(
      context: context,
      builder: (_) => _BookmarkOptionsDialog(workId: workId, initiallyBookmarked: initiallyBookmarked, novel: novel),
    );

/// The menu item opening a work's bookmark options; nothing without an account.
List<FrostMenuEntry> bookmarkOptionsMenuEntries(BuildContext context, {required int workId, required bool initiallyBookmarked, bool novel = false}) => [
  if (pixivAccountNotifier.value != null)
    FrostMenuAction(
      context.t.bookmarkOptions.title,
      leading: const FrostGlyph.icon(PivIcons.tags),
      onSelected: () {
        if (context.mounted) unawaited(showBookmarkOptions(context, workId: workId, initiallyBookmarked: initiallyBookmarked, novel: novel));
      },
    ),
];

/// The button beside a detail page's bookmark button.
class AppBookmarkOptionsButton extends StatelessWidget {
  const AppBookmarkOptionsButton({required this.workId, required this.initiallyBookmarked, this.novel = false, super.key});

  final int workId;
  final bool initiallyBookmarked;
  final bool novel;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: pixivAccountNotifier,
    builder: (context, account, _) => FrostButton.icon(
      icon: PivIcons.tags,
      label: context.t.bookmarkOptions.title,
      onPressed: account == null ? null : () => unawaited(showBookmarkOptions(context, workId: workId, initiallyBookmarked: initiallyBookmarked, novel: novel)),
    ),
  );
}

/// Public or private as a segmented control.
class AppRestrictPicker extends StatelessWidget {
  const AppRestrictPicker({required this.value, required this.onChanged, super.key});

  final Restrict value;
  final ValueChanged<Restrict>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t.privacy;
    return FrostPicker<Restrict>.segmented(
      label: t.label,
      value: value,
      onChanged: onChanged,
      options: [
        FrostPickerOption(value: Restrict.public, label: t.public),
        FrostPickerOption(value: Restrict.private, label: t.private),
      ],
    );
  }
}

class _BookmarkOptionsDialog extends ConsumerStatefulWidget {
  const _BookmarkOptionsDialog({required this.workId, required this.initiallyBookmarked, required this.novel});

  final int workId;
  final bool initiallyBookmarked;
  final bool novel;

  @override
  ConsumerState<_BookmarkOptionsDialog> createState() => _BookmarkOptionsDialogState();
}

class _BookmarkOptionsDialogState extends ConsumerState<_BookmarkOptionsDialog> {
  static const _placeholderTags = ['Sample tag', 'Another', 'Tag', 'A longer sample'];

  final _input = TextEditingController();
  final _typed = <String>[];
  late final String? _account = pixivAccountNotifier.value?.user.id;

  Restrict? _restrict;
  Set<String>? _chosen;

  WorkBookmarkKey get _key => (accountId: _account, workId: widget.workId, novel: widget.novel);

  IllustBookmarkProvider get _bookmark =>
      illustBookmarkProvider(IllustBookmarkArgs(accountId: _account, illustId: widget.workId, isBookmarked: widget.initiallyBookmarked, isNovel: widget.novel));

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _addTyped() {
    final tag = _input.text.trim().replaceFirst(RegExp('^#+'), '');
    _input.clear();
    if (tag.isEmpty) return;
    setState(() {
      if (!_typed.contains(tag)) _typed.add(tag);
      _chosen?.add(tag);
    });
  }

  void _toggle(String tag) => setState(() {
    final chosen = _chosen!;
    if (!chosen.remove(tag)) chosen.add(tag);
  });

  bool get _stillSameAccount => pixivAccountNotifier.value?.user.id == _account;

  Future<bool> _save() async {
    _addTyped();
    final failed = context.t.bookmarkOptions.failed;
    try {
      await ref.read(_bookmark.notifier).save(restrict: _restrict!, tags: _chosen!.toList());
      return true;
    } catch (error) {
      if (_stillSameAccount) toastErrorWithCause(failed, error);
      return false;
    }
  }

  Future<bool> _remove() async {
    final failed = context.t.bookmarkOptions.failed;
    try {
      await ref.read(_bookmark.notifier).toggle();
      return true;
    } catch (error) {
      if (_stillSameAccount) toastErrorWithCause(failed, error);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final options = ref.watch(workBookmarkOptionsProvider(_key));
    final bookmark = ref.watch(_bookmark);
    final loaded = options.value;
    if (loaded != null) {
      _restrict ??= loaded.restrict;
      _chosen ??= {...loaded.chosen};
    }
    final ready = loaded != null && !bookmark.updating;
    return FrostDialog(
      title: t.bookmarkOptions.title,
      leadingAction: bookmark.isBookmarked
          ? FrostDialogAction(label: t.bookmarkOptions.remove, role: FrostButtonRole.destructive, enabled: ready, onPressed: _remove)
          : null,
      actions: [
        FrostDialogAction(label: t.common.cancel, role: FrostButtonRole.cancel),
        FrostDialogAction(label: t.bookmarkOptions.save, isDefault: true, enabled: ready, onPressed: _save),
      ],
      content: switch (options) {
        AsyncValue(:final error?) when loaded == null => FrostCompactMessage.error(
          error: error,
          onAction: () => ref.invalidate(workBookmarkOptionsProvider(_key)),
        ),
        _ when loaded == null => IgnorePointer(
          child: _form(context, restrict: Restrict.public, tags: _placeholderTags, chosen: const {}).frostSkeleton(true),
        ),
        _ => _form(context, restrict: _restrict!, tags: {...loaded.tags, ..._typed}.toList(), chosen: _chosen!),
      },
    );
  }

  Widget _form(BuildContext context, {required Restrict restrict, required List<String> tags, required Set<String> chosen}) {
    final t = context.t.bookmarkOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FrostGap.group,
      children: [
        AppRestrictPicker(value: restrict, onChanged: (value) => setState(() => _restrict = value)),
        FrostTextField(controller: _input, label: t.tags, placeholder: t.addTag, textInputAction: TextInputAction.done, onSubmitted: (_) => _addTyped()),
        if (tags.isEmpty)
          FrostText(t.noTags, role: FrostTextRole.footnote, tone: FrostTextTone.secondary)
        else
          FrostWrap(
            children: [for (final tag in tags) FrostTag(label: tag, selected: chosen.contains(tag), onPressed: () => _toggle(tag))],
          ),
      ],
    );
  }
}
