import 'package:flutter/material.dart';

@immutable
class AppSystemFontConfig {
  const AppSystemFontConfig({required this.family, required this.fallbacks});

  final String family;
  final List<String> fallbacks;
}

/// Font resolution for interface and content text.
///
/// The bundled Noto Sans SC and JP subsets draw Latin and CJK text alike on
/// every platform, so pages look the same on Windows, macOS, Linux and
/// mobile. The platform's own CJK fonts remain as fallbacks for characters
/// outside the bundled subsets, and the platform's colour emoji font is
/// always kept in the chain for Unicode emoji.
abstract final class AppSystemFonts {
  static const bundledSimplified = 'Noto Sans SC';
  static const bundledJapanese = 'Noto Sans JP';

  static AppSystemFontConfig resolve({required TargetPlatform platform, required Locale locale}) {
    final chinese = locale.languageCode == 'zh';
    // Traditional Chinese uses the Simplified subset's glyphs (Big5 level 1
    // is included); only Japanese keeps Japanese regional forms first.
    final family = chinese ? bundledSimplified : bundledJapanese;
    final other = chinese ? bundledJapanese : bundledSimplified;
    return AppSystemFontConfig(family: family, fallbacks: [other, ..._platformFallbacks(platform, locale)]);
  }

  static List<String> _platformFallbacks(TargetPlatform platform, Locale locale) => switch (platform) {
    TargetPlatform.linux => [
      ..._cjkFallbacks(locale, jp: 'Noto Sans CJK JP', simplified: 'Noto Sans CJK SC', traditional: 'Noto Sans CJK TC'),
      'Noto Color Emoji',
      'Symbola',
    ],
    TargetPlatform.windows => [
      ..._cjkFallbacks(locale, jp: 'Yu Gothic UI', simplified: 'Microsoft YaHei UI', traditional: 'Microsoft JhengHei UI'),
      'Segoe UI Emoji',
      'Segoe UI Symbol',
    ],
    TargetPlatform.macOS ||
    TargetPlatform.iOS => [..._cjkFallbacks(locale, jp: 'Hiragino Sans', simplified: 'PingFang SC', traditional: 'PingFang TC'), 'Apple Color Emoji'],
    TargetPlatform.android || TargetPlatform.fuchsia => [
      ..._cjkFallbacks(locale, jp: 'Noto Sans CJK JP', simplified: 'Noto Sans CJK SC', traditional: 'Noto Sans CJK TC'),
      'Noto Color Emoji',
    ],
  };

  static List<String> _cjkFallbacks(Locale locale, {required String jp, required String simplified, required String traditional}) {
    if (locale.languageCode == 'ja') {
      return [jp, simplified, traditional];
    }

    if (locale.languageCode == 'zh') {
      final usesTraditional = locale.scriptCode == 'Hant' || const {'HK', 'MO', 'TW'}.contains(locale.countryCode);
      return usesTraditional ? [traditional, simplified, jp] : [simplified, traditional, jp];
    }

    // Pixiv content is predominantly Japanese, so prefer its regional glyphs
    // when the application locale itself does not identify a CJK variant.
    return [jp, simplified, traditional];
  }
}
