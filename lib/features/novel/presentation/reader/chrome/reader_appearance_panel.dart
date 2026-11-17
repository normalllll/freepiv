import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/custom/reader/reader_typesetting.dart';
import 'package:frost_ui/frost_ui.dart';

/// Every reader setting, applied as it changes: text size, theme, font, line
/// spacing, margins, page mode and animation, tap zones, first-line indent,
/// the volume keys on a device that has them, auto scroll speed, and the list
/// of keyboard shortcuts. The panel opens over the text so each change shows
/// on the text above it; opening it pauses auto scroll ([onShown]).
class ReaderAppearancePanel extends ConsumerStatefulWidget {
  const ReaderAppearancePanel({required this.volumeSupported, required this.onShown, required this.onShortcuts, super.key});

  final bool volumeSupported;
  final ValueChanged<bool> onShown;

  /// Opens the list of keyboard shortcuts.
  final VoidCallback onShortcuts;

  @override
  ConsumerState<ReaderAppearancePanel> createState() => _ReaderAppearancePanelState();
}

class _ReaderAppearancePanelState extends ConsumerState<ReaderAppearancePanel> {
  late final ValueChanged<bool> _shown = widget.onShown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _shown(true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _shown(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.novel.reader;
    final settings = ref.watch(readerSettingsProvider);
    final notifier = ref.read(readerSettingsProvider.notifier);

    String speedName(ReaderAutoScrollSpeed speed) => switch (speed) {
      ReaderAutoScrollSpeed.verySlow => t.speedVerySlow,
      ReaderAutoScrollSpeed.slow => t.speedSlow,
      ReaderAutoScrollSpeed.normal => t.speedNormal,
      ReaderAutoScrollSpeed.fast => t.speedFast,
      ReaderAutoScrollSpeed.veryFast => t.speedVeryFast,
    };

    Widget labelled(String label, Widget control) => FrostFormRow(label: FrostText(label), control: control);

    return FrostFormSection(
      children: [
        Row(
          spacing: FrostGap.inline,
          children: [
            Expanded(child: FrostText(t.fontSize)),
            FrostText('${settings.textSize.round()}', key: const ValueKey('reader-font-size-value')),
            FrostStepper(
              key: const ValueKey('reader-font-size'),
              value: settings.textSize,
              min: AppSettings.readerFontSizeRange.min,
              max: AppSettings.readerFontSizeRange.max,
              onChanged: (value) => notifier.setTextSize(value.toDouble()),
              semanticLabel: t.fontSize,
            ),
          ],
        ),
        labelled(
          t.theme,
          FrostPicker<ReaderTheme>.palette(
            key: const ValueKey('reader-theme'),
            label: t.theme,
            value: settings.theme,
            onChanged: notifier.setTheme,
            options: [
              for (final theme in ReaderTheme.values)
                FrostPickerOption(
                  value: theme,
                  label: switch (theme) {
                    ReaderTheme.app => t.themeApp,
                    ReaderTheme.white => t.themeWhite,
                    ReaderTheme.paper => t.themePaper,
                    ReaderTheme.green => t.themeGreen,
                    ReaderTheme.night => t.themeNight,
                    ReaderTheme.black => t.themeBlack,
                  },
                  color: ReaderPalette.of(context, theme).background,
                ),
            ],
          ),
        ),
        labelled(
          t.font,
          FrostPicker<ReaderFont>.segmented(
            key: const ValueKey('reader-font'),
            label: t.font,
            value: settings.font,
            onChanged: notifier.setFont,
            options: [
              FrostPickerOption(value: ReaderFont.sans, label: t.fontSans),
              FrostPickerOption(value: ReaderFont.serif, label: t.fontSerif),
              FrostPickerOption(value: ReaderFont.kai, label: t.fontKai),
            ],
          ),
        ),
        labelled(
          t.lineHeight,
          FrostPicker<ReaderLineSpacing>.segmented(
            key: const ValueKey('reader-line-spacing'),
            label: t.lineHeight,
            value: settings.lineSpacing,
            onChanged: notifier.setLineSpacing,
            options: [
              FrostPickerOption(value: ReaderLineSpacing.compact, label: t.lineSpacingCompact),
              FrostPickerOption(value: ReaderLineSpacing.regular, label: t.lineSpacingRegular),
              FrostPickerOption(value: ReaderLineSpacing.relaxed, label: t.lineSpacingRelaxed),
            ],
          ),
        ),
        labelled(
          t.margins,
          FrostPicker<ReaderMargins>.segmented(
            key: const ValueKey('reader-margins'),
            label: t.margins,
            value: settings.margins,
            onChanged: notifier.setMargins,
            options: [
              FrostPickerOption(value: ReaderMargins.narrow, label: t.marginsNarrow),
              FrostPickerOption(value: ReaderMargins.regular, label: t.marginsRegular),
              FrostPickerOption(value: ReaderMargins.wide, label: t.marginsWide),
            ],
          ),
        ),
        labelled(
          t.pageMode,
          FrostPicker<ReaderPageMode>.segmented(
            key: const ValueKey('reader-page-mode'),
            label: t.pageMode,
            value: settings.pageMode,
            onChanged: notifier.setPageMode,
            options: [
              FrostPickerOption(value: ReaderPageMode.scroll, label: t.pageModeScroll),
              FrostPickerOption(value: ReaderPageMode.paged, label: t.pageModePaged),
            ],
          ),
        ),
        if (settings.pageMode == ReaderPageMode.paged)
          labelled(
            t.pageAnimation,
            FrostPicker<ReaderPageAnimation>.segmented(
              key: const ValueKey('reader-page-animation'),
              label: t.pageAnimation,
              value: settings.pageAnimation,
              onChanged: notifier.setPageAnimation,
              options: [
                FrostPickerOption(value: ReaderPageAnimation.slide, label: t.pageAnimationSlide),
                FrostPickerOption(value: ReaderPageAnimation.cover, label: t.pageAnimationCover),
                FrostPickerOption(value: ReaderPageAnimation.none, label: t.pageAnimationNone),
              ],
            ),
          ),
        labelled(
          t.tapZones,
          FrostPicker<ReaderTapZones>.segmented(
            key: const ValueKey('reader-tap-zones'),
            label: t.tapZones,
            value: settings.tapZones,
            onChanged: notifier.setTapZones,
            options: [
              FrostPickerOption(value: ReaderTapZones.sides, label: t.tapZonesSides),
              FrostPickerOption(value: ReaderTapZones.forward, label: t.tapZonesForward),
            ],
          ),
        ),
        FrostListRow.toggle(key: const ValueKey('reader-indent'), title: t.indent, value: settings.indent, onChanged: notifier.setIndent),
        if (widget.volumeSupported)
          FrostListRow.toggle(
            key: const ValueKey('reader-volume-keys'),
            title: t.volumeKeys,
            subtitle: FrostRowSubtitle(t.volumeKeysHelp),
            value: settings.volumeKeys,
            onChanged: notifier.setVolumeKeys,
          ),
        if (settings.pageMode == ReaderPageMode.scroll)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostGap.inline,
            children: [
              FrostText(t.autoScrollSpeed),
              FrostSlider(
                key: const ValueKey('reader-scroll-speed'),
                value: settings.autoScrollSpeed.index.toDouble(),
                min: 0,
                max: ReaderAutoScrollSpeed.values.length - 1,
                divisions: ReaderAutoScrollSpeed.values.length - 1,
                semanticLabel: t.autoScrollSpeed,
                valueLabel: (value) => speedName(ReaderAutoScrollSpeed.values[value.round()]),
                onChanged: (value) => notifier.setAutoScrollSpeed(ReaderAutoScrollSpeed.values[value.round()]),
              ),
            ],
          ),
        FrostListRow(key: const ValueKey('reader-shortcuts'), title: t.shortcuts, accessory: FrostRowAccessory.chevron, onPressed: widget.onShortcuts),
      ],
    );
  }
}

/// The keys the reader answers to.
class ReaderShortcutsList extends StatelessWidget {
  const ReaderShortcutsList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t.novel.reader;
    Widget row(String title, String keys) => FrostListRow(title: title, value: keys);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(t.shortcutNextScreen, 'Space · → · PgDn'),
        row(t.shortcutPreviousScreen, 'Shift+Space · ← · PgUp'),
        row(t.shortcutLines, '↑ · ↓'),
        row(t.shortcutChapters, '[ · ]'),
        row(t.shortcutEnds, 'Home · End'),
        row(t.shortcutContents, 'T'),
        row(t.shortcutEscape, 'Esc'),
      ],
    );
  }
}

/// Opens the list of keyboard shortcuts in a sheet, or a dialog on a wide window.
Future<void> showReaderShortcuts(BuildContext context) => showFrostSheet<void>(
  context: context,
  title: context.t.novel.reader.shortcuts,
  detents: const [FrostSheetDetent.fitted],
  builder: (context) => const ReaderShortcutsList(),
);
