import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/system_transparency.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

/// The window's background: blurred artwork with its intensity, Mica where
/// the system offers it, or off. The slider previews live and saves when it
/// is let go; the intensity is kept while another background is chosen.
class BackgroundSettingsSection extends ConsumerWidget {
  const BackgroundSettingsSection({super.key});

  static const _divisions = 18;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.settings.theme;
    final settings = ref.watch(backgroundSettingsProvider);
    final notifier = ref.read(backgroundSettingsProvider.notifier);
    final inset = FrostGap.of(context).rowInset;
    return FrostGroupedSection(
      footer: SystemTransparencyPreference.disabledOf(context) ? t.systemTransparencyReduced : null,
      children: [
        Padding(
          padding: EdgeInsets.all(inset),
          child: FrostFormRow(
            label: FrostText(t.background, role: FrostTextRole.body),
            control: FrostPicker<BackgroundMaterial>.segmented(
              label: t.background,
              value: settings.material,
              options: [
                FrostPickerOption(value: BackgroundMaterial.ambient, label: t.ambientBlur),
                if (FrostWindowCaptionScope.systemBackdropAvailableOf(context)) FrostPickerOption(value: BackgroundMaterial.mica, label: t.mica),
                FrostPickerOption(value: BackgroundMaterial.off, label: t.backgroundOff),
              ],
              onChanged: notifier.setMaterial,
            ),
          ),
        ),
        FrostPresence(
          visible: settings.material == BackgroundMaterial.ambient,
          effect: FrostPresenceEffect.expand,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostListRow(title: t.backgroundIntensity),
              Padding(
                padding: EdgeInsetsDirectional.only(start: inset, end: inset, bottom: FrostGap.related),
                child: FrostSlider(
                  value: settings.intensity.toDouble(),
                  min: AppSettings.minBackgroundIntensity.toDouble(),
                  max: AppSettings.defaultBackgroundIntensity.toDouble(),
                  divisions: _divisions,
                  semanticLabel: t.backgroundIntensity,
                  valueLabel: (value) => '${value.round()}%',
                  onChanged: notifier.previewIntensity,
                  onChangeEnd: notifier.saveIntensity,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
