import 'dart:async';

import 'package:freepiv/core/downloads/downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/i18n/strings.g.dart';

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, AppLocale?>(AppLocaleNotifier.new);

final previewImageQualityProvider = NotifierProvider<PreviewImageQualityNotifier, PreviewImageQuality>(PreviewImageQualityNotifier.new);

final viewerImageQualityProvider = NotifierProvider<ViewerImageQualityNotifier, ViewerImageQuality>(ViewerImageQualityNotifier.new);

final downloadSavePathSettingsProvider = NotifierProvider<DownloadSavePathSettingsNotifier, DownloadSavePathSettings>(DownloadSavePathSettingsNotifier.new);

final maxConcurrentDownloadsProvider = NotifierProvider<MaxConcurrentDownloadsNotifier, int>(MaxConcurrentDownloadsNotifier.new);

final proxySettingsProvider = NotifierProvider<AppProxySettingsNotifier, AppProxySettings>(AppProxySettingsNotifier.new);

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
