import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/settings/presentation/proxy_settings_dialog.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const _pagePadding = EdgeInsets.all(16);
  static const _maxContentWidth = 560.0;
  static const _contentPadding = EdgeInsets.all(20);

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final appLocale = ref.watch(appLocaleProvider);
    final previewQuality = ref.watch(previewImageQualityProvider);
    final viewerQuality = ref.watch(viewerImageQualityProvider);
    final downloadPathSettings = ref.watch(downloadSavePathSettingsProvider);
    final maxConcurrentDownloads = ref.watch(maxConcurrentDownloadsProvider);
    final proxySettings = ref.watch(proxySettingsProvider);
    final tokens = FreepivThemeTokens.of(context);
    final translations = t;

    return AutoScaffold(
      builder: (context, layout, orientation, shouldUseDesktopShell) {
        return Scaffold(
          backgroundColor: tokens.surface,
          appBar: shouldUseDesktopShell ? null : AppBar(title: Text(translations.navigation.settings)),
          body: SafeArea(
            top: shouldUseDesktopShell,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isPortrait = constraints.maxHeight >= constraints.maxWidth;
                final isMobilePortrait = !isDesktopPlatform && isPortrait;
                final maxContentWidth = isMobilePortrait ? double.infinity : _maxContentWidth;
                final minContentHeight = math.max(0.0, constraints.maxHeight - _pagePadding.vertical);

                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: Scrollbar(
                    controller: _scrollController,
                    child: ListView(
                      controller: _scrollController,
                      padding: _pagePadding,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxContentWidth, minHeight: minContentHeight),
                            child: EnergeticCard(
                              accentColor: tokens.brand,
                              padding: _contentPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(translations.settings.theme.title, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 12),
                                  _ThemeModeSelector(
                                    value: themeMode,
                                    onChanged: (mode) {
                                      ref.read(themeModeProvider.notifier).setThemeMode(mode);
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(height: 1),
                                  const SizedBox(height: 20),
                                  Text(translations.settings.language.title, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 12),
                                  _LanguageSelector(
                                    value: appLocale,
                                    onChanged: (locale) {
                                      unawaited(ref.read(appLocaleProvider.notifier).setLocale(locale));
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(height: 1),
                                  const SizedBox(height: 20),
                                  _ImageSettingsSection(
                                    previewQuality: previewQuality,
                                    viewerQuality: viewerQuality,
                                    onPreviewQualityChanged: (quality) {
                                      ref.read(previewImageQualityProvider.notifier).setQuality(quality);
                                    },
                                    onViewerQualityChanged: (quality) {
                                      ref.read(viewerImageQualityProvider.notifier).setQuality(quality);
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(height: 1),
                                  const SizedBox(height: 20),
                                  _ProxySettingsSection(settings: proxySettings, onTap: () => showProxySettingsDialog(context)),
                                  const SizedBox(height: 20),
                                  const Divider(height: 1),
                                  const SizedBox(height: 20),
                                  _DownloadSettingsSection(
                                    settings: downloadPathSettings,
                                    maxConcurrentDownloads: maxConcurrentDownloads,
                                    onModeChanged: _setDownloadPathMode,
                                    onChooseDirectory: _chooseDownloadDirectory,
                                    onMaxConcurrentDownloadsChanged: (value) {
                                      ref.read(maxConcurrentDownloadsProvider.notifier).setLimit(value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _setDownloadPathMode(DownloadSavePathMode mode) async {
    final notifier = ref.read(downloadSavePathSettingsProvider.notifier);
    if (mode == DownloadSavePathMode.defaultPath) {
      notifier.useDefaultDirectory();
      return;
    }

    final currentSettings = ref.read(downloadSavePathSettingsProvider);
    if (currentSettings.customDirectory == null) {
      await _chooseDownloadDirectory();
      return;
    }

    notifier.useExistingCustomDirectory();
  }

  Future<void> _chooseDownloadDirectory() async {
    final translations = t;
    final selectedPath = await FilePicker.getDirectoryPath(dialogTitle: translations.settings.downloads.dialogTitle);
    if (!mounted || selectedPath == null || selectedPath.isEmpty) {
      return;
    }

    try {
      final downloadPath = await prepareDesktopCustomDownloadDirectory(selectedPath);
      if (!mounted) {
        return;
      }

      ref.read(downloadSavePathSettingsProvider.notifier).useCustomDirectory(downloadPath);
      AppToast.success(t.settings.downloads.directorySet(path: downloadPath));
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.errorWithCause(t.settings.downloads.directoryUnavailable, error);
    }
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return ConstrainedSegmentedButton<ThemeMode>(
      maxWidth: null,
      segments: [
        ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(translations.settings.theme.system)),
        ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(translations.settings.theme.light)),
        ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(translations.settings.theme.dark)),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.value, required this.onChanged});

  final AppLocale? value;
  final ValueChanged<AppLocale?> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return DropdownButtonFormField<AppLocale?>(
      initialValue: value,
      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      items: [
        DropdownMenuItem(value: null, child: Text(translations.settings.language.systemDefault)),
        DropdownMenuItem(value: AppLocale.enUs, child: Text(translations.settings.language.enUs)),
        DropdownMenuItem(value: AppLocale.zhCn, child: Text(translations.settings.language.zhCn)),
        DropdownMenuItem(value: AppLocale.zhHantTw, child: Text(translations.settings.language.zhTw)),
        DropdownMenuItem(value: AppLocale.jaJp, child: Text(translations.settings.language.jaJp)),
      ],
      onChanged: onChanged,
    );
  }
}

class _ImageSettingsSection extends StatelessWidget {
  const _ImageSettingsSection({
    required this.previewQuality,
    required this.viewerQuality,
    required this.onPreviewQualityChanged,
    required this.onViewerQualityChanged,
  });

  final PreviewImageQuality previewQuality;
  final ViewerImageQuality viewerQuality;
  final ValueChanged<PreviewImageQuality> onPreviewQualityChanged;
  final ValueChanged<ViewerImageQuality> onViewerQualityChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(translations.settings.images.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(translations.settings.images.previewQuality, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _PreviewQualitySelector(value: previewQuality, onChanged: onPreviewQualityChanged),
        const SizedBox(height: 16),
        Text(translations.settings.images.viewerQuality, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _ViewerQualitySelector(value: viewerQuality, onChanged: onViewerQualityChanged),
      ],
    );
  }
}

class _PreviewQualitySelector extends StatelessWidget {
  const _PreviewQualitySelector({required this.value, required this.onChanged});

  final PreviewImageQuality value;
  final ValueChanged<PreviewImageQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return ConstrainedSegmentedButton<PreviewImageQuality>(
      maxWidth: null,
      segments: [
        ButtonSegment(value: PreviewImageQuality.medium, icon: const Icon(Icons.image_outlined), label: Text(translations.settings.images.medium)),
        ButtonSegment(value: PreviewImageQuality.large, icon: const Icon(Icons.photo_outlined), label: Text(translations.settings.images.large)),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}

class _ViewerQualitySelector extends StatelessWidget {
  const _ViewerQualitySelector({required this.value, required this.onChanged});

  final ViewerImageQuality value;
  final ValueChanged<ViewerImageQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return ConstrainedSegmentedButton<ViewerImageQuality>(
      maxWidth: null,
      segments: [
        ButtonSegment(
          value: ViewerImageQuality.large,
          icon: const Icon(Icons.photo_size_select_large_outlined),
          label: Text(translations.settings.images.large),
        ),
        ButtonSegment(value: ViewerImageQuality.original, icon: const Icon(Icons.open_in_full_outlined), label: Text(translations.settings.images.original)),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}

class _ProxySettingsSection extends StatelessWidget {
  const _ProxySettingsSection({required this.settings, required this.onTap});

  final AppProxySettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final translations = t.settings.proxy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(translations.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _ProxySettingsTile(settings: settings, onTap: onTap),
      ],
    );
  }
}

class _ProxySettingsTile extends StatelessWidget {
  const _ProxySettingsTile({required this.settings, required this.onTap});

  final AppProxySettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = FreepivThemeTokens.of(context);
    final translations = t.settings.proxy;
    final active = settings.active;

    return Material(
      color: Color.alphaBlend((active ? tokens.brand : tokens.surfaceTint).withValues(alpha: active ? 0.08 : 0.30), tokens.surfaceRaised),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Icon(active ? Icons.hub : Icons.hub_outlined, color: active ? tokens.brand : colorScheme.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(translations.open, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      active ? translations.entrySubtitleOn(url: settings.url!) : translations.entrySubtitleOff,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadSettingsSection extends StatelessWidget {
  const _DownloadSettingsSection({
    required this.settings,
    required this.maxConcurrentDownloads,
    required this.onModeChanged,
    required this.onChooseDirectory,
    required this.onMaxConcurrentDownloadsChanged,
  });

  final DownloadSavePathSettings settings;
  final int maxConcurrentDownloads;
  final ValueChanged<DownloadSavePathMode> onModeChanged;
  final VoidCallback onChooseDirectory;
  final ValueChanged<int> onMaxConcurrentDownloadsChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final translations = t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(translations.settings.downloads.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(translations.settings.downloads.savePath, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _DownloadPathModeSelector(value: settings.mode, onChanged: onModeChanged),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_outlined),
          title: Text(_downloadPathTitle(settings, translations)),
          subtitle: Text(_downloadPathSubtitle(settings, translations), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: settings.mode == DownloadSavePathMode.custom
              ? IconButton(
                  tooltip: translations.settings.downloads.chooseFolder,
                  icon: const Icon(Icons.folder_open_outlined),
                  color: colorScheme.primary,
                  onPressed: onChooseDirectory,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(translations.settings.downloads.maxConcurrentDownloads, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          translations.settings.downloads.maxConcurrentDownloadsSubtitle(count: maxConcurrentDownloads),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        Slider(
          value: maxConcurrentDownloads.toDouble(),
          min: AppSettings.minConcurrentDownloads.toDouble(),
          max: AppSettings.maxConcurrentDownloadsLimit.toDouble(),
          divisions: AppSettings.maxConcurrentDownloadsLimit - AppSettings.minConcurrentDownloads,
          label: '$maxConcurrentDownloads',
          onChanged: (value) => onMaxConcurrentDownloadsChanged(value.round()),
        ),
      ],
    );
  }

  String _downloadPathTitle(DownloadSavePathSettings settings, Translations translations) {
    return switch (settings.mode) {
      DownloadSavePathMode.defaultPath => translations.settings.downloads.defaultPath,
      DownloadSavePathMode.custom => translations.settings.downloads.customPath,
    };
  }

  String _downloadPathSubtitle(DownloadSavePathSettings settings, Translations translations) {
    return switch (settings.mode) {
      DownloadSavePathMode.defaultPath => translations.settings.downloads.systemDownloadsFolder,
      DownloadSavePathMode.custom => settings.customDirectory ?? translations.settings.downloads.noFolderSelected,
    };
  }
}

class _DownloadPathModeSelector extends StatelessWidget {
  const _DownloadPathModeSelector({required this.value, required this.onChanged});

  final DownloadSavePathMode value;
  final ValueChanged<DownloadSavePathMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return ConstrainedSegmentedButton<DownloadSavePathMode>(
      maxWidth: null,
      segments: [
        ButtonSegment(
          value: DownloadSavePathMode.defaultPath,
          icon: const Icon(Icons.download_outlined),
          label: Text(translations.settings.downloads.defaultPath),
        ),
        ButtonSegment(value: DownloadSavePathMode.custom, icon: const Icon(Icons.folder_outlined), label: Text(translations.settings.downloads.customPath)),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}
