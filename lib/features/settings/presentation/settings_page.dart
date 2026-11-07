import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/theme/transparency_logic.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/fanbox/login_logic.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/fanbox/login_panel.dart';
import 'package:freepiv/features/settings/presentation/appearance_settings_section.dart';
import 'package:freepiv/features/settings/presentation/pixiv_sign_out.dart';
import 'package:freepiv/features/settings/presentation/proxy_settings_dialog.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

/// Settings: Appearance, Language, Images, Network,
/// Downloads and Accounts as Frost settings sections, the categories beside
/// the settings on wide windows and a list leading to each on narrow ones.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _section = 0;
  bool _sectionOpen = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final sections = <Widget Function()>[
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostGap.section,
        children: [
          const AppearanceSettingsSection(),
          FrostGroupedSection(
            children: [
              FrostListRow.toggle(
                title: t.settings.theme.reduceTransparency,
                subtitle: FrostRowSubtitle(t.settings.theme.reduceTransparencyHint),
                value: ref.watch(reduceTransparencyProvider),
                onChanged: (value) => ref.read(reduceTransparencyProvider.notifier).setEnabled(value),
              ),
              FrostSettingsSelectTile<FrostNavigationPlacement>(
                title: t.navigationPlacement.title,
                value: ref.watch(navigationPlacementProvider),
                items: [
                  FrostPickerOption(value: FrostNavigationPlacement.automatic, label: t.navigationPlacement.automatic),
                  FrostPickerOption(value: FrostNavigationPlacement.bottom, label: t.navigationPlacement.bottom),
                  FrostPickerOption(value: FrostNavigationPlacement.sidebar, label: t.navigationPlacement.sidebar),
                ],
                onChanged: ref.read(navigationPlacementProvider.notifier).setPlacement,
              ),
            ],
          ),
        ],
      ),
      () => FrostGroupedSection(
        header: t.settings.language.title,
        children: [
          FrostPicker<AppLocale?>.menu(
            label: t.settings.language.title,
            value: ref.watch(appLocaleProvider),
            options: [
              FrostPickerOption(value: null, label: t.settings.language.systemDefault),
              // Each language is named in itself, so a wrong pick can always be undone.
              for (final entry in languageOptionNames.entries) FrostPickerOption(value: entry.key, label: entry.value),
            ],
            onChanged: (locale) => unawaited(ref.read(appLocaleProvider.notifier).setLocale(locale)),
          ),
        ],
      ),
      () => FrostGroupedSection(
        header: t.settings.images.title,
        children: [
          FrostSettingsSelectTile<PreviewImageQuality>(
            title: t.settings.images.previewQuality,
            value: ref.watch(previewImageQualityProvider),
            items: [
              FrostPickerOption(value: PreviewImageQuality.medium, label: t.settings.images.medium),
              FrostPickerOption(value: PreviewImageQuality.large, label: t.settings.images.large),
            ],
            onChanged: ref.read(previewImageQualityProvider.notifier).setQuality,
          ),
          FrostSettingsSelectTile<ViewerImageQuality>(
            title: t.settings.images.viewerQuality,
            value: ref.watch(viewerImageQualityProvider),
            items: [
              FrostPickerOption(value: ViewerImageQuality.large, label: t.settings.images.large),
              FrostPickerOption(value: ViewerImageQuality.original, label: t.settings.images.original),
            ],
            onChanged: ref.read(viewerImageQualityProvider.notifier).setQuality,
          ),
        ],
      ),
      () {
        final proxy = ref.watch(proxySettingsProvider);
        return FrostGroupedSection(
          header: t.settings.proxy.title,
          children: [
            FrostListRow(
              title: t.settings.proxy.shortTitle,
              subtitle: FrostRowSubtitle(proxy.active ? t.settings.proxy.entrySubtitleOn(url: proxy.url!) : t.settings.proxy.entrySubtitleOff),
              accessory: FrostRowAccessory.chevron,
              onPressed: () => unawaited(showProxySettingsDialog(context)),
            ),
          ],
        );
      },
      () => _DownloadSettings(onChoose: _chooseDirectory),
      () => const _AccountSettings(),
    ];
    final labels = [
      t.settings.theme.title,
      t.settings.language.title,
      t.settings.images.title,
      t.settings.proxy.title,
      t.settings.downloads.title,
      t.settings.account.title,
    ];
    // A section fills its pane, so a short one starts at the top.
    Widget section(int index) => SizedBox.expand(
      child: SingleChildScrollView(
        child: FrostContentColumn(maxWidth: FrostMetrics.readingMaxWidth, child: sections[index]()),
      ),
    );
    void openSection(int index) => setState(() {
      _section = index;
      _sectionOpen = true;
    });

    // The header stands above the sections, which keep their own scrolling.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(bottom: false, child: FrostPageHeader(title: FrostText(t.navigation.settings))),
        Expanded(
          child: FrostSettingsSections(
            labels: labels,
            selectedIndex: _section,
            onSelected: (index) => setState(() => _section = index),
            sectionBuilder: (context, index) => section(index),
            compact: FrostSectionsCompact(
              navigationBuilder: (context) => SingleChildScrollView(
                child: FrostContentColumn(
                  maxWidth: FrostMetrics.readingMaxWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: FrostGap.group),
                    child: FrostGroupedSection(
                      children: [
                        for (final (index, label) in labels.indexed)
                          FrostListRow(title: label, accessory: FrostRowAccessory.chevron, onPressed: () => openSection(index)),
                      ],
                    ),
                  ),
                ),
              ),
              section: _sectionOpen ? section(_section) : null,
              onClose: () => setState(() => _sectionOpen = false),
              onNavigate: openSection,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _chooseDirectory() async {
    final selected = await FilePicker.getDirectoryPath(dialogTitle: t.settings.downloads.dialogTitle);
    if (!mounted || selected == null || selected.isEmpty) return;
    try {
      final path = await prepareDesktopCustomDownloadDirectory(selected);
      if (!mounted) return;
      ref.read(downloadSavePathSettingsProvider.notifier).useCustomDirectory(path);
      FrostToast.success(t.settings.downloads.directorySet(path: path));
    } catch (error) {
      if (mounted) toastErrorWithCause(t.settings.downloads.directoryUnavailable, error);
    }
  }
}

