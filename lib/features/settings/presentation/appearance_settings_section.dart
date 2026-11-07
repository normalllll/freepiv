import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

/// Appearance: display mode, tone, the accent (six
/// presets or a custom colour) for the brightness being edited, and a way
/// back to the default; a failed save says so with a retry.
class AppearanceSettingsSection extends ConsumerWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final labels = t.settings.theme;
    final state = ref.watch(appearanceProvider);
    final settings = state.settings;
    final notifier = ref.read(appearanceProvider.notifier);
    final brightness = switch (settings.mode) {
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
    };
    final followsSystem = settings.mode == ThemeMode.system;
    final tone = settings.effectiveToneFor(brightness);
    final accent = settings.accentFor(brightness);
    final custom = settings.customAccentFor(brightness);
    final presets = freepivFrostConfig.palettes.accentPresets;
    final names = [labels.presetPink, labels.presetBlue, labels.presetTeal, labels.presetViolet, labels.presetAmber, labels.presetOrange];
    final preset = presets.indexOf(accent);
    final isDefault = accent == freepivFrostConfig.palettes.defaultAccent(brightness);
    return FrostGroupedSection(
      header: labels.title,
      // While the system decides, it explains what is being edited.
      footer: followsSystem ? '${labels.systemNeutralHint} · ${brightness == Brightness.light ? labels.systemEditingLight : labels.systemEditingDark}' : null,
      children: [
        FrostListRow(
          title: labels.displayMode,
          trailing: FrostPicker<ThemeMode>.segmented(
            label: labels.displayMode,
            value: settings.mode,
            options: [
              FrostPickerOption(value: ThemeMode.system, label: labels.system),
              FrostPickerOption(value: ThemeMode.light, label: labels.light),
              FrostPickerOption(value: ThemeMode.dark, label: labels.dark),
            ],
            onChanged: notifier.setMode,
          ),
        ),
        FrostListRow(
          title: labels.tone,
          trailing: FrostPicker<FrostTone>.segmented(
            label: labels.tone,
            value: tone,
            options: [
              FrostPickerOption(value: FrostTone.neutral, label: labels.neutral, enabled: !followsSystem),
              FrostPickerOption(value: FrostTone.cool, label: labels.cool, enabled: !followsSystem),
              FrostPickerOption(value: FrostTone.warm, label: labels.warm, enabled: !followsSystem),
            ],
            onChanged: (next) => notifier.setTone(brightness, next),
          ),
        ),
        FrostListRow(
          title: brightness == Brightness.light ? labels.lightAccent : labels.darkAccent,
          trailing: Wrap(
            spacing: FrostGap.inline,
            runSpacing: FrostGap.inline,
            children: [
              for (final (index, color) in presets.indexed)
                FrostColorSwatch(color: color, label: names[index], selected: preset == index, onPressed: () => notifier.setPreset(brightness, color)),
              FrostColorSwatch(
                color: custom ?? accent,
                label: labels.custom,
                icon: preset < 0 ? null : PivIcons.settings,
                selected: preset < 0,
                onPressed: () => unawaited(showCustomAccentEditor(context, brightness: brightness, initial: custom ?? accent)),
              ),
            ],
          ),
        ),
        FrostListRow(
          title: '#${accentHex(accent)}',
          value: isDefault ? labels.defaultAccent : null,
          trailing: isDefault ? null : FrostButton.quiet(label: labels.restoreDefault, onPressed: () => notifier.restoreDefault(brightness)),
        ),
        if (state.unsaved || state.saveError != null)
          FrostInlineBanner(
            tone: FrostBannerTone.negative,
            message: state.saveError != null ? labels.saveFailed : labels.unsaved,
            actionLabel: state.saveError != null ? t.common.retry : null,
            onAction: state.saveError != null && !state.saving ? () => unawaited(notifier.retrySave()) : null,
          ),
      ],
    );
  }
}

