import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/block/block_list.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

/// The tags and users hidden on this device, each removable, and a way to add
/// a tag. Users are added from the menus of their works and their page.
class BlockSettingsSection extends StatelessWidget {
  const BlockSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final labels = context.t.block;
    return ValueListenableBuilder<BlockList>(
      valueListenable: AppSettings.blockListListenable,
      builder: (context, blocks, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostGap.section,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: FrostGap.of(context).rowInset),
            child: FrostText(labels.localOnly, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
          ),
          FrostGroupedSection(
            header: labels.tags,
            children: [
              if (blocks.tags.isEmpty) FrostListRow(title: labels.emptyTags),
              for (final tag in blocks.tags)
                FrostListRow(
                  key: ValueKey(('tag', tag)),
                  title: '#$tag',
                  contentTitle: true,
                  trailing: _RemoveButton(
                    label: labels.remove(name: tag),
                    onPressed: () => AppSettings.blockList = AppSettings.blockList.withoutTag(tag),
                  ),
                ),
              FrostListRow(title: labels.addTag, accessory: FrostRowAccessory.chevron, onPressed: () => unawaited(showAddBlockedTagDialog(context))),
            ],
          ),
          FrostGroupedSection(
            header: labels.users,
            children: [
              if (blocks.users.isEmpty) FrostListRow(title: labels.emptyUsers),
              for (final user in blocks.users)
                FrostListRow(
                  key: ValueKey(('user', user.id)),
                  title: user.name,
                  contentTitle: true,
                  subtitle: FrostRowSubtitle('${context.t.common.id} ${user.id}'),
                  trailing: _RemoveButton(
                    label: labels.remove(name: user.name),
                    onPressed: () => AppSettings.blockList = AppSettings.blockList.withoutUser(user.id),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FrostButton.icon(icon: PivIcons.close, label: label, size: FrostControlSize.compact, onPressed: onPressed);
}

/// Asks for a tag to block, exactly as Pixiv spells it. A tag that is empty or
/// already blocked keeps the form open with the reason.
Future<void> showAddBlockedTagDialog(BuildContext context) async {
  final form = GlobalKey<_AddTagFormState>();
  await showFrostFormDialog(
    context: context,
    title: context.t.block.addTag,
    submitLabel: context.t.block.add,
    sections: [_AddTagForm(key: form)],
    onSubmit: () => form.currentState?.submit() ?? false,
  );
}

class _AddTagForm extends StatefulWidget {
  const _AddTagForm({super.key});

  @override
  State<_AddTagForm> createState() => _AddTagFormState();
}

class _AddTagFormState extends State<_AddTagForm> {
  final _tag = TextEditingController();
  String? _error;

  /// Blocks the tag typed, without spaces or a leading #; false, with the
  /// reason shown, where it is empty or already blocked.
  bool submit() {
    final labels = context.t.block;
    final name = BlockList.normalizeTag(_tag.text);
    if (name.isEmpty || AppSettings.blockList.blocksTag(name)) {
      setState(() => _error = name.isEmpty ? labels.tagRequired : labels.tagExists);
      return false;
    }
    AppSettings.blockList = AppSettings.blockList.withTag(name);
    return true;
  }

  @override
  void dispose() {
    _tag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.t.block;
    return FrostFormSection(
      children: [
        FrostTextField(
          controller: _tag,
          label: labels.tagName,
          placeholder: labels.tagPlaceholder,
          error: _error,
          autofocus: true,
          onChanged: (_) => setState(() => _error = null),
        ),
      ],
    );
  }
}
