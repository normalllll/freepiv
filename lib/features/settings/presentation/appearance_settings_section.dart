import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';

class AppearanceSettingsSection extends ConsumerWidget {
  const AppearanceSettingsSection({required this.modeSelector, super.key});

  final Widget modeSelector;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appearanceProvider);
    final settings = state.settings;
    final brightness = settings.mode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : settings.mode == ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
    final tone = settings.effectiveToneFor(brightness);
    final labels = t.settings.theme;
    final tokens = FrostThemeTokens.of(context);
    final accent = settings.accentFor(brightness);
    final custom = settings.customAccentFor(brightness);
    final presetIndex = freepivFrostConfig.palettes.accentPresets.indexOf(accent);
    final names = [labels.presetPink, labels.presetBlue, labels.presetTeal, labels.presetViolet, labels.presetAmber, labels.presetOrange];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(labels.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(labels.displayMode, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: modeSelector),
        ),
        const SizedBox(height: 20),
        Text(labels.tone, style: Theme.of(context).textTheme.titleSmall),
        _SystemHint(visible: settings.mode == ThemeMode.system, text: labels.systemNeutralHint),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: _ToneSelector(
              brightness: brightness,
              accent: accent,
              selected: tone,
              enabled: settings.mode != ThemeMode.system,
              onChanged: (next) => ref.read(appearanceProvider.notifier).setTone(brightness, next),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(brightness == Brightness.light ? labels.lightAccent : labels.darkAccent, style: Theme.of(context).textTheme.titleSmall),
        _SystemHint(visible: settings.mode == ThemeMode.system, text: brightness == Brightness.light ? labels.systemEditingLight : labels.systemEditingDark),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < freepivFrostConfig.palettes.accentPresets.length; i++)
              _AccentSwatch(
                color: freepivFrostConfig.palettes.accentPresets[i],
                label: names[i],
                selected: presetIndex == i,
                onPressed: () => ref.read(appearanceProvider.notifier).setPreset(brightness, freepivFrostConfig.palettes.accentPresets[i]),
              ),
            _CustomAccentButton(color: custom, selected: presetIndex < 0, onPressed: () => _openCustomEditor(context, brightness, tone, custom ?? accent)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text('#${accentHex(accent)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens.textSecondary)),
            if (accent == freepivFrostConfig.palettes.defaultAccent(brightness))
              Text(labels.defaultAccent, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens.textSecondary))
            else
              TextButton(onPressed: () => ref.read(appearanceProvider.notifier).restoreDefault(brightness), child: Text(labels.restoreDefault)),
          ],
        ),
        if (state.unsaved || state.saveError != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: tokens.textPrimary),
                const SizedBox(width: 8),
                Expanded(child: Text(state.saveError != null ? labels.saveFailed : labels.unsaved)),
                if (state.saveError != null)
                  TextButton(onPressed: state.saving ? null : () => ref.read(appearanceProvider.notifier).retrySave(), child: Text(t.common.retry)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openCustomEditor(BuildContext context, Brightness brightness, FrostTone tone, Color initial) async {
    final focus = FocusManager.instance.primaryFocus;
    final editor = _CustomAccentEditor(brightness: brightness, tone: tone, initial: initial);
    if (MediaQuery.sizeOf(context).width < 600) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 600),
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: editor,
        ),
      );
    } else {
      await showFrostDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: editor),
        ),
      );
    }
    focus?.requestFocus();
  }
}

class _ToneSelector extends StatelessWidget {
  const _ToneSelector({required this.brightness, required this.accent, required this.selected, required this.enabled, required this.onChanged});

  final Brightness brightness;
  final Color accent;
  final FrostTone selected;
  final bool enabled;
  final ValueChanged<FrostTone> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = t.settings.theme;
    final tones = FrostTone.values;
    final names = [labels.neutral, labels.cool, labels.warm];
    final style = Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12);
    final scaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(textDirection: Directionality.of(context), textScaler: scaler);
    var maxLabelWidth = 0.0;
    for (final name in names) {
      painter.text = TextSpan(text: name, style: style);
      painter.layout();
      if (painter.width > maxLabelWidth) maxLabelWidth = painter.width;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < (maxLabelWidth + 32) * 3 + 16;
        final options = [
          for (var i = 0; i < tones.length; i++)
            _ToneOption(
              tone: tones[i],
              brightness: brightness,
              accent: accent,
              label: names[i],
              selected: selected == tones[i],
              enabled: enabled,
              vertical: vertical,
              onTap: () => onChanged(tones[i]),
            ),
        ];
        return vertical
            ? Column(
                children: [for (final option in options) Padding(padding: const EdgeInsets.only(bottom: 8), child: option)],
              )
            : Row(
                children: [
                  for (final option in options)
                    Expanded(
                      child: Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: option),
                    ),
                ],
              );
      },
    );
  }
}