/// Where downloads are saved (desktop) and how many run at once.
class _DownloadSettings extends ConsumerWidget {
  const _DownloadSettings({required this.onChoose});

  final Future<void> Function() onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.t.settings.downloads;
    final path = ref.watch(downloadSavePathSettingsProvider);
    final limit = ref.watch(maxConcurrentDownloadsProvider);
    final notifier = ref.read(downloadSavePathSettingsProvider.notifier);
    return FrostGroupedSection(
      header: labels.title,
      footer: labels.maxConcurrentDownloadsSubtitle(count: limit),
      children: [
        if (isDesktopPlatform) ...[
          FrostListRow(
            title: labels.savePath,
            trailing: FrostPicker<DownloadSavePathMode>.segmented(
              label: labels.savePath,
              value: path.mode,
              options: [
                FrostPickerOption(value: DownloadSavePathMode.defaultPath, label: labels.defaultPath),
                FrostPickerOption(value: DownloadSavePathMode.custom, label: labels.customPath),
              ],
              onChanged: (mode) {
                if (mode == DownloadSavePathMode.defaultPath) {
                  notifier.useDefaultDirectory();
                } else if (path.customDirectory == null) {
                  unawaited(onChoose());
                } else {
                  notifier.useExistingCustomDirectory();
                }
              },
            ),
          ),
          FrostListRow(
            title: switch (path.mode) {
              DownloadSavePathMode.defaultPath => labels.systemDownloadsFolder,
              DownloadSavePathMode.custom => path.customDirectory ?? labels.noFolderSelected,
            },
            contentTitle: true,
            trailing: path.mode == DownloadSavePathMode.custom ? FrostButton.quiet(label: labels.chooseFolder, onPressed: () => unawaited(onChoose())) : null,
          ),
        ],
        FrostListRow(
          title: labels.maxConcurrentDownloads,
          trailing: FrostStepper(
            value: limit,
            min: AppSettings.minConcurrentDownloads,
            max: AppSettings.maxConcurrentDownloadsLimit,
            semanticLabel: labels.maxConcurrentDownloads,
            onChanged: (value) => ref.read(maxConcurrentDownloadsProvider.notifier).setLimit(value.round()),
          ),
        ),
      ],
    );
  }
}

/// The Pixiv account, signed out only after a confirmation, and the FANBOX
/// session: connect, update it, or sign out of it.
class _AccountSettings extends ConsumerWidget {
  const _AccountSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final session = ref.watch(fanboxSessionProvider);
    final operation = ref.watch(fanboxOperationProvider('account'));
    final connected = session.asData?.value != null;
    final busy = session.isLoading || operation.isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.section,
      children: [
        ValueListenableBuilder(
          valueListenable: pixivAccountNotifier,
          builder: (context, account, _) => FrostGroupedSection(
            header: 'Pixiv',
            children: [
              FrostListRow(
                title: account == null ? t.settings.account.notSignedIn : account.user.name,
                contentTitle: account != null,
                subtitle: FrostRowSubtitle(account == null ? t.settings.account.signedOutSubtitle : '@${account.user.account}'),
              ),
              if (account != null) FrostListRow(title: t.settings.account.signOut, destructive: true, onPressed: () => unawaited(confirmPixivSignOut(context))),
            ],
          ),
        ),
        FrostGroupedSection(
          header: t.fanbox.title,
          footer: operation.hasError ? fanboxLoginError(t, operation.error!) : null,
          children: [
            FrostListRow(title: connected ? t.fanbox.accountConnected : t.settings.account.notSignedIn),
            FrostListRow(
              title: connected ? t.fanbox.updateSession : t.fanbox.login,
              accessory: FrostRowAccessory.chevron,
              enabled: !busy,
              onPressed: () => unawaited(_connect(context)),
            ),
            if (connected)
              FrostListRow(
                title: t.fanbox.logout,
                destructive: true,
                enabled: !busy,
                onPressed: () => unawaited(ref.read(fanboxOperationProvider('account').notifier).run(() => ref.read(fanboxSessionProvider.notifier).signOut())),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _connect(BuildContext context) => showFrostDialog<void>(
    context: context,
    builder: (dialogContext) => FrostDialog(
      title: dialogContext.t.fanbox.login,
      showsCloseButton: true,
      content: FanboxLoginPanel(onSignedIn: () => Navigator.pop(dialogContext)),
    ),
  );
}

/// The interface languages, each named in itself.
const languageOptionNames = <AppLocale, String>{AppLocale.enUs: 'English', AppLocale.zhCn: '简体中文', AppLocale.zhHantTw: '繁體中文', AppLocale.jaJp: '日本語'};
