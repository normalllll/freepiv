import 'package:freepiv/app/frost_config.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:freepiv/features/fanbox/account_settings.dart';
import 'package:freepiv/features/settings/presentation/appearance_settings_section.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/app/theme/transparency_logic.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/settings/presentation/proxy_settings_dialog.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/app/router/app_route.dart';

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
    final themeMode = ref.watch(appearanceProvider).settings.mode;
    final appLocale = ref.watch(appLocaleProvider);
    final previewQuality = ref.watch(previewImageQualityProvider);
    final viewerQuality = ref.watch(viewerImageQualityProvider);
    final downloadPathSettings = ref.watch(downloadSavePathSettingsProvider);
    final maxConcurrentDownloads = ref.watch(maxConcurrentDownloadsProvider);
    final proxySettings = ref.watch(proxySettingsProvider);
    final reduceTransparency = ref.watch(reduceTransparencyProvider);
    final translations = t;

    final groups = <List<Widget>>[
      [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppearanceSettingsSection(
                modeSelector: ThemeModeSelector(value: themeMode, onChanged: (mode) => ref.read(appearanceProvider.notifier).setMode(mode)),
              ),
              const SizedBox(height: 16),
              FrostListRow.toggle(
                title: translations.settings.theme.reduceTransparency,
                subtitle: FrostRowSubtitle(translations.settings.theme.reduceTransparencyHint),
                value: reduceTransparency,
                onChanged: (value) => ref.read(reduceTransparencyProvider.notifier).setEnabled(value),
              ),
            ],
          ),
        ),
      ],
      [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(translations.settings.language.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _LanguageSelector(
                value: appLocale,
                onChanged: (locale) {
                  unawaited(ref.read(appLocaleProvider.notifier).setLocale(locale));
                },
              ),
            ],
          ),
        ),
      ],
      [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
            ],
          ),
        ),
      ],
      [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_ProxySettingsSection(settings: proxySettings, onTap: () => showProxySettingsDialog(context))],
          ),
        ),
      ],
      [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
      ],
      [const Padding(padding: EdgeInsets.all(16), child: FanboxAccountSettings())],
      [
        ListTile(
          title: Text(translations.settings.account.signOut),
          leading: const Icon(Icons.logout),
          onTap: pixivAccountNotifier.value == null
              ? null
              : () {
                  setPixivAccount(null);
                  context.go(AppRoute.login.path);
                },
        ),
      ],
    ];
    Widget section(int index) => SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: groups[index]),
    );

    return FrostAutoScaffold(
      builder: (context, layout, orientation, useHorizontalLayout) {
        return Scaffold(
          appBar: useHorizontalLayout ? null : PivAppBar(FrostPageHeader(title: Text(translations.navigation.settings))),
          body: _withSidebarHeading(
            context,
            useHorizontalLayout: useHorizontalLayout,
            child: FrostSettingsSections(
              labels: [
                translations.settings.theme.title,
                translations.settings.language.title,
                translations.settings.images.title,
                translations.settings.proxy.title,
                translations.settings.downloads.title,
                translations.fanbox.title,
                translations.settings.account.title,
              ],
              selectedIndex: _section,
              onSelected: (index) => setState(() => _section = index),
              sectionBuilder: (context, index) => section(index),
              compact: FrostSectionsCompact(
                section: _sectionOpen ? section(_section) : null,
                onClose: () => setState(() => _sectionOpen = false),
                onNavigate: (index) => setState(() {
                  _section = index;
                  _sectionOpen = true;
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  /// In the sidebar layout the page title is a large heading above the
  /// sections, like the downloads page; Windows shows it in the caption bar.
  Widget _withSidebarHeading(BuildContext context, {required bool useHorizontalLayout, required Widget child}) {
    if (!useHorizontalLayout) return child;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          FrostInlinePageHeading(title: t.navigation.settings),
          Expanded(child: child),
        ],
      ),
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
      FrostToast.success(t.settings.downloads.directorySet(path: downloadPath));
    } catch (error) {
      if (!mounted) {
        return;
      }
      toastErrorWithCause(t.settings.downloads.directoryUnavailable, error);
    }
  }
}

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({required this.value, required this.onChanged, super.key});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;
    final tokens = FrostThemeTokens.of(context);
    final options = [
      (mode: ThemeMode.system, icon: Icons.brightness_auto_outlined, label: translations.settings.theme.system),
      (mode: ThemeMode.light, icon: Icons.light_mode_outlined, label: translations.settings.theme.light),
      (mode: ThemeMode.dark, icon: Icons.dark_mode_outlined, label: translations.settings.theme.dark),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 14);
        final painter = TextPainter(textDirection: Directionality.of(context), textScaler: MediaQuery.textScalerOf(context));
        var requiredWidth = 8.0;
        for (final option in options) {
          painter.text = TextSpan(text: option.label, style: style);
          painter.layout();
          requiredWidth += painter.width + 52;
        }
        final vertical = constraints.maxWidth < requiredWidth;
        final children = [
          for (final option in options)
            _ThemeModeOption(
              key: ValueKey('theme-mode-${option.mode.name}'),
              label: option.label,
              icon: option.icon,
              selected: option.mode == value,
              onTap: () => onChanged(option.mode),
            ),
        ];
        return DecoratedBox(
          key: const ValueKey('theme-mode-track'),
          decoration: BoxDecoration(color: tokens.surfaceInset, borderRadius: BorderRadius.circular(FrostRadius.lg)),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: vertical
                ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
                : Row(children: [for (final child in children) Expanded(child: child)]),
          ),
        );
      },
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({required this.label, required this.icon, required this.selected, required this.onTap, super.key});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = FrostThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: AnimatedContainer(
          duration: FrostMotion.duration(context, FrostMotion.hover),
          decoration: BoxDecoration(
            color: selected ? tokens.surfaceRaised : tokens.surfaceInset,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: tokens.isDark ? .18 : .07),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: FrostClickSurface(
              feedback: FrostClickFeedback.quiet,
              shape: FrostClickShape.rounded(BorderRadius.circular(8)),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: FrostDensity.of(context).pointerFieldHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Same selection language as FrostSegmentedButton:
                          // raised pill, accent ink and weight, no underline.
                          Icon(icon, size: FrostControlSize.regular.iconSize, color: selected ? tokens.selectionInk : tokens.textSecondary),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: selected ? tokens.selectionInk : tokens.textSecondary,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The languages the app offers, each written in its own language.
const languageOptionNames = <AppLocale, String>{AppLocale.enUs: 'English', AppLocale.zhCn: '简体中文', AppLocale.zhHantTw: '繁體中文', AppLocale.jaJp: '日本語'};

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.value, required this.onChanged});

  final AppLocale? value;
  final ValueChanged<AppLocale?> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = t;

    return FrostPicker<AppLocale?>.menu(
      label: translations.settings.language.title,
      value: value,
      options: [
        FrostPickerOption(value: null, label: translations.settings.language.systemDefault),
        // Each language is named in itself, so a wrong pick can always be undone.
        for (final entry in languageOptionNames.entries) FrostPickerOption(value: entry.key, label: entry.value),
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

    return FrostPicker<PreviewImageQuality>.segmented(
      label: translations.settings.images.title,
      options: [
        FrostPickerOption(
          value: PreviewImageQuality.medium,
          leading: const FrostGlyph.icon(FrostIconData.glyph(Icons.image_outlined)),
          label: translations.settings.images.medium,
        ),
        FrostPickerOption(
          value: PreviewImageQuality.large,
          leading: const FrostGlyph.icon(FrostIconData.glyph(Icons.photo_outlined)),
          label: translations.settings.images.large,
        ),
      ],
      value: value,
      onChanged: (selection) => onChanged(selection),
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

    return FrostPicker<ViewerImageQuality>.segmented(
      label: translations.settings.images.title,
      options: [
        FrostPickerOption(
          value: ViewerImageQuality.large,
          leading: const FrostGlyph.icon(FrostIconData.glyph(Icons.photo_size_select_large_outlined)),
          label: translations.settings.images.large,
        ),
        FrostPickerOption(
          value: ViewerImageQuality.original,
          leading: const FrostGlyph.icon(FrostIconData.glyph(Icons.open_in_full_outlined)),
          label: translations.settings.images.original,
        ),
      ],
      value: value,
      onChanged: (selection) => onChanged(selection),
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
    final tokens = FrostThemeTokens.of(context);
    final translations = t.settings.proxy;
    final active = settings.active;

    return Material(
      color: tokens.surfaceRaised,
      borderRadius: BorderRadius.circular(8),
      child: FrostClickSurface(
        shape: FrostClickShape.rounded(BorderRadius.circular(8)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Icon(active ? Icons.hub : Icons.hub_outlined, color: active ? tokens.keyGraphicOn(tokens.surfaceRaised) : colorScheme.onSurfaceVariant),
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
    final tokens = FrostThemeTokens.of(context);
    final translations = t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(translations.settings.downloads.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(translations.settings.downloads.savePath, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (isDesktopPlatform) _DownloadPathModeSelector(value: settings.mode, onChanged: onModeChanged),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_outlined),
          title: Text(_downloadPathTitle(settings, translations)),
          subtitle: Text(_downloadPathSubtitle(settings, translations), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: isDesktopPlatform && settings.mode == DownloadSavePathMode.custom
              ? IconButton(
                  tooltip: translations.settings.downloads.chooseFolder,
                  icon: const Icon(Icons.folder_open_outlined),
                  color: tokens.keyGraphicOn(tokens.surfaceRaised),
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

    return FrostPicker<DownloadSavePathMode>.segmented(
      label: translations.settings.images.title,
      options: [
        FrostPickerOption(
          value: DownloadSavePathMode.defaultPath,
          leading: const FrostGlyph.icon(FrostIconData.glyph(Icons.download_outlined)),
          label: translations.settings.downloads.defaultPath,
        ),
        FrostPickerOption(
          value: DownloadSavePathMode.custom,
          leading: const FrostGlyph.icon(FrostIconData.glyph(Icons.folder_outlined)),
          label: translations.settings.downloads.customPath,
        ),
      ],
      value: value,
      onChanged: (selection) => onChanged(selection),
    );
  }
}