class _ToneOption extends StatelessWidget {
  const _ToneOption({
    required this.tone,
    required this.brightness,
    required this.accent,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.vertical,
    required this.onTap,
  });

  final FrostTone tone;
  final Brightness brightness;
  final Color accent;
  final String label;
  final bool selected;
  final bool enabled;
  final bool vertical;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = FrostPalettes.pink.palette(brightness, tone, accent);
    final tokens = FrostThemeTokens.of(context);
    final preview = Container(
      height: vertical ? 36 : 40,
      width: vertical ? 62 : double.infinity,
      decoration: BoxDecoration(
        color: palette.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: palette.line),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: enabled ? label : '$label, ${t.settings.theme.systemNeutralHint}',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: FrostClickSurface(
            feedback: FrostClickFeedback.quiet,
            shape: FrostClickShape.rounded(BorderRadius.circular(8)),
            onTap: enabled ? onTap : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? tokens.textPrimary : tokens.line, width: selected ? 1.5 : 1),
              ),
              padding: const EdgeInsets.all(7),
              child: vertical
                  ? Row(
                      children: [
                        preview,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                        ),
                        Icon(selected ? Icons.check_circle : Icons.circle_outlined, size: 18, color: selected ? tokens.textPrimary : Colors.transparent),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        preview,
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
                              ),
                            ),
                            Icon(selected ? Icons.check_circle : Icons.circle_outlined, size: 16, color: selected ? tokens.textPrimary : Colors.transparent),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({required this.color, required this.label, required this.selected, required this.onPressed});
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = FrostThemeTokens.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, ${accentHex(color)}',
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: onPressed,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? tokens.textPrimary : tokens.line, width: selected ? 2 : 1),
            ),
            child: selected ? Icon(Icons.check, size: 20, color: color.computeLuminance() > .4 ? Colors.black : Colors.white) : null,
          ),
        ),
      ),
    );
  }
}

/// A one-line note under a heading, present only while following the system. It
/// takes no room otherwise, so the heading sits as close to its controls as the
/// others; the space opens and closes smoothly with the mode.
class _SystemHint extends StatelessWidget {
  const _SystemHint({required this.visible, required this.text});

  final bool visible;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: FrostMotion.duration(context, FrostMotion.expand),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: visible
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: FrostThemeTokens.of(context).textSecondary)),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class _CustomAccentButton extends StatelessWidget {
  const _CustomAccentButton({required this.color, required this.selected, required this.onPressed});
  final Color? color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = FrostThemeTokens.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: color == null
            ? const Icon(Icons.palette_outlined, size: 18)
            : Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.textPrimary),
                ),
              ),
        label: Text(t.settings.theme.custom),
      ),
    );
  }
}

class _CustomAccentEditor extends ConsumerStatefulWidget {
  const _CustomAccentEditor({required this.brightness, required this.tone, required this.initial});
  final Brightness brightness;
  final FrostTone tone;
  final Color initial;

  @override
  ConsumerState<_CustomAccentEditor> createState() => _CustomAccentEditorState();
}

