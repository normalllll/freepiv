import 'dart:async';
import 'dart:convert';

import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

enum PreviewImageQuality { medium, large }

enum ViewerImageQuality { large, original }

enum DownloadSavePathMode { defaultPath, custom }

abstract interface class AppSettingsStore {
  Map<String, dynamic> load();

  Future<void> write(String key, dynamic value);
}

final class HiveAppSettingsStore implements AppSettingsStore {
  HiveAppSettingsStore(this._box);

  static Future<HiveAppSettingsStore> open() async {
    await Hive.initFlutter();
    return HiveAppSettingsStore(await Hive.openBox<dynamic>(AppSettings.boxName));
  }

  final Box<dynamic> _box;

  @override
  Map<String, dynamic> load() {
    final values = <String, dynamic>{};
    for (final key in _box.keys) {
      if (key is String) {
        values[key] = _box.get(key);
      }
    }
    return values;
  }

  @override
  Future<void> write(String key, dynamic value) {
    if (value == null) {
      return _box.delete(key);
    }
    return _box.put(key, value);
  }
}

class AppSettings {
  AppSettings._();

  static const boxName = 'app_settings';

  static const _accountSessionKey = 'accountSession';
  static const _themeModeKey = 'themeMode';
  static const _localeCodeKey = 'localeCode';
  static const _previewImageQualityKey = 'previewImageQuality';
  static const _viewerImageQualityKey = 'viewerImageQuality';
  static const _downloadSavePathModeKey = 'downloadSavePathMode';
  static const _downloadCustomDirectoryKey = 'downloadCustomDirectory';

  static const defaultLocaleCode = 'en-US';
  static const supportedLocaleCodes = {'en-US', 'zh-CN', 'zh-Hant-TW', 'ja-JP'};

  static const _settingKeys = {
    _accountSessionKey,
    _themeModeKey,
    _localeCodeKey,
    _previewImageQualityKey,
    _viewerImageQualityKey,
    _downloadSavePathModeKey,
    _downloadCustomDirectoryKey,
  };

  static final Map<String, dynamic> _values = {};
  static AppSettingsStore? _store;

  static UserAccountResult? get accountSession {
    return _accountSessionFromJson(_values[_accountSessionKey]);
  }

  static set accountSession(UserAccountResult? value) {
    _write(_accountSessionKey, value == null ? null : _accountSessionToJson(value));
  }

  static int? get themeMode => _values[_themeModeKey] as int?;

  static set themeMode(int? value) {
    _write(_themeModeKey, value);
  }

  static String? get localeCode {
    final value = _values[_localeCodeKey];
    if (value is String && supportedLocaleCodes.contains(value)) {
      return value;
    }

    return null;
  }

  static set localeCode(String? value) {
    _write(_localeCodeKey, value == null || supportedLocaleCodes.contains(value) ? value : defaultLocaleCode);
  }

  static PreviewImageQuality get previewImageQuality {
    return _enumSetting(_previewImageQualityKey, PreviewImageQuality.values, PreviewImageQuality.medium);
  }

  static set previewImageQuality(PreviewImageQuality value) {
    _write(_previewImageQualityKey, value.name);
  }

  static ViewerImageQuality get viewerImageQuality {
    return _enumSetting(_viewerImageQualityKey, ViewerImageQuality.values, ViewerImageQuality.large);
  }

  static set viewerImageQuality(ViewerImageQuality value) {
    _write(_viewerImageQualityKey, value.name);
  }

  static DownloadSavePathMode get downloadSavePathMode {
    return _enumSetting(_downloadSavePathModeKey, DownloadSavePathMode.values, DownloadSavePathMode.defaultPath);
  }

  static set downloadSavePathMode(DownloadSavePathMode value) {
    _write(_downloadSavePathModeKey, value.name);
  }

  static String? get downloadCustomDirectory {
    final value = _values[_downloadCustomDirectoryKey];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  static set downloadCustomDirectory(String? value) {
    _write(_downloadCustomDirectoryKey, value == null || value.isEmpty ? null : value);
  }

  static Future<void> initialize({AppSettingsStore? store}) async {
    _store = store ?? await HiveAppSettingsStore.open();

    _values
      ..clear()
      ..addAll(_filterSettings(_activeStore.load()));
  }

  static void _write(String key, dynamic value) {
    final store = _activeStore;
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
    unawaited(store.write(key, value));
  }

  static Map<String, dynamic> _filterSettings(Map<String, dynamic> values) {
    final settings = <String, dynamic>{};
    for (final entry in values.entries) {
      if (_settingKeys.contains(entry.key) && _isValidSettingValue(entry.key, entry.value)) {
        settings[entry.key] = entry.value;
      }
    }
    return settings;
  }

  static bool _isValidSettingValue(String key, dynamic value) {
    if (value == null) {
      return true;
    }

    return switch (key) {
      _accountSessionKey => _accountSessionFromJson(value) != null,
      _themeModeKey => value is int && value >= 0 && value <= 2,
      _localeCodeKey => value is String && supportedLocaleCodes.contains(value),
      _previewImageQualityKey => _isEnumSettingValue(value, PreviewImageQuality.values),
      _viewerImageQualityKey => _isEnumSettingValue(value, ViewerImageQuality.values),
      _downloadSavePathModeKey => _isEnumSettingValue(value, DownloadSavePathMode.values),
      _downloadCustomDirectoryKey => value is String && value.isNotEmpty,
      _ => false,
    };
  }

  static T _enumSetting<T extends Enum>(String key, List<T> values, T fallback) {
    final value = _values[key];
    if (value is String) {
      for (final enumValue in values) {
        if (enumValue.name == value) {
          return enumValue;
        }
      }
    }

    return fallback;
  }

  static bool _isEnumSettingValue<T extends Enum>(Object value, List<T> values) {
    return value is String && values.any((enumValue) => enumValue.name == value);
  }

  static AppSettingsStore get _activeStore {
    final store = _store;
    if (store == null) {
      throw StateError('AppSettings.initialize() must be called before writing settings.');
    }
    return store;
  }
}

Map<String, dynamic> _accountSessionToJson(UserAccountResult account) {
  return _jsonMap(account.toJson()) ?? <String, dynamic>{};
}

UserAccountResult? _accountSessionFromJson(Object? value) {
  final json = _jsonMap(value);
  if (json == null) {
    return null;
  }

  try {
    return UserAccountResult.fromJson(json);
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _jsonMap(Object? value) {
  try {
    final decoded = value is String ? json.decode(value) : json.decode(json.encode(value));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {
    // Invalid persisted settings should be ignored.
  }

  return null;
}
