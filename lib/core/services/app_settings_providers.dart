import 'dart:async';

import 'package:freepiv/core/downloads/downloader.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:flutter/foundation.dart';

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, AppLocale?>(AppLocaleNotifier.new);

final previewImageQualityProvider = NotifierProvider<PreviewImageQualityNotifier, PreviewImageQuality>(PreviewImageQualityNotifier.new);

final viewerImageQualityProvider = NotifierProvider<ViewerImageQualityNotifier, ViewerImageQuality>(ViewerImageQualityNotifier.new);

final downloadSavePathSettingsProvider = NotifierProvider<DownloadSavePathSettingsNotifier, DownloadSavePathSettings>(DownloadSavePathSettingsNotifier.new);

final maxConcurrentDownloadsProvider = NotifierProvider<MaxConcurrentDownloadsNotifier, int>(MaxConcurrentDownloadsNotifier.new);

final recordHistoryProvider = NotifierProvider<RecordHistoryNotifier, bool>(RecordHistoryNotifier.new);

final historyLimitProvider = NotifierProvider<HistoryLimitNotifier, HistoryLimit>(HistoryLimitNotifier.new);

final proxySettingsProvider = NotifierProvider<AppProxySettingsNotifier, AppProxySettings>(AppProxySettingsNotifier.new);

final backgroundSettingsProvider = NotifierProvider<BackgroundSettingsNotifier, BackgroundSettings>(BackgroundSettingsNotifier.new);

final sidebarExpandedProvider = NotifierProvider<SidebarExpandedNotifier, bool>(SidebarExpandedNotifier.new);

final readerSettingsProvider = NotifierProvider<ReaderSettingsNotifier, ReaderSettings>(ReaderSettingsNotifier.new);

Future<void> initializeLocaleSettings() async {
  final localeCode = AppSettings.localeCode;
  if (localeCode == null) {
    await LocaleSettings.useDeviceLocale();
    return;
  }

  await LocaleSettings.setLocale(_appLocaleFromCode(localeCode));
}

class AppLocaleNotifier extends Notifier<AppLocale?> {
  @override
  AppLocale? build() {
    final localeCode = AppSettings.localeCode;
    return localeCode == null ? null : _appLocaleFromCode(localeCode);
  }

  Future<void> setLocale(AppLocale? locale) async {
    if (state == locale) {
      return;
    }

    if (locale == null) {
      await LocaleSettings.useDeviceLocale();
    } else {
      await LocaleSettings.setLocale(locale);
    }

    AppSettings.localeCode = locale?.languageTag;
    refreshPixivApiLanguage();
    state = locale;
  }
}

class PreviewImageQualityNotifier extends Notifier<PreviewImageQuality> {
  @override
  PreviewImageQuality build() {
    return AppSettings.previewImageQuality;
  }

  void setQuality(PreviewImageQuality quality) {
    state = quality;
    AppSettings.previewImageQuality = quality;
  }
}

class ViewerImageQualityNotifier extends Notifier<ViewerImageQuality> {
  @override
  ViewerImageQuality build() {
    return AppSettings.viewerImageQuality;
  }

  void setQuality(ViewerImageQuality quality) {
    state = quality;
    AppSettings.viewerImageQuality = quality;
  }
}

class AppProxySettingsNotifier extends Notifier<AppProxySettings> {
  @override
  AppProxySettings build() {
    return AppSettings.proxySettings;
  }

  void setProxySettings(AppProxySettings settings) {
    AppSettings.proxySettings = settings;
    refreshPixivApiProxy();
    state = AppSettings.proxySettings;
  }
}

class MaxConcurrentDownloadsNotifier extends Notifier<int> {
  @override
  int build() {
    return AppSettings.maxConcurrentDownloads;
  }

  void setLimit(int limit) {
    AppSettings.maxConcurrentDownloads = limit;
    state = AppSettings.maxConcurrentDownloads;
    unawaited(downloadManager.refreshQueue());
  }
}

class RecordHistoryNotifier extends Notifier<bool> {
  @override
  bool build() => AppSettings.recordHistory;

  void set(bool record) {
    AppSettings.recordHistory = record;
    state = record;
  }
}

class HistoryLimitNotifier extends Notifier<HistoryLimit> {
  @override
  HistoryLimit build() => AppSettings.historyLimit;

  void set(HistoryLimit limit) {
    AppSettings.historyLimit = limit;
    state = limit;
  }
}

