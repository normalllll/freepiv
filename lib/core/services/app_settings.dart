import 'dart:async';
import 'dart:convert';

import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

enum PreviewImageQuality { medium, large }

enum ViewerImageQuality { large, original }

enum DownloadSavePathMode { defaultPath, custom }

enum AppProxyProtocol {
  http,
  socks;

  String get urlScheme {
    return switch (this) {
      AppProxyProtocol.http => 'http',
      AppProxyProtocol.socks => 'socks5',
    };
  }
}

class AppProxySettings {
  const AppProxySettings({required this.enabled, this.url});

  final bool enabled;
  final String? url;

  bool get hasUrl => url != null && url!.isNotEmpty;

  bool get active => enabled && hasUrl;

  String? get activeUrl => active ? url : null;

  AppProxySettings copyWith({bool? enabled, String? url, bool clearUrl = false}) {
    return AppProxySettings(enabled: enabled ?? this.enabled, url: clearUrl ? null : url ?? this.url);
  }

  @override
  int get hashCode => Object.hash(enabled, url);

  @override
  bool operator ==(Object other) {
    return other is AppProxySettings && other.enabled == enabled && other.url == url;
  }
}

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
  static const _maxConcurrentDownloadsKey = 'maxConcurrentDownloads';
  static const _proxyEnabledKey = 'proxyEnabled';
  static const _proxyUrlKey = 'proxyUrl';

  static const defaultLocaleCode = 'en-US';
  static const supportedLocaleCodes = {'en-US', 'zh-CN', 'zh-Hant-TW', 'ja-JP'};
  static const defaultMaxConcurrentDownloads = 3;
  static const minConcurrentDownloads = 1;
  static const maxConcurrentDownloadsLimit = 6;

  static const _settingKeys = {
    _accountSessionKey,
    _themeModeKey,
    _localeCodeKey,
    _previewImageQualityKey,
    _viewerImageQualityKey,
    _downloadSavePathModeKey,
    _downloadCustomDirectoryKey,
    _maxConcurrentDownloadsKey,
    _proxyEnabledKey,
    _proxyUrlKey,
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

  static int get maxConcurrentDownloads {
    final value = _values[_maxConcurrentDownloadsKey];
    if (value is int && _isValidMaxConcurrentDownloads(value)) {
      return value;
    }
    return defaultMaxConcurrentDownloads;
  }

  static set maxConcurrentDownloads(int value) {
    _write(_maxConcurrentDownloadsKey, _normalizeMaxConcurrentDownloads(value));
  }

  static AppProxySettings get proxySettings {
    return AppProxySettings(enabled: proxyEnabled, url: proxyUrl);
  }

  static set proxySettings(AppProxySettings value) {
    proxyUrl = value.url;
    proxyEnabled = value.enabled;
  }

  static bool get proxyEnabled {
    return _values[_proxyEnabledKey] == true;
  }

  static set proxyEnabled(bool value) {
    _write(_proxyEnabledKey, value);
  }

  static String? get proxyUrl {
    final value = _values[_proxyUrlKey];
    if (value is String) {
      return normalizeProxyUrl(value);
    }
    return null;
  }

  static set proxyUrl(String? value) {
    _write(_proxyUrlKey, value == null ? null : normalizeProxyUrl(value));
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
      _maxConcurrentDownloadsKey => value is int && _isValidMaxConcurrentDownloads(value),
      _proxyEnabledKey => value is bool,
      _proxyUrlKey => value is String && normalizeProxyUrl(value) != null,
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

  static bool _isValidMaxConcurrentDownloads(int value) {
    return value >= minConcurrentDownloads && value <= maxConcurrentDownloadsLimit;
  }

  static int _normalizeMaxConcurrentDownloads(int value) {
    return value.clamp(minConcurrentDownloads, maxConcurrentDownloadsLimit).toInt();
  }

  static AppSettingsStore get _activeStore {
    final store = _store;
    if (store == null) {
      throw StateError('AppSettings.initialize() must be called before writing settings.');
    }
    return store;
  }
}

String? normalizeProxyUrl(String value, {AppProxyProtocol defaultProtocol = AppProxyProtocol.http}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final withScheme = trimmed.contains('://') ? trimmed : '${defaultProtocol.urlScheme}://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
    return null;
  }

  final scheme = _normalizedProxyScheme(uri.scheme);
  if (scheme == null) {
    return null;
  }

  final port = _proxyPort(uri);
  if (port <= 0 || port > 65535) {
    return null;
  }

  if (uri.userInfo.isNotEmpty || !_isValidProxyHost(uri.host)) {
    return null;
  }

  if ((uri.path.isNotEmpty && uri.path != '/') || uri.query.isNotEmpty || uri.fragment.isNotEmpty) {
    return null;
  }

  return Uri(scheme: scheme, host: uri.host, port: port).toString();
}