/// Edits the custom accent for [brightness]: hue, saturation and brightness
/// sliders and a HEX field, with what the colour would look like. Colours
/// Frost cannot make legible are refused; weak ones need Apply anyway.
Future<void> showCustomAccentEditor(BuildContext context, {required Brightness brightness, required Color initial}) => showFrostDialog<void>(
  context: context,
  builder: (context) => _CustomAccentEditor(brightness: brightness, initial: initial),
);

class _CustomAccentEditor extends ConsumerStatefulWidget {
  const _CustomAccentEditor({required this.brightness, required this.initial});

  final Brightness brightness;
  final Color initial;

  @override
  ConsumerState<_CustomAccentEditor> createState() => _CustomAccentEditorState();
}

class _CustomAccentEditorState extends ConsumerState<_CustomAccentEditor> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late Color _color = widget.initial;
  late final _hex = TextEditingController(text: '#${accentHex(widget.initial)}');
  bool _validHex = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor value) => setState(() {
    _hsv = value;
    _color = value.toColor();
    _hex.text = '#${accentHex(_color)}';
    _validHex = true;
    _error = null;
  });

  void _setHex(String value) {
    final parsed = parseAccentHex(value);
    setState(() {
      _validHex = parsed != null;
      if (parsed != null) {
        _color = parsed;
        _hsv = HSVColor.fromColor(parsed);
      }
      _error = null;
    });
  }

  Future<bool> _apply() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await ref.read(appearanceProvider.notifier).applyCustom(widget.brightness, _color);
    if (!mounted) return saved;
    setState(() {
      _saving = false;
      if (!saved) _error = t.settings.theme.saveFailed;
    });
    return saved;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final labels = t.settings.theme;
    final validation = validateAccent(_color, widget.brightness, freepivFrostConfig.palettes);
    final rejected = validation.severity == FrostAccentSeverity.rejected;
    final warning = validation.severity == FrostAccentSeverity.warning;
    final light = widget.brightness == Brightness.light;
    return FrostDialog(
      title: light ? labels.editLightAccent : labels.editDarkAccent,
      leadingAction: rejected
          ? FrostDialogAction(
              label: labels.useDefault,
              onPressed: () {
                _setHsv(HSVColor.fromColor(freepivFrostConfig.palettes.defaultAccent(widget.brightness)));
                return false;
              },
            )
          : null,
      actions: [
        FrostDialogAction(label: t.common.cancel, role: FrostButtonRole.cancel),
        FrostDialogAction(
          label: _saving ? labels.saving : (warning ? labels.applyAnyway : t.common.apply),
          isDefault: true,
          enabled: _validHex && !rejected && !_saving,
          onPressed: _apply,
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostGap.related,
        children: [
          Row(
            spacing: FrostGap.group,
            children: [
              FrostColorSwatch(color: _color, label: labels.preview, selected: true),
              Expanded(
                child: FrostButton.prominent(label: labels.previewButton, onPressed: () {}),
              ),
            ],
          ),
          for (final (label, value, max, change) in [
            (labels.hue, _hsv.hue, 360.0, (double value) => _hsv.withHue(value)),
            (labels.saturation, _hsv.saturation, 1.0, (double value) => _hsv.withSaturation(value)),
            (labels.value, _hsv.value, 1.0, (double value) => _hsv.withValue(value)),
          ])
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FrostGap.inline,
              children: [
                FrostText(label),
                FrostSlider(value: value, max: max, semanticLabel: label, onChanged: _saving ? null : (value) => _setHsv(change(value))),
              ],
            ),
          FrostTextField(
            controller: _hex,
            label: labels.hex,
            error: _validHex ? (rejected ? (light ? labels.rejectedLight : labels.rejectedDark) : null) : labels.invalidHex,
            onChanged: _setHex,
          ),
          if (warning) FrostText(labels.weakContrast, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
          if (_error case final error?) FrostText(error, role: FrostTextRole.footnote),
        ],
      ),
    );
  }
}