class DownloadSavePathSettings {
  const DownloadSavePathSettings({required this.mode, required this.customDirectory});

  final DownloadSavePathMode mode;
  final String? customDirectory;

  DownloadSavePathSettings copyWith({DownloadSavePathMode? mode, String? customDirectory}) {
    return DownloadSavePathSettings(mode: mode ?? this.mode, customDirectory: customDirectory ?? this.customDirectory);
  }

  @override
  int get hashCode => Object.hash(mode, customDirectory);

  @override
  bool operator ==(Object other) {
    return other is DownloadSavePathSettings && other.mode == mode && other.customDirectory == customDirectory;
  }
}

class DownloadSavePathSettingsNotifier extends Notifier<DownloadSavePathSettings> {
  @override
  DownloadSavePathSettings build() {
    return DownloadSavePathSettings(mode: AppSettings.downloadSavePathMode, customDirectory: AppSettings.downloadCustomDirectory);
  }

  void useDefaultDirectory() {
    state = state.copyWith(mode: DownloadSavePathMode.defaultPath);
    AppSettings.downloadSavePathMode = DownloadSavePathMode.defaultPath;
  }

  void useCustomDirectory(String directory) {
    state = DownloadSavePathSettings(mode: DownloadSavePathMode.custom, customDirectory: directory);
    AppSettings.downloadCustomDirectory = directory;
    AppSettings.downloadSavePathMode = DownloadSavePathMode.custom;
  }

  void useExistingCustomDirectory() {
    if (state.customDirectory == null) {
      return;
    }

    state = state.copyWith(mode: DownloadSavePathMode.custom);
    AppSettings.downloadSavePathMode = DownloadSavePathMode.custom;
  }
}

AppLocale _appLocaleFromCode(String code) {
  try {
    return AppLocaleUtils.parse(code);
  } catch (_) {
    return AppLocale.enUs;
  }
}

/// What the window is painted with and how strongly.
typedef BackgroundSettings = ({BackgroundMaterial material, int intensity});

class BackgroundSettingsNotifier extends Notifier<BackgroundSettings> {
  @override
  BackgroundSettings build() => (material: AppSettings.backgroundMaterial, intensity: AppSettings.backgroundIntensity);

  void setMaterial(BackgroundMaterial material) {
    if (state.material == material) return;
    state = (material: material, intensity: state.intensity);
    AppSettings.backgroundMaterial = material;
  }

  /// Shows [value] while the slider moves, without saving it.
  void previewIntensity(double value) => state = (material: state.material, intensity: AppSettings.normalizeBackgroundIntensity(value));

  /// Saves [value] when the slider is let go.
  void saveIntensity(double value) {
    previewIntensity(value);
    AppSettings.backgroundIntensity = state.intensity;
  }
}

class SidebarExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => AppSettings.sidebarExpanded;

  void setExpanded(bool expanded) {
    if (state == expanded) return;
    state = expanded;
    AppSettings.sidebarExpanded = expanded;
  }
}

/// The novel reader's typography and controls, kept across launches.
@immutable
class ReaderSettings {
  const ReaderSettings({required this.textSize, required this.lineHeight, required this.autoScrollSpeed, required this.volumeKeys});

  final double textSize;
  final double lineHeight;
  final double autoScrollSpeed;
  final bool volumeKeys;

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.textSize == textSize &&
      other.lineHeight == lineHeight &&
      other.autoScrollSpeed == autoScrollSpeed &&
      other.volumeKeys == volumeKeys;

  @override
  int get hashCode => Object.hash(textSize, lineHeight, autoScrollSpeed, volumeKeys);
}

class ReaderSettingsNotifier extends Notifier<ReaderSettings> {
  @override
  ReaderSettings build() => ReaderSettings(
    textSize: AppSettings.readerFontSize,
    lineHeight: AppSettings.readerLineHeight,
    autoScrollSpeed: AppSettings.readerAutoScrollSpeed,
    volumeKeys: AppSettings.readerVolumeKeys,
  );

  void setTextSize(double value) {
    AppSettings.readerFontSize = value;
    state = build();
  }

  void setLineHeight(double value) {
    AppSettings.readerLineHeight = value;
    state = build();
  }

  void setAutoScrollSpeed(double value) {
    AppSettings.readerAutoScrollSpeed = value;
    state = build();
  }

  void setVolumeKeys(bool value) {
    AppSettings.readerVolumeKeys = value;
    state = build();
  }
}