String? normalizeProxyEndpoint({required String host, required String port, AppProxyProtocol protocol = AppProxyProtocol.http}) {
  final cleanHost = _cleanProxyHostInput(host);
  final cleanPort = port.trim();
  if (!_isValidProxyHost(cleanHost) || !_isValidProxyPort(cleanPort)) {
    return null;
  }

  final urlHost = cleanHost.contains(':') ? '[$cleanHost]' : cleanHost;
  return normalizeProxyUrl('$urlHost:$cleanPort', defaultProtocol: protocol);
}

String proxyHostFromUrl(String url) {
  final normalizedUrl = normalizeProxyUrl(url);
  if (normalizedUrl == null) {
    return '';
  }

  return Uri.parse(normalizedUrl).host;
}

String proxyPortFromUrl(String url) {
  final normalizedUrl = normalizeProxyUrl(url);
  if (normalizedUrl == null) {
    return '';
  }

  return Uri.parse(normalizedUrl).port.toString();
}

bool isValidProxyHostInput(String host) {
  return _isValidProxyHost(host);
}

bool isValidProxyPortInput(String port) {
  return _isValidProxyPort(port);
}

AppProxyProtocol proxyProtocolFromUrl(String url) {
  final normalizedUrl = normalizeProxyUrl(url);
  if (normalizedUrl == null) {
    return AppProxyProtocol.http;
  }

  final scheme = Uri.parse(normalizedUrl).scheme.toLowerCase();
  return scheme.startsWith('socks') ? AppProxyProtocol.socks : AppProxyProtocol.http;
}

String? _normalizedProxyScheme(String scheme) {
  final lower = scheme.toLowerCase();
  return switch (lower) {
    'http' || 'https' => 'http',
    'socks' || 'socks4' || 'socks5' => 'socks5',
    _ => null,
  };
}

int _proxyPort(Uri uri) {
  try {
    return uri.hasPort ? uri.port : -1;
  } on FormatException {
    return -1;
  }
}

bool _isValidProxyHost(String host) {
  final trimmed = _cleanProxyHostInput(host);
  if (trimmed.isEmpty || trimmed.contains(RegExp(r'\s'))) {
    return false;
  }

  if (trimmed.contains(':')) {
    return RegExp(r'^[0-9a-fA-F:.]+$').hasMatch(trimmed);
  }

  final labels = trimmed.split('.');
  return labels.every((label) {
    return label.isNotEmpty && label.length <= 63 && !label.startsWith('-') && !label.endsWith('-') && RegExp(r'^[A-Za-z0-9-]+$').hasMatch(label);
  });
}

bool _isValidProxyPort(String port) {
  final trimmed = port.trim();
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
    return false;
  }

  final value = int.tryParse(trimmed);
  return value != null && value > 0 && value <= 65535;
}

String _cleanProxyHostInput(String host) {
  final trimmed = host.trim();
  if (trimmed.length >= 2 && trimmed.startsWith('[') && trimmed.endsWith(']')) {
    return trimmed.substring(1, trimmed.length - 1);
  }

  return trimmed;
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