class _CustomAccentEditorState extends ConsumerState<_CustomAccentEditor> {
  late HSVColor _hsv;
  late Color _draftColor;
  late final TextEditingController _hex;
  bool _validHex = true;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _draftColor = widget.initial;
    _hex = TextEditingController(text: '#${accentHex(widget.initial)}');
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor value) {
    setState(() {
      _hsv = value;
      _draftColor = value.toColor();
      _hex.text = '#${accentHex(_draftColor)}';
      _validHex = true;
      _saveError = null;
    });
  }

  void _setHex(String value) {
    final parsed = parseAccentHex(value);
    setState(() {
      _validHex = parsed != null;
      if (parsed != null) {
        _draftColor = parsed;
        _hsv = HSVColor.fromColor(parsed);
      }
      _saveError = null;
    });
  }

  Future<void> _apply() async {
    if (_saving || !_validHex) return;
    final color = _draftColor;
    if (validateAccent(color, widget.brightness, freepivFrostConfig.palettes).severity == FrostAccentSeverity.rejected) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final saved = await ref.read(appearanceProvider.notifier).applyCustom(widget.brightness, color);
    if (!mounted) return;
    if (saved) {
      setState(() => _saving = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      setState(() {
        _saving = false;
        _saveError = t.settings.theme.saveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = t.settings.theme;
    final color = _draftColor;
    final validation = validateAccent(color, widget.brightness, freepivFrostConfig.palettes);
    final rejected = validation.severity == FrostAccentSeverity.rejected;
    final warning = validation.severity == FrostAccentSeverity.warning;
    final palette = FrostPalettes.pink.palette(widget.brightness, widget.tone, color);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.brightness == Brightness.light ? labels.editLightAccent : labels.editDarkAccent, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _SaturationValueBoard(hsv: _hsv, onChanged: _saving ? null : _setHsv),
        const SizedBox(height: 12),
        Text(labels.hue, style: Theme.of(context).textTheme.labelLarge),
        Slider(value: _hsv.hue, min: 0, max: 360, onChanged: _saving ? null : (value) => _setHsv(_hsv.withHue(value))),
        TextField(
          controller: _hex,
          enabled: !_saving,
          decoration: InputDecoration(
            labelText: labels.hex,
            errorText: !_validHex
                ? labels.invalidHex
                : rejected
                ? (widget.brightness == Brightness.light ? labels.rejectedLight : labels.rejectedDark)
                : null,
            helperText: _validHex && warning ? labels.weakContrast : null,
            errorMaxLines: 3,
            helperMaxLines: 3,
            suffixIcon: !_validHex || rejected || warning
                ? Icon(rejected || !_validHex ? Icons.error_outline : Icons.warning_amber_outlined, color: palette.textPrimary)
                : null,
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: _setHex,
          onEditingComplete: () {
            if (_validHex) _hex.text = '#${accentHex(_draftColor)}';
            FocusScope.of(context).unfocus();
          },
        ),
        if (_saveError != null) ...[const SizedBox(height: 8), Semantics(liveRegion: true, child: Text(_saveError!))],
        const SizedBox(height: 16),
        Text(labels.preview, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.canvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.line),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: palette.actionFill, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  labels.previewButton,
                  style: TextStyle(color: palette.onAction, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.favorite, color: palette.keyGraphicOn(palette.canvas)),
              Icon(Icons.check_circle, color: palette.keyGraphicOn(palette.canvas)),
            ],
          ),
        ),
      ],
    );
    final actions = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (rejected)
            TextButton(
              onPressed: _saving ? null : () => _setHsv(HSVColor.fromColor(freepivFrostConfig.palettes.defaultAccent(widget.brightness))),
              child: Text(labels.useDefault),
            ),
          TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: Text(t.common.cancel)),
          FilledButton(
            onPressed: _validHex && !rejected && !_saving ? _apply : null,
            child: SizedBox(
              width: 105,
              child: Center(
                child: Text(
                  _saving
                      ? labels.saving
                      : warning
                      ? labels.applyAnyway
                      : t.common.apply,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height - 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(child: content),
              ),
              actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _SaturationValueBoard extends StatelessWidget {
  const _SaturationValueBoard({required this.hsv, required this.onChanged});
  final HSVColor hsv;
  final ValueChanged<HSVColor>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hue = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 2,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              onPanDown: onChanged == null ? null : (details) => _update(details.localPosition, constraints.biggest),
              onPanUpdate: onChanged == null ? null : (details) => _update(details.localPosition, constraints.biggest),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(colors: [Colors.white, Colors.transparent]),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: hue, borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Colors.transparent])),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black]),
                        ),
                      ),
                    ),
                    Positioned(
                      left: hsv.saturation * constraints.maxWidth - 10,
                      top: (1 - hsv.value) * constraints.maxHeight - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 3)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            Text(t.settings.theme.saturation),
            Expanded(
              child: Slider(value: hsv.saturation, onChanged: onChanged == null ? null : (value) => onChanged!(hsv.withSaturation(value))),
            ),
          ],
        ),
        Row(
          children: [
            Text(t.settings.theme.value),
            Expanded(
              child: Slider(value: hsv.value, onChanged: onChanged == null ? null : (value) => onChanged!(hsv.withValue(value))),
            ),
          ],
        ),
      ],
    );
  }

  void _update(Offset point, Size size) {
    onChanged?.call(hsv.withSaturation((point.dx / size.width).clamp(0, 1)).withValue((1 - point.dy / size.height).clamp(0, 1)));
  }
}
